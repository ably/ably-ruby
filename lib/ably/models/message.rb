module Ably::Models
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
  # @!attribute [r] hash
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class Message
    include Ably::Modules::Conversions
    include Ably::Modules::Encodeable
    include Ably::Modules::ModelCommon
    include Ably::Modules::SafeDeferrable if defined?(Ably::Realtime)

    # {Message} initializer
    #
    # @param  hash_object [Hash]            object with the underlying message details
    # @param  [Hash]      options           an options Hash for this initializer
    # @option options     [ProtocolMessage] :protocol_message  An optional protocol message to assocate the presence message with
    # @option options     [Logger]          :logger            An optional Logger to be used by {Ably::Modules::SafeDeferrable} if an exception is caught in a callback
    #
    def initialize(hash_object, options = {})
      @logger           = options[:logger] # Logger expected for SafeDeferrable
      @protocol_message = options[:protocol_message]
      @raw_hash_object  = hash_object

      set_hash_object hash_object

      ensure_utf_8 :name,      name,      allow_nil: true
      ensure_utf_8 :client_id, client_id, allow_nil: true
      ensure_utf_8 :encoding,  encoding,  allow_nil: true
    end

    %w( name client_id encoding connection_id ).each do |attribute|
      define_method attribute do
        hash[attribute.to_sym]
      end
    end

    def data
      @data ||= hash[:data].freeze
    end

    def id
      hash.fetch(:id) { "#{protocol_message.id!}:#{protocol_message_index}" }
    end

    def connection_id
      hash.fetch(:connection_id) { protocol_message.connection_id if assigned_to_protocol_message? }
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

    def to_json(*args)
      as_json(*args).tap do |message|
        decode_binary_data_before_to_json message
      end.to_json
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

    def set_hash_object(hash)
      @hash_object = IdiomaticRubyWrapper(hash.clone.freeze, stop_at: [:data])
    end

    def logger
      return logger if logger
      protocol_message.logger if protocol_message
    end
  end
end
