module Ably
  module Rest
    # The Ably Realtime service organises the traffic within any application into named channels.
    # Channels are the "unit" of message distribution; clients attach to channels to subscribe to messages, and every message broadcast by the service is associated with a unique channel.
    class Channel
      include Ably::Modules::Conversions

      attr_reader :client, :name, :options

      # Initialize a new Channel object
      #
      # @param client [Ably::Rest::Client]
      # @param name [String] The name of the channel
      # @param channel_options [Hash] Channel options, currently reserved for future Encryption options
      def initialize(client, name, channel_options = {})
        @client  = client
        @name    = name
        @options = channel_options.clone.freeze
      end

      # Publish a message to the channel
      #
      # @param name [String] The event name of the message to publish
      # @param data [String] The message payload
      # @return [Boolean] true if the message was published, otherwise false
      def publish(name, data)
        payload = {
          name: name,
          data: data
        }

        response = client.post("#{base_path}/publish", payload)

        [201, 204].include?(response.status)
      end

      # Return the message history of the channel
      #
      # @param [Hash] options the options for the message history request
      # @option options [Integer,Time] :start      Time or millisecond since epoch
      # @option options [Integer,Time] :end        Time or millisecond since epoch
      # @option options [Symbol]       :direction  `:forwards` or `:backwards`
      # @option options [Integer]      :limit      Maximum number of messages to retrieve up to 10,000
      # @option options [Symbol]       :by         `:message`, `:bundle` or `:hour`. Defaults to `:message`
      #
      # @return [Ably::Models::PaginatedResource<Ably::Models::Message>] An Array of hashes representing the message history that supports paging (next, first)
      def history(options = {})
        url = "#{base_path}/messages"

        merge_options = { live: true }  # TODO: Remove live param as all history should be live
        [:start, :end].each { |option| merge_options[option] = as_since_epoch(options[option]) if options.has_key?(option) }

        response = client.get(url, options.merge(merge_options))

        Ably::Models::PaginatedResource.new(response, url, client, coerce_into: 'Ably::Models::Message')
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
