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
        disconnected: { retry_every: 0.5, max_time_in_state: 10 },
        suspended:    { retry_every: 5,   max_time_in_state: 60 }
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

        connection.on(:closed) do
          connection.reset_resume_info
        end

        connection.once(:connecting) do
          close_connection_when_reactor_is_stopped
        end

        EventMachine.next_tick do
          # Connect once Connection object is initialised
          connection.connect if client.connect_automatically
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
          connection.transition_state_machine :failed, Ably::Exceptions::InsecureRequestError.new('Cannot use Basic Auth over non-TLS connections', 401, 40103)
          return
        end

        logger.debug 'ConnectionManager: Opening a websocket transport connection'

        connection.create_websocket_transport do |websocket_transport|
          subscribe_to_transport_events websocket_transport
          yield websocket_transport if block_given?
        end

        logger.debug "ConnectionManager: Setting up automatic connection timeout timer for #{TIMEOUTS.fetch(:open)}s"
        create_timeout_timer_whilst_in_state(:connect, TIMEOUTS.fetch(:open)) do
          connection_opening_failed Ably::Exceptions::ConnectionTimeoutError.new("Connection to Ably timed out after #{TIMEOUTS.fetch(:open)}s", nil, 80014)
        end
      end

      # Called by the transport when a connection attempt fails
      #
      # @api private
      def connection_opening_failed(error)
        logger.warn "ConnectionManager: Connection to #{connection.current_host}:#{connection.port} failed; #{error.message}"
        connection.transition_state_machine next_retry_state, Ably::Exceptions::ConnectionError.new("Connection failed; #{error.message}", nil, 80000)
      end

      # Called whenever a new connection message is received with an error
      #
      # @api private
      def connected_with_error(error)
        logger.warn "ConnectionManager: Connected with error; #{error.message}"
        connection.trigger :error, error
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
        connection.once(:failed) { connection.trigger :error, error }
      end

      # When a connection is disconnected whilst connecting, attempt reconnect and/or set state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected_when_connecting(current_transition)
        return unless connection.disconnected? || connection.suspended? # do nothing if state has changed through an explicit request
        return unless retry_connection? # do not always reattempt connection or change state as client may be re-authorising

        unless connection_retry_from_suspended_state?
          return if connection_retry_for(:disconnected, ignore_states: [:connecting])
        end

        return if connection_retry_for(:suspended, ignore_states: [:connecting])

        # Fallback if no other criteria met
        connection.transition_state_machine :failed, current_transition.metadata
      end

      # When a connection is disconnected after connecting, attempt reconnect and/or set state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected_whilst_connected(current_transition)
        logger.warn "ConnectionManager: Connection to #{connection.transport.url} was disconnected unexpectedly"

        if current_transition.metadata.kind_of?(Ably::Models::ErrorInfo)
          connection.trigger :error, current_transition.metadata
          logger.error "ConnectionManager: Error received when disconnected within ProtocolMessage - #{current_transition.metadata}"
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
          connection.once_or_if(:disconnected) do
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

      # Create a timer that will execute in timeout_in seconds.
      # If the connection state changes however, cancel the timer
      def create_timeout_timer_whilst_in_state(timer_id, timeout_in)
        raise ArgumentError, 'Block required' unless block_given?

        timers[timer_id] << EventMachine::Timer.new(timeout_in) do
          yield
        end
        connection.once_state_changed { clear_timers timer_id }
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
      def connection_retry_for(from_state, options = {})
        retry_params = CONNECT_RETRY_CONFIG.fetch(from_state)

        if time_spent_attempting_state(from_state, options) <= retry_params.fetch(:max_time_in_state)
          logger.debug "ConnectionManager: Pausing for #{retry_params.fetch(:retry_every)}s before attempting to reconnect"
          create_timeout_timer_whilst_in_state(:reconnect, retry_params.fetch(:retry_every)) do
            connection.connect if connection.state == from_state
          end
          true
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

        connection.state_history.reverse.take_while do |transition|
          allowed_states.include?(transition[:state].to_sym)
        end.select do |transition|
          transition[:state] == state
        end
      end

      def subscribe_to_transport_events(transport)
        transport.__incoming_protocol_msgbus__.on(:protocol_message) do |protocol_message|
          connection.__incoming_protocol_msgbus__.publish :protocol_message, protocol_message
        end

        transport.on(:disconnected) do
          if connection.closing?
            connection.transition_state_machine :closed
          elsif !connection.closed? && !connection.disconnected?
            connection.transition_state_machine :disconnected
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
          logger.warn "ConnectionManager: Token has expired and is renewable, renewing token now"

          operation = proc do
            begin
              client.auth.authorise
            rescue StandardError => auth_error
              connection.transition_state_machine :failed, auth_error
              nil
            end
          end

          callback = proc do |token|
            state_changed_callback = proc do
              @renewing_token = false
              connection.off &state_changed_callback
            end

            connection.once :connected, :closed, :failed, &state_changed_callback

            if token && !token.expired?
              reconnect_transport
            else
              connection.transition_state_machine :failed, error unless connection.failed?
            end
          end

          EventMachine.defer operation, callback
        else
          logger.warn "ConnectionManager: Token has expired and is not renewable"
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

      def logger
        connection.logger
      end
    end
  end
end
