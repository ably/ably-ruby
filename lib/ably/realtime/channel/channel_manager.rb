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

        setup_connection_event_handlers
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

      # Detach a channel as a result of an error
      def suspend(error)
        channel.transition_state_machine! :detaching, reason: error
      end

      # When a channel is no longer attached or has failed,
      # all messages awaiting an ACK response should fail immediately
      def fail_messages_awaiting_ack(error)
        # Allow a short time for other queued operations to complete before failing all messages
        EventMachine.next_tick do
          error = Ably::Exceptions::MessageDeliveryFailed.new("Channel cannot publish messages whilst state is '#{channel.state}'") unless error
          fail_messages_in_queue connection.__pending_message_ack_queue__, error
          fail_messages_in_queue connection.__outgoing_message_queue__, error
        end
      end

      def fail_messages_in_queue(queue, error)
        queue.delete_if do |protocol_message|
          if protocol_message.channel == channel.name
            nack_messages protocol_message, error
            true
          end
        end
      end

      def nack_messages(protocol_message, error)
        (protocol_message.messages + protocol_message.presence).each do |message|
          logger.debug "Calling NACK failure callbacks for #{message.class.name} - #{message.to_json}, protocol message: #{protocol_message}"
          message.fail error
        end
        logger.debug "Calling NACK failure callbacks for #{protocol_message.class.name} - #{protocol_message.to_json}"
        protocol_message.fail error
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

      # Any message sent before an ACK/NACK was received on the previous transport
      # needs to be resent to the Ably service so that a subsequent ACK/NACK is received.
      # It is up to Ably to ensure that duplicate messages are not retransmitted on the channel
      # base on the serial numbers
      #
      # TODO: Move this into the Connection class, it does not belong in a Channel class
      #
      # @api private
      def resend_pending_message_ack_queue
        connection.__pending_message_ack_queue__.delete_if do |protocol_message|
          if protocol_message.channel == channel.name
            connection.__outgoing_message_queue__ << protocol_message
            connection.__outgoing_protocol_msgbus__.publish :protocol_message
            true
          end
        end
      end

      def setup_connection_event_handlers
        connection.unsafe_on(:closed) do
          channel.transition_state_machine :detaching if can_transition_to?(:detaching)
        end

        connection.unsafe_on(:suspended) do |error|
          if can_transition_to?(:detaching)
            channel.transition_state_machine :detaching, reason: Ably::Exceptions::ConnectionSuspended.new('Connection suspended', nil, 80002, error)
          end
        end

        connection.unsafe_on(:failed) do |error|
          if can_transition_to?(:failed) && !channel.detached?
            channel.transition_state_machine :failed, reason: Ably::Exceptions::ConnectionFailed.new('Connection failed', nil, 80002, error)
          end
        end

        connection.unsafe_on(:connected) do |error|
          resend_pending_message_ack_queue
        end
      end

      def logger
        connection.logger
      end
    end
  end
end
