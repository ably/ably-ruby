module Ably
  module Realtime
    # The Channel class represents a Channel belonging to this application.
    # The Channel instance allows messages to be published and
    # received, and controls the lifecycle of this instance's
    # attachment to the channel.
    #
    # Channels will always be in one of the following states:
    #
    #   initialized: 0
    #   attaching:   1
    #   attached:    2
    #   detaching:   3
    #   detached:    4
    #   failed:      5
    #
    # Note that the states are available as Enum-like constants:
    #
    #   Channel::STATE.Initialized
    #   Channel::STATE.Attaching
    #   Channel::STATE.Attached
    #   Channel::STATE.Detaching
    #   Channel::STATE.Detached
    #   Channel::STATE.Failed
    #
    class Channel
      include Ably::Modules::Conversions
      include Ably::Modules::EventEmitter
      extend Ably::Modules::Enum

      STATE = ruby_enum('STATE',
        :initialized,
        :attaching,
        :attached,
        :detaching,
        :detached,
        :failed
      )

      configure_event_emitter coerce_into: Proc.new { |event| STATE(event) }

      attr_reader :client, :name

      def initialize(client, name)
        @client          = client
        @name            = name
        @subscriptions   = Hash.new { |hash, key| hash[key] = [] }
        @queue           = []

        state = STATE.Initialized

        __protocol_msgbus__.subscribe(:message) do |message|
          @subscriptions[:all].each { |cb| cb.call(message) }
          @subscriptions[message.name].each { |cb| cb.call(message) }
        end

        on(:attached) do
          state = STATE.Attached
          process_queue
        end
      end

      # Current Channel state {Ably::Modules::Enum}
      #
      # @return [Symbol] state
      def state
        @state
      end

      def state?(check_state)
        @state == check_state
      end

      def publish(event, data)
        queue << { name: event, data: data, timestamp: as_since_epoch(Time.now) }

        if attached?
          process_queue
        else
          attach
        end
      end

      def subscribe(event = :all, &blk)
        event = event.to_s unless event == :all
        attach unless attached?
        @subscriptions[event] << blk
      end

      def attach
        unless state?(STATE.Attaching)
          state = STATE.Attaching
          client.attach_to_channel(name)
        end
      end

      def attached?
        state?(STATE.Attached)
      end

      def __protocol_msgbus__
        @__protocol_msgbus__ ||= Ably::Util::PubSub.new(
          coerce_into: Proc.new { |event| Models::ProtocolMessage::ACTION(event) }
        )
      end

      private
      attr_reader :queue

      # Set the current Channel state {Ably::Modules::Enum}
      #
      # @return [Symbol] new state
      def state=(new_state)
        @state = State(new_state)
      end

      def process_queue
        client.send_messages(name, queue.shift(100)) until queue.empty?
      end
    end
  end
end
