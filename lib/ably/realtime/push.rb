require 'ably/realtime/push/admin'

module Ably
  module Realtime
    # Class providing push notification functionality
    class Push
      # @private
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # A {Ably::Realtime::Push::Admin} object.
      #
      # @spec RSH1
      #
      # @return [Ably::Realtime::Push::Admin]
      #
      def admin
        @admin ||= Admin.new(self)
      end

      # Activates the device for push notifications with FCM or APNS, obtaining a unique identifier from them.
      # Subsequently registers the device with Ably and stores the deviceIdentityToken in local storage.
      #
      # @spec RSH2a
      #
      # @note This is unsupported in the Ruby library
      #
      def activate(*arg)
        raise_unsupported
      end

      # Deactivates the device from receiving push notifications with Ably and FCM or APNS.
      #
      # @spec RSH2b
      #
      # @note This is unsupported in the Ruby library
      #
      def deactivate(*arg)
        raise_unsupported
      end

      private

      def raise_unsupported
        raise Ably::Exceptions::PushNotificationsNotSupported, 'This device does not support receiving or subscribing to push notifications. All PushChannel methods are unavailable'
      end
    end
  end
end
