module Ably::Rest
  class Push
    # Manage device registrations for push notifications
    class DeviceRegistrations
      include Ably::Modules::Conversions

      attr_reader :client
      attr_reader :admin

      def initialize(admin)
        @admin = admin
        @client = admin.client
      end

      # Get registered devices with optional filters
      #
      # @param [Hash] options   the filter options for the get registered device request
      # @option options [String]   :client_id  filter by devices registered to a client identifier
      # @option options [String]   :device_id  filter by unique device ID
      # @option options [Integer]  :limit      maximum number of devices to retrieve up to 1,000, defaults to 100
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::DeviceDetails>]  Paginated list of matching {Ably::Models::DeviceDetails}
      #
      def get(options = {})
        raise ArgumentError, "options must be a Hash" unless options.kind_of?(Hash)
        raise ArgumentError, "device_id filter cannot be specified alongside a client_id filter. Use one or the other" if options[:client_id] && options[:device_id]

        options = options.clone

        url = ["/push/deviceRegistrations", options[:device_id]].compact.join('/')
        response = client.get(url, IdiomaticRubyWrapper(options).as_json)

        paginated_options = {
          coerce_into: 'Ably::Models::DeviceDetails',
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        Ably::Models::PaginatedResult.new(response, '', client, paginated_options)
      end

      # Save and register device
      #
      # @param [Ably::Models::DeviceDetails]  device   the device details to save
      #
      # @return [void]
      #
      def save(device)
        device_details = DeviceDetails(device)
        raise ArgumentError, "Device ID is required yet is empty" if device_details.id.nil? || device_details == ''

        client.put("/push/deviceRegistrations/#{device_details.id}", device_details.as_json)
      end

      # Remove device matching options
      #
      # @param [Hash] options   the filter options for the remove request
      # @option options [String]   :client_id  remove devices registered to a client identifier
      # @option options [String]   :device_id  remove device with this unique device ID
      #
      # @return [void]
      #
      def remove(options)
        filter = if options.kind_of?(Ably::Models::DeviceDetails)
          { 'deviceId' => options.id }
        else
          raise ArgumentError, "options must be a Hash" unless options.kind_of?(Hash)
          raise ArgumentError, "device_id filter cannot be specified alongside a client_id filter. Use one or the other" if options[:client_id] && options[:device_id]
          IdiomaticRubyWrapper(options).as_json
        end
        client.delete("/push/deviceRegistrations", filter)
      end
    end
  end
end
