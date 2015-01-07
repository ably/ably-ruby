module Ably::Realtime
  class Channel
    # ChannelManager is responsible for all actions relating to channel state: attaching, detaching or failure
    # Channel state changes are performed by this class and executed from {ChannelStateMachine}
    #
    # This is a private class and should never be used directly by developers as the API is likely to change in future.
    #
    # @api private
    class ChannelManager
      extend Forwardable

      def initialize(channel, connection)
        @channel    = channel
        @connection = connection

        connection.on(:closed) do
          channel.transition_state_machine :detaching if can_transition_to?(:detaching)
        end

        connection.on(:failed) do |error|
          channel.transition_state_machine :failed, error if can_transition_to?(:failed)
        end

        channel.on(:attached, :detached) do
          channel.set_failed_channel_error_reason nil
        end
      end

      # Commence attachment
      def attach
        if can_transition_to?(:attached)
          connect_if_connection_initialized
          send_attach_protocol_message
        end
      end

      # Commence attachment
      def detach
        if connection.closed?
          channel.transition_state_machine :detached
        elsif can_transition_to?(:detached)
          send_detach_protocol_message
        end
      end

      # Commence presence SYNC if applicable
      def sync(attached_protocol_message)
        if attached_protocol_message.has_presence_flag?
          channel.presence.sync_started
        else
          channel.presence.sync_completed
        end
      end

      # Channel has failed
      def failed(error)
        logger.error "Channel #{channel.name} error: #{error}"
        channel.trigger :error, error
      end

      private

      attr_reader :channel, :connection
      def_delegators :channel, :can_transition_to?

      # If the connection has not previously connected, connect now
      def connect_if_connection_initialized
        connection.connect if connection.initialized?
      end

      def send_attach_protocol_message
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Attach
      end

      def send_detach_protocol_message
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Detach
      end

      def send_state_change_protocol_message(state)
        connection.send_protocol_message(
          action:  state.to_i,
          channel: channel.name
        )
      end

      def logger
        connection.logger
      end
    end
  end
end
