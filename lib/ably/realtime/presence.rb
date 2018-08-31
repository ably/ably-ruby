module Ably::Realtime
  # Presence provides access to presence operations and state for the associated Channel
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

    # Enter the specified client_id into this channel. The given client will be added to the
    # presence set and presence subscribers will see a corresponding presence message.
    # This method is provided to support connections (e.g. connections from application
    # server instances) that act on behalf of multiple client_ids. In order to be able to
    # enter the channel with this method, the client library must have been instanced
    # either with a key, or with a token bound to the wildcard client_id
    #
    # @param [String]  client_id   id of the client
    # @param [String,Hash,nil]   data   optional data (eg a status message) for this member
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

    # Leave a given client_id from this channel. This client will be removed from the
    # presence set and presence subscribers will see a leave message for this client.
    #
    # @param (see Presence#enter_client)
    #
    # @yield (see Presence#enter_client)
    # @return (see Presence#enter_client)
    #
    def leave_client(client_id, data = nil, &success_block)
      ensure_supported_client_id client_id
      ensure_supported_payload data

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Leave, client_id, data, &success_block)
    end

    # Update the presence data for this client. If the client is not already a member of
    # the presence set it will be added, and presence subscribers will see an enter or
    # update message for this client.
    #
    # @param (see Presence#enter)
    #
    # @yield (see Presence#enter)
    # @return (see Presence#enter)
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

    # Update the presence data for a specified client_id into this channel.
    # If the client is not already a member of the presence set it will be added, and
    # presence subscribers will see an enter or update message for this client.
    # As with {#enter_client}, the connection must be authenticated in a way that
    # enables it to represent an arbitrary clientId.
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

    # Get the presence members for this Channel.
    #
    # @param (see Ably::Realtime::Presence::MembersMap#get)
    # @option options (see Ably::Realtime::Presence::MembersMap#get)
    # @yield (see Ably::Realtime::Presence::MembersMap#get)
    # @return (see Ably::Realtime::Presence::MembersMap#get)
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

    # Subscribe to presence events on the associated Channel.
    # This implicitly attaches the Channel if it is not already attached.
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
    # If a block is not provided, all subscriptions will be unsubscribed
    #
    # @param actions [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    #
    # @return [void]
    #
    def unsubscribe(*actions, &callback)
      super
    end

    # Return the presence messages history for the channel
    #
    # Once attached to a channel, you can retrieve presence message history on the channel before the
    # channel was attached with the option <tt>until_attach: true</tt>.  This is very useful for
    # developers who wish to capture new presence events as well as retrieve historical presence state with
    # the guarantee that no presence history has been missed.
    #
    # @param (see Ably::Rest::Presence#history)
    # @option options (see Ably::Rest::Presence#history)
    # @option options [Boolean]  :until_attach  When true, request for history will be limited only to messages published before the associated channel was attached. The associated channel must be attached.
    #
    # @yield [Ably::Models::PaginatedResult<Ably::Models::PresenceMessage>] First {Ably::Models::PaginatedResult page} of {Ably::Models::PresenceMessage} objects accessible with {Ably::Models::PaginatedResult#items #items}.
    #
    # @return [Ably::Util::SafeDeferrable]
    #
    def history(options = {}, &callback)
      if options.delete(:until_attach)
        unless channel.attached?
          error = Ably::Exceptions::InvalidRequest.new('option :until_attach is invalid as the channel is not attached')
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end
        options[:from_serial] = channel.attached_serial
      end

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

    # Returns true when the initial member SYNC following channel attach is completed
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
