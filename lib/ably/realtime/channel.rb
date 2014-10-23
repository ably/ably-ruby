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
    # @!attribute [r] state
    #   @return {Ably::Realtime::Connection::STATE} channel state
    #
    class Channel
      include Ably::Modules::Conversions
      include Ably::Modules::EventEmitter
      include Ably::Modules::EventMachineHelpers
      extend Ably::Modules::Enum

      STATE = ruby_enum('STATE',
        :initialized,
        :attaching,
        :attached,
        :detaching,
        :detached,
        :failed
      )
      include Ably::Modules::State

      # Max number of messages to bundle in a single ProtocolMessage
      MAX_PROTOCOL_MESSAGE_BATCH_SIZE = 50

      attr_reader :client, :name

      def initialize(client, name)
        @client        = client
        @name          = name
        @subscriptions = Hash.new { |hash, key| hash[key] = [] }
        @queue         = []
        @state         = STATE.Initialized

        setup_event_handlers
      end

      # Publish a message on the channel
      #
      # @param event [String] The event name of the message
      # @param data [String,ByteArray] payload for the message
      # @yield [Ably::Realtime::Models::Message] On success, will call the block with the {Ably::Realtime::Models::Message}
      # @return [Ably::Realtime::Models::Message]
      #
      def publish(event, data, &callback)
        Models::Message.new({
          name: event,
          data: data,
          timestamp: as_since_epoch(Time.now),
          client_id: client.client_id
        }, nil).tap do |message|
          message.callback(&callback) if block_given?
          queue_message message
        end
      end

      def subscribe(event = :all, &blk)
        event = event.to_s unless event == :all
        attach unless attached? || attaching?
        @subscriptions[event] << blk
      end

      def attach
        unless attached? || attaching?
          change_state STATE.Attaching
          send_attach_protocol_message
        end
      end

      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= Ably::Util::PubSub.new(
          coerce_into: Proc.new { |event| Models::ProtocolMessage::ACTION(event) }
        )
      end

      private
      attr_reader :queue

      def setup_event_handlers
        __incoming_protocol_msgbus__.subscribe(:message) do |message|
          @subscriptions[:all].each         { |cb| cb.call(message) }
          @subscriptions[message.name].each { |cb| cb.call(message) }
        end

        on(:attached) do
          process_queue
        end
      end

      # Queue message and process queue if channel is attached.
      # If channel is not yet attached, attempt to attach it before the message queue is processed.
      def queue_message(message)
        queue << message

        if attached?
          process_queue
        else
          attach
        end
      end

      def messages_in_queue?
        !queue.empty?
      end

      # Move messages from Channel Queue into Outgoing Connection Queue
      def process_queue
        condition = -> { attached? && messages_in_queue? }
        non_blocking_loop_while(condition) do
          send_messages_within_protocol_message(queue.shift(MAX_PROTOCOL_MESSAGE_BATCH_SIZE))
        end
      end

      def send_messages_within_protocol_message(messages)
        client.connection.send_protocol_message(
          action:   Models::ProtocolMessage::ACTION.Message.to_i,
          channel:  name,
          messages: messages
        )
      end

      def send_attach_protocol_message
        client.connection.send_protocol_message(
          action:  Models::ProtocolMessage::ACTION.Attach.to_i,
          channel: name
        )
      end

      # Used by {Ably::Modules::State} to debug state changes
      def logger
        client.logger
      end
    end
  end
end
