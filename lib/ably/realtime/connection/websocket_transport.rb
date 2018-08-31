module Ably::Realtime
  class Connection
    # EventMachine WebSocket transport
    # @api private
    class WebsocketTransport < EventMachine::Connection
      include Ably::Modules::EventEmitter
      extend Ably::Modules::Enum

      # Valid WebSocket connection states
      STATE = ruby_enum('STATE',
        :initialized,
        :connecting,
        :connected,
        :disconnecting,
        :disconnected
      )
      include Ably::Modules::StateEmitter

      def initialize(connection, url)
        @connection = connection
        @state      = STATE.Initialized
        @url        = url

        setup_event_handlers
      end

      # Disconnect the socket transport connection and write all pending text.
      # If Disconnected state is not automatically emitted, it will be emitted automatically
      # @return [void]
      # @api public
      def disconnect
        close_connection_after_writing
        change_state STATE.Disconnecting
        create_timer(2) do
          # if connection is not disconnected within 2s, set state as disconnected
          change_state STATE.Disconnected unless disconnected?
        end
      end

      # Network connection has been established
      # Required {http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Connection EventMachine::Connection} interface
      def post_init
        clear_timer
        change_state STATE.Connecting
        setup_driver
      end

      # Remote TCP connection attempt completes successfully
      # Required {http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Connection EventMachine::Connection} interface
      def connection_completed
        change_state STATE.Connected
        start_tls if client.use_tls?
        driver.start
      end

      # Called by the event loop whenever data has been received by the network connection.
      # Simply pass onto the WebSocket driver to process and determine content boundaries.
      # Required {http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Connection EventMachine::Connection} interface
      def receive_data(data)
        driver.parse(data)
      end

      # Called whenever a connection (either a server or client connection) is closed
      # Required {http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Connection EventMachine::Connection} interface
      def unbind
        change_state STATE.Disconnected, reason_closed || 'Websocket connection closed unexpectedly'
      end

      # URL end point including initialization configuration
      # {http://www.rubydoc.info/gems/websocket-driver/0.3.5/WebSocket/Driver WebSocket::Driver} interface
      def url
        @url
      end

      # {http://www.rubydoc.info/gems/websocket-driver/0.3.5/WebSocket/Driver WebSocket::Driver} interface
      def write(data)
        send_data(data)
      end

      # True if socket connection is ready to be released
      # i.e. it is not currently connecting or connected
      def ready_for_release?
        !connecting? && !connected?
      end

      # @!attribute [r] __incoming_protocol_msgbus__
      # @return [Ably::Util::PubSub] Websocket Transport internal incoming protocol message bus
      # @api private
      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # @!attribute [r] __outgoing_protocol_msgbus__
      # @return [Ably::Util::PubSub] Websocket Transport internal outgoing protocol message bus
      # @api private
      def __outgoing_protocol_msgbus__
        @__outgoing_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      private
      def driver
        @driver
      end

      def connection
        @connection
      end

      def reason_closed
        @reason_closed
      end

      # Send object down the WebSocket driver connection as a serialized string/byte array based on protocol
      # @param [Object] object to serialize and send to the WebSocket driver
      def send_object(object)
        case client.protocol
        when :json
          driver.text(object.to_json)
        when :msgpack
          driver.binary(object.to_msgpack.unpack('C*'))
        else
          client.logger.fatal { "WebsocketTransport: Unsupported protocol '#{client.protocol}' for serialization, object cannot be serialized and sent to Ably over this WebSocket" }
        end
      end

      def setup_event_handlers
        __outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
          send_object protocol_message
          client.logger.debug { "WebsocketTransport: Prot msg sent =>: #{protocol_message.action} #{protocol_message}" }
        end
      end

      def clear_timer
        if defined?(@timer) && @timer
          @timer.cancel
          @timer = nil
        end
      end

      def create_timer(period)
        @timer = EventMachine::Timer.new(period) do
          yield
        end
      end

      def setup_driver
        @driver = WebSocket::Driver.client(self)

        driver.on("open") do
          logger.debug { "WebsocketTransport: socket opened to #{url}, waiting for Connected protocol message" }
        end

        driver.on("message") do |event|
          event_data = parse_event_data(event.data).freeze
          protocol_message = Ably::Models::ProtocolMessage.new(event_data, logger: logger)
          action_name = Ably::Models::ProtocolMessage::ACTION[event_data['action']] rescue event_data['action']
          logger.debug { "WebsocketTransport: Prot msg recv <=: #{action_name} - #{event_data}" }

          if protocol_message.invalid?
            error = Ably::Exceptions::ProtocolError.new("Invalid Protocol Message received: #{event_data}\nConnection moving to the failed state as the protocol is invalid and unsupported", 400, Ably::Exceptions::Codes::PROTOCOL_ERROR)
            logger.fatal { "WebsocketTransport: #{error.message}" }
            failed_protocol_message = Ably::Models::ProtocolMessage.new(
              action: Ably::Models::ProtocolMessage::ACTION.Error,
              error: error.as_json,
              logger: logger
            )
            __incoming_protocol_msgbus__.publish :protocol_message, failed_protocol_message
          else
            __incoming_protocol_msgbus__.publish :protocol_message, protocol_message
          end
        end

        driver.on("ping") do
          __incoming_protocol_msgbus__.publish :protocol_message, Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Heartbeat, source: :websocket)
        end

        driver.on("error") do |error|
          logger.error { "WebsocketTransport: Protocol Error on transports - #{error.message}" }
        end

        @reason_closed = nil
        driver.on("closed") do |event|
          @reason_closed = "#{event.code}: #{event.reason}"
          logger.warn { "WebsocketTransport: Driver reported transport as closed - #{reason_closed}" }
        end
      end

      def client
        connection.client
      end

      # Used to log transport messages
      def logger
        connection.logger
      end

      def parse_event_data(data)
        case client.protocol
        when :json
          JSON.parse(data)
        when :msgpack
          MessagePack.unpack(data.pack('C*'))
        else
          client.logger.fatal { "WebsocketTransport: Unsupported Protocol Message format #{client.protocol}" }
          data
        end
      end

      def create_pub_sub_message_bus
        Ably::Util::PubSub.new(
          coerce_into: lambda do |event|
            raise KeyError, "Expected :protocol_message, :#{event} is disallowed" unless event == :protocol_message
            :protocol_message
          end
        )
      end
    end
  end
end
