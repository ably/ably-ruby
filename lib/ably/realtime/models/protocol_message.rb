module Ably::Realtime::Models
  # A message sent and received over the Realtime protocol.
  # A ProtocolMessage always relates to a single channel only, but
  # can contain multiple individual Messages or PresenceMessages.
  # ProtocolMessages are serially numbered on a connection.
  # See the {http://docs.ably.io/client-lib-development-guide/protocol/ Ably client library developer documentation}
  # for further details on the members of a ProtocolMessage
  #
  # @!attribute [r] action
  #   @return [Integer] Protocol Message action from list of {ACTIONS}
  # @!attribute [r] action_sym
  #   @return [Symbol] Protocol Message action as a symbol
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
    include Ably::Modules::Conversions

    # Actions which are sent by the Ably Realtime API
    #
    # The values correspond to the ints which the API
    # understands.
    ACTIONS = {
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
    }.freeze

    # Retrieve an action symbol by the integer value
    def self.action_sym_for(action_int)
      @actions_index_by_int ||= ACTIONS.invert.freeze
      @actions_index_by_int[action_int]
    end

    # Retrive an action integer value from a symbol and raise an exception if invalid
    def self.action!(action_sym)
      ACTIONS.fetch(action_sym)
    end

    # Indicates this protocol message action will generate an ACK response such as :message or :presence
    def self.ack_required?(for_action)
      for_action = ACTIONS.fetch(for_action) if for_action.kind_of?(Symbol)
      [action!(:presence), action!(:message)].include?(for_action)
    end

    def initialize(json_object)
      @raw_json_object = json_object
      @json_object     = rubify(@raw_json_object).freeze
    end

    %w( action count
        channel channel_serial
        connection_id connection_serial ).each do |attribute|
      define_method attribute do
        json[attribute.to_sym]
      end
    end

    def action_sym
      self.class.action_sym_for(action)
    end

    def error
      @error_info ||= ErrorInfo.new(json[:error]) if json[:error]
    end

    def timestamp
      as_time_from_epoch(json[:timestamp]) if json[:timestamp]
    end

    def message_serial
      json[:msg_serial]
    end

    def messages
      @messages ||=
        Array(json[:messages]).map do |message|
          Message.new(message, self)
        end
    end

    def presence
      @presence ||=
        Array(json[:presence]).map do |message|
          PresenceMessage.new(message, self)
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
      raise RuntimeError, ":action is missing, cannot generate valid JSON for ProtocolMessage" unless action_sym
      raise RuntimeError, ":msg_serial is missing, cannot generate valid JSON for ProtocolMessage" if ack_required? && !message_serial

      json_object = json.dup.tap do |json_object|
        json_object[:messages] = messages.map(&:to_json_object) unless messages.empty?
        json_object[:presence] = presence.map(&:to_json_object) unless presence.empty?
      end

      javify(json_object)
    end

    def to_json
      to_json_object.to_json
    end
  end
end
