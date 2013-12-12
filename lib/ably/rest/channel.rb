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
      def publish(message)
        validate_message(message)

        response = client.post("/channels/#{name}/publish", message)

        response.status == 201
      end

      private
      def validate_message(message)
        unless message.has_key?(:name) && message.has_key?(:data)
          raise ArgumentError, "message must be a Hash with :name and :data keys"
        end

        if message[:name].empty?
          raise ArgumentError, "message name must not be empty"
        end
      end
    end
  end
end
