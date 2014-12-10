module Ably
  module Rest
    # The Ably Realtime service organises the traffic within any application into named channels.
    # Channels are the "unit" of message distribution; clients attach to channels to subscribe to messages, and every message broadcast by the service is associated with a unique channel.
    #
    # @!attribute [r] client
    #   @return {Ably::Realtime::Client} Ably client associated with this channel
    # @!attribute [r] name
    #   @return {String} channel name
    # @!attribute [r] options
    #   @return {Hash} channel options configured for this channel, see {#initialize} for channel_options
    class Channel
      include Ably::Modules::Conversions

      attr_reader :client, :name, :options

      # Initialize a new Channel object
      #
      # @param client [Ably::Rest::Client]
      # @param name [String] The name of the channel
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      # @option channel_options [Boolean]  :encrypted       setting this to true for this channel will encrypt & decrypt all messages automatically
      # @option channel_options [Hash]     :cipher_params   A hash of options to configure the encryption. *:key* is required, all other options are optional.  See {Ably::Util::Crypto#initialize} for a list of `cipher_params` options
      #
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

        message = Ably::Models::Message.new(payload, nil).tap do |message|
          message.encode self
        end

        response = client.post("#{base_path}/publish", message)

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
      # @return [Ably::Models::PaginatedResource<Ably::Models::Message>] An Array of {Ably::Models::Message} objects that supports paging (#next_page, #first_page)
      def history(options = {})
        url = "#{base_path}/messages"
        options = options.dup

        merge_options = { live: true }  # TODO: Remove live param as all history should be live
        [:start, :end].each { |option| merge_options[option] = as_since_epoch(options[option]) if options.has_key?(option) }

        paginated_options = {
          coerce_into: 'Ably::Models::Message',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        response = client.get(url, options.merge(merge_options))

        Ably::Models::PaginatedResource.new(response, url, client, paginated_options) do |message|
          message.tap do |message|
            message.decode self
          end
        end
      end

      # Return the {Ably::Rest::Presence} object
      #
      # @return [Ably::Rest::Presence]
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
