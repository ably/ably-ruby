module Ably::Rest::Models
  # A Message object encapsulates an individual message published in Ably retrieved via Rest
  class Message
    def initialize(message)
      @message = message.dup.freeze
    end

    # Event name
    #
    # @return [String]
    def name
      json[:name]
    end

    # Payload
    #
    # @return [Object]
    def data
      json[:data]
    end

    # Client ID of the publisher of the message
    #
    # @return [String]
    def client_id
      json[:client_id]
    end

    # Timestamp when message was sent.  This property is populated by the sender.
    #
    # @return [Time]
    def sender_timestamp
      Time.at(json[:timestamp] / 1000.0) if json[:timestamp]
    end

    # Unique message ID
    #
    # @return [String]
    def message_id
      json[:message_id]
    end

    # Provide a normal Hash accessor to the underlying raw message object
    #
    # @return [Object]
    def [](key)
      json[key]
    end

    # Raw message object
    #
    # @return [Hash]
    def json
      @message
    end

    def ==(other)
      other.kind_of?(Message) &&
        json == other.json
    end
  end
end
