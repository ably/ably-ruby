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
      def detach(error, previous_state)
        if connection.closed? || connection.connecting? || connection.suspended?
          channel.transition_state_machine :detached, reason: error
        elsif can_transition_to?(:detached)
          send_detach_protocol_message previous_state
        end
      end

      # Channel is attached, notify presence if sync is expected
      def attached(attached_protocol_message)
        # If no attached ProtocolMessage then this attached request was triggered by the client
        # library, such as returning to attached when detach has failed
        if attached_protocol_message
          channel.presence.manager.on_attach attached_protocol_message.has_presence_flag?
          channel.properties.set_attach_serial(attached_protocol_message.channel_serial)
          channel.options.set_modes_from_flags(attached_protocol_message.flags)
          channel.options.set_params(attached_protocol_message.params)
        end
      end

      # An error has occurred on the channel
      def log_channel_error(error)
        logger.error { "ChannelManager: Channel '#{channel.name}' error: #{error}" }
      end

      # Request channel to be reattached by sending an attach protocol message
      # @param [Hash] options
      # @option options [Ably::Models::ErrorInfo]  :reason
      def request_reattach(options = {})
        reason = options[:reason]
        send_attach_protocol_message(options[:forced_attach])
        logger.debug { "Explicit channel reattach request sent to Ably due to #{reason}" }
        channel.set_channel_error_reason(reason) if reason
        channel.transition_state_machine! :attaching, reason: reason unless channel.attaching?
      end

      def duplicate_attached_received(protocol_message)
        logger.debug { "Server initiated ATTACHED message received for channel '#{channel.name}' with state #{channel.state}" }
        if protocol_message.error
          channel.set_channel_error_reason protocol_message.error
          log_channel_error protocol_message.error
        end

        channel.properties.set_attach_serial(protocol_message.channel_serial)
        channel.options.set_modes_from_flags(protocol_message.flags)

        unless protocol_message.has_channel_resumed_flag?
          channel.emit :update, Ably::Models::ChannelStateChange.new(
            current: channel.state,
            previous: channel.state,
            event: Ably::Realtime::Channel::EVENT(:update),
            reason: protocol_message.error,
            resumed: false,
          )
          channel.presence.manager.on_attach protocol_message.has_presence_flag?
        end
      end

      # Handle DETACED messages, see #RTL13 for server-initated detaches
      def detached_received(reason)
        case channel.state.to_sym
        when :detaching
          channel.transition_state_machine :detached, reason: reason
        when :attached, :suspended
          channel.transition_state_machine :attaching, reason: reason
        else
          logger.debug { "ChannelManager: DETACHED ProtocolMessage received, but no action to take as not DETACHING, ATTACHED OR SUSPENDED" }
        end
      end

      # When continuity on the connection is interrupted or channel becomes suspended (implying loss of continuity)
      # then all messages published but awaiting an ACK from Ably should be failed with a NACK
      # @param [Hash] options
      # @option options [Boolean]  :immediately
      def fail_messages_awaiting_ack(error, options = {})
        immediately = options[:immediately] || false

        fail_proc = lambda do
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

      # When a channel becomes suspended or failed,
      # all queued messages should be failed immediately as we don't queue in
      # any of those states
      def fail_queued_messages(error)
        error = Ably::Exceptions::MessageDeliveryFailed.new("Queued messages on channel '#{channel.name}' in state '#{channel.state}' will never be delivered") unless error
        fail_messages_in_queue connection.__outgoing_message_queue__, error
      end

      def fail_messages_in_queue(queue, error)
        queue.delete_if do |protocol_message|
          if protocol_message.action.match_any?(:presence, :message)
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
        logger.debug { "Calling NACK failure callbacks for #{protocol_message.class.name} - #{protocol_message.to_json}" }
        protocol_message.fail error
      end

      def nack_message(message, error, protocol_message = nil)
        logger.debug { "Calling NACK failure callbacks for #{message.class.name} - #{message.to_json} #{"protocol message: #{protocol_message}" if protocol_message}" }
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

      # If the connection is still connected and the channel still suspended after
      # channel_retry_timeout has passed, then attempt to reattach automatically, see #RTL13b
      def start_attach_from_suspended_timer
        cancel_attach_from_suspended_timer
        if connection.connected?
          channel.unsafe_once { |event| cancel_attach_from_suspended_timer unless event == :update }
          connection.unsafe_once { |event| cancel_attach_from_suspended_timer unless event == :update }

          @attach_from_suspended_timer = EventMachine::Timer.new(channel_retry_timeout) do
            channel.transition_state_machine! :attaching
          end
        end
      end

      private
      attr_reader :pending_state_change_timer

      def channel
        @channel
      end

      def connection
        @connection
      end

      def_delegators :channel, :can_transition_to?

      def cancel_attach_from_suspended_timer
        @attach_from_suspended_timer.cancel if @attach_from_suspended_timer
        @attach_from_suspended_timer = nil
      end

      # If the connection has not previously connected, connect now
      def connect_if_connection_initialized
        connection.connect if connection.initialized?
      end

      def realtime_request_timeout
        connection.defaults.fetch(:realtime_request_timeout)
      end

      def channel_retry_timeout
        connection.defaults.fetch(:channel_retry_timeout)
      end

      def send_attach_protocol_message(forced_attach = false)
        # Shouldn't queue attach message as per RTL4i
        if forced_attach || connection.state?(:connected)
          message_options = {}
          message_options[:params] = channel.options.params if channel.options.params.any?
          message_options[:flags] = channel.options.modes_to_flags if channel.options.modes
          if channel.attach_resume
            message_options[:flags] = message_options[:flags].to_i | Ably::Models::ProtocolMessage::ATTACH_FLAGS_MAPPING[:resume]
          end

          message_options[:channelSerial] = channel.properties.channel_serial # RTL4c1
          send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Attach, :suspended, message_options
        end
      end

      def send_detach_protocol_message(previous_state)
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Detach, previous_state # return to previous state if failed
      end

      def send_state_change_protocol_message(new_state, state_if_failed, message_options = {})
        state_at_time_of_request = channel.state
        @pending_state_change_timer = EventMachine::Timer.new(realtime_request_timeout) do
          if channel.state == state_at_time_of_request
            error = Ably::Models::ErrorInfo.new(code: Ably::Exceptions::Codes::CHANNEL_OPERATION_FAILED_NO_RESPONSE_FROM_SERVER, message: "Channel #{new_state} operation failed (timed out)")
            channel.transition_state_machine state_if_failed, reason: error
          end
        end

        channel.once_state_changed do
          @pending_state_change_timer.cancel if @pending_state_change_timer
          @pending_state_change_timer = nil
        end

        resend_if_disconnected_and_connected = lambda do
          connection.unsafe_once(:disconnected) do
            next unless pending_state_change_timer
            connection.unsafe_once(:connected) do
              next unless pending_state_change_timer
              connection.send_protocol_message(
                action:  new_state.to_i,
                channel: channel.name,
                **message_options.to_h
              )
              resend_if_disconnected_and_connected.call
            end
          end
        end

        # since attach is sent on every connect, no need to introduce logic that sends attach on disconnect and connect
        # RTN15c6, RTN15c7
        if new_state == Ably::Models::ProtocolMessage::ACTION.Attach
          connection.send_protocol_message_immediately(
            action:  new_state.to_i,
            channel: channel.name,
            **message_options.to_h
            )
          return
        end

        resend_if_disconnected_and_connected.call

        connection.send_protocol_message(
          action:  new_state.to_i,
          channel: channel.name,
          **message_options.to_h
        )
      end

      def logger
        connection.logger
      end
    end
  end
end
