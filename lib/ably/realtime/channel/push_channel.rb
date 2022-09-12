module Ably::Realtime
  class Channel
    # Enables devices to subscribe to push notifications for a channel.
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

      # Subscribes the device to push notifications for the channel.
      #
      # @spec RSH7a
      #
      # @note This is unsupported in the Ruby library
      def subscribe_device(*args)
        raise_unsupported
      end

      # Subscribes all devices associated with the current device's clientId to push notifications for the channel.
      #
      # @spec RSH7b
      #
      # @note This is unsupported in the Ruby library
      def subscribe_client_id(*args)
        raise_unsupported
      end

      # Unsubscribes the device from receiving push notifications for the channel.
      #
      # @spec RSH7c
      #
      # @note This is unsupported in the Ruby library
      def unsubscribe_device(*args)
        raise_unsupported
      end

      # Unsubscribes all devices associated with the current device's clientId from receiving push notifications for the channel.
      #
      # @spec RSH7d
      #
      # @note This is unsupported in the Ruby library
      def unsubscribe_client_id(*args)
        raise_unsupported
      end

      # Retrieves all push subscriptions for the channel. Subscriptions can be filtered using a params object.
      # Returns a {Ably::Models::PaginatedResult} object containing an array of {Ably::Models::PushChannelSubscription} objects.
      #
      # @spec RSH7e
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
