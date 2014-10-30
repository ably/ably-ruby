module Ably::Realtime
  # Presence provides access to presence operations and state for the associated Channel
  class Presence
    include Ably::Modules::EventEmitter
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

    # {Ably::Realtime::Channel} this Presence object is assoicated with
    attr_reader :channel

    def initialize(channel)
      @channel       = channel
      @state         = STATE.Initialized
      @members       = Hash.new
      @subscriptions = Hash.new { |hash, key| hash[key] = [] }

      setup_event_handlers
    end

    # Enter this client into this channel. This client will be added to the presence set
    # and presence subscribers will see an enter message for this client.
    # @param [Hash,String] options an options Hash to specify client data and/or client ID, or a String with the client data
    # @option options [String] :client_data optional data (eg a status message) for this member
    # @option options [String] :client_id the optional id of the client.
    #                                     This option is provided to support connections from server instances that act on behalf of
    #                                     multiple client_ids. In order to be able to enter the channel with this method, the client
    #                                     library must have been instanced either with a key, or with a token bound to the wildcard clientId.
    # @yield [Ably::Realtime::Presence] On success, will call the block with the {Ably::Realtime::Presence}
    # @return [Ably::Realtime::PresenceMessage] Deferrable {Ably::Realtime::PresenceMessage} that supports both success (callback) and failure (errback) callbacks
    #
    def enter(options = {}, &blk)
      unless options[:client_id] || client.client_id
        raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000)
      end

      if state == STATE.Entered
        blk.call self if block_given?
        return
      end

      ensure_channel_attached do
        once(STATE.Entered) { blk.call self } if block_given?

        if !entering?
          change_state STATE.Entering
          send_presence_protocol_message(Ably::Models::PresenceMessage::STATE.Enter, options).tap do |deferrable|
            deferrable.errback  { |message, error| change_state STATE.Failed, error }
            deferrable.callback { |message| change_state STATE.Entered }
          end
        end
      end
    end

    # Leave this client from this channel. This client will be removed from the presence
    # set and presence subscribers will see a leave message for this client.
    # @param (see Presence#enter)
    # @yield (see Presence#enter)
    # @return (see Presence#enter)
    #
    def leave(options = {}, &blk)
      if state == STATE.Left
        blk.call self if block_given?
        return
      end

      ensure_channel_attached do
        once(STATE.Left) { blk.call self } if block_given?

        if !leaving?
          change_state STATE.Leaving
          send_presence_protocol_message(Ably::Models::PresenceMessage::STATE.Leave, options).tap do |deferrable|
            deferrable.errback  { |message, error| change_state STATE.Failed, error }
            deferrable.callback { |message| change_state STATE.Left }
          end
        end
      end
    end

    # Get the presence state for this Channel.
    # Optionally get a member's {Ably::Models::PresenceMessage} state by member_id
    # @return [Array<Ably::Models::PresenceMessage>, Ably::Models::PresenceMessage] members on the channel
    def get()
      members.map { |key, presence| presence }
    end

    # Subscribe to presence events on the associated Channel.
    # This implicitly attaches the Channel if it is not already attached.
    #
    # @param state [Ably::Models::PresenceMessage::State] Optional, the state change to subscribe to.  Defaults to all presence states.
    # @yield [Ably::Models::PresenceMessage] For each presence state change event, the block is called
    #
    def subscribe(state = :all, &blk)
      enter unless entered? || entering?
      subscriptions[message_state_key(state)] << blk
    end

    # Unsubscribe the matching block for presence events on the associated Channel.
    # If a block is not provided, all subscriptions will be unsubscribed
    #
    # @param state [Ably::Models::PresenceMessage::State] Optional, the state change to subscribe to.  Defaults to all presence states.
    #
    def unsubscribe(state = :all, &blk)
      if message_state_key(state) == :all
        subscriptions.keys
      else
        Array(message_state_key(state))
      end.each do |key|
        subscriptions[key].delete_if do |block|
          !block_given? || blk == block
        end
      end
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
    attr_reader :members, :subscriptions

    def setup_event_handlers
      __incoming_msgbus__.subscribe(:presence) do |presence|
        subscriptions[:all].each           { |cb| cb.call(presence) }
        subscriptions[presence.state].each { |cb| cb.call(presence) }
        update_members_from_presence_message presence
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
    end

    # @return [Ably::Models::PresenceMessage] presence message is returned allowing callbacks to be added
    def send_presence_protocol_message(presence_state, options)
      presence_message = create_presence_message(presence_state, options)
      unless presence_message.client_id
        raise Ably::Exceptions::Standard.new('Unable to enter presence channel without a client_id', 400, 91000)
      end

      protocol_message = {
        action:  Ably::Models::ProtocolMessage::ACTION.Presence,
        channel: channel.name,
        presence: [presence_message]
      }

      client.connection.send_protocol_message protocol_message

      presence_message
    end

    def create_presence_message(state, options)
      model = {
        state: Ably::Models::PresenceMessage.STATE(state).to_i,
        clientId: options[:client_id] || client.client_id,
      }
      model.merge!(clientData: options[:client_data]) if options[:client_data]

      Ably::Models::PresenceMessage.new(model, nil)
    end

    def update_members_from_presence_message(presence_message)
      unless presence_message.member_id
        new Ably::Exceptions::ProtocolError.new("Protocol error, presence message is missing memberId", 400, 80013)
      end

      case presence_message.state
      when Ably::Models::PresenceMessage::STATE.Enter
        members[presence_message.member_id] = presence_message

      when Ably::Models::PresenceMessage::STATE.Update
        members[presence_message.member_id] = presence_message

      when Ably::Models::PresenceMessage::STATE.Leave
        members.delete presence_message.member_id

      else
        new Ably::Exceptions::ProtocolError.new("Protocol error, unknown presence state #{presence.state}", 400, 80013)
      end
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
        raise Ably::Exceptions::Standard.new('Unable to enter presence channel in detached or failed state', 400, 91001)
      else
        channel.once(Channel::STATE.Attached) { yield }
        channel.attach
      end
    end

    def client
      channel.client
    end

    # Used by {Ably::Modules::StateEmitter} to debug state changes
    def logger
      client.logger
    end

    def message_state_key(state)
      if state == :all
        :all
      else
        Ably::Models::PresenceMessage.STATE(state)
      end
    end
  end
end
