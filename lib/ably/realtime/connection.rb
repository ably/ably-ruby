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
    class Connection < EventMachine::Connection
      include Ably::Modules::Conversions
      include Ably::Modules::EventEmitter
      extend Ably::Modules::Enum

      STATE = ruby_enum('STATE',
        :initialized,
        :connecting,
        :connected,
        :disconnected,
        :suspended,
        :closed,
        :failed
      )

      configure_event_emitter coerce_into: Proc.new { |event| STATE(event) }

      def initialize(client)
        @client         = client
        @message_serial = 0
      end

      alias_method :orig_send, :send
      def send(protocol_message)
        add_message_serial_if_ack_required_to(protocol_message) do
          protocol_message = Models::ProtocolMessage.new(protocol_message)
          client.logger.debug("Prot msg sent =>: #{protocol_message.action} #{protocol_message}")
          driver.text(protocol_message.to_json)
        end
      end

      # EventMachine::Connection interface
      def post_init
        trigger STATE.Initialized

        setup_driver
      end

      def connection_completed
        trigger STATE.Connecting

        start_tls if client.use_tls?
        driver.start
      end

      def receive_data(data)
        driver.parse(data)
      end

      def unbind
        trigger STATE.Disconnected
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

      def __protocol_msgbus__
        @__protocol_msgbus__ ||= Ably::Util::PubSub.new(
          coerce_into: Proc.new { |event| Models::ProtocolMessage::ACTION(event) }
        )
      end

      private
      attr_reader :client, :driver, :message_serial

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
          client.logger.debug("WebSocket connection opened to #{url}")
          trigger STATE.Connected
        end

        driver.on("message") do |event|
          begin
            message = Models::ProtocolMessage.new(JSON.parse(event.data))
            client.logger.debug("Prot msg recv <=: #{message.action} #{event.data}")
            __protocol_msgbus__.publish :message, message
          rescue KeyError
            client.logger.error("Unsupported Protocol Message received, unrecognised 'action': #{event.data}\nNo action taken")
          end
        end
      end
    end
  end
end
