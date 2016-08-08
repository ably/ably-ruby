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
      end

      # Commence attachment
      def attach
        if can_transition_to?(:attached)
          connect_if_connection_initialized
          send_attach_protocol_message
        end
      end

      # Commence attachment
      def detach(error = nil)
        if connection.closed? || connection.connecting? || connection.suspended?
          channel.transition_state_machine :detached, reason: error
        elsif can_transition_to?(:detached)
          send_detach_protocol_message
        end
      end

      # Channel is attached, notify presence if sync is expected
      def attached(attached_protocol_message)
        if attached_protocol_message.has_presence_flag?
          channel.presence.manager.sync_expected
        else
          channel.presence.manager.sync_not_expected
        end
        channel.set_attached_serial attached_protocol_message.channel_serial
      end

      # An error has occurred on the channel
      def emit_error(error)
        logger.error "ChannelManager: Channel '#{channel.name}' error: #{error}"
        channel.emit :error, error
      end

      # Request channel to be reattached by sending an attach protocol message
      def request_reattach(reason: nil)
        send_attach_protocol_message
        logger.debug "Explicit channel reattach request sent to Ably"
        channel.transition_state_machine! :attaching, reason: reason unless channel.attaching?
        channel.set_failed_channel_error_reason(reason) if reason
      end

      def duplicate_attached_received(error)
        if error
          channel.set_failed_channel_error_reason error
          emit_error error
        else
          logger.debug "ChannelManager: Extra ATTACHED message received for #{channel.state} channel '#{channel.name}'"
        end
      end

      # When continuity on the connection is interrupted or channel becomes suspended (implying loss of continuity)
      # then all messages published but awaiting an ACK from Ably should be failed with a NACK
      def fail_messages_awaiting_ack(error, immediately: false)
        fail_proc = Proc.new do
          error = Ably::Exceptions::MessageDeliveryFailed.new("Continuity of connection was lost so published messages awaiting ACK have failed") unless error
          fail_messages_in_queue connection.__pending_message_ack_queue__, error
        end

        # Allow a short time for other queued operations to complete before failing all messages
        if immediately
          fail_proc.call
        else
          EventMachine.add_timer(0.1) { fail_proc.call }
        end
      end

      # When a channel becomes detached, suspended or failed,
      # all queued messages should be failed immediately as we don't queue in
      # any of those states
      def fail_queued_messages(error)
        error = Ably::Exceptions::MessageDeliveryFailed.new("Queueing messages on channel '#{channel.name}' in state '#{channel.state}' is not possible") unless error
        fail_messages_in_queue connection.__outgoing_message_queue__, error
        channel.__queue__.each do |message|
          nack_message message, error
        end
        channel.__queue__.clear
      end

      def fail_messages_in_queue(queue, error)
        queue.delete_if do |protocol_message|
          if [:presence, :message].include?(protocol_message.action)
            if protocol_message.channel == channel.name
              nack_messages protocol_message, error
              true
            end
          end
        end
      end

      def nack_messages(protocol_message, error)
        (protocol_message.messages + protocol_message.presence).each do |message|
          nack_message message, error, protocol_message
        end
        logger.debug "Calling NACK failure callbacks for #{protocol_message.class.name} - #{protocol_message.to_json}"
        protocol_message.fail error
      end

      def nack_message(message, error, protocol_message = nil)
        logger.debug "Calling NACK failure callbacks for #{message.class.name} - #{message.to_json} #{"protocol message: #{protocol_message}" if protocol_message}"
        message.fail error
      end

      def drop_pending_queue_from_ack(ack_protocol_message)
        message_serial_up_to = ack_protocol_message.message_serial + ack_protocol_message.count - 1
        connection.__pending_message_ack_queue__.drop_while do |protocol_message|
          if protocol_message.message_serial <= message_serial_up_to
            yield protocol_message
            true
          end
        end
      end

      private
      def channel
        @channel
      end

      def connection
        @connection
      end

      def_delegators :channel, :can_transition_to?

      # If the connection has not previously connected, connect now
      def connect_if_connection_initialized
        connection.connect if connection.initialized?
      end

      def realtime_request_timeout
        connection.defaults.fetch(:realtime_request_timeout)
      end

      def send_attach_protocol_message
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Attach, :suspended # move to suspended
      end

      def send_detach_protocol_message
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Detach, channel.state # return to current state
      end

      def send_state_change_protocol_message(new_state, state_if_failed)
        state_at_time_of_request = channel.state
        failed_timer = EventMachine::Timer.new(realtime_request_timeout) do
          if channel.state == state_at_time_of_request
            error = Ably::Models::ErrorInfo.new(code: 90007, message: "Channel #{new_state} operation failed (timed out)")
            channel.transition_state_machine state_if_failed, reason: error
          end
        end

        channel.once_state_changed { failed_timer.cancel }

        connection.send_protocol_message(
          action:  new_state.to_i,
          channel: channel.name
        )
      end

      def logger
        connection.logger
      end
    end
  end
end
