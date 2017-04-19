require 'ably/realtime/push/admin'

module Ably
  module Realtime
    # Class providing push notification functionality
    class Push
      include Ably::Modules::AsyncWrapper

      # @private
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # (see Ably::Rest::Push#publish)
      #
      # @yield  Block is invoked upon successful publish of the message
      # @return [Ably::Util::SafeDeferrable]
      #
      def publish(recipient, data, &callback)
        raise ArgumentError, "Expecting a Hash object for recipient, got #{recipient.class}" unless recipient.kind_of?(Hash)
        raise ArgumentError, "Recipient data is empty. You must provide recipient details" if recipient.empty?
        raise ArgumentError, "Expecting a Hash object for data, got #{data.class}" unless data.kind_of?(Hash)
        raise ArgumentError, "Push data field is empty. You must provide attributes for the push notification" if data.empty?

        async_wrap(callback) do
          rest_push.publish(recipient, data)
        end
      end

      # Admin features for push notifications like managing devices and channel subscriptions
      # @return [Ably::Realtime::Push::Admin]
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

      def rest_push
        client.rest_client.push
      end

      def logger
        client.logger
      end
    end
  end
end
