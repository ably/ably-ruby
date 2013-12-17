module Ably
  module Realtime
    class Connection < EventMachine::Connection
      def initialize(client)
        @client = client
      end

      # Ably::Realtime interface
      def send(data)
        @driver.text(data)
      end

      # EventMachine::Connection interface
      def post_init
        @state = :initialised

        setup_driver
      end

      def connection_completed
        @state = :connecting

        start_tls if @client.use_ssl?
        @driver.start
      end

      def receive_data(data)
        @driver.parse(data)
      end

      def unbind
        @state = :disconnected
      end

      # WebSocket::Driver interface
      def url
        @client.endpoint.to_s
      end

      def write(data)
        send_data(data)
      end

      private
      def setup_driver
        @driver = WebSocket::Driver.client(self)

        @driver.on("open")  { @state = :connected }
        @driver.on("close") { @state = :disconnected }

        @driver.on("message") do |event|
          message = JSON.parse(event.data, symbolize_names: true)
          action  = ACTIONS.detect { |k,v| v == message[:action] }.first

          @client.trigger action, message
        end
      end
    end
  end
end
