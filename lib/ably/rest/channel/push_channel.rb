module Ably::Rest
  class Channel
    # A push channel used for push notifications
    # Each PushChannel maps to exactly one Rest Channel
    #
    # @!attribute [r] channel
    #   @return [Ably::Rest::Channel] Underlying channel object
    #
    class PushChannel
      attr_reader :channel

      def initialize(channel)
        raise ArgumentError, "Unsupported channel type '#{channel.class}'" unless channel.kind_of?(Ably::Rest::Channel)
        @channel = channel
      end

      def to_s
        "PushChannel: #{channel.name}"
      end
    end
  end
end
