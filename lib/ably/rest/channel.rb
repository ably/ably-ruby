module Ably
  module Rest
    # The Ably Realtime service organises the traffic within any application into named channels.
    # Channels are the "unit" of message distribution; clients attach to channels to subscribe to messages, and every message broadcast by the service is associated with a unique channel.
    #
    # @!attribute [r] name
    #   @return {String} channel name
    # @!attribute [r] options
    #   @return {Hash} channel options configured for this channel, see {#initialize} for channel_options
    class Channel
      include Ably::Modules::Conversions

      # Ably client associated with this channel
      # @return [Ably::Realtime::Client]
      # @api private
      attr_reader :client

      attr_reader :name, :options

      # Push channel used for push notification (client-side)
      # @return [Ably::Rest::Channel::PushChannel]
      # @api private
      attr_reader :push

      IDEMPOTENT_LIBRARY_GENERATED_ID_LENGTH = 9 # See spec RSL1k1

      # Initialize a new Channel object
      #
      # @param client [Ably::Rest::Client]
      # @param name [String] The name of the channel
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      # @option channel_options [Hash,Ably::Models::CipherParams]   :cipher   A hash of options or a {Ably::Models::CipherParams} to configure the encryption. *:key* is required, all other options are optional.  See {Ably::Util::Crypto#initialize} for a list of +:cipher+ options
      #
      def initialize(client, name, channel_options = {})
        name = (ensure_utf_8 :name, name)

        update_options channel_options
        @client  = client
        @name    = name
        @push    = PushChannel.new(self)
      end

      # Publish one or more messages to the channel. Three overloaded forms
      # @param name [String, Array<Ably::Models::Message|Hash>, Ably::Models::Message, nil]   The event name of the message to publish, or an Array of [Ably::Model::Message] objects or [Hash] objects with +:name+ and +:data+ pairs, or a single Ably::Model::Message object
      # @param data [String, ByteArray, Hash, nil]   The message payload unless an Array of [Ably::Model::Message] objects passed in the first argument, in which case an optional hash of query parameters
      # @param attributes [Hash, nil]   Optional additional message attributes such as :extras, :id, :client_id or :connection_id, applied when name attribute is nil or a string (Deprecated, will be removed in 2.0 in favour of constructing a Message object)
      # @return [Boolean]  true if the message was published, otherwise false
      #
      # @example
      #   # Publish a single message with (name, data) form
      #   channel.publish 'click', { x: 1, y: 2 }
      #
      #   # Publish an array of message Hashes
      #   messages = [
      #     { name: 'click', { x: 1, y: 2 } },
      #     { name: 'click', { x: 2, y: 3 } }
      #   ]
      #   channel.publish messages
      #
      #   # Publish an array of Ably::Models::Message objects
      #   messages = [
      #     Ably::Models::Message(name: 'click', { x: 1, y: 2 })
      #     Ably::Models::Message(name: 'click', { x: 2, y: 3 })
      #   ]
      #   channel.publish messages
      #
      #   # Publish a single Ably::Models::Message object, with a query params
      #   # specifying quickAck: true
      #   message = Ably::Models::Message(name: 'click', { x: 1, y: 2 })
      #   channel.publish message, quickAck: 'true'
      #
      def publish(first, second = nil, third = {})
        messages, qs_params = if first.kind_of?(Enumerable)
          # ([Message], qs_params) form
          [first, second]
        elsif first.kind_of?(Ably::Models::Message)
          # (Message, qs_params) form
          [[first], second]
        else
          # (name, data, attributes) form
          first = ensure_utf_8(:name, first, allow_nil: true)
          ensure_supported_payload second
          # RSL1h - attributes as an extra method parameter is extra-spec but need to
          # keep it for backcompat until version 2
          [[{ name: first, data: second }.merge(third)], nil]
        end

        payload = messages.each_with_index.map do |message, index|
          Ably::Models::Message(message.dup).tap do |msg|
            msg.encode client.encoders, options

            next if msg.client_id.nil?
            if msg.client_id == '*'
              raise Ably::Exceptions::IncompatibleClientId.new('Wildcard client_id is reserved and cannot be used when publishing messages')
            end
            unless client.auth.can_assume_client_id?(msg.client_id)
              raise Ably::Exceptions::IncompatibleClientId.new("Cannot publish with client_id '#{msg.client_id}' as it is incompatible with the current configured client_id '#{client.client_id}'")
            end
          end.as_json
        end.tap do |payload|
          if client.idempotent_rest_publishing
            # We cannot mutate for idempotent publishing if one or more messages already has an ID
            if payload.all? { |msg| !msg['id'] }
              # Mutate the JSON to support idempotent publishing where a Message.id does not exist
              idempotent_publish_id = SecureRandom.base64(IDEMPOTENT_LIBRARY_GENERATED_ID_LENGTH)
              payload.each_with_index do |msg, idx|
                msg['id'] = "#{idempotent_publish_id}:#{idx}"
              end
            end
          end
        end

        options = qs_params ? { qs_params: qs_params } : {}
        response = client.post("#{base_path}/publish", payload.length == 1 ? payload.first : payload, options)

        [201, 204].include?(response.status)
      end

      # Return the message   of the channel
      #
      # @param [Hash] options   the options for the message history request
      # @option options [Integer,Time] :start      Ensure earliest time or millisecond since epoch for any messages retrieved is +:start+
      # @option options [Integer,Time] :end        Ensure latest time or millisecond since epoch for any messages retrieved is +:end+
      # @option options [Symbol]       :direction  +:forwards+ or +:backwards+, defaults to +:backwards+
      # @option options [Integer]      :limit      Maximum number of messages to retrieve up to 1,000, defaults to 100
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::Message>] First {Ably::Models::PaginatedResult page} of {Ably::Models::Message} objects accessible with {Ably::Models::PaginatedResult#items #items}.
      #
      def history(options = {})
        url = "#{base_path}/messages"
        options = {
          :direction => :backwards,
          :limit     => 100
        }.merge(options)

        [:start, :end].each { |option| options[option] = as_since_epoch(options[option]) if options.has_key?(option) }
        raise ArgumentError, ":end must be equal to or after :start" if options[:start] && options[:end] && (options[:start] > options[:end])

        paginated_options = {
          coerce_into: 'Ably::Models::Message',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        response = client.get(url, options)

        Ably::Models::PaginatedResult.new(response, url, client, paginated_options) do |message|
          message.tap do |msg|
            decode_message msg
          end
        end
      end

      # Return the {Ably::Rest::Presence} object
      #
      # @return [Ably::Rest::Presence]
      def presence
        @presence ||= Presence.new(client, self)
      end

      # @api private
      def update_options(channel_options)
        @options = channel_options.clone.freeze
      end

      private
      def base_path
        "/channels/#{URI.encode_www_form_component(name)}"
      end

      def decode_message(message)
        message.decode client.encoders, options
      rescue Ably::Exceptions::CipherError, Ably::Exceptions::EncoderError => e
        client.logger.error { "Decoding Error on channel '#{name}', message event name '#{message.name}'. #{e.class.name}: #{e.message}" }
      end
    end
  end
end

require 'ably/rest/channel/push_channel'
