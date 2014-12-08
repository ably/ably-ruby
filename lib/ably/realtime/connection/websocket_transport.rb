module Ably::Realtime
  class Connection
    # EventMachine WebSocket transport
    # @api private
    class WebsocketTransport < EventMachine::Connection
      include Ably::Modules::EventEmitter
      include Ably::Modules::Conversions
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

      def initialize(connection)
        @connection = connection
        @state      = STATE.Initialized

        setup_event_handlers
      end

      # Disconnect the socket transport connection and write all pending text.
      # If Disconnected state is not automatically triggered, it will be triggered automatically
      # @return [void]
      # @api public
      def disconnect
        close_connection_after_writing
        change_state STATE.Disconnecting
        create_timer(2) do
          # if connection is not disconnected within 2s, set state as disconnected
          change_state STATE.Disconnected
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
        change_state STATE.Disconnected
      end

      # URL end point including initialization configuration
      # {http://www.rubydoc.info/gems/websocket-driver/0.3.5/WebSocket/Driver WebSocket::Driver} interface
      def url
        URI(client.endpoint).tap do |endpoint|
          endpoint.query = URI.encode_www_form(client.auth.auth_params.merge(
            timestamp: as_since_epoch(Time.now),
            format:    client.protocol,
            echo:      client.echo_messages
          ))
        end.to_s
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
      attr_reader :connection, :driver

      # Send object down the WebSocket driver connection as a serialized string/byte array based on protocol
      # @param [Object] object to serialize and send to the WebSocket driver
      # @api public
      def send_object(object)
        case client.protocol
        when :json
          driver.text(object.to_json)
        when :msgpack
          driver.binary(object.to_msgpack.unpack('C*'))
        else
          client.logger.fatal "WebsocketTransport: Unsupported protocol '#{client.protocol}' for serialization, object cannot be serialized and sent to Ably over this WebSocket"
        end
      end

      def setup_event_handlers
        __outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
          send_object protocol_message
          client.logger.debug "WebsocketTransport: Prot msg sent =>: #{protocol_message.action} #{protocol_message}"
        end
      end

      def clear_timer
        if @timer
          @timer.cancel
          @timer = nil
        end
      end

      def create_timer(period, &block)
        @timer = EventMachine::Timer.new(period) do
          block.call
        end
      end

      def setup_driver
        @driver = WebSocket::Driver.client(self)

        driver.on("open") do
          logger.debug "WebsocketTransport: socket opened to #{url}, waiting for Connected protocol message"
        end

        driver.on("message") do |event|
          event_data = parse_event_data(event.data).freeze
          protocol_message = Ably::Models::ProtocolMessage.new(event_data)
          logger.debug "WebsocketTransport: Prot msg recv <=: #{protocol_message.action} #{event_data}"

          if protocol_message.invalid?
            logger.fatal "WebsocketTransport: Invalid Protocol Message received: #{event_data}\nNo action taken"
          else
            __incoming_protocol_msgbus__.publish :protocol_message, protocol_message
          end
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
          client.logger.fatal "WebsocketTransport: Unsupported Protocol Message format #{client.protocol}"
          data
        end
      end

      def create_pub_sub_message_bus
        Ably::Util::PubSub.new(
          coerce_into: Proc.new do |event|
            raise KeyError, "Expected :protocol_message, :#{event} is disallowed" unless event == :protocol_message
            :protocol_message
          end
        )
      end
    end
  end
end
