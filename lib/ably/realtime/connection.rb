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
    # @!attribute [r] __outgoing_message_queue__
    #   @return [Array] An internal queue used to manage unsent outgoing messages.  You should never interface with this array directly.
    # @!attribute [r] __pending_message_queue__
    #   @return [Array] An internal queue used to manage sent messages.  You should never interface with this array directly.
    #
    class Connection < EventMachine::Connection
      include Ably::Modules::Conversions
      include Ably::Modules::EventEmitter
      extend Ably::Modules::Enum

      STATE = ruby_enum('STATE',
        :initializing,
        :initialized,
        :connecting,
        :connected,
        :disconnected,
        :suspended,
        :closed,
        :failed
      )
      include Ably::Modules::State

      attr_reader :__outgoing_message_queue__, :__pending_message_queue__

      def initialize(client)
        @client                     = client
        @message_serial             = 0
        @__outgoing_message_queue__ = []
        @__pending_message_queue__  = []
        @state                      = STATE.Initializing
      end

      # Required for test /unit/realtime/connection_spec.rb
      alias_method :orig_send, :send

      # Add protocol message to the outgoing message queue and notify the dispatcher that a message is
      # ready to be sent
      def send_protocol_message(protocol_message)
        add_message_serial_if_ack_required_to(protocol_message) do
          protocol_message = Models::ProtocolMessage.new(protocol_message)
          __outgoing_message_queue__ << protocol_message
          logger.debug("Prot msg queued =>: #{protocol_message.action} #{protocol_message}")
          __outgoing_protocol_msgbus__.publish :message, protocol_message
        end
      end

      # EventMachine::Connection interface
      def post_init
        change_state STATE.Initialized

        setup_driver
      end

      def connection_completed
        change_state STATE.Connecting

        start_tls if client.use_tls?
        driver.start
      end

      def receive_data(data)
        driver.parse(data)
      end

      def unbind
        change_state STATE.Disconnected
      end

      # WebSocket::Driver interface
      def url
        URI(client.endpoint).tap do |endpoint|
          endpoint.query = URI.encode_www_form(client.auth.auth_params.merge(timestamp: as_since_epoch(Time.now), binary: false))
        end.to_s
      end

      def write(data)
        send_data(data)
      end

      def send_text(text)
        driver.text(text)
      end

      # Client library internal outgoing message bus
      def __outgoing_protocol_msgbus__
        @__outgoing_protocol_msgbus__ ||= pub_sub_message_bus
      end

      # Client library internal incoming message bus
      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= pub_sub_message_bus
      end

      private
      attr_reader :client, :driver, :message_serial

      def pub_sub_message_bus
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
        @message_serial += 1
        protocol_message[:msgSerial] = @message_serial
        yield
      rescue StandardError => e
        @message_serial -= 1
        raise e
      end

      def setup_driver
        @driver = WebSocket::Driver.client(self)

        driver.on("open") do
          logger.debug("WebSocket connection opened to #{url}")
          change_state STATE.Connected
        end

        driver.on("message") do |event|
          begin
            message = Models::ProtocolMessage.new(JSON.parse(event.data).freeze)
            logger.debug("Prot msg recv <=: #{message.action} #{event.data}")
            __incoming_protocol_msgbus__.publish :message, message
          rescue KeyError
            client.logger.error("Unsupported Protocol Message received, unrecognised 'action': #{event.data}\nNo action taken")
          end
        end
      end

      # Used by {Ably::Modules::State} to debug state changes
      def logger
        client.logger
      end
    end
  end
end
