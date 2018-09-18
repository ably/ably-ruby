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
        "<PushChannel: name=#{channel.name}>"
      end

      # Subscribe local device for push notifications on this channel
      #
      # @note This is unsupported in the Ruby library
      def subscribe_device(*args)
        raise_unsupported
      end

      # Subscribe all devices registered to this client's authenticated client_id for push notifications on this channel
      #
      # @note This is unsupported in the Ruby library
      def subscribe_client_id(*args)
        raise_unsupported
      end

      # Unsubscribe local device for push notifications on this channel
      #
      # @note This is unsupported in the Ruby library
      def unsubscribe_device(*args)
        raise_unsupported
      end

      # Unsubscribe all devices registered to this client's authenticated client_id for push notifications on this channel
      #
      # @note This is unsupported in the Ruby library
      def unsubscribe_client_id(*args)
        raise_unsupported
      end

      # Get list of subscriptions on this channel for this device or authenticate client_id
      #
      # @note This is unsupported in the Ruby library
      def get_subscriptions(*args)
        raise_unsupported
      end

      private
      def raise_unsupported
        raise Ably::Exceptions::PushNotificationsNotSupported, 'This device does not support receiving or subscribing to push notifications. All PushChannel methods are unavailable'
      end
    end
  end
end
