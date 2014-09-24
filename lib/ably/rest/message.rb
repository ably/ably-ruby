module Ably
  module Rest
    # A Message object encapsulates an individual message published in Ably retrieved via Rest
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

      # Timestamp in milliseconds since epoch.  This property is populated by the sender.
      #
      # @return [Integer]
      def sender_timestamp
        @message[:timestamp]
      end

      # Timestamp as {Time}.  This property is populated by the sender.
      #
      # @return [Time]
      def sender_timestamp_at
        raise RuntimeError, "Sender timestamp is missing" unless sender_timestamp
        Time.at(sender_timestamp / 1000.0)
      end

      # Unique message ID
      #
      # @return [String]
      def message_id
        @message[:message_id]
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
end
