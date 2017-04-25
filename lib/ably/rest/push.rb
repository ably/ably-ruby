require 'ably/rest/push/admin'

module Ably
  module Rest
    # Class providing push notification functionality
    class Push
      include Ably::Modules::Conversions

      # @private
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Admin features for push notifications like managing devices and channel subscriptions
      # @return [Ably::Rest::Push::Admin]
      def admin
        @admin ||= Admin.new(self)
      end

      # Activate this device for push notifications by registering with the push transport such as GCM/APNS
      #
      # @note This is unsupported in the Ruby library
      def activate(*arg)
        raise_unsupported
      end

      # Deactivate this device for push notifications by removing the registration with the push transport such as GCM/APNS
      #
      # @note This is unsupported in the Ruby library
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
