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
      def client
        @client
      end

      def connection
        @connection
      end

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

        if [:sync, :presence, :message].any? { |prevent_duplicate| protocol_message.action == prevent_duplicate }
          if connection.serial && protocol_message.has_connection_serial? && protocol_message.connection_serial <= connection.serial
            error_target = if protocol_message.channel
              get_channel(protocol_message.channel)
            else
              connection
            end
            error_message = "Protocol error, duplicate message received for serial #{protocol_message.connection_serial}"
            error_target.emit :error, Ably::Exceptions::ProtocolError.new(error_message, 400, 80013)
            logger.error error_message
            return
          end
        end

        update_connection_recovery_info protocol_message

        case protocol_message.action
          when ACTION.Heartbeat
          when ACTION.Ack
            ack_pending_queue_for_message_serial(protocol_message) if protocol_message.has_message_serial?

          when ACTION.Nack
            logger.warn "NACK received: #{protocol_message}"
            nack_pending_queue_for_message_serial(protocol_message) if protocol_message.has_message_serial?

          when ACTION.Connect
          when ACTION.Connected
            if connection.disconnected? || connection.closing? || connection.closed? || connection.failed?
              logger.debug "Incoming CONNECTED ProtocolMessage discarded as connection has moved on and is in state: #{connection.state}"
            elsif connection.connected?
              logger.error "CONNECTED ProtocolMessage should not have been received when the connection is in the CONNECTED state"
            else
              process_connected_message protocol_message
            end

          when ACTION.Disconnect, ACTION.Disconnected
            connection.transition_state_machine :disconnected, reason: protocol_message.error unless connection.disconnected?

          when ACTION.Close
          when ACTION.Closed
            connection.transition_state_machine :closed unless connection.closed?

          when ACTION.Error
            if protocol_message.channel && !protocol_message.has_message_serial?
              dispatch_channel_error protocol_message
            else
              process_connection_error protocol_message
            end

          when ACTION.Attach
          when ACTION.Attached
            get_channel(protocol_message.channel).tap do |channel|
              if channel.attached?
                channel.manager.duplicate_attached_received protocol_message.error
              else
                channel.transition_state_machine :attached, reason: protocol_message.error, resumed: protocol_message.channel_resumed?, protocol_message: protocol_message
              end
            end

          when ACTION.Detach
          when ACTION.Detached
            get_channel(protocol_message.channel).tap do |channel|
              channel.transition_state_machine :detached unless channel.detached?
            end

          when ACTION.Sync
            presence = get_channel(protocol_message.channel).presence
            protocol_message.presence.each do |presence_message|
              presence.__incoming_msgbus__.publish :sync, presence_message
            end
            presence.members.update_sync_serial protocol_message.channel_serial

          when ACTION.Presence
            presence = get_channel(protocol_message.channel).presence
            protocol_message.presence.each do |presence_message|
              presence.__incoming_msgbus__.publish :presence, presence_message
            end

          when ACTION.Message
            channel = get_channel(protocol_message.channel)
            protocol_message.messages.each do |message|
              channel.__incoming_msgbus__.publish :message, message
            end

          else
            error = Ably::Exceptions::ProtocolError.new("Protocol Message Action #{protocol_message.action} is unsupported by this MessageDispatcher", 400, 80013)
            client.connection.emit :error, error
            logger.fatal error.message
        end
      end

      def dispatch_channel_error(protocol_message)
        logger.warn "Channel Error message received: #{protocol_message.error}"
        if !protocol_message.has_message_serial?
          get_channel(protocol_message.channel).transition_state_machine :failed, reason: protocol_message.error
        else
          logger.fatal "Cannot process ProtocolMessage as not yet implemented: #{protocol_message}"
        end
      end

      def process_connection_error(protocol_message)
        connection.manager.error_received_from_server(protocol_message.error || Ably::Models::ErrorInfo.new(message: 'Error reason unknown'))
      end

      def process_connected_message(protocol_message)
        if client.auth.token_client_id_allowed?(protocol_message.connection_details.client_id)
          client.auth.configure_client_id protocol_message.connection_details.client_id
          client.connection.set_connection_details protocol_message.connection_details
          connection.transition_state_machine :connected, reason: protocol_message.error, protocol_message: protocol_message
        else
          reason = Ably::Exceptions::IncompatibleClientId.new("Client ID '#{protocol_message.connection_details.client_id}' specified by the server is incompatible with the library's configured client ID '#{client.client_id}'", 400, 40012)
          connection.transition_state_machine :failed, reason: reason, protocol_message: protocol_message
        end
      end

      def update_connection_recovery_info(protocol_message)
        connection.update_connection_serial protocol_message.connection_serial if protocol_message.has_connection_serial?
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
          message.fail protocol_message.error
        end
      end

      def drop_pending_queue_from_ack(ack_protocol_message)
        message_serial_up_to = ack_protocol_message.message_serial + ack_protocol_message.count - 1

        while !connection.__pending_message_ack_queue__.empty?
          next_message = connection.__pending_message_ack_queue__.first
          return if next_message.message_serial > message_serial_up_to
          yield connection.__pending_message_ack_queue__.shift
        end
      end

      def subscribe_to_incoming_protocol_messages
        connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |*args|
          dispatch_protocol_message(*args)
        end
      end
    end
  end
end
