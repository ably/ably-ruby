module Ably::Models
  # Convert presence_messsage argument to a {PresenceMessage} object and associate with a protocol message if provided
  #
  # @param presence_message [PresenceMessage,Hash] A presence message object or Hash of presence message properties
  # @param protocol_message [ProtocolMessage] An optional protocol message to assocate the presence message with
  #
  # @return [PresenceMessage]
  def self.PresenceMessage(presence_message, protocol_message = nil)
    case presence_message
    when PresenceMessage
      presence_message.tap do
        presence_message.assign_to_protocol_message protocol_message
      end
    else
      PresenceMessage.new(presence_message, protocol_message)
    end
  end

  # A class representing an individual presence message to be sent or received
  # via the Ably Realtime service.
  #
  # @!attribute [r] action
  #   @return [STATE] the state change event signified by a PresenceMessage
  # @!attribute [r] client_id
  #   @return [String] The client_id associated with this presence state
  # @!attribute [r] member_id
  #   @return [String] A unique member identifier, disambiguating situations where a given client_id is present on multiple connections simultaneously
  # @!attribute [r] data
  #   @return [Object] Optional client-defined status or other event payload associated with this state
  # @!attribute [r] encoding
  #   @return [Object] The encoding for the message data. Encoding and decoding of messages is handled automatically by the client library.
  #                    Therefore, the `encoding` attribute should always be nil unless an Ably library decoding error has occurred.
  # @!attribute [r] timestamp
  #   @return [Time] Timestamp when the message was received by the Ably the real-time service
  # @!attribute [r] hash
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class PresenceMessage
    include Ably::Modules::Conversions
    include Ably::Modules::Encodeable
    include Ably::Modules::ModelCommon
    include EventMachine::Deferrable
    extend Ably::Modules::Enum

    ACTION = ruby_enum('ACTION',
      :enter,
      :leave,
      :update
    )

    # {Message} initializer
    #
    # @param hash_object      [Hash]             object with the underlying message details
    # @param protocol_message [ProtocolMessage] if this message has been published, then it is associated with a {ProtocolMessage}
    #
    def initialize(hash_object, protocol_message = nil)
      @protocol_message = protocol_message
      @raw_hash_object  = hash_object

      set_hash_object hash_object

      ensure_utf_8 :client_id, client_id, allow_nil: true
      ensure_utf_8 :member_id, member_id, allow_nil: true
      ensure_utf_8 :encoding,  encoding,  allow_nil: true
    end

    %w( client_id member_id data encoding ).each do |attribute|
      define_method attribute do
        hash[attribute.to_sym]
      end
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
  end
end
