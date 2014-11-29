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
    #   @return {Ably::Models::ErrorInfo} error information associated with a connection failure
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
      # The connection manager responsible for creating, maintaining and closing the connection and underlying transport
      # @return {Ably::Realtime::Connection::ConnectionManager}
      attr_reader :manager

      # @api private
      # An internal queue used to manage unsent outgoing messages.  You should never interface with this array directly
      # @return [Array]
      attr_reader :__outgoing_message_queue__

      # @api private
      # An internal queue used to manage sent messages.  You should never interface with this array directly
      # @return [Array]
      attr_reader :__pending_message_queue__

      # @api public
      def initialize(client)
        @client                     = client

        @serial                     = -1
        @__outgoing_message_queue__ = []
        @__pending_message_queue__  = []

        Client::IncomingMessageDispatcher.new client, self
        Client::OutgoingMessageDispatcher.new client, self

        EventMachine.next_tick do
          trigger STATE.Initialized
        end

        @state_machine              = ConnectionStateMachine.new(self)
        @manager                    = ConnectionManager.new(self)
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
            transition_state_machine(:closed)
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
          transition_state_machine(:connecting) unless connecting?
          once(STATE.Connected) { block.call self } if block_given?
        end
      end

      # Reconfigure the current connection ID
      # @return <void>
      # @api private
      def update_connection_id(connection_id)
        @id = connection_id
      end

      # Call #transition_to on {Ably::Realtime::Connection::ConnectionStateMachine}
      #
      # @return [Boolean] true if new_state can be transitioned to by state machine
      # @api private
      def transition_state_machine(new_state, emit_object = nil)
        state_machine.transition_to(new_state, emit_object)
      end

      # Call #transition_to! on {Ably::Realtime::Connection::ConnectionStateMachine}.
      # An exception wil be raised if new_state cannot be transitioned to by state machine
      #
      # @return <void>
      # @api private
      def transition_state_machine!(new_state, emit_object = nil)
        state_machine.transition_to!(new_state, emit_object)
      end

      # Provides an internal method for the {Ably::Realtime::Connection} state to match the {Ably::Realtime::Connection::ConnectionStateMachine}'s state
      # @api private
      def synchronize_state_with_statemachine(*args)
        log_state_machine_state_change
        change_state state_machine.current_state, state_machine.last_transition.metadata
      end

      # @!attribute [r] __outgoing_protocol_msgbus__
      # @return [Ably::Util::PubSub] Client library internal outgoing protocol message bus
      # @api private
      def __outgoing_protocol_msgbus__
        @__outgoing_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # @!attribute [r] __incoming_protocol_msgbus__
      # @return [Ably::Util::PubSub] Client library internal incoming protocol message bus
      # @api private
      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # @!attribute [r] host
      # @return [String] The default host name used for this connection
      def host
        client.endpoint.host
      end

      # @!attribute [r] port
      # @return [Integer] The default port used for this connection
      def port
        client.use_tls? ? 443 : 80
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
      # @param [Ably::Models::ProtocolMessage] protocol_message
      # @return <void>
      # @api private
      def send_protocol_message(protocol_message)
        add_message_serial_if_ack_required_to(protocol_message) do
          Ably::Models::ProtocolMessage.new(protocol_message).tap do |protocol_message|
            add_message_to_outgoing_queue protocol_message
            notify_message_dispatcher_of_new_message protocol_message
            logger.debug("Connection: Prot msg queued =>: #{protocol_message.action} #{protocol_message}")
          end
        end
      end

      # @api private
      def add_message_to_outgoing_queue(protocol_message)
        __outgoing_message_queue__ << protocol_message
      end

      # @api private
      def notify_message_dispatcher_of_new_message(protocol_message)
        __outgoing_protocol_msgbus__.publish :protocol_message, protocol_message
      end

      # @!attribute [r] previous_state
      # @return [Ably::Realtime::Connection::STATE,nil] The previous state for this connection
      # @api private
      def previous_state
        if state_machine.previous_state
          STATE(state_machine.previous_state)
        end
      end

      # @!attribute [r] state_history
      # @return [Array<Hash>] All previous states including the current state in date ascending order with Hash properties :state, :metadata, :transitioned_at
      # @api private
      def state_history
        state_machine.history.map do |transition|
          {
            state:           STATE(transition.to_state),
            metadata:        transition.metadata,
            transitioned_at: transition.created_at
          }
        end
      end

      # @api private
      def create_websocket_transport(&block)
        @transport = EventMachine.connect(host, port, WebsocketTransport, self) do |websocket_transport|
          yield websocket_transport if block_given?
        end
      end

      # @api private
      def release_websocket_transport
        @transport = nil
      end

      # As we are using a state machine, do not allow change_state to be used
      # #transition_state_machine must be used instead
      private :change_state

      private
      attr_reader :serial, :state_machine

      def create_pub_sub_message_bus
        Ably::Util::PubSub.new(
          coerce_into: Proc.new do |event|
            raise KeyError, "Expected :protocol_message, :#{event} is disallowed" unless event == :protocol_message
            :protocol_message
          end
        )
      end

      def add_message_serial_if_ack_required_to(protocol_message)
        if Ably::Models::ProtocolMessage.ack_required?(protocol_message[:action])
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

      def log_state_machine_state_change
        if state_machine.previous_state
          logger.debug "ConnectionStateMachine: Transitioned from #{state_machine.previous_state} => #{state_machine.current_state}"
        else
          logger.debug "ConnectionStateMachine: Transitioned to #{state_machine.current_state}"
        end
      end
    end
  end
end
