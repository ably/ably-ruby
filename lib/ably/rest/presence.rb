module Ably
  module Rest
    class Presence
      include Ably::Modules::Conversions

      # {Ably::Rest::Client} for this Presence object
      # @return {Ably::Rest::Client}
      # @private
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
      # @option options [Integer]   :limit           Maximum number of members to retrieve up to 1,000, defaults to 100
      # @option options [String]    :client_id       optional client_id filter for the member
      # @option options [String]    :connection_id   optional connection_id filter for the member
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::PresenceMessage>] First {Ably::Models::PaginatedResult page} of {Ably::Models::PresenceMessage} objects accessible with {Ably::Models::PaginatedResult#items #items}.
      #
      def get(options = {})
        options = options = {
          :limit     => 100
        }.merge(options)

        paginated_options = {
          coerce_into: 'Ably::Models::PresenceMessage',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        response = client.get(base_path, options)

        Ably::Models::PaginatedResult.new(response, base_path, client, paginated_options) do |presence_message|
          presence_message.tap do |message|
            decode_message message
          end
        end
      end

      # Return the presence messages history for the channel
      #
      # @param [Hash] options the options for the message history request
      # @option options [Integer,Time] :start      Ensure earliest time or millisecond since epoch for any presence messages retrieved is +:start+
      # @option options [Integer,Time] :end        Ensure latest time or millisecond since epoch for any presence messages retrieved is +:end+
      # @option options [Symbol]       :direction  +:forwards+ or +:backwards+, defaults to +:backwards+
      # @option options [Integer]      :limit      Maximum number of messages to retrieve up to 1,000, defaults to 100
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::PresenceMessage>] First {Ably::Models::PaginatedResult page} of {Ably::Models::PresenceMessage} objects accessible with {Ably::Models::PaginatedResult#items #items}.
      #
      def history(options = {})
        url = "#{base_path}/history"
        options = options = {
          :direction => :backwards,
          :limit     => 100
        }.merge(options)

        [:start, :end].each { |option| options[option] = as_since_epoch(options[option]) if options.has_key?(option) }
        raise ArgumentError, ":end must be equal to or after :start" if options[:start] && options[:end] && (options[:start] > options[:end])

        paginated_options = {
          coerce_into: 'Ably::Models::PresenceMessage',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        response = client.get(url, options)

        Ably::Models::PaginatedResult.new(response, url, client, paginated_options) do |presence_message|
          presence_message.tap do |message|
            decode_message message
          end
        end
      end

      private
      def base_path
        "/channels/#{URI.encode_www_form_component(channel.name)}/presence"
      end

      def decode_message(presence_message)
        presence_message.decode client.encoders, channel.options
      rescue Ably::Exceptions::CipherError, Ably::Exceptions::EncoderError => e
        client.logger.error { "Decoding Error on presence channel '#{channel.name}', presence message client_id '#{presence_message.client_id}'. #{e.class.name}: #{e.message}" }
      end
    end
  end
end
