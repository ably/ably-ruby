module Ably::Realtime
  class Client
    # OutgoingMessageDispatcher is a (private) class that is used to deliver
    # outgoing {Ably::Models::ProtocolMessage}s using the {Ably::Realtime::Connection}
    # when the connection state is capable of delivering messages
    class OutgoingMessageDispatcher
      include Ably::Modules::EventMachineHelpers

      ACTION = Ably::Models::ProtocolMessage::ACTION

      def initialize(client, connection)
        @client     = client
        @connection = connection

        subscribe_to_outgoing_protocol_message_queue
        setup_event_handlers
      end

      private
      def client
        @client
      end

      def connection
        @connection
      end

      def can_send_messages?
        connection.connected? || connection.closing?
      end

      def messages_in_outgoing_queue?
        !outgoing_queue.empty?
      end

      def outgoing_queue
        connection.__outgoing_message_queue__
      end

      def pending_ack_queue
        connection.__pending_message_ack_queue__
      end

      def current_transport_outgoing_message_bus
        connection.transport.__outgoing_protocol_msgbus__
      end

      def deliver_queued_protocol_messages
        condition = -> { can_send_messages? && messages_in_outgoing_queue? }

        non_blocking_loop_while(condition) do
          protocol_message = outgoing_queue.shift

          if (!connection.transport)
            protocol_message.fail Ably::Exceptions::TransportClosed.new('Transport disconnected unexpectedly', nil, Ably::Exceptions::Codes::DISCONNECTED)
            next
          end

          current_transport_outgoing_message_bus.publish :protocol_message, protocol_message

          if protocol_message.ack_required?
            pending_ack_queue << protocol_message
          else
            protocol_message.succeed protocol_message
          end
        end
      end

      def subscribe_to_outgoing_protocol_message_queue
        connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |*args|
          deliver_queued_protocol_messages
        end
      end

      def setup_event_handlers
        connection.unsafe_on(:connected) do
          # Give connection manager enough time to prevent message delivery if necessary
          # For example, if reconnecting and connection and channel state is lost,
          # then the queued messages must be NACK'd
          EventMachine.next_tick do
            deliver_queued_protocol_messages
          end
        end
      end
    end
  end
end
