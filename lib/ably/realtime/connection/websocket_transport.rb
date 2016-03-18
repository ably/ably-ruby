module Ably::Realtime
  class Connection
    # EventMachine WebSocket transport
    # @api private
    class WebsocketTransport
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

      # URL endpoint including initialization configuration
      # @return [String]
      attr_reader :url

      def initialize(connection, url)
        @connection = connection
        @state      = STATE.Initialized
        @url        = url

        change_state STATE.Connecting
        setup_driver
      end

      # Disconnect the socket transport connection and write all pending text.
      # If Disconnected state is not automatically emitted, it will be emitted automatically
      # @return [void]
      def close
        client.logger.debug "WebsocketTransport closed due to an explicit request"
        change_state STATE.Disconnecting unless disconnected?
        driver.close 3099, "WebsocketTransport closed due to an explicit request"
        create_timer(2) do
          # if connection is not disconnected within 2s, set state as disconnected
          change_state STATE.Disconnected unless disconnected?
        end
      end


      # True when socket connection is ready to be released
      # i.e. it is not currently connecting or connected
      # @return [Boolean]
      def ready_for_release?
        !connecting? && !connected?
      end

      # Websocket Transport internal incoming protocol message bus
      # @return [Ably::Util::PubSub]
      # @api private
      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # Websocket Transport internal outgoing protocol message bus
      # @return [Ably::Util::PubSub]
      # @api private
      def __outgoing_protocol_msgbus__
        @__outgoing_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      private

      attr_reader :driver, :connection

      # Send object down the WebSocket driver connection as a serialized string/byte array based on protocol
      # @param [Object] object to serialize and send to the WebSocket driver
      def send_object(object)
        case client.protocol
        when :json
          driver.send(object.to_json)
        when :msgpack
          driver.send(object.to_msgpack.unpack('C*'))
        else
          client.logger.fatal "WebsocketTransport: Unsupported protocol '#{client.protocol}' for serialization, object cannot be serialized and sent to Ably over this WebSocket"
        end
      end

      def setup_incoming_message_event_handlers
        __outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
          send_object protocol_message
          client.logger.debug "WebsocketTransport: Prot msg sent =>: #{protocol_message.action} #{protocol_message}"
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

      def options
        if client.proxy_url
          { proxy: { origin: client.proxy_url } }
        else
          {}
        end
      end

      def setup_driver
        @driver = Faye::WebSocket::Client.new(url, nil, options)

        driver.on(:open) do
          logger.debug "WebsocketTransport: Websocket opened to #{url}, waiting for Connected protocol message"
          change_state STATE.Connected
          setup_incoming_message_event_handlers
        end

        driver.on(:message) do |event|
          event_data = parse_event_data(event.data).freeze
          protocol_message = Ably::Models::ProtocolMessage.new(event_data, logger: logger)
          action_name = Ably::Models::ProtocolMessage::ACTION[event_data['action']] rescue event_data['action']
          logger.debug "WebsocketTransport: Prot msg recv <=: #{action_name} - #{event_data}"

          if protocol_message.invalid?
            error = Ably::Exceptions::ProtocolError.new("Invalid Protocol Message received: #{event_data}\nMessage has been discarded", 400, 80013)
            connection.emit :error, error
            logger.fatal "WebsocketTransport: #{error.message}"
          else
            __incoming_protocol_msgbus__.publish :protocol_message, protocol_message
          end
        end

        driver.on(:error) do |error|
          logger.error "WebsocketTransport: Transport protocol error - #{error.message}"
        end

        driver.on(:close) do |event|
          unless disconnecting? || connection.closing? || event.code == 3099 # explicit request to close
            reason_closed = "#{event.code}: #{event.reason}"
            logger.warn "WebsocketTransport: Driver reported transport as closed - #{reason_closed}"
          end
          change_state STATE.Disconnected, event
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
