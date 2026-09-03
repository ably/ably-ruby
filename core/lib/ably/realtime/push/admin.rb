require 'ably/realtime/push/device_registrations'
require 'ably/realtime/push/channel_subscriptions'

module Ably::Realtime
  class Push
    # Class providing push notification administrative functionality
    # for registering devices and attaching to channels etc.
    #
    class Admin
      include Ably::Modules::AsyncWrapper
      include Ably::Modules::Conversions

      # @api private
      attr_reader :client

      # @api private
      attr_reader :push

      def initialize(push)
        @push = push
        @client = push.client
      end

      # Sends a push notification directly to a device, or a group of devices sharing the same clientId.
      #
      # (see Ably::Rest::Push#publish)
      #
      # @spec RSH1a
      #
      # @yield  Block is invoked upon successful publish of the message
      #
      # @return [Ably::Util::SafeDeferrable]
      #
      def publish(recipient, data, &callback)
        raise ArgumentError, "Expecting a Hash object for recipient, got #{recipient.class}" unless recipient.kind_of?(Hash)
        raise ArgumentError, "Recipient data is empty. You must provide recipient details" if recipient.empty?
        raise ArgumentError, "Expecting a Hash object for data, got #{data.class}" unless data.kind_of?(Hash)
        raise ArgumentError, "Push data field is empty. You must provide attributes for the push notification" if data.empty?

        async_wrap(callback) do
          rest_push_admin.publish(recipient, data)
        end
      end

      # A {Ably::Realtime::Push::DeviceRegistrations} object.
      #
      # @spec RSH1b
      #
      # @return [Ably::Realtime::Push::DeviceRegistrations]
      #
      def device_registrations
        @device_registrations ||= DeviceRegistrations.new(self)
      end

      # A {Ably::Realtime::Push::ChannelSubscriptions} object.
      #
      # @spec RSH1c
      #
      # @return [Ably::Realtime::Push::ChannelSubscriptions]
      #
      def channel_subscriptions
        @channel_subscriptions ||= ChannelSubscriptions.new(self)
      end

      private
      def rest_push_admin
        client.rest_client.push.admin
      end

      def logger
        client.logger
      end
    end
  end
end
