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

    # A unique member identifier for this channel client, disambiguating situations where a given
    # client_id is present on multiple connections simultaneously.
    # @return [String]
    attr_reader :member_id

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
      @data          = nil
      @member_id     = nil

      setup_event_handlers
    end

    # Enter this client into this channel. This client will be added to the presence set
    # and presence subscribers will see an enter message for this client.
    #
    # @param [Hash,String] options an options Hash to specify client data and/or client ID
    # @option options [String] :data      optional data (eg a status message) for this member
    # @option options [String] :client_id the optional id of the client.
    #                                     This option is provided to support connections from server instances that act on behalf of
    #                                     multiple client_ids. In order to be able to enter the channel with this method, the client
    #                                     library must have been instanced either with a key, or with a token bound to the wildcard clientId.
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with the {Ably::Realtime::Presence}
    #
    # @return [Ably::Models::PresenceMessage] Deferrable {Ably::Models::PresenceMessage} that supports both success (callback) and failure (errback) callbacks
    #
    def enter(options = {}, &blk)
      @client_id = options.fetch(:client_id, client_id)
      @data      = options.fetch(:data, data)

      raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000) unless client_id

      if state == STATE.Entered
        blk.call self if block_given?
        return
      end

      ensure_channel_attached do
        once(STATE.Entered) { blk.call self } if block_given?

        if !entering?
          change_state STATE.Entering
          send_presence_protocol_message(Ably::Models::PresenceMessage::ACTION.Enter, client_id, data).tap do |deferrable|
            deferrable.errback  { |message, error| change_state STATE.Failed, error }
            deferrable.callback { |message| change_state STATE.Entered, message }
          end
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
    # @param [String] client_id  id of the client
    # @param [String] data       optional data (eg a status message) for this member
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with the {Ably::Realtime::Presence}
    #
    # @return [Ably::Models::PresenceMessage] Deferrable {Ably::Models::PresenceMessage} that supports both success (callback) and failure (errback) callbacks
    #
    def enter_client(client_id, data = nil, &blk)
      raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000) unless client_id

      ensure_channel_attached do
        send_presence_protocol_message(Ably::Models::PresenceMessage::ACTION.Enter, client_id, data).tap do |deferrable|
          deferrable.callback { |message| blk.call self } if block_given?
        end
      end
    end

    # Leave this client from this channel. This client will be removed from the presence
    # set and presence subscribers will see a leave message for this client.
    #
    # @yield (see Presence#enter)
    # @return (see Presence#enter)
    #
    def leave(&blk)
      raise Ably::Exceptions::Standard.new('Unable to leave presence channel that is not entered', 400, 91002) unless able_to_leave?

      if state == STATE.Left
        blk.call self if block_given?
        return
      end

      ensure_channel_attached do
        once(STATE.Left) { blk.call self } if block_given?

        if !leaving?
          change_state STATE.Leaving
          send_presence_protocol_message(Ably::Models::PresenceMessage::ACTION.Leave, client_id, nil).tap do |deferrable|
            deferrable.errback  { |message, error| change_state STATE.Failed, error }
            deferrable.callback { |message| change_state STATE.Left }
          end
        end
      end
    end

    # Leave a given client_id from this channel. This client will be removed from the
    # presence set and presence subscribers will see a leave message for this client.
    #
    # @param [String] client_id  id of the client
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with the {Ably::Realtime::Presence}
    #
    # @return [Ably::Models::PresenceMessage] Deferrable {Ably::Models::PresenceMessage} that supports both success (callback) and failure (errback) callbacks
    #
    def leave_client(client_id, &blk)
      raise Ably::Exceptions::Standard.new('Unable to leave presence channel without a client_id', 400, 91000) unless client_id

      ensure_channel_attached do
        send_presence_protocol_message(Ably::Models::PresenceMessage::ACTION.Leave, client_id, data).tap do |deferrable|
          deferrable.callback { |message| blk.call self } if block_given?
        end
      end
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
    def update(options = {}, &blk)
      @data = options.fetch(:data, data)

      ensure_channel_attached do
        send_presence_protocol_message(Ably::Models::PresenceMessage::ACTION.Update, client_id, data).tap do |deferrable|
          deferrable.callback do |message|
            change_state STATE.Entered, message unless entered?
            blk.call self if block_given?
          end
        end
      end
    end

    # Update the presence data for a specified client_id into this channel.
    # If the client is not already a member of the presence set it will be added, and
    # presence subscribers will see an enter or update message for this client.
    # As with {#enter_client}, the connection must be authenticated in a way that
    # enables it to represent an arbitrary clientId.
    #
    # @param [String] client_id  id of the client
    # @param [String] data       optional data (eg a status message) for this member
    #
    # @yield [Ably::Realtime::Presence] On success, will call the block with the {Ably::Realtime::Presence}
    #
    # @return [Ably::Models::PresenceMessage] Deferrable {Ably::Models::PresenceMessage} that supports both success (callback) and failure (errback) callbacks
    #
    def update_client(client_id, data = nil, &blk)
      raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000) unless client_id

      ensure_channel_attached do
        send_presence_protocol_message(Ably::Models::PresenceMessage::ACTION.Update, client_id, data).tap do |deferrable|
          deferrable.callback { |message| blk.call self } if block_given?
        end
      end
    end

    # Get the presence state for this Channel.
    #
    # @param [Hash,String] options an options Hash to filter members
    # @option options [String] :client_id      optional client_id for the member
    # @option options [String] :member_id      optional connection member_id for the member
    # @option options [String] :wait_for_sync  defaults to true, if false the get method returns the current list of members and does not wait for the presence sync to complete
    #
    # @yield [Array<Ably::Models::PresenceMessage>] array of members or the member
    #
    # @return [EventMachine::Deferrable] Deferrable that supports both success (callback) and failure (errback) callback
    #
    def get(options = {}, &success_block)
      wait_for_sync = options.fetch(:wait_for_sync, true)

      ensure_channel_attached do
        result_block = proc do
          members.map { |key, presence| presence }.tap do |filtered_members|
            filtered_members.keep_if { |presence| presence.member_id == options[:member_id] } if options[:member_id]
            filtered_members.keep_if { |presence| presence.client_id == options[:client_id] } if options[:client_id]
          end
        end

        EventMachine::DefaultDeferrable.new.tap do |deferrable|
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
    end

    # Subscribe to presence events on the associated Channel.
    # This implicitly attaches the Channel if it is not already attached.
    #
    # @param action [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    # @yield [Ably::Models::PresenceMessage] For each presence state change event, the block is called
    #
    # @return [void]
    #
    def subscribe(action = :all, &blk)
      ensure_channel_attached do
        subscriptions[message_action_key(action)] << blk
      end
    end

    # Unsubscribe the matching block for presence events on the associated Channel.
    # If a block is not provided, all subscriptions will be unsubscribed
    #
    # @param action [Ably::Models::PresenceMessage::ACTION] Optional, the state change action to subscribe to. Defaults to all presence actions
    #
    # @return [void]
    #
    def unsubscribe(action = :all, &blk)
      if message_action_key(action) == :all
        subscriptions.keys
      else
        Array(message_action_key(action))
      end.each do |key|
        subscriptions[key].delete_if do |block|
          !block_given? || blk == block
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

      fail_block = proc do |error|
        sync_completed
        sync_pubsub.trigger :failed, error
        channel.off &fail_block
      end

      channel.once_or_if :detached, &fail_block
      channel.once_or_if :failed, &fail_block
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
      sync_serial.nil? || sync_serial.to_s.match(/^\w+:?$/)
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
        @member_id = message.member_id
      end
    end

    # @return [Ably::Models::PresenceMessage] presence message is returned allowing callbacks to be added
    def send_presence_protocol_message(presence_action, client_id, data)
      presence_message = create_presence_message(presence_action, client_id, data)
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

    def create_presence_message(action, client_id, data)
      model = {
        action:   Ably::Models::PresenceMessage.ACTION(action).to_i,
        clientId: client_id,
      }
      model.merge!(data: data) if data

      Ably::Models::PresenceMessage.new(model, nil).tap do |presence_message|
        presence_message.encode self.channel
      end
    end

    def update_members_from_presence_message(presence_message)
      unless presence_message.member_id
        new Ably::Exceptions::ProtocolError.new("Protocol error, presence message is missing memberId", 400, 80013)
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

    def ensure_channel_attached
      if channel.attached?
        yield
      else
        attach_channel_then { yield }
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
