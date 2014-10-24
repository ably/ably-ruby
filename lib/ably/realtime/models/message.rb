module Ably::Realtime::Models
  def self.Message(message, protocol_message = nil)
    case message
    when Ably::Realtime::Models::Message
      message.tap do
        message.assign_to_protocol_message protocol_message
      end
    else
      Message.new(message, protocol_message)
    end
  end

  # A class representing an individual message to be sent or received
  # via the Ably Realtime service.
  #
  # @!attribute [r] name
  #   @return [String] The event name, if available
  # @!attribute [r] client_id
  #   @return [String] The id of the publisher of this message
  # @!attribute [r] data
  #   @return [Object] The message payload. See the documentation for supported datatypes.
  # @!attribute [r] timestamp
  #   @return [Time] Timestamp when the message was received by the Ably the real-time service
  # @!attribute [r] id
  #   @return [String] A globally unique message ID
  # @!attribute [r] json
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class Message
    include Shared
    include Ably::Modules::Conversions
    include EventMachine::Deferrable

    # {Message} initializer
    #
    # @param json_object [Hash] JSON like object with the underlying message details
    # @param protocol_message [ProtocolMessage] if this message has been published, then it is associated with a {ProtocolMessage}
    #
    def initialize(json_object, protocol_message = nil)
      @protocol_message = protocol_message
      @raw_json_object  = json_object
      @json_object      = IdiomaticRubyWrapper(json_object.clone.freeze, stop_at: [:data])
    end

    %w( name client_id ).each do |attribute|
      define_method attribute do
        json[attribute.to_sym]
      end
    end

    def data
      @data ||= json[:data].freeze
    end

    def id
      "#{connection_id}:#{message_serial}:#{protocol_message_index}"
    end

    def timestamp
      protocol_message.timestamp
    end

    def json
      @json_object
    end

    def to_json_object
      raise RuntimeError, ":name is missing, cannot generate valid JSON for Message" unless name
      json.dup
    end

    def to_json(*args)
      to_json_object.to_json
    end

    def assign_to_protocol_message(protocol_message)
      @protocol_message = protocol_message
    end

    private

    def protocol_message
      raise RuntimeError, "Message is not yet published with a ProtocolMessage.  ProtocolMessage is nil" if @protocol_message.nil?
      @protocol_message
    end

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
