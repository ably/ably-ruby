module Ably::Models
  # Convert messsage argument to a {Message} object and associate with a protocol message if provided
  #
  # @param message [Message,Hash] A message object or Hash of message properties
  # @param protocol_message [ProtocolMessage] An optional protocol message to assocate the message with
  #
  # @return [Message]
  def self.Message(message, protocol_message = nil)
    case message
    when Message
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
  # @!attribute [r] encoding
  #   @return [Object] The encoding for the message data. Encoding and decoding of messages is handled automatically by the client library.
  #                    Therefore, the `encoding` attribute should always be nil unless an Ably library decoding error has occurred.
  # @!attribute [r] timestamp
  #   @return [Time] Timestamp when the message was received by the Ably the real-time service
  # @!attribute [r] id
  #   @return [String] A globally unique message ID
  # @!attribute [r] hash
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class Message
    include Ably::Modules::ModelCommon
    include Ably::Modules::Encodeable
    include EventMachine::Deferrable

    # {Message} initializer
    #
    # @param hash_object      [Hash]            object with the underlying message details
    # @param protocol_message [ProtocolMessage] if this message has been published, then it is associated with a {ProtocolMessage}
    #
    def initialize(hash_object, protocol_message = nil)
      @protocol_message = protocol_message
      @raw_hash_object  = hash_object

      set_hash_object hash_object

      ensure_utf8_string_for :client_id, client_id
      ensure_utf8_string_for :encoding,  encoding
    end

    %w( name client_id encoding ).each do |attribute|
      define_method attribute do
        hash[attribute.to_sym]
      end
    end

    def data
      @data ||= hash[:data].freeze
    end

    def id
      hash[:id] || "#{protocol_message.id!}:#{protocol_message_index}"
    end

    def timestamp
      if hash[:timestamp]
        as_time_from_epoch(hash[:timestamp])
      else
        protocol_message.timestamp
      end
    end

    def hash
      @hash_object
    end

    def as_json(*args)
      raise RuntimeError, ':name is missing, cannot generate a valid Hash for Message' unless name

      hash.dup.tap do |message|
        decode_binary_data_before_to_json message
      end.as_json
    end

    # Assign this message to a ProtocolMessage before delivery to the Ably system
    # @api private
    def assign_to_protocol_message(protocol_message)
      @protocol_message = protocol_message
    end

    # True if this message is assigned to a ProtocolMessage for delivery to Ably, or received from Ably
    # @return [Boolean]
    # @api private
    def assigned_to_protocol_message?
      !!@protocol_message
    end

    # The optional ProtocolMessage this message is assigned to.  If ProtocolMessage is nil, an error will be raised.
    # @return [Ably::Models::ProtocolMessage]
    # @api private
    def protocol_message
      raise RuntimeError, 'Message is not yet published with a ProtocolMessage. ProtocolMessage is nil' if @protocol_message.nil?
      @protocol_message
    end

    private
    attr_reader :raw_hash_object

    def protocol_message_index
      protocol_message.messages.map(&:object_id).index(self.object_id)
    end

    def connection_id
      protocol_message.connection_id
    end

    def message_serial
      protocol_message.message_serial
    end

    def set_hash_object(hash)
      @hash_object = IdiomaticRubyWrapper(hash.clone.freeze, stop_at: [:data])
    end
  end
end
