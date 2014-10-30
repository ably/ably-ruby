module Ably
  module Realtime
    # The Connection class represents the connection associated with an Ably Realtime instance.
    # The Connection object exposes the lifecycle and parameters of the realtime connection.
    #
    # Connections will always be in one of the following states:
    #
    #   initialized:  0
    #   connecting:   1
    #   connected:    2
    #   disconnected: 3
    #   suspended:    4
    #   closed:       5
    #   failed:       6
    #
    # Note that the states are available as Enum-like constants:
    #
    #   Connection::STATE.Initialized
    #   Connection::STATE.Connecting
    #   Connection::STATE.Connected
    #   Connection::STATE.Disconnected
    #   Connection::STATE.Suspended
    #   Connection::STATE.Closed
    #   Connection::STATE.Failed
    #
    # @!attribute [r] state
    #   @return {Ably::Realtime::Connection::STATE} connection state
    # @!attribute [r] id
    #   @return {String} the assigned connection ID
    # @!attribute [r] error_reason
    #   @return {Ably::Realtime::Models::ErrorInfo} error information associated with a connection failure
    class Connection
      include Ably::Modules::EventEmitter
      extend Ably::Modules::Enum

      # Valid Connection states
      STATE = ruby_enum('STATE',
        :initialized,
        :connecting,
        :connected,
        :disconnected,
        :suspended,
        :closed,
        :failed
      )
      include Ably::Modules::StateEmitter

      attr_reader :id, :error_reason, :client

      # @api private
      # Underlying socket transport used for this connection, for internal use by the client library
      # @return {Ably::Realtime::Connection::WebsocketTransport}
      attr_reader :transport

      # @api private
      # An internal queue used to manage unsent outgoing messages.  You should never interface with this array directly
      # @return [Array]
      attr_reader :__outgoing_message_queue__

      # @api private
      # An internal queue used to manage sent messages.  You should never interface with this array directly
      # @return [Array]
      attr_reader :__pending_message_queue__

      # @api private
      # Timers used to manage connection state, for internal use by the client library
      # @return [Hash]
      attr_reader :timers

      # @api public
      def initialize(client)
        @client                     = client

        @serial                     = -1
        @__outgoing_message_queue__ = []
        @__pending_message_queue__  = []

        @timers                     = Hash.new { |hash, key| hash[key] = [] }
        @timers[:initializer]       << EventMachine::Timer.new(0.001) { connect }

        Client::IncomingMessageDispatcher.new client, self
        Client::OutgoingMessageDispatcher.new client, self

        EventMachine.next_tick do
          trigger STATE.Initialized
        end

        @state_machine              = ConnectionStateMachine.new(self)
        @state                      = STATE(state_machine.current_state)
      end

      # Causes the connection to close, entering the closed state, from any state except
      # the failed state. Once closed, the library will not attempt to re-establish the
      # connection without a call to {Connection#connect}.
      #
      # @yield [Ably::Realtime::Connection] block is called as soon as this connection is in the Closed state
      #
      # @return <void>
      def close(&block)
        if closed?
          block.call self
        else
          EventMachine.next_tick do
            state_machine.transition_to(:closed)
          end
          once(STATE.Closed) { block.call self } if block_given?
        end
      end

      # Causes the library to re-attempt connection, if it was previously explicitly
      # closed by the user, or was closed as a result of an unrecoverable error.
      #
      # @yield [Ably::Realtime::Connection] block is called as soon as this connection is in the Connected state
      #
      # @return <void>
      def connect(&block)
        if connected?
          block.call self
        else
          state_machine.transition_to(:connecting)
          once(STATE.Connected) { block.call self } if block_given?
        end
      end

      # Reconfigure the current connection ID
      # @return <void>
      # @api private
      def update_connection_id(connection_id)
        @id = connection_id
      end

      # Send #transition_to to connection state machine
      # @return [Boolean] true if new_state can be transitioned_to by state machine
      # @api private
      def transition_state_machine(new_state)
        state_machine.transition_to(new_state)
      end

      # @!attribute [r] __outgoing_protocol_msgbus__
      # @return [Ably::Util::PubSub] Client library internal outgoing message bus
      # @api private
      def __outgoing_protocol_msgbus__
        @__outgoing_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # @!attribute [r] __incoming_protocol_msgbus__
      # @return [Ably::Util::PubSub] Client library internal incoming message bus
      # @api private
      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # @!attribute [r] logger
      # @return [Logger] The Logger configured for this client when the client was instantiated.
      #                  Configure the log_level with the `:log_level` option, refer to {Ably::Realtime::Client#initialize}
      def logger
        client.logger
      end

      # Add protocol message to the outgoing message queue and notify the dispatcher that a message is
      # ready to be sent
      #
      # @param [Ably::Realtime::Models::ProtocolMessage] protocol_message
      # @return <void>
      # @api private
      def send_protocol_message(protocol_message)
        add_message_serial_if_ack_required_to(protocol_message) do
          protocol_message = Models::ProtocolMessage.new(protocol_message)
          __outgoing_message_queue__ << protocol_message
          logger.debug("Prot msg queued =>: #{protocol_message.action} #{protocol_message}")
          __outgoing_protocol_msgbus__.publish :message, protocol_message
        end
      end

      # Creates and sets up a new {WebSocketTransport} available on attribute #transport
      # @yield [Ably::Realtime::Connection::WebsocketTransport] block is called with new websocket transport
      # @api private
      def setup_transport(&block)
        if transport && !transport.ready_for_release?
          raise RuntimeError, "Existing WebsocketTransport is connected, and must be closed first"
        end

        @transport = EventMachine.connect(connection_host, connection_port, WebsocketTransport, self) do |websocket|
          yield websocket
        end
      end

      # Reconnect the {Ably::Realtime::Connection::WebsocketTransport} following a disconnection
      # @api private
      def reconnect_transport
        raise RuntimeError, "WebsocketTransport is not set up" if !transport
        raise RuntimeError, "WebsocketTransport is not disconnected so cannot be reconnected" if !transport.disconnected?

        transport.reconnect(connection_host, connection_port)
      end

      private
      attr_reader :manager, :serial, :state_machine

      def connection_host
        client.endpoint.host
      end

      def connection_port
        client.use_tls? ? 443 : 80
      end

      def create_pub_sub_message_bus
        Ably::Util::PubSub.new(
          coerce_into: Proc.new { |event| Models::ProtocolMessage::ACTION(event) }
        )
      end

      def add_message_serial_if_ack_required_to(protocol_message)
        if Models::ProtocolMessage.ack_required?(protocol_message[:action])
          add_message_serial_to(protocol_message) { yield }
        else
          yield
        end
      end

      def add_message_serial_to(protocol_message)
        @serial += 1
        protocol_message[:msgSerial] = serial
        yield
      rescue StandardError => e
        @serial -= 1
        raise e
      end
    end
  end
end
