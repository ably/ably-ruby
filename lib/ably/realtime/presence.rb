module Ably::Realtime
  # Presence provides access to presence operations and state for the associated Channel
  class Presence
    include Ably::Modules::EventEmitter
    include Ably::Modules::AsyncWrapper
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

    def initialize(channel)
      @channel       = channel
      @state         = STATE.Initialized
      @members       = Hash.new
      @subscriptions = Hash.new { |hash, key| hash[key] = [] }
      @client_id     = client.client_id

      setup_event_handlers
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
    # @return [EventMachine::Deferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
    #
    def enter(options = {}, &success_block)
      @client_id = options.fetch(:client_id, client_id)
      @data      = options.fetch(:data, nil)
      deferrable = EventMachine::DefaultDeferrable.new

      raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000) unless client_id
      return deferrable_succeed(deferrable, &success_block) if state == STATE.Entered

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
    # @return [EventMachine::Deferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
    #
    def enter_client(client_id, options = {}, &success_block)
      raise ArgumentError, 'options must be a Hash' unless options.kind_of?(Hash)
      raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000) unless client_id

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
      @data      = options.fetch(:data, data) # nil value defaults leave data to existing value
      deferrable = EventMachine::DefaultDeferrable.new

      raise Ably::Exceptions::Standard.new('Unable to leave presence channel that is not entered', 400, 91002) unless able_to_leave?
      return deferrable_succeed(deferrable, &success_block) if state == STATE.Left

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
      raise Ably::Exceptions::Standard.new('Unable to leave presence channel without a client_id', 400, 91000) unless client_id

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
      @data      = options.fetch(:data, nil)
      deferrable = EventMachine::DefaultDeferrable.new

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
      raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000) unless client_id

      send_presence_action_for_client(Ably::Models::PresenceMessage::ACTION.Update, client_id, options, &success_block)
    end

    # Get the presence state for this Channel.
    #
    # @param [Hash,String] options an options Hash to filter members
    # @option options [String] :client_id      optional client_id for the member
    # @option options [String] :connection_id  optional connection_id for the member
    # @option options [String] :wait_for_sync  defaults to true, if false the get method returns the current list of members and does not wait for the presence sync to complete
    #
    # @yield [Array<Ably::Models::PresenceMessage>] array of members or the member
    #
    # @return [EventMachine::Deferrable] Deferrable that supports both success (callback) and failure (errback) callback
    #
    def get(options = {}, &success_block)
      wait_for_sync = options.fetch(:wait_for_sync, true)
      deferrable    = EventMachine::DefaultDeferrable.new

      ensure_channel_attached(deferrable) do
        result_block = proc do
          members.map { |key, presence| presence }.tap do |filtered_members|
            filtered_members.keep_if { |presence| presence.connection_id == options[:connection_id] } if options[:connection_id]
            filtered_members.keep_if { |presence| presence.client_id == options[:client_id] } if options[:client_id]
          end
        end

        if !wait_for_sync || sync_complete?
          result = result_block.call
          success_block.call result if block_given?
          deferrable.succeed result
        else
          sync_pubsub.once(:done) do
            result = result_block.call
            success_block.call result if block_given?
            deferrable.succeed result
          end

          sync_pubsub.once(:failed) do |error|
            deferrable.fail error
          end
        end
      end
    end

    # Subscribe to presence events on the associated Channel.
    # This implicitly attaches the Channel if it is not already attached.
    #
    # @param action [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    # @yield [Ably::Models::PresenceMessage] For each presence state change event, the block is called
    #
    # @return [void]
    #
    def subscribe(action = :all, &callback)
      ensure_channel_attached do
        subscriptions[message_action_key(action)] << callback
      end
    end

    # Unsubscribe the matching block for presence events on the associated Channel.
    # If a block is not provided, all subscriptions will be unsubscribed
    #
    # @param action [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    #
    # @return [void]
    #
    def unsubscribe(action = :all, &callback)
      if message_action_key(action) == :all
        subscriptions.keys
      else
        Array(message_action_key(action))
      end.each do |key|
        subscriptions[key].delete_if do |block|
          !block_given? || callback == block
        end
      end
    end

    # Return the presence messages history for the channel
    #
    # @param (see Ably::Rest::Presence#history)
    # @option options (see Ably::Rest::Presence#history)
    #
    # @yield [Ably::Models::PaginatedResource<Ably::Models::PresenceMessage>] An Array of {Ably::Models::PresenceMessage} objects that supports paging (#next_page, #first_page)
    #
    # @return [EventMachine::Deferrable]
    #
    def history(options = {}, &callback)
      async_wrap(callback) do
        rest_presence.history(options.merge(async_blocking_operations: true))
      end
    end

    # When attaching to a channel that has members present, the client and server
    # initiate a sync automatically so that the client has a complete list of members.
    #
    # Whilst this sync is happening, this method returns false
    #
    # @return [Boolean]
    def sync_complete?
      sync_complete
    end

    # Expect SYNC ProtocolMessages with a list of current members on this channel from the server
    #
    # @return [void]
    #
    # @api private
    def sync_started
      @sync_complete = false

      sync_pubsub.once(:sync_complete) do
        sync_changes_backlog.each do |presence_message|
          apply_member_presence_changes presence_message
        end
        sync_completed
        sync_pubsub.trigger :done
      end

      channel.once_or_if [:detached, :failed] do |error|
        sync_completed
        sync_pubsub.trigger :failed, error
      end
    end

    # The server has indicated that no members are present on this channel and no SYNC is expected,
    # or that the SYNC has now completed
    #
    # @return [void]
    #
    # @api private
    def sync_completed
      @sync_complete = true
      @sync_changes_backlog = []
    end

    # Update the SYNC serial from the ProtocolMessage so that SYNC can be resumed.
    # If the serial is nil, or the part after the first : is empty, then the SYNC is complete
    #
    # @return [void]
    #
    # @api private
    def update_sync_serial(serial)
      @sync_serial = serial
      sync_pubsub.trigger :sync_complete if sync_serial_cursor_at_end?
    end

    # @!attribute [r] __incoming_msgbus__
    # @return [Ably::Util::PubSub] Client library internal channel incoming message bus
    # @api private
    def __incoming_msgbus__
      @__incoming_msgbus__ ||= Ably::Util::PubSub.new(
        coerce_into: Proc.new { |event| Ably::Models::ProtocolMessage::ACTION(event) }
      )
    end

    private
    attr_reader :members, :subscriptions, :sync_serial, :sync_complete


    # A simple PubSub class used to publish synchronisation state changes
    def sync_pubsub
      @sync_pubsub ||= Ably::Util::PubSub.new
    end

    # During a SYNC of presence members, all enter, update and leave events are queued for processing once the SYNC is complete
    def sync_changes_backlog
      @sync_changes_backlog ||= []
    end

    # When channel serial in ProtocolMessage SYNC is nil or
    # an empty cursor appears after the ':' such as 'cf30e75054887:psl_7g:client:189'
    # then there are no more SYNC messages to come
    def sync_serial_cursor_at_end?
      sync_serial.nil? || sync_serial.to_s.match(/^[\w-]+:?$/)
    end

    def able_to_leave?
      entering? || entered?
    end

    def setup_event_handlers
      __incoming_msgbus__.subscribe(:presence, :sync) do |presence_message|
        presence_message.decode self.channel
        update_members_from_presence_message presence_message
      end

      channel.on(Channel::STATE.Detaching) do
        change_state STATE.Leaving
      end

      channel.on(Channel::STATE.Detached) do
        change_state STATE.Left
      end

      channel.on(Channel::STATE.Failed) do
        change_state STATE.Failed unless left? || initialized?
      end

      on(STATE.Entered) do |message|
        @connection_id = message.connection_id
      end
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

      Ably::Models::PresenceMessage.new(model, nil).tap do |presence_message|
        presence_message.encode self.channel
      end
    end

    def update_members_from_presence_message(presence_message)
      unless presence_message.connection_id
        Ably::Exceptions::ProtocolError.new("Protocol error, presence message is missing connectionId", 400, 80013)
      end

      if sync_complete?
        apply_member_presence_changes presence_message
      else
        if presence_message.action == Ably::Models::PresenceMessage::ACTION.Present
          add_presence_member presence_message
          publish_presence_member_state_change presence_message
        else
          sync_changes_backlog << presence_message
        end
      end
    end

    def apply_member_presence_changes(presence_message)
      case presence_message.action
      when Ably::Models::PresenceMessage::ACTION.Enter, Ably::Models::PresenceMessage::ACTION.Update
        add_presence_member presence_message
      when Ably::Models::PresenceMessage::ACTION.Leave
        remove_presence_member presence_message
      else
        Ably::Exceptions::ProtocolError.new("Protocol error, unknown presence action #{presence_message.action}", 400, 80013)
      end

      publish_presence_member_state_change presence_message
    end

    def add_presence_member(presence_message)
      members[presence_message.member_key] = presence_message
    end

    def remove_presence_member(presence_message)
      members.delete presence_message.member_key
    end

    def publish_presence_member_state_change(presence_message)
      subscriptions[:all].each                    { |cb| cb.call(presence_message) }
      subscriptions[presence_message.action].each { |cb| cb.call(presence_message) }
    end

    def ensure_channel_attached(deferrable = nil)
      if channel.attached?
        yield
      else
        attach_channel_then { yield }
      end
      deferrable
    end

    def send_protocol_message_and_transition_state_to(action, options = {}, &success_block)
      deferrable   = options.fetch(:deferrable) { raise ArgumentError, 'option :deferrable is required' }
      client_id    = options.fetch(:client_id) { raise ArgumentError, 'option :client_id is required' }
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

        protocol_message.errback do |message, error|
          change_state failed_state, error if failed_state
          deferrable_fail deferrable, error
        end
      end
    end

    def deferrable_succeed(deferrable, *args, &block)
      block.call self, *args if block_given?
      EventMachine.next_tick { deferrable.succeed self, *args } # allow callback to be added to the returned Deferrable
      deferrable
    end

    def deferrable_fail(deferrable, *args, &block)
      block.call self, *args if block_given?
      EventMachine.next_tick { deferrable.fail self, *args } # allow errback to be added to the returned Deferrable
      deferrable
    end

    def send_presence_action_for_client(action, client_id, options = {}, &success_block)
      deferrable = EventMachine::DefaultDeferrable.new

      ensure_channel_attached(deferrable) do
        send_presence_protocol_message(action, client_id, options).tap do |protocol_message|
          protocol_message.callback { |message| deferrable_succeed deferrable, &success_block }
          protocol_message.errback  { |message| deferrable_fail    deferrable }
        end
      end
    end

    def attach_channel_then
      if channel.detached? || channel.failed?
        raise Ably::Exceptions::Standard.new('Unable to enter presence channel in detached or failed action', 400, 91001)
      else
        channel.once(Channel::STATE.Attached) { yield }
        channel.attach
      end
    end

    def client
      channel.client
    end

    def rest_presence
      client.rest_client.channel(channel.name).presence
    end

    # Used by {Ably::Modules::StateEmitter} to debug action changes
    def logger
      client.logger
    end

    def message_action_key(action)
      if action == :all
        :all
      else
        Ably::Models::PresenceMessage.ACTION(action)
      end
    end
  end
end
