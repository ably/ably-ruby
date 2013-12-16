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
      # @param message [Hash] The message to publish (must contain :name and :data keys)
      # @return [Boolean] true if the message was published, otherwise false
      def publish(event, message)
        payload = {
          name: event,
          data: message
        }

        response = client.post("/channels/#{name}/publish", payload)

        response.status == 201
      end

      # Return the history of the channel
      #
      # @return [Array] An Array of hashes representing the history
      def history
        response = client.get("/channels/#{name}/history")

        response.body
      end
    end
  end
end
