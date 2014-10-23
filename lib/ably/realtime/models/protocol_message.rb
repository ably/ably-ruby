module Ably::Realtime::Models
  # A message sent and received over the Realtime protocol.
  # A ProtocolMessage always relates to a single channel only, but
  # can contain multiple individual Messages or PresenceMessages.
  # ProtocolMessages are serially numbered on a connection.
  # See the {http://docs.ably.io/client-lib-development-guide/protocol/ Ably client library developer documentation}
  # for further details on the members of a ProtocolMessage
  #
  # @!attribute [r] action
  #   @return [ACTION] Protocol Message action {Ably::Modules::Enum} from list of {ACTION}. Returns nil if action is unsupported by protocol.
  # @!attribute [r] count
  #   @return [Integer] The count field is used for ACK and NACK actions. See {http://docs.ably.io/client-lib-development-guide/protocol/#message-acknowledgement message acknowledgement protocol}
  # @!attribute [r] error_info
  #   @return [ErrorInfo] Contains error information
  # @!attribute [r] channel
  #   @return [String] Channel name for messages
  # @!attribute [r] channel_serial
  #   @return [String] Contains a serial number for amessage on the current channel
  # @!attribute [r] connection_id
  #   @return [String] Contains a string connection ID
  # @!attribute [r] connection_serial
  #   @return [Bignum] Contains a serial number for a message on the current connection
  # @!attribute [r] message_serial
  #   @return [Bignum] Contains a serial number for a message sent from the client to the service.
  # @!attribute [r] timestamp
  #   @return [Time] An optional timestamp, applied by the service in messages sent to the client, to indicate the system time at which the message was sent (milliseconds past epoch)
  # @!attribute [r] messages
  #   @return [Message] A {ProtocolMessage} with a `:message` action contains one or more messages belonging to a channel.
  # @!attribute [r] presence
  #   @return [PresenceMessage] A {ProtocolMessage} with a `:presence` action contains one or more presence updates belonging to a channel.
  # @!attribute [r] json
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class ProtocolMessage
    include Shared
    extend Ably::Modules::Enum
    include Ably::Modules::Conversions

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
      message:      15
    )

    # Indicates this protocol message action will generate an ACK response such as :message or :presence
    def self.ack_required?(for_action)
      [ACTION.Presence, ACTION.Message].include?(ACTION(for_action))
    end

    def initialize(json_object)
      @raw_json_object = json_object
      @json_object     = IdiomaticRubyWrapper(@raw_json_object.clone.freeze)
    end

    %w( count channel channel_serial
        connection_id connection_serial ).each do |attribute|
      define_method attribute do
        json[attribute.to_sym]
      end
    end

    def action
      ACTION(json[:action])
    rescue KeyError
      raise KeyError, "Action '#{json[:action]}' is not supported by ProtocolMessage"
    end

    def error
      @error_info ||= ErrorInfo.new(json[:error]) if json[:error]
    end

    def timestamp
      as_time_from_epoch(json[:timestamp]) if json[:timestamp]
    end

    def message_serial
      Integer(json[:msg_serial])
    rescue TypeError
      raise TypeError, "msg_serial '#{json[:msg_serial]}' is invalid, a positive Integer is required for a ProtocolMessage"
    end

    def has_message_serial?
      message_serial && true
    rescue TypeError
      false
    end

    def messages
      @messages ||=
        Array(json[:messages]).map do |message|
          Ably::Realtime::Models.Message(message, self)
        end
    end

    def add_message(message)
      messages << message
    end

    def presence
      @presence ||=
        Array(json[:presence]).map do |message|
          PresenceMessage(message, self)
        end
    end

    def json
      @json_object
    end

    # Indicates this protocol message will generate an ACK response when sent
    # Examples of protocol messages required ACK include :message and :presence
    def ack_required?
      self.class.ack_required?(action)
    end

    def to_json_object
      raise TypeError, ":action is missing, cannot generate valid JSON for ProtocolMessage" unless action
      raise TypeError, ":msg_serial is missing, cannot generate valid JSON for ProtocolMessage" if ack_required? && !has_message_serial?

      json.dup.tap do |json_object|
        json_object[:messages] = messages.map(&:to_json_object) unless messages.empty?
        json_object[:presence] = presence.map(&:to_json_object) unless presence.empty?
      end
    end

    def to_json(*args)
      to_json_object.to_json
    end

    def to_s
      to_json
    end
  end
end
