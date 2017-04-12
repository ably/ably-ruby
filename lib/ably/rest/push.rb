require 'ably/rest/push/admin'

module Ably
  module Rest
    # Class providing push notification functionality
    class Push
      include Ably::Modules::Conversions

      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Publish a push message directly to a single recipient
      #
      # @param recipient [Hash] A recipient device, client_id or raw APNS/GCM target. Refer to push documentation
      # @param data      [Hash] The notification payload data and fields. Refer to push documentation
      #
      # @return [void]
      #
      def publish(recipient, data)
        raise ArgumentError, "Expecting a Hash object for recipient, got #{recipient.class}" unless recipient.kind_of?(Hash)
        raise ArgumentError, "Recipient data is empty. You must provide recipient details" if recipient.empty?
        raise ArgumentError, "Expecting a Hash object for data, got #{data.class}" unless data.kind_of?(Hash)
        raise ArgumentError, "Push data field is empty. You must provide attributes for the push notification" if data.empty?

        publish_data = data.merge(recipient: IdiomaticRubyWrapper(recipient))
        # Co-erce to camelCase for notitication fields which are always camelCase
        publish_data[:notification] = IdiomaticRubyWrapper(data[:notification]) if publish_data[:notification].kind_of?(Hash)
        client.post('/push/publish', publish_data)
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
