module Ably
  module Rest
    # Enables messages to be published and historic messages to be retrieved for a channel.
    #
    class Channel
      include Ably::Modules::Conversions

      # Ably client associated with this channel
      # @return [Ably::Realtime::Client]
      # @api private
      attr_reader :client

      # The channel name.
      # @return [String]
      attr_reader :name

      attr_reader :options

      # A {Ably::Rest::Channel::PushChannel} object
      # @spec RSH4
      # @return [Ably::Rest::Channel::PushChannel]
      # @api private
      attr_reader :push

      IDEMPOTENT_LIBRARY_GENERATED_ID_LENGTH = 9 # See spec RSL1k1

      # Initialize a new Channel object
      #
      # @param client [Ably::Rest::Client]
      # @param name [String] The name of the channel
      # @param channel_options [Hash, Ably::Models::ChannelOptions]     A hash of options or a {Ably::Models::ChannelOptions}
      #
      def initialize(client, name, channel_options = {})
        name = (ensure_utf_8 :name, name)

        @options = Ably::Models::ChannelOptions(channel_options)
        @client  = client
        @name    = name
        @push    = PushChannel.new(self)
      end

      # Publishes a message to the channel. A callback may optionally be passed in to this call to be notified of success or failure of the operation.
      #
      # @spec RSL1
      #
      # @param name [String, Array<Ably::Models::Message|Hash>, Ably::Models::Message, nil]   The event name of the message to publish, or an Array of [Ably::Model::Message] objects or [Hash] objects with +:name+ and +:data+ pairs, or a single Ably::Model::Message object
      # @param data [String, Array, Hash, nil]   The message payload unless an Array of [Ably::Model::Message] objects passed in the first argument, in which case an optional hash of query parameters
      # @param attributes [Hash, nil]   Optional additional message attributes such as :extras, :id, :client_id or :connection_id, applied when name attribute is nil or a string (Deprecated, will be removed in 2.0 in favour of constructing a Message object)
      # @return [Boolean]  true if the message was published, otherwise false
      #
      # @example
      #   # Publish a single message with (name, data) form
      #   channel.publish 'click', { x: 1, y: 2 }
      #
      #   # Publish a single message with single Hash form
      #   message = { name: 'click', data: { x: 1, y: 2 } }
      #   channel.publish message
      #
      #   # Publish an array of message Hashes form
      #   messages = [
      #     { name: 'click', data: { x: 1, y: 2 } },
      #     { name: 'click', data: { x: 2, y: 3 } }
      #   ]
      #   channel.publish messages
      #
      #   # Publish an array of Ably::Models::Message objects form
      #   messages = [
      #     Ably::Models::Message(name: 'click', data: { x: 1, y: 2 })
      #     Ably::Models::Message(name: 'click', data: { x: 2, y: 3 })
      #   ]
      #   channel.publish messages
      #
      #   # Publish a single Ably::Models::Message object form
      #   message = Ably::Models::Message(name: 'click', data: { x: 1, y: 2 })
      #   channel.publish message
      #
      def publish(name, data = nil, attributes = {})
        qs_params = nil
        qs_params = data if name.kind_of?(Enumerable) || name.kind_of?(Ably::Models::Message)

        messages = build_messages(name, data, attributes) # (RSL1a, RSL1b)

        if messages.sum(&:size) > (max_message_size = client.max_message_size || Ably::Rest::Client::MAX_MESSAGE_SIZE)
          raise Ably::Exceptions::MaxMessageSizeExceeded.new("Maximum message size exceeded #{max_message_size} bytes.")
        end

        payload = messages.map do |message|
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

      # Retrieves a {Ably::Models::PaginatedResult} object, containing an array of historical {Ably::Models::Message}
      # objects for the channel. If the channel is configured to persist messages, then messages can be retrieved from
      # history for up to 72 hours in the past. If not, messages can only be retrieved from history for up to two minutes in the past.
      #
      # @spec RSL2a
      #
      # @param [Hash] options   the options for the message history request
      # @option options [Integer,Time] :start      The time from which messages are retrieved, specified as milliseconds since the Unix epoch. RSL2b1
      # @option options [Integer,Time] :end        The time until messages are retrieved, specified as milliseconds since the Unix epoch. RSL2b1
      # @option options [Symbol]       :direction  The order for which messages are returned in. Valid values are backwards which orders messages from most recent to oldest, or forwards which orders messages from oldest to most recent. The default is backwards. RSL2b2
      # @option options [Integer]      :limit      An upper limit on the number of messages returned. The default is 100, and the maximum is 1000. RSL2b3
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::Message>] A {Ably::Models::PaginatedResult} object containing an array of {Ably::Models::Message} objects.
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

      # A {Ably::Rest::Presence} object.
      # @spec RSL3
      # @return [Ably::Rest::Presence]
      def presence
        @presence ||= Presence.new(client, self)
      end

      # Sets the {Ably::Models::ChannelOptions} for the channel.
      # @spec RSL7
      # @param channel_options [Hash, Ably::Models::ChannelOptions]  A hash of options or a {Ably::Models::ChannelOptions}
      # @return [Ably::Models::ChannelOptions]
      def set_options(channel_options)
        @options = Ably::Models::ChannelOptions(channel_options)
      end
      alias options= set_options

      # Retrieves a {Ably::Models::ChannelDetails} object for the channel, which includes status and occupancy metrics.
      # @spec RSL8
      # @return [Ably::Models::ChannelDetails] 	A {Ably::Models::ChannelDetails} object.
      def status
        Ably::Models::ChannelDetails.new(client.get(base_path).body)
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
