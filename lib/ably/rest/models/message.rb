module Ably::Rest::Models
  # A Message object encapsulates an individual message published in Ably retrieved via Rest
  class Message
    include Ably::Modules::Conversions

    def initialize(message)
      @message = IdiomaticRubyWrapper(message.clone.freeze)
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

    # Timestamp when the message was received by the Ably the real-time service
    #
    # @return [Time]
    def timestamp
      as_time_from_epoch(json[:timestamp]) if json[:timestamp]
    end

    # Unique message ID
    #
    # @return [String]
    def id
      json[:id]
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
