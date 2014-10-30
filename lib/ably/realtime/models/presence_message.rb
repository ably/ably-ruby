module Ably::Realtime::Models
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
  # @!attribute [r] state
  #   @return [STATE] the event signified by a PresenceMessage
  # @!attribute [r] client_id
  #   @return [String] The client_id associated with this presence state
  # @!attribute [r] member_id
  #   @return [String] A unique member identifier, disambiguating situations where a given client_id is present on multiple connections simultaneously
  # @!attribute [r] client_data
  #   @return [Object] Optional client-defined status or other event payload associated with this state
  # @!attribute [r] timestamp
  #   @return [Time] Timestamp when the message was received by the Ably the real-time service
  # @!attribute [r] json
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class PresenceMessage
    include Shared
    include Ably::Modules::Conversions
    include EventMachine::Deferrable
    extend Ably::Modules::Enum

    # TODO: Change to ACTION
    STATE = ruby_enum('STATE',
      :enter,
      :leave,
      :update
    )

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

    %w( client_id member_id client_data ).each do |attribute|
      define_method attribute do
        json[attribute.to_sym]
      end
    end

    def timestamp
      protocol_message.timestamp
    end

    def state
      STATE(json[:state])
    end

    def json
      @json_object
    end

    def to_json_object
      json.dup.tap do |json|
        json['state'] = state.to_i
      end
    rescue KeyError
      raise KeyError, ":state is missing or invalid, cannot generate valid JSON for ProtocolMessage"
    end

    def to_json(*args)
      to_json_object.to_json
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
    # @return [Ably::Realtime::Models::ProtocolMessage]
    # @api private
    def protocol_message
      raise RuntimeError, "Presence Message is not yet published with a ProtocolMessage. ProtocolMessage is nil" if @protocol_message.nil?
      @protocol_message
    end

    private
    def protocol_message_index
      protocol_message.presence.index(self)
    end

    def connection_id
      protocol_message.connection_id
    end

    def message_serial
      protocol_message.message_serial
    end
  end
end
