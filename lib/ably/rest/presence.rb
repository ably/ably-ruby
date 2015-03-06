module Ably
  module Rest
    class Presence
      include Ably::Modules::Conversions

      # {Ably::Rest::Client} for this Presence object
      # @return {Ably::Rest::Client}
      attr_reader :client

      # {Ably::Rest::Channel} this Presence object is associated with
      # @return {Ably::Rest::Channel}
      attr_reader :channel

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
      # @param [Hash] options the options for the set of members present
      # @option options [Integer,Time] :start      Time or millisecond since epoch
      # @option options [Integer,Time] :end        Time or millisecond since epoch
      # @option options [Symbol]       :direction  `:forwards` or `:backwards`
      # @option options [Integer]      :limit      Maximum number of members to retrieve up to 10,000
      #
      # @return [Ably::Models::PaginatedResource<Ably::Models::PresenceMessage>] An Array of {Ably::Models::PresenceMessage} objects that supports paging (#next_page, #first_page)
      #
      def get(options = {})
        options = options.dup

        paginated_options = {
          coerce_into: 'Ably::Models::PresenceMessage',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        response = client.get(base_path, options)

        Ably::Models::PaginatedResource.new(response, base_path, client, paginated_options) do |presence_message|
          presence_message.tap do |presence_message|
            decode_message presence_message
          end
        end
      end

      # Return the presence messages history for the channel
      #
      # @param [Hash] options the options for the message history request
      # @option options [Integer,Time] :start      Time or millisecond since epoch
      # @option options [Integer,Time] :end        Time or millisecond since epoch
      # @option options [Symbol]       :direction  `:forwards` or `:backwards`
      # @option options [Integer]      :limit      Maximum number of presence messages to retrieve up to 10,000
      #
      # @return [Ably::Models::PaginatedResource<Ably::Models::PresenceMessage>] An Array of {Ably::Models::PresenceMessage} objects that supports paging (#next_page, #first_page)
      #
      def history(options = {})
        url = "#{base_path}/history"
        options = options.dup

        [:start, :end].each { |option| options[option] = as_since_epoch(options[option]) if options.has_key?(option) }

        paginated_options = {
          coerce_into: 'Ably::Models::PresenceMessage',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        response = client.get(url, options)

        Ably::Models::PaginatedResource.new(response, url, client, paginated_options) do |presence_message|
          presence_message.tap do |presence_message|
            decode_message presence_message
          end
        end
      end

      private
      def base_path
        "/channels/#{CGI.escape(channel.name)}/presence"
      end

      def decode_message(presence_message)
        presence_message.decode channel
      rescue Ably::Exceptions::CipherError, Ably::Exceptions::EncoderError => e
        client.logger.error "Decoding Error on presence channel '#{channel.name}', presence message client_id '#{presence_message.client_id}'. #{e.class.name}: #{e.message}"
      end
    end
  end
end
