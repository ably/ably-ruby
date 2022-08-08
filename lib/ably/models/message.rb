# frozen_string_literal: true

require "ably/models/message_encoders/base"

module Ably
  # Models module provides the methods and classes for the Ably library
  #
  module Models
    # Convert messsage argument to a {Message} object and associate with a protocol message if provided
    #
    # @param message [Message,Hash] A message object or Hash of message properties
    # @param [Hash] options (see Message#initialize)
    #
    # @return [Message]
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
    #   @return [Time] Timestamp when the message was received by the Ably the realtime service
    # @!attribute [r] id
    #   @return [String] A globally unique message ID
    # @!attribute [r] connection_id
    #   @return [String] The connection_id of the publisher of the message
    # @!attribute [r] attributes
    #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
    #
    class Message
      include ::Ably::Modules::Conversions
      include ::Ably::Modules::Encodeable
      include ::Ably::Modules::ModelCommon
      include ::Ably::Modules::SafeDeferrable if defined?(Ably::Realtime)

      # Statically register a default set of encoders for this class
      ::Ably::Models::MessageEncoders.register_default_encoders self

      # {Message} initializer
      #
      # @param  attributes [Hash]             object with the underlying message detail key value attributes
      # @param  [Hash]      options           an options Hash for this initializer
      # @option options     [ProtocolMessage] :protocol_message  An optional protocol message to assocate the presence message with
      # @option options     [Logger]          :logger            An optional Logger to be used by {Ably::Modules::SafeDeferrable} if an exception is caught in a callback
      #
      def initialize(attributes, options = {})
        @logger = options[:logger] # Logger expected for SafeDeferrable
        @protocol_message = options[:protocol_message]
        @raw_hash_object = attributes

        set_attributes_object attributes

        self.attributes[:name] = ensure_utf_8(:name, name, allow_nil: true) if name
        self.attributes[:client_id] = ensure_utf_8(:client_id, client_id, allow_nil: true) if client_id
        self.attributes[:encoding] = ensure_utf_8(:encoding, encoding, allow_nil: true) if encoding

        self.attributes.freeze
      end

      %w[name client_id encoding].each do |attribute|
        define_method attribute do
          attributes[attribute.to_sym]
        end
      end

      def data
        @data ||= attributes[:data].freeze
      end

      def id
        attributes.fetch(:id) { "#{protocol_message.id!}:#{protocol_message_index}" }
      end

      def connection_id
        attributes.fetch(:connection_id) { protocol_message.connection_id if assigned_to_protocol_message? }
      end

      def timestamp
        if attributes[:timestamp]
          as_time_from_epoch(attributes[:timestamp])
        else
          protocol_message.timestamp
        end
      end

      attr_reader :attributes

      def to_json(*args)
        as_json(*args).tap do |message|
          decode_binary_data_before_to_json message
        end.to_json
      end

      # The size is the sum over name, data, clientId, and extras in bytes (TO3l8a)
      #
      def size
        %w[name data client_id extras].map do |attr|
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
      # @return [Boolean]
      # @api private
      def assigned_to_protocol_message?
        !!@protocol_message
      end

      # The optional ProtocolMessage this message is assigned to.  If ProtocolMessage is nil, an error will be raised.
      # @return [Ably::Models::ProtocolMessage]
      # @api private
      def protocol_message
        raise "Message is not yet published with a ProtocolMessage. ProtocolMessage is nil" if @protocol_message.nil?

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
          raise ArgumentError, "extras contains an unsupported type #{val.class}" unless val.is_a?(IdiomaticRubyWrapper) || val.is_a?(Array) || val.is_a?(Hash) || val.nil?
        end
      end

      # Delta extras extension (TM2i)
      # @return [DeltaExtras, nil]
      # @api private
      def delta_extras
        return nil if attributes[:extras][:delta].nil?

        @delta_extras ||= DeltaExtras.new(attributes[:extras][:delta]).freeze
      end

      def protocol_message_index
        protocol_message.messages.map(&:object_id).index(object_id)
      end

      private

      attr_reader :raw_hash_object

      def set_attributes_object(new_attributes)
        @attributes = IdiomaticRubyWrapper(new_attributes.clone, stop_at: %I[data extras])
      end

      def logger
        return @logger if @logger

        protocol_message&.logger
      end
    end
  end
end
