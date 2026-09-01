module Ably::Realtime
  class Push
    # Manage device registrations for push notifications
    class DeviceRegistrations
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

      # (see Ably::Rest::Push::DeviceRegistrations#get)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def get(device_id, &callback)
        device_id = device_id.id if device_id.kind_of?(Ably::Models::DeviceDetails)
        raise ArgumentError, "device_id must be a string or DeviceDetails object" unless device_id.kind_of?(String)

        async_wrap(callback) do
          rest_device_registrations.get(device_id)
        end
      end

      # (see Ably::Rest::Push::DeviceRegistrations#list)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def list(params = {}, &callback)
        params = {} if params.nil?
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)
        raise ArgumentError, "device_id filter cannot be specified alongside a client_id filter. Use one or the other" if params[:client_id] && params[:device_id]

        async_wrap(callback) do
          rest_device_registrations.list(params.merge(async_blocking_operations: true))
        end
      end

      # (see Ably::Rest::Push::DeviceRegistrations#save)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def save(device, &callback)
        device_details = DeviceDetails(device)
        raise ArgumentError, "Device ID is required yet is empty" if device_details.id.nil? || device_details == ''

        async_wrap(callback) do
          rest_device_registrations.save(device_details)
        end
      end

      # (see Ably::Rest::Push::DeviceRegistrations#remove)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def remove(device_id, &callback)
        device_id = device_id.id if device_id.kind_of?(Ably::Models::DeviceDetails)
        raise ArgumentError, "device_id must be a string or DeviceDetails object" unless device_id.kind_of?(String)

        async_wrap(callback) do
          rest_device_registrations.remove(device_id)
        end
      end

      # (see Ably::Rest::Push::DeviceRegistrations#remove_where)
      #
      # @yield  Block is invoked when request succeeds
      # @return [Ably::Util::SafeDeferrable]
      #
      def remove_where(params = {}, &callback)
        filter = if params.kind_of?(Ably::Models::DeviceDetails)
          { 'deviceId' => params.id }
        else
          raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)
          raise ArgumentError, "device_id filter cannot be specified alongside a client_id filter. Use one or the other" if params[:client_id] && params[:device_id]
          IdiomaticRubyWrapper(params).as_json
        end

        async_wrap(callback) do
          rest_device_registrations.remove_where(filter)
        end
      end

      private
      def rest_device_registrations
        client.rest_client.push.admin.device_registrations
      end

      def logger
        client.logger
      end
    end
  end
end
