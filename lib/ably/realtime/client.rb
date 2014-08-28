module Ably
  module Realtime
    # A client for the Ably Realtime API
    class Client
      include Callbacks

      DOMAIN = "staging-realtime.ably.io"

      def initialize(options)
        @ssl         = options[:ssl] || true
        @rest_client = Ably::Rest::Client.new(options)

        on(:attached) do |data|
          channel = channel(data[:channel])

          channel.trigger(:attached)
        end

        on(:message) do |data|
          channel = channel(data[:channel])

          data[:messages].each do |message|
            channel.trigger(:message, message)
          end
        end
      end

      def token
        @token ||= @rest_client.request_token
      end

      # Return a Realtime Channel for the given name
      #
      # @param name [String] The name of the channel
      # @return [Ably::Realtime::Channel]
      def channel(name)
        @channels ||= {}
        @channels[name] ||= Ably::Realtime::Channel.new(self, name)
      end

      def send_message(channel_name, message)
        payload = {
          action:   ACTIONS[:message],
          channel:  channel_name,
          messages: [message]
        }.to_json

        connection.send(payload)
      end

      def attach_to_channel(channel_name)
        payload = {
          action: ACTIONS[:attach],
          channel: channel_name
        }.to_json

        connection.send(payload)
      end

      def use_ssl?
        @ssl == true
      end

      def endpoint
        @endpoint ||= URI::Generic.build(
          scheme: use_ssl? ? "wss" : "ws",
          host:   DOMAIN,
          query:  "access_token=#{token.id}&binary=false&timestamp=#{Time.now.to_i}"
        )
      end

      def connection
        @connection ||= begin
          host = endpoint.host
          port = use_ssl? ? 443 : 80

          EventMachine.connect(host, port, Connection, self)
        end
      end
    end
  end
end

