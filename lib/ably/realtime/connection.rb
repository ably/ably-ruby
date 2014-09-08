module Ably
  module Realtime
    class Connection < EventMachine::Connection
      include Callbacks

      def initialize(client)
        @client = client
      end

      # Ably::Realtime interface
      def send(data)
        @driver.text(data)
      end

      # EventMachine::Connection interface
      def post_init
        trigger :initalised

        setup_driver
      end

      def connection_completed
        trigger :connecting

        start_tls if @client.use_tls?
        @driver.start
      end

      def receive_data(data)
        @driver.parse(data)
      end

      def unbind
        trigger :disconnected
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

        @driver.on("open")  { trigger :connected }

        @driver.on("message") do |event|
          message = JSON.parse(event.data, symbolize_names: true)
          action  = ACTIONS.detect { |k,v| v == message[:action] }.first

          @client.trigger action, message
        end
      end
    end
  end
end
