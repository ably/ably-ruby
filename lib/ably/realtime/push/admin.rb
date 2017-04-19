require 'ably/realtime/push/device_registrations'
require 'ably/realtime/push/channel_subscriptions'

module Ably::Realtime
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

      # Manage device registrations
      # @return [Ably::Realtime::Push::DeviceRegistrations]
      def device_registrations
        @device_registrations ||= DeviceRegistrations.new(self)
      end

      # Manage channel subscriptions for devices or clients
      # @return [Ably::Realtime::Push::ChannelSubscriptions]
      def channel_subscriptions
        @channel_subscriptions ||= ChannelSubscriptions.new(self)
      end
    end
  end
end
