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
      # Configuration for automatic recovery of failed connection attempts
      CONNECT_RETRY_CONFIG = {
        disconnected: { retry_every: 15,  max_time_in_state: 120 },
        suspended:    { retry_every: 120, max_time_in_state: Float::INFINITY }
      }.freeze

      # Time to wait following a connection state request before it's considered a failure
      TIMEOUTS = {
        open:  15,
        close: 10
      }

      # Error codes from the server that can potentially be resolved
      RESOLVABLE_ERROR_CODES = {
        token_expired: 40140
      }

      def initialize(connection)
        @connection = connection
        @timers     = Hash.new { |hash, key| hash[key] = [] }

        connection.unsafe_on(:closed) do
          connection.reset_resume_info
        end

        connection.unsafe_once(:connecting) do
          close_connection_when_reactor_is_stopped
        end

        EventMachine.next_tick do
          # Connect once Connection object is initialised
          connection.connect if client.auto_connect
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
          connection.transition_state_machine :failed, Ably::Exceptions::InsecureRequest.new('Cannot use Basic Auth over non-TLS connections', 401, 40103)
          return
        end

        logger.debug 'ConnectionManager: Opening a websocket transport connection'

        connection.create_websocket_transport.tap do |socket_deferrable|
          socket_deferrable.callback do |websocket_transport|
            subscribe_to_transport_events websocket_transport
            yield websocket_transport if block_given?
          end
          socket_deferrable.errback do |error|
            connection_opening_failed error
          end
        end

        logger.debug "ConnectionManager: Setting up automatic connection timeout timer for #{TIMEOUTS.fetch(:open)}s"
        create_timeout_timer_whilst_in_state(:connect, TIMEOUTS.fetch(:open)) do
          connection_opening_failed Ably::Exceptions::ConnectionTimeout.new("Connection to Ably timed out after #{TIMEOUTS.fetch(:open)}s", nil, 80014)
        end
      end

      # Called by the transport when a connection attempt fails
      #
      # @api private
      def connection_opening_failed(error)
        logger.warn "ConnectionManager: Connection to #{connection.current_host}:#{connection.port} failed; #{error.message}"
        connection.transition_state_machine next_retry_state, Ably::Exceptions::ConnectionError.new("Connection failed: #{error.message}", nil, 80000)
      end

      # Called whenever a new connection is made
      #
      # @api private
      def connected(protocol_message)
        if connection.key
          if protocol_message.connection_key == connection.key
            logger.debug "ConnectionManager: Connection resumed successfully - ID #{connection.id} and key #{connection.key}"
            EventMachine.next_tick { connection.resumed }
          else
            logger.debug "ConnectionManager: Connection was not resumed, old connection ID #{connection.id} has been updated with new connect ID #{protocol_message.connection_id} and key #{protocol_message.connection_key}"
            detach_attached_channels protocol_message.error
            connection.configure_new protocol_message.connection_id, protocol_message.connection_key, protocol_message.connection_serial
          end
        else
          logger.debug "ConnectionManager: New connection created with ID #{protocol_message.connection_id} and key #{protocol_message.connection_key}"
          connection.configure_new protocol_message.connection_id, protocol_message.connection_key, protocol_message.connection_serial
        end
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

        create_timeout_timer_whilst_in_state(:close, TIMEOUTS.fetch(:close)) do
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
        connection.logger.fatal "ConnectionManager: Connection failed - #{error}"
        connection.manager.destroy_transport
        connection.unsafe_once(:failed) { connection.emit :error, error }
      end

      # When a connection is disconnected whilst connecting, attempt reconnect and/or set state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected_when_connecting(current_transition)
        return unless connection.disconnected? || connection.suspended? # do nothing if state has changed through an explicit request
        return unless retry_connection? # do not always reattempt connection or change state as client may be re-authorising

        error = current_transition.metadata
        if error.kind_of?(Ably::Models::ErrorInfo)
          renew_token_and_reconnect error if error.code == RESOLVABLE_ERROR_CODES.fetch(:token_expired)
          return
        end

        unless connection_retry_from_suspended_state?
          return if connection_retry_for(:disconnected)
        end

        return if connection_retry_for(:suspended)

        # Fallback if no other criteria met
        connection.transition_state_machine :failed, current_transition.metadata
      end

      # When a connection is disconnected after connecting, attempt reconnect and/or set state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected_whilst_connected(current_transition)
        logger.warn "ConnectionManager: Connection to #{connection.transport.url} was disconnected unexpectedly"

        error = current_transition.metadata
        if error.kind_of?(Ably::Models::ErrorInfo) && error.code != RESOLVABLE_ERROR_CODES.fetch(:token_expired)
          connection.emit :error, error
          logger.error "ConnectionManager: Error in Disconnected ProtocolMessage received from the server - #{error}"
        end

        destroy_transport
        respond_to_transport_disconnected_when_connecting current_transition
      end

      # {Ably::Models::ProtocolMessage ProtocolMessage Error} received from server.
      # Some error states can be resolved by the client library.
      #
      # @api private
      def error_received_from_server(error)
        case error.code
        when RESOLVABLE_ERROR_CODES.fetch(:token_expired)
          connection.transition_state_machine :disconnected
          connection.unsafe_once_or_if(:disconnected) do
            renew_token_and_reconnect error
          end
        else
          logger.error "ConnectionManager: Error #{error.class.name} code #{error.code} received from server '#{error.message}', transitioning to failed state"
          connection.transition_state_machine :failed, error
        end
      end

      # Number of consecutive attempts for provided state
      # @return [Integer]
      # @api private
      def retry_count_for_state(state)
        retries_for_state(state, ignore_states: [:connecting]).count
      end

      private
      attr_reader :connection

      # Timers used to manage connection state, for internal use by the client library
      # @return [Hash]
      attr_reader :timers

      def transport
        connection.transport
      end

      def client
        connection.client
      end

      def channels
        client.channels
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

      def next_retry_state
        if connection_retry_from_suspended_state? || time_passed_since_disconnected > CONNECT_RETRY_CONFIG.fetch(:disconnected).fetch(:max_time_in_state)
          :suspended
        else
          :disconnected
        end
      end

      def connection_retry_from_suspended_state?
        !retries_for_state(:suspended, ignore_states: [:connecting]).empty?
      end

      def time_passed_since_disconnected
        time_spent_attempting_state(:disconnected, ignore_states: [:connecting])
      end

      # Reattempt a connection with a delay based on the CONNECT_RETRY_CONFIG for `from_state`
      #
      # @return [Boolean] True if a connection attempt has been set up, false if no further connection attempts can be made for this state
      #
      def connection_retry_for(from_state)
        retry_params = CONNECT_RETRY_CONFIG.fetch(from_state)

        if can_reattempt_connect_for_state?(from_state)
          if retries_for_state(from_state, ignore_states: [:connecting]).empty?
            logger.debug "ConnectionManager: Will attempt reconnect immediately as no previous reconnect attempts made in this state"
            EventMachine.next_tick { connection.connect }
          else
            logger.debug "ConnectionManager: Pausing for #{retry_params.fetch(:retry_every)}s before attempting to reconnect"
            create_timeout_timer_whilst_in_state(:reconnect, retry_params.fetch(:retry_every)) do
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
        retry_params = CONNECT_RETRY_CONFIG.fetch(state)
        time_spent_attempting_state(state, ignore_states: [:connecting]) < retry_params.fetch(:max_time_in_state)
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
          elsif !connection.closed? && !connection.disconnected?
            exception = if reason
              Ably::Exceptions::ConnectionClosed.new(reason)
            end
            if connection_retry_from_suspended_state? || !can_reattempt_connect_for_state?(:disconnected)
              connection.transition_state_machine :suspended, exception
            else
              connection.transition_state_machine :disconnected, exception
            end
          end
        end
      end

      def renew_token_and_reconnect(error)
        if client.auth.token_renewable?
          if @renewing_token
            connection.transition_state_machine :failed, error
            return
          end

          @renewing_token = true
          logger.info "ConnectionManager: Token has expired and is renewable, renewing token now"

          client.auth.authorise.tap do |authorise_deferrable|
            authorise_deferrable.callback do |token_details|
              logger.info 'ConnectionManager: Token renewed succesfully following expiration'

              state_changed_callback = proc do
                @renewing_token = false
                connection.off &state_changed_callback
              end

              connection.unsafe_once :connected, :closed, :failed, &state_changed_callback

              if token_details && !token_details.expired?
                connection.connect
              else
                connection.transition_state_machine :failed, error unless connection.failed?
              end
            end

            authorise_deferrable.errback do |auth_error|
              logger.error "ConnectionManager: Error authorising following token expiry: #{auth_error}"
              connection.transition_state_machine :failed, auth_error
            end
          end
        else
          logger.error "ConnectionManager: Token has expired and is not renewable - #{error}"
          connection.transition_state_machine :failed, error
        end
      end

      def unsubscribe_from_transport_events(transport)
        transport.__incoming_protocol_msgbus__.unsubscribe
        transport.off
        logger.debug "ConnectionManager: Unsubscribed from all events from current transport"
      end

      def close_connection_when_reactor_is_stopped
        EventMachine.add_shutdown_hook do
          connection.close unless connection.closed? || connection.failed?
        end
      end

      def retry_connection?
        !@renewing_token
      end

      def detach_attached_channels(error)
        channels.select do |channel|
          channel.attached? || channel.attaching?
        end.each do |channel|
          logger.warn "Force detaching channel '#{channel.name}': #{error}"
          channel.manager.suspend error
        end
      end

      def logger
        connection.logger
      end
    end
  end
end
