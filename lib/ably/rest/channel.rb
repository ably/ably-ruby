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

        response = client.post("#{base_path}/publish", payload)

        response.status == 201
      end

      # Return the message history of the channel
      #
      # Options:
      #   - start:      Time or millisecond since epoch
      #   - end:        Time or millisecond since epoch
      #   - direction:  :forwards or :backwards
      #   - limit:      Maximum number of messages to retrieve up to 10,000
      #   - by:         :message, :bundle or :hour. Defaults to :message
      #
      # @return [PagedResource] An Array of hashes representing the message history that supports paging (next, first)
      def history(options = {})
        url = "#{base_path}/messages"
        # TODO: Remove live param as all history should be live
        response = client.get(url, options.merge(live: true))

        PagedResource.new(response, url, client)
      end

      def presence
        @presence ||= Presence.new(client, self)
      end

      private
      def base_path
        "/channels/#{CGI.escape(name)}"
      end
    end
  end
end
