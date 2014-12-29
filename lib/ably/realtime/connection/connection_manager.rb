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

      # Time to wait for a CLOSED ProtocolMessage response from the server in response to a CLOSE request
      FORCE_CONNECTION_CLOSED_TIMEOUT = 5

      def initialize(connection)
        @connection = connection

        @timers               = Hash.new { |hash, key| hash[key] = [] }
        @timers[:initializer] << EventMachine::Timer.new(0.01) { connection.connect }
      end

      # Creates and sets up a new {Ably::Realtime::Connection::WebsocketTransport} available on attribute #transport
      #
      # @yield [Ably::Realtime::Connection::WebsocketTransport] block is called with new websocket transport
      # @api private
      def setup_transport(&block)
        if transport && !transport.ready_for_release?
          raise RuntimeError, 'Existing WebsocketTransport is connected, and must be closed first'
        end

        logger.debug "ConnectionManager: Opening connection to #{connection.host}:#{connection.port}"

        connection.create_websocket_transport do |websocket_transport|
          subscribe_to_transport_events websocket_transport
          yield websocket_transport if block_given?
        end
      end

      # Called by the transport when a connection attempt fails
      #
      # @api private
      def connection_opening_failed(error)
        logger.error "ConnectionManager: Connection to #{connection.host}:#{connection.port} failed; #{error.message}"
        connection.transition_state_machine next_retry_state, Ably::Models::ErrorInfo.new(message: "Connection failed; #{error.message}", code: 80000)
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
          transport.reconnect connection.host, connection.port
        end
      end

      # Send a Close {Ably::Models::ProtocolMessage} to the server and release the transport
      #
      # @api private
      def close_connection
        connection.send_protocol_message(action: Ably::Models::ProtocolMessage::ACTION.Close)

        timer = EventMachine::Timer.new(FORCE_CONNECTION_CLOSED_TIMEOUT) do
          force_close_connection if connection.closing?
        end

        connection.once(:closed) do
          timer.cancel
        end
      end

      # Close the underlying transport immediately and set the connection state to closed
      #
      # @api private
      def force_close_connection
        destroy_transport
        connection.transition_state_machine :closed
      end

      # Remove all timers set up as part of the initialize process.
      # Typically called by StateMachine when connection is closed and can no longer process the timers
      #
      # @api private
      def cancel_initialized_timers
        clear_timers :initializer
      end

      # Remove all timers related to connection attempt retries following a disconnect or suspended connection state.
      # Typically called by StateMachine when connection is opened to ensure no further connection attempts are made
      #
      # @api private
      def cancel_connection_retry_timers
        clear_timers :connection_retry_timers
      end

      # When a connection is disconnected try and reconnect or set the connection state to :suspended or :failed
      #
      # @api private
      def respond_to_transport_disconnected(current_transition)
        unless connection_retry_from_suspended_state?
          return if connection_retried_for(:disconnected, ignore_states: [:connecting])
        end

        return if connection_retried_for(:suspended, ignore_states: [:connecting])

        # Fallback if no other criteria met
        connection.transition_state_machine :failed, current_transition.metadata
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

      def connection_retried_for(from_state, options = {})
        retry_params = CONNECT_RETRY_CONFIG.fetch(from_state)

        if time_spent_attempting_state(from_state, options) <= retry_params.fetch(:max_time_in_state)
          logger.debug "ConnectionManager: Pausing for #{retry_params.fetch(:retry_every)}s before attempting to reconnect"
          @timers[:connection_retry_timers] << EventMachine::Timer.new(retry_params.fetch(:retry_every)) do
            connection.connect
          end
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
          elsif !connection.closed?
            connection.transition_state_machine :disconnected
          end
        end
      end

      def unsubscribe_from_transport_events(transport)
        transport.__incoming_protocol_msgbus__.unsubscribe
        transport.off
        logger.debug "ConnectionManager: Unsubscribed from all events from current transport"
      end

      def logger
        connection.logger
      end
    end
  end
end
