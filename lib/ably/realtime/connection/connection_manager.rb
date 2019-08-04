require 'ably/rest/middleware/exceptions'

module Ably::Realtime
  class Connection
    # ConnectionManager is responsible for all actions relating to underlying connection and transports,
    # such as opening, closing, attempting reconnects etc.
    # Connection state changes are performed by this class and executed from {ConnectionStateMachine}
    #
    # This is a private class and should never be used directly by developers as the API is likely to change in future.
    #
    # @api private
    class ConnectionManager
      # Error codes from the server that can potentially be resolved
      RESOLVABLE_ERROR_CODES = {
        token_expired: Ably::Exceptions::TOKEN_EXPIRED_CODE
      }

      def initialize(connection)
        @connection     = connection
        @timers         = Hash.new { |hash, key| hash[key] = [] }

        connection.unsafe_on(:closed) do
          connection.reset_resume_info
        end

        connection.unsafe_once(:connecting) do
          close_connection_when_reactor_is_stopped
        end

        EventMachine.next_tick do
          # Connect once Connection object is initialised
          connection.connect if client.auto_connect && connection.can_transition_to?(:connecting)
        end
      end

      # Creates and sets up a new {Ably::Realtime::Connection::WebsocketTransport} available on attribute #transport
      #
      # @yield [Ably::Realtime::Connection::WebsocketTransport] block is called with new websocket transport
      # @api private
      def setup_transport
        if transport && !transport.ready_for_release?
          raise RuntimeError, 'Existing WebsocketTransport is connected, and must be closed first'
        end

        unless client.auth.authentication_security_requirements_met?
          connection.transition_state_machine :failed, reason: Ably::Exceptions::InsecureRequest.new('Cannot use Basic Auth over non-TLS connections', 401, Ably::Exceptions::Codes::INVALID_USE_OF_BASIC_AUTH_OVER_NONTLS_TRANSPORT)
          return
        end

        logger.debug { 'ConnectionManager: Opening a websocket transport connection' }

        # The socket attempt can fail at the same time as a timer firing so ensure
        #   only one outcome is processed from this setup attempt
        setup_attempt_status = {}
        setup_failed = lambda do
          return true if setup_attempt_status[:failed]
          setup_attempt_status[:failed] = true
          false
        end

        connection.create_websocket_transport.tap do |socket_deferrable|
          socket_deferrable.callback do |websocket_transport|
            subscribe_to_transport_events websocket_transport
            yield websocket_transport if block_given?
          end
          socket_deferrable.errback do |error|
            next if setup_failed.call
            connection_opening_failed error
          end
        end

        # The connection request timeout must be marginally higher than the REST request timeout to ensure
        #   any HTTP auth request failure due to timeout triggers before the connection timer kicks in
        logger.debug { "ConnectionManager: Setting up automatic connection timeout timer for #{realtime_request_timeout}s" }
        create_timeout_timer_whilst_in_state(:connecting, realtime_request_timeout) do
          next if setup_failed.call
          connection_opening_failed Ably::Exceptions::ConnectionTimeout.new("Connection to Ably timed out after #{realtime_request_timeout}s", nil, Ably::Exceptions::Codes::CONNECTION_TIMED_OUT)
        end
      end

      # Called by the transport when a connection attempt fails
      #
      # @api private
      def connection_opening_failed(error)
        if error.kind_of?(Ably::Exceptions::BaseAblyException)
          # Authentication errors that indicate the authentication failure is terminal should move to the failed state
          if ([401, 403].include?(error.status) && !RESOLVABLE_ERROR_CODES.fetch(:token_expired).include?(error.code)) ||
             (error.code == Ably::Exceptions::Codes::INVALID_CLIENT_ID)
            connection.transition_state_machine :failed, reason: error
            return
          end
        end

        logger.warn { "ConnectionManager: Connection to #{connection.current_host}:#{connection.port} failed; #{error.message}" }
        next_state = get_next_retry_state_info

        if connection.state == next_state.fetch(:state)
          logger.error { "ConnectionManager: Skipping next retry state after connection opening failed as already in state #{next_state}\n#{caller[0..20].join("\n")}" }
        else
          connection.transition_state_machine next_state.fetch(:state), retry_in: next_state.fetch(:pause), reason: Ably::Exceptions::ConnectionError.new("Connection failed: #{error.message}", nil, Ably::Exceptions::Codes::CONNECTION_FAILED, error)
        end
      end

      # Called whenever a new connection is made
      #
      # @api private
      def connected(protocol_message)
        # ClientID validity is already checked as part of the incoming message processing
        client.auth.configure_client_id protocol_message.connection_details.client_id

        # Update the connection details and any associated defaults
        connection.set_connection_details protocol_message.connection_details

        if connection.key
          if protocol_message.connection_id == connection.id
            logger.debug { "ConnectionManager: Connection resumed successfully - ID #{connection.id} and key #{connection.key}" }
            EventMachine.next_tick { connection.trigger_resumed }
            resend_pending_message_ack_queue
          else
            logger.debug { "ConnectionManager: Connection was not resumed, old connection ID #{connection.id} has been updated with new connection ID #{protocol_message.connection_id} and key #{protocol_message.connection_key}" }
            nack_messages_on_all_channels protocol_message.error
            force_reattach_on_channels protocol_message.error
          end
        else
          logger.debug { "ConnectionManager: New connection created with ID #{protocol_message.connection_id} and key #{protocol_message.connection_key}" }
        end

        reattach_suspended_channels protocol_message.error

        connection.configure_new protocol_message.connection_id, protocol_message.connection_key, protocol_message.connection_serial
      end

      # When connection is CONNECTED and receives an update
      # Update the Connection details and emit an UPDATE event #RTN4h
      def connected_update(protocol_message)
        # ClientID validity is already checked as part of the incoming message processing
        client.auth.configure_client_id protocol_message.connection_details.client_id

        # Update the connection details and any associated defaults
        connection.set_connection_details protocol_message.connection_details

        connection.configure_new protocol_message.connection_id, protocol_message.connection_key, protocol_message.connection_serial

        state_change = Ably::Models::ConnectionStateChange.new(
          current: connection.state,
          previous: connection.state,
          event: Ably::Realtime::Connection::EVENT(:update),
          reason: protocol_message.error,
          protocol_message: protocol_message
        )
        connection.emit :update, state_change
      end

      # Ensures the underlying transport has been disconnected and all event emitter callbacks removed
      #
      # @api private
      def destroy_transport
        if transport
          unsubscribe_from_transport_events transport
          transport.close_connection
          connection.release_websocket_transport
        end
      end

      # @api private
      def release_and_establish_new_transport
        destroy_transport
        setup_transport
      end

      # Reconnect the {Ably::Realtime::Connection::WebsocketTransport} if possible, otherwise set up a new transport
      #
      # @api private
      def reconnect_transport
        if !transport || transport.disconnected?
          setup_transport
        else
          transport.reconnect connection.current_host, connection.port
        end
      end

      # Send a Close {Ably::Models::ProtocolMessage} to the server and release the transport
      #
      # @api private
      def close_connection
        connection.send_protocol_message(action: Ably::Models::ProtocolMessage::ACTION.Close)

        create_timeout_timer_whilst_in_state(:closing, realtime_request_timeout) do
          force_close_connection if connection.closing?
        end
      end

      # Close the underlying transport immediately and set the connection state to closed
      #
      # @api private
      def force_close_connection
        destroy_transport
        connection.transition_state_machine :closed
      end

      # Connection has failed
      #
      # @api private
      def fail(error)
        connection.logger.fatal { "ConnectionManager: Connection failed - #{error}" }
        destroy_transport
        channels.each do |channel|
          next if channel.detached? || channel.initialized?
          channel.transition_state_machine :failed, reason: error if channel.can_transition_to?(:failed)
        end
      end

      # When a connection is disconnected whilst connecting, attempt reconnect and/or set state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected_when_connecting(error)
        return unless connection.disconnected? || connection.suspended? # do nothing if state has changed through an explicit request
        return if currently_renewing_token? # do not always reattempt connection or change state as client may be re-authorising

        if error.kind_of?(Ably::Models::ErrorInfo)
          if RESOLVABLE_ERROR_CODES.fetch(:token_expired).include?(error.code)
            next_state = get_next_retry_state_info(1)
            logger.debug { "ConnectionManager: Transport disconnected because of token expiry, pausing #{next_state.fetch(:pause)}s before reattempting to connect" }
            EventMachine.add_timer(next_state.fetch(:pause)) { renew_token_and_reconnect error }
            return
          end
        end

        if connection.state == :suspended
          return if connection_retry_for(:suspended)
        elsif connection.state == :disconnected
          return if connection_retry_for(:disconnected)
        end

        # Fallback if no other criteria met
        connection.transition_state_machine :failed, reason: error
      end

      # When a connection is disconnected after connecting, attempt reconnect and/or set state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected_whilst_connected(error)
        unless connection.disconnected? || connection.suspended?
          logger.warn { "ConnectionManager: Connection #{"to #{connection.transport.url}" if connection.transport} was disconnected unexpectedly" }
        else
          logger.debug { "ConnectionManager: Transport disconnected whilst connection in #{connection.state} state" }
        end

        if error.kind_of?(Ably::Models::ErrorInfo) && !RESOLVABLE_ERROR_CODES.fetch(:token_expired).include?(error.code)
          logger.error { "ConnectionManager: Error in Disconnected ProtocolMessage received from the server - #{error}" }
        end

        destroy_transport
        respond_to_transport_disconnected_when_connecting error
      end

      # {Ably::Models::ProtocolMessage ProtocolMessage Error} received from server.
      # Some error states can be resolved by the client library.
      #
      # @api private
      def error_received_from_server(error)
        case error.code
        when RESOLVABLE_ERROR_CODES.fetch(:token_expired)
          next_state = get_next_retry_state_info(1)
          connection.transition_state_machine next_state.fetch(:state), retry_in: next_state.fetch(:pause), reason: error
        else
          logger.error { "ConnectionManager: Error #{error.class.name} code #{error.code} received from server '#{error.message}', transitioning to failed state" }
          connection.transition_state_machine :failed, reason: error
        end
      end

      # Number of consecutive attempts for provided state
      # @return [Integer]
      # @api private
      def retry_count_for_state(state)
        retries_for_state(state, ignore_states: [:connecting]).count
      end

      # Any message sent before an ACK/NACK was received on the previous transport
      # need to be resent to the Ably service so that a subsequent ACK/NACK is received.
      # It is up to Ably to ensure that duplicate messages are not retransmitted on the channel
      # base on the serial numbers
      #
      # @api private
      def resend_pending_message_ack_queue
        connection.__pending_message_ack_queue__.delete_if do |protocol_message|
          if protocol_message.ack_required?
            connection.__outgoing_message_queue__ << protocol_message
            connection.__outgoing_protocol_msgbus__.publish :protocol_message
            true
          end
        end
      end

      # @api private
      def suspend_active_channels(error)
        channels.select do |channel|
          channel.attached? || channel.attaching? || channel.detaching?
        end.each do |channel|
          channel.transition_state_machine! :suspended, reason: error
        end
      end

      # @api private
      def detach_active_channels
        channels.select do |channel|
          channel.attached? || channel.attaching? || channel.detaching?
        end.each do |channel|
          channel.transition_state_machine! :detaching # will always move to detached immediately if connection is closed
        end
      end

      # @api private
      def fail_active_channels(error)
        channels.select do |channel|
          channel.attached? || channel.attaching? || channel.detaching? || channel.suspended?
        end.each do |channel|
          channel.transition_state_machine! :failed, reason: error
        end
      end

      # When continuity on a connection is lost all messages
      # whether queued or awaiting an ACK must be NACK'd as we now have a new connection
      def nack_messages_on_all_channels(error)
        channels.each do |channel|
          channel.manager.fail_messages_awaiting_ack error, immediately: true
          channel.manager.fail_queued_messages error
        end
      end

      # Liveness timer ensures a connection that has not heard from Ably in heartbeat_interval
      # is moved to the disconnected state automatically
      def reset_liveness_timer
        @liveness_timer.cancel if @liveness_timer
        @liveness_timer = EventMachine::Timer.new(connection.heartbeat_interval + 0.1) do
          if connection.connected? && (connection.time_since_connection_confirmed_alive? >= connection.heartbeat_interval)
            msg = "No activity seen from realtime in #{connection.heartbeat_interval}; assuming connection has dropped";
            error = Ably::Exceptions::ConnectionTimeout.new(msg, Ably::Exceptions::Codes::DISCONNECTED, 408)
            connection.transition_state_machine! :disconnected, reason: error
          end
        end
      end

      private
      def connection
        @connection
      end

      # Timers used to manage connection state, for internal use by the client library
      # @return [Hash]
      def timers
        @timers
      end

      def transport
        connection.transport
      end

      def client
        connection.client
      end

      def channels
        client.channels
      end

      def realtime_request_timeout
        connection.defaults.fetch(:realtime_request_timeout)
      end

      def retry_timeout_for(state)
        connection.defaults.fetch("#{state}_retry_timeout".to_sym) { raise ArgumentError.new("#{state} does not have a configured retry timeout") }
      end

      def state_has_retry_timeout?(state)
        connection.defaults.has_key?("#{state}_retry_timeout".to_sym)
      end

      # Create a timer that will execute in timeout_in seconds.
      # If the connection state changes however, cancel the timer
      def create_timeout_timer_whilst_in_state(timer_id, timeout_in)
        raise ArgumentError, 'Block required' unless block_given?

        timers[timer_id] << EventMachine::Timer.new(timeout_in) do
          yield
        end
        connection.unsafe_once_state_changed { clear_timers timer_id }
      end

      def clear_timers(key)
        timers.fetch(key, []).each(&:cancel)
      end

      def get_next_retry_state_info(allow_extra_immediate_retries = 0)
        retry_state = if connection_retry_from_suspended_state? || !can_reattempt_connect_for_state?(:disconnected)
          :suspended
        else
          :disconnected
        end
        {
          state: retry_state,
          pause: next_retry_pause(retry_state, allow_extra_immediate_retries)
        }
      end

      def next_retry_pause(retry_state, allow_extra_immediate_retries = 0)
        return nil unless state_has_retry_timeout?(retry_state)

        if retries_for_state(retry_state, ignore_states: [:connecting]).count <= allow_extra_immediate_retries
          0
        else
          retry_timeout_for(retry_state)
        end
      end

      def connection_retry_from_suspended_state?
        !retries_for_state(:suspended, ignore_states: [:connecting]).empty?
      end

      def time_passed_since_disconnected
        time_spent_attempting_state(:disconnected, ignore_states: [:connecting])
      end

      # Reattempt a connection with a delay based on the configured retry timeout for +from_state+
      #
      # @return [Boolean] True if a connection attempt has been set up, false if no further connection attempts can be made for this state
      #
      def connection_retry_for(from_state)
        if can_reattempt_connect_for_state?(from_state)
          if connection.state == :disconnected && retries_for_state(from_state, ignore_states: [:connecting]).empty?
            logger.debug { "ConnectionManager: Will attempt reconnect immediately as no previous reconnect attempts made in state #{from_state}" }
            EventMachine.next_tick { connection.connect }
          else
            logger.debug { "ConnectionManager: Pausing for #{retry_timeout_for(from_state)}s before attempting to reconnect" }
            create_timeout_timer_whilst_in_state(from_state, retry_timeout_for(from_state)) do
              connection.connect if connection.state == from_state
            end
          end
          true
        end
      end

      # True if the client library has not exceeded the configured max_time_in_state for the current State
      # For example, if the state is disconnected, and has been in a cycle of disconnected > connect > disconnected
      #  so long as the time in this cycle of states is less than max_time_in_state, this will return true
      def can_reattempt_connect_for_state?(state)
        case state
        when :disconnected
          time_spent_attempting_state(:disconnected, ignore_states: [:connecting]) < connection.connection_state_ttl
        when :suspended
          true # suspended state remains indefinitely
        else
          raise ArgumentError, "Connections in state '#{state}' cannot be reattempted"
        end
      end

      # Returns a float representing the amount of time passed since the first consecutive attempt of this state
      #
      # @param (see #retries_for_state)
      # @return [Float] time passed in seconds
      #
      def time_spent_attempting_state(state, options)
        states = retries_for_state(state, options)
        if states.empty?
          0
        else
          Time.now.to_f - states.last[:transitioned_at].to_f
        end.to_f
      end

      # Checks the state change history for the current connection and returns all matching consecutive states.
      # This is useful to determine the number of retries of a particular state on a connection.
      #
      # @param  state   [Symbol]
      # @param  options [Hash]
      # @option options [Array<Symbol>] :ignore_states states that should be ignored when determining consecutive historical retries for `state`.
      #                                 For example, when working out :connecting attempts, :disconnect state changes should be ignored as they are a side effect of a failed :connecting
      #
      # @return [Array<Hash>] Array of consecutive state attempts matching `state` in order of transitioned_at desc
      #
      def retries_for_state(state, options)
        ignore_states = options.fetch(:ignore_states, [])
        allowed_states = Array(state) + Array(ignore_states)

        state_history_ordered = connection.state_history.reverse
        last_state = state_history_ordered.first

        # If this method is called after the transition has been persisted to memory,
        # then we need to ignore the current transition when reviewing the number of retries
        if last_state[:state].to_sym == state && last_state.fetch(:transitioned_at).to_f > Time.now.to_f - 0.1
          state_history_ordered.shift
        end

        state_history_ordered.take_while do |transition|
          allowed_states.include?(transition[:state].to_sym)
        end.select do |transition|
          transition[:state] == state
        end
      end

      def subscribe_to_transport_events(transport)
        transport.__incoming_protocol_msgbus__.unsafe_on(:protocol_message) do |protocol_message|
          connection.__incoming_protocol_msgbus__.publish :protocol_message, protocol_message
        end

        transport.unsafe_on(:disconnected) do |reason|
          if connection.closing?
            connection.transition_state_machine :closed
          elsif !connection.closed? && !connection.disconnected? && !connection.failed? && !connection.suspended?
            exception = if reason
              Ably::Exceptions::TransportClosed.new(reason, nil, Ably::Exceptions::Codes::DISCONNECTED)
            else
              Ably::Exceptions::TransportClosed.new('Transport disconnected unexpectedly', nil, Ably::Exceptions::Codes::DISCONNECTED)
            end
            next_state = get_next_retry_state_info
            connection.transition_state_machine next_state.fetch(:state), retry_in: next_state.fetch(:pause), reason: exception
          end
        end
      end

      def renew_token_and_reconnect(error)
        if client.auth.token_renewable?
          if currently_renewing_token?
            logger.error { 'ConnectionManager: Attempting to renew token whilst another token renewal is underway. Aborting current renew token request' }
            return
          end

          logger.info { "ConnectionManager: Token has expired and is renewable, renewing token now" }

          # Authorize implicitly reconnects, see #RTC8
          client.auth.authorize.tap do |authorize_deferrable|
            authorize_deferrable.callback do |token_details|
              logger.info { 'ConnectionManager: Token renewed succesfully following expiration' }
            end
          end
        else
          logger.error { "ConnectionManager: Token has expired and is not renewable - #{error}" }
          connection.transition_state_machine :failed, reason: error
        end
      end

      def unsubscribe_from_transport_events(transport)
        transport.__incoming_protocol_msgbus__.unsubscribe
        transport.off
        logger.debug { "ConnectionManager: Unsubscribed from all events from current transport" }
      end

      def close_connection_when_reactor_is_stopped
        EventMachine.add_shutdown_hook do
          connection.close unless connection.closed? || connection.failed?
        end
      end

      def currently_renewing_token?
        client.auth.authorization_in_flight?
      end

      def reattach_suspended_channels(error)
        channels.select do |channel|
          channel.suspended?
        end.each do |channel|
          channel.transition_state_machine :attaching
        end
      end

      # When continuity on a connection is lost all messages
      # Channels in the ATTACHED or ATTACHING state should explicitly be re-attached
      # by sending a new ATTACH to Ably
      def force_reattach_on_channels(error)
        channels.select do |channel|
          channel.attached? || channel.attaching?
        end.each do |channel|
          channel.manager.request_reattach reason: error
        end
      end

      def logger
        connection.logger
      end
    end
  end
end
