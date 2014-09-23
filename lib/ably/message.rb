module Ably
  # A Message encapsulates an individual message sent or received in Ably
  class Message
    def initialize(message)
      @message = message.dup.freeze
    end

    # Event name
    #
    # @return [String]
    def name
      @message[:name]
    end

    # Payload
    #
    # @return [Object]
    def data
      @message[:data]
    end

    # Client ID of the publisher of the message
    #
    # @return [String]
    def client_id
      @message[:client_id]
    end

    # Timestamp in milliseconds since epoch.  This property is populated by the Ably system.
    #
    # @return [Integer]
    def timestamp
      @message[:timestamp]
    end

    # Timestamp as {Time}.  This property is populated by the Ably system.
    #
    # @return [Time]
    def timestamp_at
      raise RuntimeError, "Timestamp is missing" unless timestamp
      Time.at(timestamp / 1000.0)
    end

    # Unique serial number of this message within the channel
    #
    # @return [Integer]
    def channel_serial
      @message[:channel_serial]
    end

    # Provide a normal Hash accessor to the underlying raw message object
    #
    # @return [Object]
    def [](key)
      @message[key]
    end

    # Raw message object
    #
    # @return [Hash]
    def raw_message
      @message
    end

    def ==(other)
      self.kind_of?(other.class) &&
        raw_message == other.raw_message
    end
  end
end
