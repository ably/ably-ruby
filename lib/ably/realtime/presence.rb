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
      :left,
      :failed
    )
    include Ably::Modules::StateEmitter
    include Ably::Modules::UsesStateMachine

    # {Ably::Realtime::Channel} this Presence object is associated with
    # @return [Ably::Realtime::Channel]
    attr_reader :channel

    # A unique identifier for this channel client based on their connection, disambiguating situations
    # where a given client_id is present on multiple connections simultaneously.
    # @return [String]
    attr_reader :connection_id

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
    # @param [Hash] options an options Hash to specify client data and/or client ID
    # @option options [String] :data      optional data (eg a status message) for this member
    # @option options [String] :client_id the optional id of the client.
    #                                     This option is provided to support connections from server instances that act on behalf of
    #                                     multiple client_ids. In order to be able to enter the channel with this method, the client
    #                                     library must have been instanced either with a key, or with a token bound to the wildcard clientId.
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with this {Ably::Realtime::Presence} object
    # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
    #
    def enter(options = {}, &success_block)
      client_id  = options.fetch(:client_id, self.client_id)
      data       = options.fetch(:data, nil)
      deferrable = create_deferrable

      ensure_supported_client_id client_id
      ensure_supported_payload data unless data.nil?

      @data = data
      @client_id = client_id

      return deferrable_succeed(deferrable, &success_block) if state == STATE.Entered

      ensure_presence_publishable_on_connection
      ensure_channel_attached(deferrable) do
        if entering?
          once_or_if(STATE.Entered, else: proc { |args| deferrable_fail deferrable, *args }) do
            deferrable_succeed deferrable, &success_block
          end
        else
          change_state STATE.Entering
          send_protocol_message_and_transition_state_to(
            Ably::Models::PresenceMessage::ACTION.Enter,
            deferrable:   deferrable,
            target_state: STATE.Entered,
            client_id:    client_id,
            data:         data,
            failed_state: STATE.Failed,
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
    #
    # @param [Hash]    options         an options Hash for this client event
    # @option options [String] :data   optional data (eg a status message) for this member
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with this {Ably::Realtime::Presence} object
    # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
    #
    def enter_client(client_id, options = {}, &success_block)
      raise ArgumentError, 'options must be a Hash' unless options.kind_of?(Hash)
      ensure_supported_client_id client_id
      ensure_supported_payload options[:data] if options.has_key?(:data)

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Enter, client_id, options, &success_block)
    end

    # Leave this client from this channel. This client will be removed from the presence
    # set and presence subscribers will see a leave message for this client.
    #
    # @param [Hash,String] options an options Hash to specify client data and/or client ID
    # @option options [String] :data      optional data (eg a status message) for this member
    #
    # @yield (see Presence#enter)
    # @return (see Presence#enter)
    #
    def leave(options = {}, &success_block)
      data       = options.fetch(:data, self.data) # nil value defaults leave data to existing value
      deferrable = create_deferrable

      ensure_supported_client_id client_id
      ensure_supported_payload data unless data.nil?
      raise Ably::Exceptions::Standard.new('Unable to leave presence channel that is not entered', 400, 91002) unless able_to_leave?

      @data = data

      return deferrable_succeed(deferrable, &success_block) if state == STATE.Left

      ensure_presence_publishable_on_connection
      ensure_channel_attached(deferrable) do
        if leaving?
          once_or_if(STATE.Left, else: proc { |error|deferrable_fail deferrable, *args }) do
            deferrable_succeed deferrable, &success_block
          end
        else
          change_state STATE.Leaving
          send_protocol_message_and_transition_state_to(
            Ably::Models::PresenceMessage::ACTION.Leave,
            deferrable:   deferrable,
            target_state: STATE.Left,
            client_id:    client_id,
            data:         data,
            failed_state: STATE.Failed,
            &success_block
          )
        end
      end
    end

    # Leave a given client_id from this channel. This client will be removed from the
    # presence set and presence subscribers will see a leave message for this client.
    #
    # @param (see Presence#enter_client)
    # @option options (see Presence#enter_client)
    #
    # @yield (see Presence#enter_client)
    # @return (see Presence#enter_client)
    #
    def leave_client(client_id, options = {}, &success_block)
      raise ArgumentError, 'options must be a Hash' unless options.kind_of?(Hash)
      ensure_supported_client_id client_id
      ensure_supported_payload options[:data] if options.has_key?(:data)

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Leave, client_id, options, &success_block)
    end

    # Update the presence data for this client. If the client is not already a member of
    # the presence set it will be added, and presence subscribers will see an enter or
    # update message for this client.
    #
    # @param [Hash,String] options an options Hash to specify client data
    # @option options [String] :data      optional data (eg a status message) for this member
    #
    # @yield (see Presence#enter)
    # @return (see Presence#enter)
    #
    def update(options = {}, &success_block)
      data       = options.fetch(:data, nil)
      deferrable = create_deferrable

      ensure_supported_client_id client_id
      ensure_supported_payload data unless data.nil?

      @data = data

      ensure_presence_publishable_on_connection
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
    # @option options (see Presence#enter_client)
    #
    # @yield (see Presence#enter_client)
    # @return (see Presence#enter_client)
    #
    def update_client(client_id, options = {}, &success_block)
      raise ArgumentError, 'options must be a Hash' unless options.kind_of?(Hash)
      ensure_supported_client_id client_id
      ensure_supported_payload options[:data] if options.has_key?(:data)

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Update, client_id, options, &success_block)
    end

    # Get the presence state for this Channel.
    #
    # @param (see Ably::Realtime::Presence::MembersMap#get)
    # @option options (see Ably::Realtime::Presence::MembersMap#get)
    # @yield (see Ably::Realtime::Presence::MembersMap#get)
    # @return (see Ably::Realtime::Presence::MembersMap#get)
    #
    def get(options = {}, &block)
      deferrable = create_deferrable

      ensure_channel_attached(deferrable) do
        members.get(options).tap do |members_map_deferrable|
          members_map_deferrable.callback do |*args|
            safe_yield block, *args if block_given?
            deferrable.succeed *args
          end
          members_map_deferrable.errback do |*args|
            deferrable.fail *args
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
      ensure_channel_attached do
        super
      end
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
        raise ArgumentError, 'option :until_attach cannot be specified if the channel is not attached' unless channel.attached?
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
        coerce_into: Proc.new { |event| Ably::Models::ProtocolMessage::ACTION(event) }
      )
    end

    # Configure the connection ID for this presence channel.
    # Typically configured only once when a user first enters a presence channel.
    # @api private
    def set_connection_id(new_connection_id)
      @connection_id = new_connection_id
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
    def able_to_leave?
      entering? || entered?
    end

    # @return [Ably::Models::PresenceMessage] presence message is returned allowing callbacks to be added
    def send_presence_protocol_message(presence_action, client_id, options = {})
      presence_message = create_presence_message(presence_action, client_id, options)
      unless presence_message.client_id
        raise Ably::Exceptions::Standard.new('Unable to enter create presence message without a client_id', 400, 91000)
      end

      protocol_message = {
        action:  Ably::Models::ProtocolMessage::ACTION.Presence,
        channel: channel.name,
        presence: [presence_message]
      }

      client.connection.send_protocol_message protocol_message

      presence_message
    end

    def create_presence_message(action, client_id, options = {})
      model = {
        action:   Ably::Models::PresenceMessage.ACTION(action).to_i,
        clientId: client_id
      }
      model.merge!(data: options.fetch(:data)) if options.has_key?(:data)

      Ably::Models::PresenceMessage.new(model, logger: logger).tap do |presence_message|
        presence_message.encode self.channel
      end
    end

    def ensure_presence_publishable_on_connection
      if !connection.can_publish_messages?
        raise Ably::Exceptions::MessageQueueingDisabled.new("Message cannot be published. Client is configured to disallow queueing of messages and connection is currently #{connection.state}")
      end
    end

    def ensure_channel_attached(deferrable = nil)
      if channel.attached?
        yield
      else
        attach_channel_then { yield }
      end
      deferrable
    end

    def ensure_supported_client_id(check_client_id)
      raise Ably::Exceptions::IncompatibleClientId.new('Unable to enter/update/leave presence channel without a client_id', 400, 40012) unless check_client_id
      raise Ably::Exceptions::IncompatibleClientId.new('Unable to enter/update/leave presence channel with the reserved wildcard client_id', 400, 40012) if check_client_id == '*'
      if client.auth.client_id_confirmed? && client.auth.client_id != check_client_id
        raise Ably::Exceptions::IncompatibleClientId.new("Cannot enter with provided client_id '#{check_client_id}' as it is incompatible with the current configured client_id '#{client_id}'", 400, 40012)
      end
    end

    def send_protocol_message_and_transition_state_to(action, options = {}, &success_block)
      deferrable   = options.fetch(:deferrable) { raise ArgumentError, 'option :deferrable is required' }
      client_id    = options.fetch(:client_id)  { raise ArgumentError, 'option :client_id is required' }
      target_state = options.fetch(:target_state, nil)
      failed_state = options.fetch(:failed_state, nil)

      protocol_message_options = if options.has_key?(:data)
        { data: options.fetch(:data) }
      else
        { }
      end

      send_presence_protocol_message(action, client_id, protocol_message_options).tap do |protocol_message|
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
      safe_yield block, self, *args if block_given?
      EventMachine.next_tick { deferrable.succeed self, *args } # allow callback to be added to the returned Deferrable before calling succeed
      deferrable
    end

    def deferrable_fail(deferrable, *args, &block)
      safe_yield block, *args if block_given?
      EventMachine.next_tick { deferrable.fail *args } # allow errback to be added to the returned Deferrable
      deferrable
    end

    def send_presence_action_for_client(action, client_id, options = {}, &success_block)
      ensure_presence_publishable_on_connection

      deferrable = create_deferrable
      ensure_channel_attached(deferrable) do
        send_presence_protocol_message(action, client_id, options).tap do |protocol_message|
          protocol_message.callback { |message| deferrable_succeed deferrable, &success_block }
          protocol_message.errback  { |error| deferrable_fail deferrable, error }
        end
      end
    end

    def attach_channel_then
      if channel.detached? || channel.failed?
        raise Ably::Exceptions::InvalidStateChange.new("Operation is not allowed when channel is in #{channel.state}", 400, 91001)
      else
        channel.unsafe_once(Channel::STATE.Attached) { yield }
        channel.attach
      end
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
