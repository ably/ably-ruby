module Ably::Models
  # A message sent and received over the Realtime protocol.
  # A ProtocolMessage always relates to a single channel only, but
  # can contain multiple individual Messages or PresenceMessages.
  # ProtocolMessages are serially numbered on a connection.
  # See the {http://docs.ably.io/client-lib-development-guide/protocol/ Ably client library developer documentation}
  # for further details on the members of a ProtocolMessage
  #
  # @!attribute [r] action
  #   @return [ACTION] Protocol Message action {Ably::Modules::Enum} from list of {ACTION}. Returns nil if action is unsupported by protocol
  # @!attribute [r] auth
  #   @return [Ably::Models::AuthDetails] Authentication details used to perform authentication upgrades over an existing transport
  # @!attribute [r] count
  #   @return [Integer] The count field is used for ACK and NACK actions. See {http://docs.ably.io/client-lib-development-guide/protocol/#message-acknowledgement message acknowledgement protocol}
  # @!attribute [r] error
  #   @return [ErrorInfo] Contains error information
  # @!attribute [r] channel
  #   @return [String] Channel name for messages
  # @!attribute [r] channel_serial
  #   @return [String] Contains a serial number for a message on the current channel
  # @!attribute [r] connection_id
  #   @return [String] Contains a string public identifier for the connection
  # @!attribute [r] connection_key
  #   @return [String] Contains a string private connection key used to recover this connection
  # @!attribute [r] connection_serial
  #   @return [Bignum] Contains a serial number for a message sent from the server to the client
  # @!attribute [r] message_serial
  #   @return [Bignum] Contains a serial number for a message sent from the client to the server
  # @!attribute [r] timestamp
  #   @return [Time] An optional timestamp, applied by the service in messages sent to the client, to indicate the system time at which the message was sent (milliseconds past epoch)
  # @!attribute [r] messages
  #   @return [Array<Message>] A {ProtocolMessage} with a `:message` action contains one or more messages belonging to the channel
  # @!attribute [r] presence
  #   @return [Array<PresenceMessage>] A {ProtocolMessage} with a `:presence` action contains one or more presence updates belonging to the channel
  # @!attribute [r] flags
  #   @return [Integer] Flags indicating special ProtocolMessage states
  # @!attribute [r] attributes
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class ProtocolMessage
    include Ably::Modules::ModelCommon
    include Ably::Modules::Encodeable
    include Ably::Modules::SafeDeferrable if defined?(Ably::Realtime)
    extend Ably::Modules::Enum

    # Actions which are sent by the Ably Realtime API
    #
    # The values correspond to the ints which the API
    # understands.
    ACTION = ruby_enum('ACTION',
      heartbeat:    0,
      ack:          1,
      nack:         2,
      connect:      3,
      connected:    4,
      disconnect:   5,
      disconnected: 6,
      close:        7,
      closed:       8,
      error:        9,
      attach:       10,
      attached:     11,
      detach:       12,
      detached:     13,
      presence:     14,
      message:      15,
      sync:         16,
      auth:         17
    )

    # Indicates this protocol message action will generate an ACK response such as :message or :presence
    # @api private
    def self.ack_required?(for_action)
      ACTION(for_action).match_any?(ACTION.Presence, ACTION.Message)
    end

    # {ProtocolMessage} initializer
    #
    # @param  hash_object [Hash]            object with the underlying protocol message data
    # @param  [Hash]      options           an options Hash for this initializer
    # @option options     [Logger]          :logger            An optional Logger to be used by {Ably::Modules::SafeDeferrable} if an exception is caught in a callback
    #
    def initialize(hash_object, options = {})
      @logger = options[:logger] # Logger expected for SafeDeferrable

      @raw_hash_object = hash_object
      @hash_object     = IdiomaticRubyWrapper(@raw_hash_object.clone)

      raise ArgumentError, 'Invalid ProtocolMessage, action cannot be nil' if @hash_object[:action].nil?
      @hash_object[:action] = ACTION(@hash_object[:action]).to_i unless @hash_object[:action].kind_of?(Integer)

      @hash_object.freeze
    end

    %w(id channel channel_serial connection_id).each do |attribute|
      define_method attribute do
        attributes[attribute.to_sym]
      end
    end

    def connection_key
      # connection_key in connection details takes precedence over connection_key on the ProtocolMessage
      # connection_key in the ProtocolMessage will be deprecated in future protocol versions > 0.8
      connection_details.connection_key || attributes[:connection_key]
    end

    def id!
      raise RuntimeError, 'ProtocolMessage #id is nil' unless id
      id
    end

    def action
      ACTION(attributes[:action])
    rescue KeyError
      raise KeyError, "Action '#{attributes[:action]}' is not supported by ProtocolMessage"
    end

    def error
      @error ||= ErrorInfo.new(attributes[:error]) if attributes[:error]
    end

    def timestamp
      as_time_from_epoch(attributes[:timestamp]) if attributes[:timestamp]
    end

    def message_serial
      Integer(attributes[:msg_serial])
    rescue TypeError
      raise TypeError, "msg_serial '#{attributes[:msg_serial]}' is invalid, a positive Integer is expected for a ProtocolMessage"
    end

    def connection_serial
      Integer(attributes[:connection_serial])
    rescue TypeError
      raise TypeError, "connection_serial '#{attributes[:connection_serial]}' is invalid, a positive Integer is expected for a ProtocolMessage"
    end

    def count
      [1, attributes[:count].to_i].max
    end

    # @api private
    def has_message_serial?
      message_serial && true
    rescue TypeError
      false
    end

    # @api private
    def has_connection_serial?
      connection_serial && true
    rescue TypeError
      false
    end

    def serial
      if has_connection_serial?
        connection_serial
      else
        message_serial
      end
    end

    # @api private
    def has_serial?
      has_connection_serial? || has_message_serial?
    end

    def messages
      @messages ||=
        Array(attributes[:messages]).map do |message|
          Ably::Models.Message(message, protocol_message: self)
        end
    end

    # @api private
    def add_message(message)
      messages << message
    end

    def presence
      @presence ||=
        Array(attributes[:presence]).map do |message|
          Ably::Models.PresenceMessage(message, protocol_message: self)
        end
    end

    def flags
      Integer(attributes[:flags])
    rescue TypeError
      0
    end

    # @api private
    def has_presence_flag?
      flags & 1 == 1
    end

    # @api private
    def has_backlog_flag?
      flags & 2 == 2 # 2^1
    end

    # @api private
    def has_channel_resumed_flag?
      flags & 4 == 4 # 2^2
    end

    # @api private
    def has_local_presence_flag?
      flags & 8 == 8 # 2^3
    end

    # @api private
    def has_transient_flag?
      flags & 16 == 16 # 2^4
    end

    # @api private
    def has_attach_presence_flag?
      flags & 65536 == 65536 # 2^16
    end

    # @api private
    def has_attach_publish_flag?
      flags & 131072 == 131072 # 2^17
    end

    # @api private
    def has_attach_subscribe_flag?
      flags & 262144 == 262144 # 2^18
    end

    # @api private
    def has_attach_presence_subscribe_flag?
      flags & 524288 == 524288 # 2^19
    end

    def connection_details
      @connection_details ||= Ably::Models::ConnectionDetails(attributes[:connection_details])
    end

    def auth
      @auth ||= Ably::Models::AuthDetails(attributes[:auth])
    end

    # Indicates this protocol message will generate an ACK response when sent
    # Examples of protocol messages required ACK include :message and :presence
    # @api private
    def ack_required?
      self.class.ack_required?(action)
    end

    def attributes
      @hash_object
    end

    # Return a JSON ready object from the underlying #attributes using Ably naming conventions for keys
    def as_json(*args)
      raise TypeError, ':action is missing, cannot generate a valid Hash for ProtocolMessage' unless action
      raise TypeError, ':msg_serial or :connection_serial is missing, cannot generate a valid Hash for ProtocolMessage' if ack_required? && !has_serial?

      attributes.dup.tap do |hash_object|
        hash_object['action']   = action.to_i
        hash_object['messages'] = messages.map(&:as_json) unless messages.empty?
        hash_object['presence'] = presence.map(&:as_json) unless presence.empty?
      end.as_json
    end

    def to_s
      json_hash = as_json

      # Decode any binary data to before converting to a JSON string representation
      %w(messages presence).each do |message_type|
        if json_hash[message_type] && !json_hash[message_type].empty?
          json_hash[message_type].each do |message|
            decode_binary_data_before_to_json message
          end
        end
      end

      json_hash.to_json
    end

    # True if the ProtocolMessage appears to be invalid, however this is not a guarantee
    # @return [Boolean]
    # @api private
    def invalid?
      action_enum = action rescue nil
      !action_enum || (ack_required? && !has_serial?)
    end

    # @!attribute [r] logger
    # @api private
    attr_reader :logger
  end
end
