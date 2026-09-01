require 'ably/models/message_encoders/base'

module Ably::Models
  # Convert messsage argument to a {Message} object and associate with a protocol message if provided
  #
  # @param message [Message,Hash] A message object or Hash of message properties
  # @param [Hash] options (see Message#initialize)
  #
  # @return [Message]
  #
  def self.Message(message, options = {})
    case message
    when Message
      message.tap do
        message.assign_to_protocol_message options[:protocol_message] if options[:protocol_message]
      end
    else
      Message.new(message, options)
    end
  end

  # Contains an individual message that is sent to, or received from, Ably.
  #
  class Message
    include Ably::Modules::Conversions
    include Ably::Modules::Encodeable
    include Ably::Modules::ModelCommon
    include Ably::Modules::SafeDeferrable if defined?(Ably::Realtime)

    # Statically register a default set of encoders for this class
    Ably::Models::MessageEncoders.register_default_encoders self

    # {Message} initializer
    #
    # @spec TM2, TM3
    #
    # @param  attributes [Hash]             object with the underlying message detail key value attributes
    # @param  [Hash]      options           an options Hash for this initializer
    # @option options     [ProtocolMessage] :protocol_message  An optional protocol message to assocate the presence message with
    # @option options     [Logger]          :logger            An optional Logger to be used by {Ably::Modules::SafeDeferrable} if an exception is caught in a callback
    #
    def initialize(attributes, options = {})
      @logger           = options[:logger] # Logger expected for SafeDeferrable
      @protocol_message = options[:protocol_message]
      @raw_hash_object  = attributes

      set_attributes_object attributes

      self.attributes[:name] = ensure_utf_8(:name, name, allow_nil: true) if name
      self.attributes[:client_id] = ensure_utf_8(:client_id, client_id, allow_nil: true) if client_id
      self.attributes[:encoding] = ensure_utf_8(:encoding,  encoding,  allow_nil: true) if encoding

      self.attributes.freeze
    end

    # The client ID of the publisher of this message.
    #
    # @spec RSL1g1, TM2b
    #
    # @return [String]
    #
    def client_id
      attributes[:client_id]
    end

    # This is typically empty, as all messages received from Ably are automatically decoded client-side using this value.
    # However, if the message encoding cannot be processed, this attribute contains the remaining transformations
    # not applied to the data payload.
    #
    # @spec TM2e
    #
    # @return [String]
    #
    def encoding
      attributes[:encoding]
    end

    # The event name.
    #
    # @spec TM2g
    #
    # @return [String]
    #
    def name
      attributes[:name]
    end

    # The message payload, if provided.
    #
    # @spec TM2d
    #
    # @return [Hash, nil]
    #
    def data
      @data ||= attributes[:data].freeze
    end

    # A Unique ID assigned by Ably to this message.
    #
    # @spec TM2a
    #
    # @return [String]
    #
    def id
      attributes.fetch(:id) { "#{protocol_message.id!}:#{protocol_message_index}" }
    end

    # The connection ID of the publisher of this message.
    #
    # @spec TM2c
    #
    # @return [String]
    #
    def connection_id
      attributes.fetch(:connection_id) { protocol_message.connection_id if assigned_to_protocol_message? }
    end

    # Timestamp of when the message was received by Ably, as milliseconds since the Unix epoch.
    #
    # @spec TM2f
    #
    # @return [Integer]
    #
    def timestamp
      if attributes[:timestamp]
        as_time_from_epoch(attributes[:timestamp])
      else
        protocol_message.timestamp
      end
    end

    def attributes
      @attributes
    end

    def to_json(*args)
      as_json(*args).tap do |message|
        decode_binary_data_before_to_json message
      end.to_json
    end

    # The size is the sum over name, data, clientId, and extras in bytes (TO3l8a)
    #
    def size
      %w(name data client_id extras).map do |attr|
        if (value = attributes[attr.to_sym]).is_a?(String)
          value.bytesize
        elsif value.nil?
          0
        else
          value.to_json.bytesize
        end
      end.sum
    end

    # Assign this message to a ProtocolMessage before delivery to the Ably system
    # @api private
    def assign_to_protocol_message(protocol_message)
      @protocol_message = protocol_message
    end

    # True if this message is assigned to a ProtocolMessage for delivery to Ably, or received from Ably
    #
    # @return [Boolean]
    #
    # @api private
    def assigned_to_protocol_message?
      !!@protocol_message
    end

    # The optional ProtocolMessage this message is assigned to.  If ProtocolMessage is nil, an error will be raised.
    #
    # @return [Ably::Models::ProtocolMessage]
    #
    # @api private
    def protocol_message
      raise RuntimeError, 'Message is not yet published with a ProtocolMessage. ProtocolMessage is nil' if @protocol_message.nil?
      @protocol_message
    end

    # Contains any arbitrary key value pairs which may also contain other primitive JSON types, JSON-encodable objects or JSON-encodable arrays.
    # The extras field is provided to contain message metadata and/or ancillary payloads in support of specific functionality, e.g. push
    # 1.2 adds the delta extension which is of type DeltaExtras, and the headers extension, which contains arbitrary string->string key-value pairs,
    # settable at publish time. Unless otherwise specified, the client library should not attempt to do any filtering or validation of the extras
    # field itself, but should treat it opaquely, encoding it and passing it to realtime unaltered.
    # @api private
    def extras
      attributes[:extras].tap do |val|
        unless val.kind_of?(IdiomaticRubyWrapper) || val.kind_of?(Array) || val.kind_of?(Hash) || val.nil?
          raise ArgumentError, "extras contains an unsupported type #{val.class}"
        end
      end
    end

    # Delta extras extension (TM2i)
    #
    # @return [DeltaExtras, nil]
    #
    # @api private
    def delta_extras
      return nil if attributes[:extras][:delta].nil?
      @delta_extras ||= DeltaExtras.new(attributes[:extras][:delta]).freeze
    end

    def protocol_message_index
      protocol_message.messages.map(&:object_id).index(self.object_id)
    end

    private
    def raw_hash_object
      @raw_hash_object
    end

    def set_attributes_object(new_attributes)
      @attributes = IdiomaticRubyWrapper(new_attributes.clone, stop_at: [:data, :extras])
    end

    def logger
      return @logger if @logger
      protocol_message.logger if protocol_message
    end
  end
end
