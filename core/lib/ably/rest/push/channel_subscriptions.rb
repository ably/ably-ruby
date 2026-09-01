module Ably::Rest
  class Push
    # Manage push notification channel subscriptions for devices or client identifiers
    class ChannelSubscriptions
      include Ably::Modules::Conversions

      # @api private
      attr_reader :client

      # @api private
      attr_reader :admin

      def initialize(admin)
        @admin = admin
        @client = admin.client
      end

      # List channel subscriptions filtered by optional params
      #
      # @param [Hash] params   the filter options for the list channel subscription request. At least one of channel, client_id or device_id is required
      # @option params [String]   :channel    filter by realtime pub/sub channel name
      # @option params [String]   :client_id  filter by devices registered to a client identifier. If provided with device_id param, a concat operation is used so that any device with this client_id or provided device_id is returned.
      # @option params [String]   :device_id  filter by unique device ID. If provided with client_id param, a concat operation is used so that any device with this device_id or provided client_id is returned.
      # @option params [Integer]  :limit      maximum number of subscriptions to retrieve up to 1,000, defaults to 100
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::PushChannelSubscription>]  Paginated list of matching {Ably::Models::PushChannelSubscription}
      #
      def list(params)
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)

        if (IdiomaticRubyWrapper(params).keys & [:channel, :client_id, :device_id]).length == 0
          raise ArgumentError, "at least one channel, client_id or device_id filter param must be provided"
        end

        params = params.clone

        paginated_options = {
          coerce_into: 'Ably::Models::PushChannelSubscription',
          async_blocking_operations: params.delete(:async_blocking_operations),
        }

        response = client.get('/push/channelSubscriptions', IdiomaticRubyWrapper(params).as_json)

        Ably::Models::PaginatedResult.new(response, '', client, paginated_options)
      end

      # List channels with at least one subscribed device
      #
      # @param [Hash] params   the options for the list channels request
      # @option params [Integer]  :limit      maximum number of channels to retrieve up to 1,000, defaults to 100
      #
      # @return [Ably::Models::PaginatedResult<String>]  Paginated list of matching {Ably::Models::PushChannelSubscription}
      #
      def list_channels(params = {})
        params = {} if params.nil?
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)

        params = params.clone

        paginated_options = {
          coerce_into: 'String',
          async_blocking_operations: params.delete(:async_blocking_operations),
        }

        response = client.get('/push/channels', IdiomaticRubyWrapper(params).as_json)

        Ably::Models::PaginatedResult.new(response, '', client, paginated_options)
      end

      # Save push channel subscription for a device or client ID
      #
      # @param [Ably::Models::PushChannelSubscription,Hash]   push_channel_subscription   the push channel subscription details to save
      #
      # @return [void]
      #
      def save(push_channel_subscription)
        push_channel_subscription_object = PushChannelSubscription(push_channel_subscription)
        raise ArgumentError, "Channel is required yet is empty" if push_channel_subscription_object.channel.to_s.empty?

        client.post("/push/channelSubscriptions", push_channel_subscription_object.as_json)
      end

      # Remove a push channel subscription
      #
      # @param [Ably::Models::PushChannelSubscription,Hash]   push_channel_subscription   the push channel subscription details to remove
      #
      # @return [void]
      #
      def remove(push_channel_subscription)
        push_channel_subscription_object = PushChannelSubscription(push_channel_subscription)
        raise ArgumentError, "Channel is required yet is empty" if push_channel_subscription_object.channel.to_s.empty?
        if push_channel_subscription_object.client_id.to_s.empty? && push_channel_subscription_object.device_id.to_s.empty?
          raise ArgumentError, "Either client_id or device_id must be present"
        end

        client.delete("/push/channelSubscriptions", push_channel_subscription_object.as_json)
      end

      # Remove all matching push channel subscriptions
      #
      # @param [Hash] params   the filter options for the list channel subscription request. At least one of channel, client_id or device_id is required
      # @option params [String]   :channel    filter by realtime pub/sub channel name
      # @option params [String]   :client_id  filter by devices registered to a client identifier. If provided with device_id param, a concat operation is used so that any device with this client_id or provided device_id is returned.
      # @option params [String]   :device_id  filter by unique device ID. If provided with client_id param, a concat operation is used so that any device with this device_id or provided client_id is returned.
      #
      # @return [void]
      #
      def remove_where(params)
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)

        if (IdiomaticRubyWrapper(params).keys & [:channel, :client_id, :device_id]).length == 0
          raise ArgumentError, "at least one channel, client_id or device_id filter param must be provided"
        end

        params = params.clone

        client.delete("/push/channelSubscriptions", IdiomaticRubyWrapper(params).as_json)
      end
    end
  end
end
