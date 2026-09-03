module Ably
  module Rest
    # Enables the retrieval of the current and historic presence set for a channel.
    #
    class Presence
      include Ably::Modules::Conversions

      # {Ably::Rest::Client} for this Presence object
      #
      # @return {Ably::Rest::Client}
      #
      # @private
      attr_reader :client

      # {Ably::Rest::Channel} this Presence object is associated with
      #
      # @return [Ably::Rest::Channel]
      #
      attr_reader :channel

      # Initialize a new Presence object
      #
      # @param client [Ably::Rest::Client]
      # @param channel [Channel] The channel object
      #
      def initialize(client, channel)
        @client  = client
        @channel = channel
      end

      # Retrieves the current members present on the channel and the metadata for each member, such as their
      # {Ably::Models::PresenceMessage::ACTION} and ID. Returns a {Ably::Models::PaginatedResult} object,
      # containing an array of {Ably::Models::PresenceMessage} objects.
      #
      # @spec RSPa, RSP3a, RSP3a2, RSP3a3
      #
      # @param [Hash] options the options for the set of members present
      # @option options [Integer]   :limit           An upper limit on the number of messages returned. The default is 100, and the maximum is 1000. (RSP3a)
      # @option options [String]    :client_id       Filters the list of returned presence members by a specific client using its ID. (RSP3a2)
      # @option options [String]    :connection_id   Filters the list of returned presence members by a specific connection using its ID. (RSP3a3)
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::PresenceMessage>] A {Ably::Models::PaginatedResult} object containing an array of {Ably::Models::PresenceMessage} objects.
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

      # Retrieves a {Ably::Models::PaginatedResult} object, containing an array of historical {Ably::Models::PresenceMessage}
      # objects for the channel. If the channel is configured to persist messages, then presence messages can be retrieved
      # from history for up to 72 hours in the past. If not, presence messages can only be retrieved from history for up to two minutes in the past.
      #
      # @spec RSP4a
      #
      # @param [Hash] options the options for the message history request
      # @option options [Integer,Time] :start      The time from which messages are retrieved, specified as milliseconds since the Unix epoch. (RSP4b1)
      # @option options [Integer,Time] :end        The time until messages are retrieved, specified as milliseconds since the Unix epoch. (RSP4b1)
      # @option options [Symbol]       :direction  The order for which messages are returned in. Valid values are backwards which orders messages from most recent to oldest, or forwards which orders messages from oldest to most recent. The default is backwards. (RSP4b2)
      # @option options [Integer]      :limit      An upper limit on the number of messages returned. The default is 100, and the maximum is 1000. (RSP4b3)
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::PresenceMessage>] A {Ably::Models::PaginatedResult} object containing an array of {Ably::Models::PresenceMessage} objects.
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
