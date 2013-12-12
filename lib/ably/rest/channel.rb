module Ably
  module Rest
    class Channel
      attr_reader :client, :name

      def initialize(client, name)
        @client = client
        @name   = name
      end

      def publish(message)
        response = client.post("/channels/#{name}/publish", message)

        response.status == 201
      end
    end
  end
end
