module Ably::Models
  # Convert presence_messsage argument to a {PresenceMessage} object and associate with a protocol message if provided
  #
  # @param presence_message [PresenceMessage,Hash] A presence message object or Hash of presence message properties
  # @param [Hash] options (see PresenceMessage#initialize)
  #
  # @return [PresenceMessage]
  #
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
  class PresenceMessage
    include Ably::Modules::Conversions
    include Ably::Modules::Encodeable
    include Ably::Modules::ModelCommon
    include Ably::Modules::SafeDeferrable if defined?(Ably::Realtime)
    extend Ably::Modules::Enum

    # Describes the possible actions members in the presence set can emit.
    #
    #   ABSENT	    TP2	A member is not present in the channel.
    #   PRESENT	    TP2	When subscribing to presence events on a channel that already has members present, this event is emitted for every member already present on the channel before the subscribe listener was registered.
    #   ENTER	      TP2	A new member has entered the channel.
    #   LEAVE	      TP2	A member who was present has now left the channel. This may be a result of an explicit request to leave or implicitly when detaching from the channel. Alternatively, if a member's connection is abruptly disconnected and they do not resume their connection within a minute, Ably treats this as a leave event as the client is no longer present.
    #   UPDATE	    TP2	An already present member has updated their member data. Being notified of member data updates can be very useful, for example, it can be used to update the status of a user when they are typing a message.
    #
    # @spec TP2
    #
    ACTION = ruby_enum('ACTION',
      :absent,
      :present,
      :enter,
      :leave,
      :update
    )

    # Statically register a default set of encoders for this class
    Ably::Models::MessageEncoders.register_default_encoders self

    # {PresenceMessage} initializer
    #
    # @param  attributes  [Hash]            object with the underlying presence message key value attributes
    # @param  [Hash]      options           an options Hash for this initializer
    # @option options     [ProtocolMessage] :protocol_message  An optional protocol message to assocate the presence message with
    # @option options     [Logger]          :logger            An optional Logger to be used by {Ably::Modules::SafeDeferrable} if an exception is caught in a callback
    #
    def initialize(attributes, options = {})
      @logger           = options[:logger] # Logger expected for SafeDeferrable
      @protocol_message = options[:protocol_message]
      @raw_hash_object  = attributes

      set_attributes_object attributes

      self.attributes[:client_id] = ensure_utf_8(:client_id, client_id, allow_nil: true) if client_id
      self.attributes[:connection_id] = ensure_utf_8(:connection_id, connection_id, allow_nil: true) if connection_id
      self.attributes[:encoding] = ensure_utf_8(:encoding, encoding, allow_nil: true) if encoding

      self.attributes.freeze
    end

    # The ID of the client that published the PresenceMessage.
    #
    # @spec TP3c
    #
    # @return [String]
    #
    def client_id
      attributes[:client_id]
    end

    # The payload of the {Ably::Models::PresenceMessage}.
    #
    # @spec TP3e
    #
    # @return [Hash, nil]
    #
    def data
      attributes[:data]
    end

    # This will typically be empty as all presence messages received from Ably are automatically decoded client-side
    # using this value. However, if the message encoding cannot be processed, this attribute will contain the remaining
    # transformations not applied to the data payload.
    #
    # @spec TP3f
    #
    # @return [String]
    #
    def encoding
      attributes[:encoding]
    end

    # A unique ID assigned to each {Ably::Models::PresenceMessage} by Ably.
    #
    # @spec TP3a
    #
    # @return [String]
    #
    def id
      attributes.fetch(:id) { "#{protocol_message.id!}:#{protocol_message_index}" }
    end

    # The ID of the connection associated with the client that published the {Ably::Models::PresenceMessage}.
    #
    # @spec TP3d
    #
    # @return [String]
    #
    def connection_id
      attributes.fetch(:connection_id) { protocol_message.connection_id if assigned_to_protocol_message? }
    end

    # Combines clientId and connectionId to ensure that multiple connected clients with an identical clientId are uniquely
    # identifiable. A string function that returns the combined clientId and connectionId.
    #
    # @spec TP3h
    #
    # @return [String]
    #
    def member_key
      "#{connection_id}:#{client_id}"
    end

    # The time the {Ably::Models::PresenceMessage} was received by Ably, as milliseconds since the Unix epoch.
    #
    # @spec TP3g
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

    # The type of {Ably::Models::PresenceMessage::ACTION} the PresenceMessage is for.
    #
    # @spec TP3b
    #
    # @return [Ably::Models::PresenceMessage::ACTION]
    #
    def action
      ACTION(attributes[:action])
    end

    def attributes
      @attributes
    end

    # Return a JSON ready object from the underlying #attributes using Ably naming conventions for keys
    def as_json(*args)
      attributes.dup.tap do |presence_message|
        presence_message['action'] = action.to_i
      end.as_json.reject { |key, val| val.nil? }
    rescue KeyError
      raise KeyError, ':action is missing or invalid, cannot generate a valid Hash for ProtocolMessage'
    end

    def to_json(*args)
      as_json(*args).tap do |presence_message|
        decode_binary_data_before_to_json presence_message
      end.to_json
    end

    # The size is the sum over data and clientId in bytes (TO3l8a)
    #
    def size
      %w(data client_id).map do |attr|
        if (value = attributes[attr.to_sym]).is_a?(String)
          value.bytesize
        elsif value.nil?
          0
        else
          value.to_json.bytesize
        end
      end.sum
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

    # Create a static shallow clone of this object with the optional attributes to overide existing values
    # Shallow clones have no dependency on the originating ProtocolMessage as all field values are stored as opposed to calculated
    # Clones are useful when the original PresenceMessage needs to be mutated, such as storing in a PresenceMap with action :present
    def shallow_clone(new_attributes = {})
      new_attributes = IdiomaticRubyWrapper(new_attributes.clone.freeze, stop_at: [:data])

      self.class.new(attributes.to_hash.merge(
        id: new_attributes[:id] || id,
        connection_id: new_attributes[:connection_id] || connection_id,
        timestamp: new_attributes[:timestamp] || as_since_epoch(timestamp)
      ).merge(new_attributes.to_hash))
    end

    private
    def raw_hash_object
      @raw_hash_object
    end

    def protocol_message_index
      protocol_message.presence.index(self)
    end

    def set_attributes_object(new_attributes)
      @attributes = IdiomaticRubyWrapper(new_attributes.clone, stop_at: [:data])
    end

    def logger
      return @logger if @logger
      protocol_message.logger if protocol_message
    end
  end
end
