module Ably::Realtime
  class Connection
    # ConnectionManager is responsible for all actions relating to underlying connection and transports,
    # such as opening, closing, attempting reconnects etc.
    #
    # This is a private class and should never be used directly by developers as the API is likely to change in future.
    #
    # @api private
    class ConnectionManager
      CONNECTION_FAILED = { retry_after: 0.5, max_retries: 2, code: 80000 }.freeze

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
      rescue EventMachine::ConnectionError => e
        logger.info "ConnectionManager: Connection to #{connection.host}:#{connection.port} failed; #{e.message}"
        connection.transition_state_machine :disconnected, Ably::Models::ErrorInfo.new(message: "Connection failed; #{e.message}", code: 80000)
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
        protocol_message = connection.send_protocol_message(action: Ably::Models::ProtocolMessage::ACTION.Close)

        unsubscribe_from_transport_events transport

        protocol_message.callback do
          destroy_transport
        end
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

      # When a connection is disconnected try and reconnect or set the connection state to :failed
      #
      # @api private
      def respond_to_transport_disconnected(current_transition)
        error_code = current_transition && current_transition.metadata.code

        if connection.previous_state == :connecting && error_code == CONNECTION_FAILED[:code]
          return if retry_connection_failed
        end

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

      def retry_connection_failed
        if retries_for_state(:disconnected, ignore_states: [:connecting]).count < CONNECTION_FAILED[:max_retries]
          logger.debug "ConnectionManager: Pausing for #{CONNECTION_FAILED[:retry_after]}s before attempting to reconnect"
          @timers[:connection_retry_timers] << EventMachine::Timer.new(CONNECTION_FAILED[:retry_after]) do
            connection.connect
          end
        end
      end

      def retries_for_state(state, ignore_states:)
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
          connection.transition_state_machine :disconnected
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
