module Ably
  module Realtime
    class Connection < EventMachine::Connection
      include Ably::Modules::Conversions
      include Ably::Modules::Callbacks

      def initialize(client)
        @client         = client
        @message_serial = 0
      end

      def send(protocol_message)
        add_message_serial_if_ack_required_to(protocol_message) do
          protocol_message = Models::ProtocolMessage.new(protocol_message)
          client.log_http("Prot msg sent =>: #{protocol_message.action_sym} #{protocol_message.to_json}")
          driver.text(protocol_message.to_json)
        end
      end

      # EventMachine::Connection interface
      def post_init
        trigger :initalised

        setup_driver
      end

      def connection_completed
        trigger :connecting

        start_tls if client.use_tls?
        driver.start
      end

      def receive_data(data)
        driver.parse(data)
      end

      def unbind
        trigger :disconnected
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
          client.log_http("WebSocket connection opened to #{url}")
          trigger :connected
        end

        driver.on("message") do |event|
          message = Models::ProtocolMessage.new(JSON.parse(event.data))
          client.log_http("Prot msg recv <=: #{message.action_sym} #{message.to_json}")
          client.trigger message.action_sym, message
        end
      end
    end
  end
end
