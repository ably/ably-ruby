module Ably::Models
  # Convert presence_messsage argument to a {PresenceMessage} object and associate with a protocol message if provided
  #
  # @param presence_message [PresenceMessage,Hash] A presence message object or Hash of presence message properties
  # @param [Hash] options (see PresenceMessage#initialize)
  #
  # @return [PresenceMessage]
  def self.PresenceMessage(presence_message, options = {})
    case presence_message
    when PresenceMessage
      presence_message.tap do
        presence_message.assign_to_protocol_message options[:protocol_message] if options[:protocol_message]
      end
    else
      PresenceMessage.new(presence_message, options)
    end
  end

  # A class representing an individual presence message to be sent or received
  # via the Ably Realtime service.
  #
  # @!attribute [r] action
  #   @return [STATE] the state change event signified by a PresenceMessage
  # @!attribute [r] client_id
  #   @return [String] The client_id associated with this presence state
  # @!attribute [r] connection_id
  #   @return [String] A unique member identifier, disambiguating situations where a given client_id is present on multiple connections simultaneously
  # @!attribute [r] member_key
  #   @return [String] A unique connection and client_id identifier ensuring multiple connected clients with the same client_id are unique
  # @!attribute [r] data
  #   @return [Object] Optional client-defined status or other event payload associated with this state
  # @!attribute [r] encoding
  #   @return [String] The encoding for the message data. Encoding and decoding of messages is handled automatically by the client library.
  #                    Therefore, the `encoding` attribute should always be nil unless an Ably library decoding error has occurred.
  # @!attribute [r] timestamp
  #   @return [Time] Timestamp when the message was received by the Ably the realtime service
  # @!attribute [r] hash
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class PresenceMessage
    include Ably::Modules::Conversions
    include Ably::Modules::Encodeable
    include Ably::Modules::ModelCommon
    include Ably::Modules::SafeDeferrable if defined?(Ably::Realtime)
    extend Ably::Modules::Enum

    ACTION = ruby_enum('ACTION',
      :absent,
      :present,
      :enter,
      :leave,
      :update
    )

    # {PresenceMessage} initializer
    #
    # @param  hash_object [Hash]            object with the underlying presence message details
    # @param  [Hash]      options           an options Hash for this initializer
    # @option options     [ProtocolMessage] :protocol_message  An optional protocol message to assocate the presence message with
    # @option options     [Logger]          :logger            An optional Logger to be used by {Ably::Modules::SafeDeferrable} if an exception is caught in a callback
    #
    def initialize(hash_object, options = {})
      @logger           = options[:logger] # Logger expected for SafeDeferrable
      @protocol_message = options[:protocol_message]
      @raw_hash_object  = hash_object

      set_hash_object hash_object

      ensure_utf_8 :client_id,     client_id,     allow_nil: true
      ensure_utf_8 :connection_id, connection_id, allow_nil: true
      ensure_utf_8 :encoding,      encoding,      allow_nil: true
    end

    %w( client_id data encoding ).each do |attribute|
      define_method attribute do
        hash[attribute.to_sym]
      end
    end

    def id
      hash.fetch(:id) { "#{protocol_message.id!}:#{protocol_message_index}" }
    end

    def connection_id
      hash.fetch(:connection_id) { protocol_message.connection_id if assigned_to_protocol_message? }
    end

    def member_key
      "#{connection_id}:#{client_id}"
    end

    def timestamp
      if hash[:timestamp]
        as_time_from_epoch(hash[:timestamp])
      else
        protocol_message.timestamp
      end
    end

    def action
      ACTION(hash[:action])
    end

    def hash
      @hash_object
    end

    # Return a JSON ready object from the underlying #hash using Ably naming conventions for keys
    def as_json(*args)
      hash.dup.tap do |presence_message|
        presence_message['action'] = action.to_i
        decode_binary_data_before_to_json presence_message
      end.as_json
    rescue KeyError
      raise KeyError, ':action is missing or invalid, cannot generate a valid Hash for ProtocolMessage'
    end

    # Assign this presence message to a ProtocolMessage before delivery to the Ably system
    # @api private
    def assign_to_protocol_message(protocol_message)
      @protocol_message = protocol_message
    end

    # True if this presence message is assigned to a ProtocolMessage for delivery to Ably, or received from Ably
    # @return [Boolean]
    # @api private
    def assigned_to_protocol_message?
      !!@protocol_message
    end

    # The optional ProtocolMessage this presence message is assigned to.  If ProtocolMessage is nil, an error will be raised.
    # @return [Ably::Models::ProtocolMessage]
    # @api private
    def protocol_message
      raise RuntimeError, 'Presence Message is not yet published with a ProtocolMessage. ProtocolMessage is nil' if @protocol_message.nil?
      @protocol_message
    end

    private
    attr_reader :raw_hash_object

    def protocol_message_index
      protocol_message.presence.index(self)
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
