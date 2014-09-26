module Ably::Realtime::Models
  # A class representing an individual message to be sent or received
  # via the Ably Realtime service.
  #
  # @!attribute [r] name
  #   @return [String] The event name, if available
  # @!attribute [r] client_id
  #   @return [String] The id of the publisher of this message
  # @!attribute [r] data
  #   @return [Object] The message payload. See the documentation for supported datatypes.
  # @!attribute [r] sender_timestamp
  #   @return [Time] Timestamp when the message was sent according to the publisher client
  # @!attribute [r] ably_timestamp
  #   @return [Time] Timestamp when the message was received by the Ably the service for publishing
  # @!attribute [r] message_id
  #   @return [String] A globally unique message ID
  # @!attribute [r] json
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class Message
    include Shared
    include Ably::Modules::Conversions

    def initialize(json_object, protocol_message)
      @protocol_message = protocol_message
      @raw_json_object  = json_object
      @json_object      = IdiomaticRubyWrapper(@raw_json_object.clone.freeze, stop_at: [:data])
    end

    %w( name client_id ).each do |attribute|
      define_method attribute do
        json[attribute.to_sym]
      end
    end

    def data
      @data ||= json[:data].freeze
    end

    def message_id
      "#{connection_id}:#{message_serial}:#{protocol_message_index}"
    end

    def sender_timestamp
      as_time_from_epoch(json[:timestamp]) if json[:timestamp]
    end

    def ably_timestamp
      protocol_message.timestamp
    end

    def json
      @json_object
    end

    def to_json_object
      raise RuntimeError, ":name is missing, cannot generate valid JSON for Message" unless name

      json.dup.tap do |json_object|
        json_object[:timestamp] = as_since_epoch(Time.now) unless sender_timestamp
      end
    end

    def to_json(*args)
      to_json_object.to_json
    end

    private
    attr_reader :protocol_message

    def protocol_message_index
      protocol_message.messages.index(self)
    end

    def connection_id
      protocol_message.connection_id
    end

    def message_serial
      protocol_message.message_serial
    end
  end
end
