module Ably::Realtime
  class Push
    # Manage push notification channel subscriptions for devices or clients
    class ChannelSubscriptions
      include Ably::Modules::Conversions
      include Ably::Modules::AsyncWrapper

      # @api private
      attr_reader :client

      # @api private
      attr_reader :admin

      def initialize(admin)
        @admin = admin
        @client = admin.client
      end

      # (see Ably::Rest::Push::ChannelSubscriptions#list)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def list(params, &callback)
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)

        if (IdiomaticRubyWrapper(params).keys & [:channel, :client_id, :device_id]).length == 0
          raise ArgumentError, "at least one channel, client_id or device_id filter param must be provided"
        end

        async_wrap(callback) do
          rest_channel_subscriptions.list(params.merge(async_blocking_operations: true))
        end
      end

      # (see Ably::Rest::Push::ChannelSubscriptions#list_channels)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def list_channels(params = {}, &callback)
        params = {} if params.nil?
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)

        async_wrap(callback) do
          rest_channel_subscriptions.list_channels(params.merge(async_blocking_operations: true))
        end
      end

      # (see Ably::Rest::Push::ChannelSubscriptions#save)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def save(push_channel_subscription, &callback)
        push_channel_subscription_object = PushChannelSubscription(push_channel_subscription)
        raise ArgumentError, "Channel is required yet is empty" if push_channel_subscription_object.channel.to_s.empty?

        async_wrap(callback) do
          rest_channel_subscriptions.save(push_channel_subscription)
        end
      end

      # (see Ably::Rest::Push::ChannelSubscriptions#remove)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def remove(push_channel_subscription, &callback)
        push_channel_subscription_object = PushChannelSubscription(push_channel_subscription)
        raise ArgumentError, "Channel is required yet is empty" if push_channel_subscription_object.channel.to_s.empty?
        if push_channel_subscription_object.client_id.to_s.empty? && push_channel_subscription_object.device_id.to_s.empty?
          raise ArgumentError, "Either client_id or device_id must be present"
        end

        async_wrap(callback) do
          rest_channel_subscriptions.remove(push_channel_subscription)
        end
      end

      # (see Ably::Rest::Push::ChannelSubscriptions#remove_where)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def remove_where(params, &callback)
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)

        if (IdiomaticRubyWrapper(params).keys & [:channel, :client_id, :device_id]).length == 0
          raise ArgumentError, "at least one channel, client_id or device_id filter param must be provided"
        end

        async_wrap(callback) do
          rest_channel_subscriptions.remove_where(params)
        end
      end

      private
      def rest_channel_subscriptions
        client.rest_client.push.admin.channel_subscriptions
      end

      def logger
        client.logger
      end
    end
  end
end
