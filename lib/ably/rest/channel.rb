module Ably
  module Rest
    class Channel
      attr_reader :client, :name

      # Initialize a new Channel object
      #
      # @param client [Ably::Rest::Client]
      # @param name [String] The name of the channel
      def initialize(client, name)
        @client = client
        @name   = name
      end

      # Publish a message to the channel
      #
      # @param message [Hash] The message to publish
      # @return [Boolean] true if the message was published, otherwise false
      def publish(message)
        response = client.post("/channels/#{name}/publish", message)

        response.status == 201
      end
    end
  end
end
