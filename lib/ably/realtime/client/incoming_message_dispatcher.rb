module Ably::Realtime
  class Client
    # IncomingMessageDispatcher is a (private) class that is used to dispatch {Ably::Models::ProtocolMessage} that are
    # received from Ably via the {Ably::Realtime::Connection}
    class IncomingMessageDispatcher
      ACTION = Ably::Models::ProtocolMessage::ACTION

      def initialize(client, connection)
        @client     = client
        @connection = connection
        subscribe_to_incoming_protocol_messages
      end

      private
      attr_reader :client, :connection

      def channels
        client.channels
      end

      def get_channel(channel_name)
        channels.fetch(channel_name) do
          logger.warn "Received channel message for non-existent channel"
          Ably::Realtime::Models::NilChannel.new
        end
      end

      def logger
        client.logger
      end

      def dispatch_protocol_message(*args)
        protocol_message = args.first

        unless protocol_message.kind_of?(Ably::Models::ProtocolMessage)
          raise ArgumentError, "Expected a ProtocolMessage. Received #{protocol_message}"
        end

        unless [:nack, :error].include?(protocol_message.action)
          logger.debug "#{protocol_message.action} received: #{protocol_message}"
        end

        update_connection_id protocol_message

        case protocol_message.action
          when ACTION.Heartbeat
          when ACTION.Ack
            ack_pending_queue_for_message_serial(protocol_message) if protocol_message.has_message_serial?

          when ACTION.Nack
            logger.warn "NACK received: #{protocol_message}"
            nack_pending_queue_for_message_serial(protocol_message) if protocol_message.has_message_serial?

          when ACTION.Connect
          when ACTION.Connected
            connection.transition_state_machine :connected

          when ACTION.Disconnect, ACTION.Disconnected

          when ACTION.Close
          when ACTION.Closed
            connection.transition_state_machine :closed

          when ACTION.Error
            logger.error "Error received: #{protocol_message.error}"
            if protocol_message.channel && !protocol_message.has_message_serial?
              get_channel(protocol_message.channel).change_state Ably::Realtime::Channel::STATE.Failed, protocol_message.error
            end

          when ACTION.Attach
          when ACTION.Attached
            get_channel(protocol_message.channel).change_state Ably::Realtime::Channel::STATE.Attached

          when ACTION.Detach
          when ACTION.Detached
            get_channel(protocol_message.channel).change_state Ably::Realtime::Channel::STATE.Detached

          when ACTION.Presence
            protocol_message.presence.each do |presence|
              get_channel(protocol_message.channel).presence.__incoming_msgbus__.publish :presence, presence
            end

          when ACTION.Message
            protocol_message.messages.each do |message|
              get_channel(protocol_message.channel).__incoming_msgbus__.publish :message, message
            end

          else
            raise ArgumentError, "Protocol Message Action #{protocol_message.action} is unsupported by this MessageDispatcher"
        end
      end

      def update_connection_id(protocol_message)
        if protocol_message.connection_id && (protocol_message.connection_id != connection.id)
          logger.debug "New connection ID set to #{protocol_message.connection_id}"
          connection.update_connection_id protocol_message.connection_id
        end
      end

      def ack_pending_queue_for_message_serial(ack_protocol_message)
        drop_pending_queue_from_ack(ack_protocol_message) do |protocol_message|
          ack_messages protocol_message.messages
          ack_messages protocol_message.presence
        end
      end

      def nack_pending_queue_for_message_serial(nack_protocol_message)
        drop_pending_queue_from_ack(nack_protocol_message) do |protocol_message|
          nack_messages protocol_message.messages, nack_protocol_message
          nack_messages protocol_message.presence, nack_protocol_message
        end
      end

      def ack_messages(messages)
        messages.each do |message|
          logger.debug "Calling ACK success callbacks for #{message.class.name} - #{message.to_json}"
          message.succeed message
        end
      end

      def nack_messages(messages, protocol_message)
        messages.each do |message|
          logger.debug "Calling NACK failure callbacks for #{message.class.name} - #{message.to_json}, protocol message: #{protocol_message}"
          message.fail message, protocol_message.error
        end
      end

      def drop_pending_queue_from_ack(ack_protocol_message)
        message_serial_up_to = ack_protocol_message.message_serial + ack_protocol_message.count - 1
        connection.__pending_message_queue__.drop_while do |protocol_message|
          if protocol_message.message_serial <= message_serial_up_to
            yield protocol_message
            true
          end
        end
      end

      def subscribe_to_incoming_protocol_messages
        connection.__incoming_protocol_msgbus__.subscribe(:message) do |*args|
          dispatch_protocol_message *args
        end
      end
    end
  end
end
