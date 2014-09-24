module Ably
  module Rest
    class Presence
      attr_reader :client, :channel

      # Initialize a new Presence object
      #
      # @param client [Ably::Rest::Client]
      # @param channel [Channel] The channel object
      def initialize(client, channel)
        @client  = client
        @channel = channel
      end

      # Obtain the set of members currently present for a channel
      #
      # @return [Models::PagedResource] An Array of presence-message Hash objects that supports paging (next, first)
      def get(options = {})
        response = client.get(base_path, options)
        Models::PagedResource.new(response, base_path, client)
      end

      # Return the presence messages history for the channel
      #
      # Options:
      #   - start:      Time or millisecond since epoch
      #   - end:        Time or millisecond since epoch
      #   - direction:  :forwards or :backwards (default is :backwards)
      #   - limit:      Maximum number of messages to retrieve up to 10,000
      #
      # @return [Models::PagedResource] An Array of presence-message Hash objects that supports paging (next, first)
      def history(options = {})
        url = "#{base_path}/history"
        response = client.get(url, options)
        Models::PagedResource.new(response, url, client)
      end

      private
      def base_path
        "/channels/#{CGI.escape(channel.name)}/presence"
      end
    end
  end
end
