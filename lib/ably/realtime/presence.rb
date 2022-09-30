module Ably::Realtime
  # Enables the presence set to be entered and subscribed to, and the historic presence set to be retrieved for a channel.
  #
  class Presence
    include Ably::Modules::Conversions
    include Ably::Modules::EventEmitter
    include Ably::Modules::AsyncWrapper
    include Ably::Modules::MessageEmitter
    include Ably::Modules::SafeYield
    extend Ably::Modules::Enum

    STATE = ruby_enum('STATE',
      :initialized,
      :entering,
      :entered,
      :leaving,
      :left
    )
    include Ably::Modules::StateEmitter
    include Ably::Modules::UsesStateMachine

    # {Ably::Realtime::Channel} this Presence object is associated with
    # @return [Ably::Realtime::Channel]
    attr_reader :channel

    # The client_id for the member present on this channel
    # @return [String]
    attr_reader :client_id

    # The data for the member present on this channel
    # @return [String]
    attr_reader :data

    # {MembersMap} containing an up to date list of members on this channel
    # @return [MembersMap]
    # @api private
    attr_reader :members

    # The Presence manager responsible for actions relating to state changes such as entering a channel
    # @return [Ably::Realtime::Presence::PresenceManager]
    # @api private
    attr_reader :manager

    def initialize(channel)
      @channel       = channel
      @client_id     = client.client_id

      @state_machine = PresenceStateMachine.new(self)
      @state         = STATE(state_machine.current_state)
      @members       = MembersMap.new(self)
      @manager       = PresenceManager.new(self)
    end

    # Enter this client into this channel. This client will be added to the presence set
    # and presence subscribers will see an enter message for this client.
    #
    # @param [String,Hash,nil]   data   optional data (eg a status message) for this member
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with this {Ably::Realtime::Presence} object
    # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
    #
    def enter(data = nil, &success_block)
      deferrable = create_deferrable

      ensure_supported_payload data
      @data = data

      return deferrable_succeed(deferrable, &success_block) if state == STATE.Entered

      requirements_failed_deferrable = ensure_presence_publishable_on_connection_deferrable
      return requirements_failed_deferrable if requirements_failed_deferrable

      ensure_channel_attached(deferrable) do
        if entering?
          once_or_if(STATE.Entered, else: lambda { |args| deferrable_fail deferrable, *args }) do
            deferrable_succeed deferrable, &success_block
          end
        else
          current_state = state
          change_state STATE.Entering
          send_protocol_message_and_transition_state_to(
            Ably::Models::PresenceMessage::ACTION.Enter,
            deferrable:   deferrable,
            target_state: STATE.Entered,
            data:         data,
            client_id:    client_id,
            failed_state: current_state, # return to current state if enter fails
            &success_block
          )
        end
      end
    end

    # Enters the presence set of the channel for a given clientId. Enables a single client to update presence on behalf
    # of any number of clients using a single connection. The library must have been instantiated with an API key
    # or a token bound to a wildcard clientId. An optional callback may be provided to notify of the success or failure of the operation.
    #
    # @spec RTP4, RTP14, RTP15
    #
    # @param [String]  client_id   id of the client
    # @param [String,Hash,nil]   data   The payload associated with the presence member. A JSON object of arbitrary key-value pairs that may contain metadata, and/or ancillary payloads.
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with this {Ably::Realtime::Presence} object
    # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
    #
    def enter_client(client_id, data = nil, &success_block)
      ensure_supported_client_id client_id
      ensure_supported_payload data

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Enter, client_id, data, &success_block)
    end

    # Leave this client from this channel. This client will be removed from the presence
    # set and presence subscribers will see a leave message for this client.
    #
    # @param (see Presence#enter)
    #
    # @yield (see Presence#enter)
    # @return (see Presence#enter)
    #
    def leave(data = nil, &success_block)
      deferrable = create_deferrable

      ensure_supported_payload data

      @data = data

      return deferrable_succeed(deferrable, &success_block) if state == STATE.Left

      requirements_failed_deferrable = ensure_presence_publishable_on_connection_deferrable
      return requirements_failed_deferrable if requirements_failed_deferrable

      ensure_channel_attached(deferrable) do
        if leaving?
          once_or_if(STATE.Left, else: lambda { |error|deferrable_fail deferrable, *args }) do
            deferrable_succeed deferrable, &success_block
          end
        else
          current_state = state
          change_state STATE.Leaving
          send_protocol_message_and_transition_state_to(
            Ably::Models::PresenceMessage::ACTION.Leave,
            deferrable:   deferrable,
            target_state: STATE.Left,
            data:         data,
            client_id:    client_id,
            failed_state: current_state, # return to current state if leave fails
            &success_block
          )
        end
      end
    end

    # Leaves the presence set of the channel for a given clientId. Enables a single client to update presence on behalf
    # of any number of clients using a single connection. The library must have been instantiated with an API key
    # or a token bound to a wildcard clientId. An optional callback may be provided to notify of the success or failure of the operation.
    #
    # @spec RTP15
    #
    # @param (see {Ably::Realtime::Presence#enter_client})
    #
    # @yield (see {Ably::Realtime::Presence#enter_client})
    # @return (see {Ably::Realtime::Presence#enter_client})
    #
    def leave_client(client_id, data = nil, &success_block)
      ensure_supported_client_id client_id
      ensure_supported_payload data

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Leave, client_id, data, &success_block)
    end

    # Updates the data payload for a presence member. If called before entering the presence set, this is treated as
    # an {Ably::Realtime::Presence::STATE.Entered} event. An optional callback may be provided to notify of the success or failure of the operation.
    #
    # @spec RTP9
    #
    # @param (see {Ably::Realtime::Presence#enter})
    #
    # @yield (see {Ably::Realtime::Presence#enter})
    # @return (see {Ably::Realtime::Presence#enter})
    #
    def update(data = nil, &success_block)
      deferrable = create_deferrable

      ensure_supported_payload data

      @data = data

      requirements_failed_deferrable = ensure_presence_publishable_on_connection_deferrable
      return requirements_failed_deferrable if requirements_failed_deferrable

      ensure_channel_attached(deferrable) do
        send_protocol_message_and_transition_state_to(
          Ably::Models::PresenceMessage::ACTION.Update,
          deferrable:   deferrable,
          target_state: STATE.Entered,
          client_id:    client_id,
          data:         data,
          &success_block
        )
      end
    end

    # Updates the data payload for a presence member using a given clientId. Enables a single client to update presence
    # on behalf of any number of clients using a single connection. The library must have been instantiated with an API
    # key or a token bound to a wildcard clientId. An optional callback may be provided to notify of the success
    # or failure of the operation.
    #
    # @spec RTP15
    #
    # @param (see Presence#enter_client)
    #
    # @yield (see Presence#enter_client)
    # @return (see Presence#enter_client)
    #
    def update_client(client_id, data = nil, &success_block)
      ensure_supported_client_id client_id
      ensure_supported_payload data

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Update, client_id, data, &success_block)
    end

    # Retrieves the current members present on the channel and the metadata for each member, such as their
    # {Ably::Models::ProtocolMessage::ACTION} and ID. Returns an array of {Ably::Models::PresenceMessage} objects.
    #
    # @spec RTP11, RTP11c1, RTP11c2, RTP11c3
    #
    # @param (see {Ably::Realtime::Presence::MembersMap#get})
    # @option options (see {Ably::Realtime::Presence::MembersMap#get})
    # @yield (see {Ably::Realtime::Presence::MembersMap#get})
    #
    # @return (see {Ably::Realtime::Presence::MembersMap#get})
    #
    def get(options = {}, &block)
      deferrable = create_deferrable

      # #RTP11d Don't return PresenceMap when wait for sync is true
      #   if the map is stale
      wait_for_sync = options.fetch(:wait_for_sync, true)
      if wait_for_sync && channel.suspended?
        EventMachine.next_tick do
          deferrable.fail Ably::Exceptions::InvalidState.new(
            'Presence state is out of sync as channel is SUSPENDED. Presence#get on a SUSPENDED channel is only supported with option wait_for_sync: false',
            nil,
            Ably::Exceptions::Codes::PRESENCE_STATE_IS_OUT_OF_SYNC
          )
        end
        return deferrable
      end

      ensure_channel_attached(deferrable, allow_suspended: true) do
        members.get(options).tap do |members_map_deferrable|
          members_map_deferrable.callback do |members|
            safe_yield(block, members) if block_given?
            deferrable.succeed(members)
          end
          members_map_deferrable.errback do |*args|
            deferrable.fail(*args)
          end
        end
      end
    end

    # Registers a listener that is called each time a {Ably::Models::PresenceMessage} is received on the channel,
    # such as a new member entering the presence set. A callback may optionally be passed in to this call to be notified
    # of success or failure of the channel {Ably::Realtime::Channel#attach} operation.
    #
    # @spec RTP6a, RTP6b
    #
    # @param actions [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    # @yield [Ably::Models::PresenceMessage] For each presence state change event, the block is called
    #
    # @return [void]
    #
    def subscribe(*actions, &callback)
      implicit_attach
      super
    end

    # Unsubscribe the matching block for presence events on the associated Channel.
    # If a block is not provided, all subscriptions will be unsubscribed {Ably::Models::PresenceMessage} for the channel.
    #
    # @spec RTP7a, RTP7b, RTE5
    #
    # @param actions [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    #
    # @return [void]
    #
    def unsubscribe(*actions, &callback)
      super
    end

    # Retrieves a {Ably::Models::PaginatedResult} object, containing an array of historical
    # {Ably::Models::PresenceMessage} objects for the channel. If the channel is configured to persist messages,
    # then presence messages can be retrieved from history for up to 72 hours in the past. If not, presence messages
    # can only be retrieved from history for up to two minutes in the past.
    #
    # @spec RTP12c, RTP12a
    #
    # @param (see {Ably::Rest::Presence#history})
    # @option options (see {Ably::Rest::Presence#history})
    #
    # @yield [Ably::Models::PaginatedResult<Ably::Models::PresenceMessage>] First {Ably::Models::PaginatedResult page} of {Ably::Models::PresenceMessage} objects accessible with {Ably::Models::PaginatedResult#items #items}.
    #
    # @return [Ably::Util::SafeDeferrable]
    #
    def history(options = {}, &callback)
      async_wrap(callback) do
        rest_presence.history(options.merge(async_blocking_operations: true))
      end
    end

    # @!attribute [r] __incoming_msgbus__
    # @return [Ably::Util::PubSub] Client library internal channel incoming protocol message bus
    # @api private
    def __incoming_msgbus__
      @__incoming_msgbus__ ||= Ably::Util::PubSub.new(
        coerce_into: lambda { |event| Ably::Models::ProtocolMessage::ACTION(event) }
      )
    end

    # Used by {Ably::Modules::StateEmitter} to debug action changes
    # @api private
    def logger
      client.logger
    end

    # Indicates whether the presence set synchronization between Ably and the clients on the channel has been completed.
    # Set to true when the sync is complete.
    #
    # @spec RTP13
    #
    # return [Boolean]
    #
    def sync_complete?
      members.sync_complete?
    end

    private
    # @return [Ably::Models::PresenceMessage] presence message is returned allowing callbacks to be added
    def send_presence_protocol_message(presence_action, client_id, data)
      presence_message = create_presence_message(presence_action, client_id, data)
      unless presence_message.client_id
        raise Ably::Exceptions::Standard.new('Unable to enter create presence message without a client_id', 400, Ably::Exceptions::Codes::UNABLE_TO_ENTER_PRESENCE_CHANNEL_NO_CLIENTID)
      end

      protocol_message = {
        action:  Ably::Models::ProtocolMessage::ACTION.Presence,
        channel: channel.name,
        presence: [presence_message]
      }

      client.connection.send_protocol_message protocol_message

      presence_message
    end

    def create_presence_message(action, client_id, data)
      model = {
        action:   Ably::Models::PresenceMessage.ACTION(action).to_i,
        clientId: client_id,
        data:     data
      }

      Ably::Models::PresenceMessage.new(model, logger: logger).tap do |presence_message|
        presence_message.encode(client.encoders, channel.options) do |encode_error, error_message|
          client.logger.error error_message
        end
      end
    end

    def ensure_presence_publishable_on_connection_deferrable
      if !connection.can_publish_messages?
        error = Ably::Exceptions::MessageQueueingDisabled.new("Presence event cannot be published as they cannot be queued when the connection is #{connection.state}")
        Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
      end
    end

    def ensure_channel_attached(deferrable = nil, options = {})
      if channel.attached?
        yield
      elsif options[:allow_suspended] && channel.suspended?
        yield
      else
        attach_channel_then(deferrable) { yield }
      end
      deferrable
    end

    def ensure_supported_client_id(check_client_id)
      unless check_client_id
        raise Ably::Exceptions::IncompatibleClientId.new('Unable to enter/update/leave presence channel without a client_id')
      end
      if check_client_id == '*'
        raise Ably::Exceptions::IncompatibleClientId.new('Unable to enter/update/leave presence channel with the reserved wildcard client_id')
      end
      unless check_client_id.kind_of?(String)
        raise Ably::Exceptions::IncompatibleClientId.new('Unable to enter/update/leave with a non String client_id value')
      end
      unless client.auth.can_assume_client_id?(check_client_id)
        raise Ably::Exceptions::IncompatibleClientId.new("Cannot enter with provided client_id '#{check_client_id}' as it is incompatible with the current configured client_id '#{client.client_id}'")
      end
    end

    def send_protocol_message_and_transition_state_to(action, options = {}, &success_block)
      deferrable   = options.fetch(:deferrable) { raise ArgumentError, 'option :deferrable is required' }
      client_id    = options.fetch(:client_id)  { raise ArgumentError, 'option :client_id is required' }
      target_state = options.fetch(:target_state, nil)
      failed_state = options.fetch(:failed_state, nil)

      send_presence_protocol_message(action, client_id, options[:data]).tap do |protocol_message|
        protocol_message.callback do |message|
          change_state target_state, message if target_state
          deferrable_succeed deferrable, &success_block
        end

        protocol_message.errback do |error|
          change_state failed_state, error if failed_state
          deferrable_fail deferrable, error
        end
      end
    end

    def deferrable_succeed(deferrable, *args, &block)
      safe_yield(block, self, *args) if block_given?
      EventMachine.next_tick { deferrable.succeed self, *args } # allow callback to be added to the returned Deferrable before calling succeed
      deferrable
    end

    def deferrable_fail(deferrable, *args, &block)
      safe_yield(block, *args) if block_given?
      EventMachine.next_tick { deferrable.fail(*args) } # allow errback to be added to the returned Deferrable
      deferrable
    end

    def send_presence_action_for_client(action, client_id, data, &success_block)
      requirements_failed_deferrable = ensure_presence_publishable_on_connection_deferrable
      return requirements_failed_deferrable if requirements_failed_deferrable

      deferrable = create_deferrable
      ensure_channel_attached(deferrable) do
        send_presence_protocol_message(action, client_id, data).tap do |protocol_message|
          protocol_message.callback { |message| deferrable_succeed deferrable, &success_block }
          protocol_message.errback  { |error| deferrable_fail deferrable, error }
        end
      end
    end

    def attach_channel_then(deferrable)
      if channel.detached? || channel.failed?
        deferrable.fail Ably::Exceptions::InvalidState.new("Operation is not allowed when channel is in #{channel.state}", 400, Ably::Exceptions::Codes::UNABLE_TO_ENTER_PRESENCE_CHANNEL_INVALID_CHANNEL_STATE)
      else
        channel.unsafe_once(:attached, :detached, :failed) do |channel_state_change|
          if channel_state_change.current == :attached
            yield
          else
            deferrable.fail Ably::Exceptions::InvalidState.new("Operation failed as channel transitioned to #{channel_state_change.current}", 400, Ably::Exceptions::Codes::UNABLE_TO_ENTER_PRESENCE_CHANNEL_INVALID_CHANNEL_STATE)
          end
        end
        channel.attach
      end
    end

    def implicit_attach
      channel.attach if channel.initialized?
    end

    def client
      channel.client
    end

    def connection
      client.connection
    end

    def rest_presence
      client.rest_client.channel(channel.name).presence
    end

    # Force subscriptions to match valid PresenceMessage actions
    def message_emitter_subscriptions_coerce_message_key(name)
      Ably::Models::PresenceMessage.ACTION(name)
    end

    def create_deferrable
      Ably::Util::SafeDeferrable.new(logger)
    end
  end
end

require 'ably/realtime/presence/presence_manager'
require 'ably/realtime/presence/members_map'
require 'ably/realtime/presence/presence_state_machine'
