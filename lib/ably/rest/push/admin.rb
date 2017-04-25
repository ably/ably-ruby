require 'ably/rest/push/device_registrations'
require 'ably/rest/push/channel_subscriptions'

module Ably::Rest
  class Push
    # Class providing push notification administrative functionality
    # for registering devices and attaching to channels etc.
    class Admin
      include Ably::Modules::Conversions

      # @api private
      attr_reader :client

      # @api private
      attr_reader :push

      def initialize(push)
        @push = push
        @client = push.client
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

      # Manage device registrations
      # @return [Ably::Rest::Push::DeviceRegistrations]
      def device_registrations
        @device_registrations ||= DeviceRegistrations.new(self)
      end

      # Manage channel subscriptions for devices or clients
      # @return [Ably::Rest::Push::ChannelSubscriptions]
      def channel_subscriptions
        @channel_subscriptions ||= ChannelSubscriptions.new(self)
      end
    end
  end
end
