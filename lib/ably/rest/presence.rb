module Ably
  module Rest
    class Presence
      include Ably::Modules::Conversions

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
      # @return [Models::PaginatedResource<Models::PresenceMessage>] An Array of presence-message Hash objects that supports paging (next, first)
      #
      def get(options = {})
        response = client.get(base_path, options)
        Models::PaginatedResource.new(response, base_path, client, coerce_into: 'Ably::Rest::Models::PresenceMessage')
      end

      # Return the presence messages history for the channel
      #
      # @param [Hash] options the options for the message history request
      # @option options [Integer,Time] :start      Time or millisecond since epoch
      # @option options [Integer,Time] :end        Time or millisecond since epoch
      # @option options [Symbol]       :direction  `:forwards` or `:backwards`
      # @option options [Integer]      :limit      Maximum number of presence messages to retrieve up to 10,000
      #
      # @return [Models::PaginatedResource<Models::PresenceMessage>] An Array of presence-message Hash objects that supports paging (next, first)
      #
      def history(options = {})
        url = "#{base_path}/history"

        merge_options = { live: true }  # TODO: Remove live param as all history should be live
        [:start, :end].each { |option| merge_options[option] = as_since_epoch(options[option]) if options.has_key?(option) }

        response = client.get(url, options.merge(merge_options))

        Models::PaginatedResource.new(response, url, client, coerce_into: 'Ably::Rest::Models::PresenceMessage')
      end

      private
      def base_path
        "/channels/#{CGI.escape(channel.name)}/presence"
      end
    end
  end
end
