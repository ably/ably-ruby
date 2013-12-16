module Ably
  module Realtime
    # A client for the Ably Realtime API
    class Client
      include Callbacks

      def initialize(options)
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

      private
      def connection
        @connection ||= begin
          uri  = URI(Ably::Realtime.api_endpoint)
          host = uri.host
          # port = uri.scheme == "wss" ? 443 : 80
          port = 80

          EventMachine.connect(host, port, Connection, self)
        end
      end
    end
  end
end

