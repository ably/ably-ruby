module Ably::Realtime
  class Channel
    # A push channel used for push notifications
    # Each PushChannel maps to exactly one Realtime Channel
    #
    # @!attribute [r] channel
    #   @return [Ably::Realtime::Channel] Underlying channel object
    #
    class PushChannel
      attr_reader :channel

      def initialize(channel)
        raise ArgumentError, "Unsupported channel type '#{channel.class}'" unless channel.kind_of?(Ably::Realtime::Channel)
        @channel = channel
      end

      def to_s
        "PushChannel: #{channel.name}"
      end
    end
  end
end
