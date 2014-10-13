module Ably::Realtime
  class Client
    # MessageDispatcher is an internal class that is used to dispatch {Ably::Realtime::Protocol} that are
    # received from Ably via the Connection class
    class MessageDispatcher
      ACTION = Models::ProtocolMessage::ACTION

      def initialize(client)
        @client = client
        subscribe_to_incoming_protocol_messages
      end

      private
      attr_reader :client

      def connection
        client.connection
      end

      def channels
        client.channels
      end

      def get_channel(channel_name)
        channels.fetch(channel_name) do
          logger.warn "Received channel message for non-existent channel"
          Models::NilChannel.new
        end
      end

      def logger
        client.logger
      end

      def dispatch_protocol_message(*args)
        protocol_message = args.first

        unless protocol_message.kind_of?(Models::ProtocolMessage)
          raise ArgumentError, "Expected a ProtocolMessage. Received #{protocol_message}"
        end

        unless [:nack, :error].include?(protocol_message.action)
          logger.debug "#{protocol_message.action} received: #{protocol_message}"
        end

        case protocol_message.action
          when ACTION.Heartbeat
          when ACTION.Ack
          when ACTION.Nack
            logger.warn "NACK received: #{protocol_message}"

          when ACTION.Connect, ACTION.Connected
          when ACTION.Disconnect, ACTION.Disconnected
          when ACTION.Close
          when ACTION.Closed
          when ACTION.Error
            logger.error "Error received: #{protocol_message.error}"

          when ACTION.Attach
          when ACTION.Attached
            get_channel(protocol_message.channel).trigger(:attached)

          when ACTION.Detach, ACTION.Detached
          when ACTION.Presence
          when ACTION.Message
            protocol_message.messages.each do |message|
              get_channel(protocol_message.channel).__protocol_msgbus__.publish :message, message
            end

          else
            raise ArgumentError, "Protocol Message Action #{protocol_message.action} is unsupported by this MessageDispatcher"
        end
      end

      def subscribe_to_incoming_protocol_messages
        connection.__protocol_msgbus__.subscribe(:message) do |*args|
          dispatch_protocol_message *args
        end
      end
    end
  end
end
