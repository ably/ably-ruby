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
          logger.warn { "Received channel message for non-existent channel" }
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

        unless protocol_message.action.match_any?(:nack, :error)
          logger.debug { "#{protocol_message.action} received: #{protocol_message}" }
        end

        if protocol_message.action.match_any?(:sync, :presence, :message)
          if connection.serial && protocol_message.has_connection_serial? && protocol_message.connection_serial <= connection.serial
            error_message = "Protocol error, duplicate message received for serial #{protocol_message.connection_serial}"
            logger.error error_message
            return
          end
        end

        update_connection_recovery_info protocol_message
        connection.set_connection_confirmed_alive

        case protocol_message.action
          when ACTION.Heartbeat
          when ACTION.Ack
            ack_pending_queue_for_message_serial(protocol_message) if protocol_message.has_message_serial?

          when ACTION.Nack
            logger.warn { "NACK received: #{protocol_message}" }
            nack_pending_queue_for_message_serial(protocol_message) if protocol_message.has_message_serial?

          when ACTION.Connect
          when ACTION.Connected
            if connection.closing?
              logger.debug { "Out-of-order incoming CONNECTED ProtocolMessage discarded as connection has moved on and is in state: #{connection.state}" }
            elsif connection.disconnected? || connection.closing? || connection.closed? || connection.failed?
              logger.warn { "Out-of-order incoming CONNECTED ProtocolMessage discarded as connection has moved on and is in state: #{connection.state}" }
            elsif connection.connected?
              logger.debug { "Updated CONNECTED ProtocolMessage received (whilst connected)" }
              process_connected_update_message protocol_message
              connection.set_connection_confirmed_alive # Connection protocol messages can change liveness settings such as max_idle_interval
            else
              process_connected_message protocol_message
              connection.set_connection_confirmed_alive # Connection protocol messages can change liveness settings such as max_idle_interval
            end

          when ACTION.Disconnect, ACTION.Disconnected
            connection.transition_state_machine :disconnected, reason: protocol_message.error unless connection.disconnected?

          when ACTION.Close
          when ACTION.Closed
            connection.transition_state_machine :closed unless connection.closed?

          when ACTION.Error
            if protocol_message.channel
              dispatch_channel_error protocol_message
            else
              process_connection_error protocol_message
            end

          when ACTION.Attach
          when ACTION.Attached
            get_channel(protocol_message.channel).tap do |channel|
              if channel.attached?
                channel.manager.duplicate_attached_received protocol_message
              else
                if channel.failed?
                  logger.warn "Ably::Realtime::Client::IncomingMessageDispatcher - Received an ATTACHED protocol message for FAILED channel #{channel.name}. Ignoring ATTACHED message"
                else
                  channel.transition_state_machine :attached, reason: protocol_message.error, resumed: protocol_message.has_channel_resumed_flag?, protocol_message: protocol_message
                end
              end
            end

          when ACTION.Detach
          when ACTION.Detached
            get_channel(protocol_message.channel).tap do |channel|
              channel.manager.detached_received protocol_message.error
            end

          when ACTION.Sync
            presence = get_channel(protocol_message.channel).presence
            presence.manager.sync_process_messages protocol_message.channel_serial, protocol_message.presence

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

          when ACTION.Auth
            client.auth.authorize

          else
            error = Ably::Exceptions::ProtocolError.new("Protocol Message Action #{protocol_message.action} is unsupported by this MessageDispatcher", 400, Ably::Exceptions::Codes::PROTOCOL_ERROR)
            logger.fatal error.message
        end
      end

      def dispatch_channel_error(protocol_message)
        logger.warn { "Channel Error message received: #{protocol_message.error}" }
        if !protocol_message.has_message_serial?
          get_channel(protocol_message.channel).transition_state_machine :failed, reason: protocol_message.error
        else
          logger.fatal { "Cannot process ProtocolMessage ERROR with message serial as not yet implemented: #{protocol_message}" }
        end
      end

      def process_connection_error(protocol_message)
        connection.manager.error_received_from_server(protocol_message.error || Ably::Models::ErrorInfo.new(message: 'Error reason unknown'))
      end

      def process_connected_message(protocol_message)
        if client.auth.token_client_id_allowed?(protocol_message.connection_details.client_id)
          connection.transition_state_machine :connected, reason: protocol_message.error, protocol_message: protocol_message
        else
          reason = Ably::Exceptions::IncompatibleClientId.new("Client ID '#{protocol_message.connection_details.client_id}' specified by the server is incompatible with the library's configured client ID '#{client.client_id}'")
          connection.transition_state_machine :failed, reason: reason, protocol_message: protocol_message
        end
      end

      def process_connected_update_message(protocol_message)
        if client.auth.token_client_id_allowed?(protocol_message.connection_details.client_id)
          connection.manager.connected_update protocol_message
        else
          reason = Ably::Exceptions::IncompatibleClientId.new("Client ID '#{protocol_message.connection_details.client_id}' in CONNECTED update specified by the server is incompatible with the library's configured client ID '#{client.client_id}'")
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
          logger.debug { "Calling ACK success callbacks for #{message.class.name} - #{message.to_json}" }
          message.succeed message
        end
      end

      def nack_messages(messages, protocol_message)
        messages.each do |message|
          logger.debug { "Calling NACK failure callbacks for #{message.class.name} - #{message.to_json}, protocol message: #{protocol_message}" }
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
