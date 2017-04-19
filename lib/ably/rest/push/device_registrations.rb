module Ably::Rest
  class Push
    # Manage device registrations for push notifications
    class DeviceRegistrations
      include Ably::Modules::Conversions

      # @api private
      attr_reader :client

      # @api private
      attr_reader :admin

      def initialize(admin)
        @admin = admin
        @client = admin.client
      end

      # Get registered device by device ID
      #
      # @param [String, Ably::Models::DeviceDetails] device_id   the device to retrieve
      #
      # @return [Ably::Models::DeviceDetails]  Returns {Ably::Models::DeviceDetails} if a match is found else a {Ably::Exceptions::ResourceMissing} is raised
      #
      def get(device_id)
        device_id = device_id.id if device_id.kind_of?(Ably::Models::DeviceDetails)
        raise ArgumentError, "device_id must be a string or DeviceDetails object" unless device_id.kind_of?(String)

        DeviceDetails(client.get("/push/deviceRegistrations/#{device_id}").body)
      end

      # List registered devices filtered by optional params
      #
      # @param [Hash] params   the filter options for the list registered device request
      # @option params [String]   :client_id  filter by devices registered to a client identifier. Cannot be used with +device_id+ param
      # @option params [String]   :device_id  filter by unique device ID. Cannot be used with +client_id+ param
      # @option params [Integer]  :limit      maximum number of devices to retrieve up to 1,000, defaults to 100
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::DeviceDetails>]  Paginated list of matching {Ably::Models::DeviceDetails}
      #
      def list(params = {})
        params = {} if params.nil?
        raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)
        raise ArgumentError, "device_id filter cannot be specified alongside a client_id filter. Use one or the other" if params[:client_id] && params[:device_id]

        params = params.clone

        paginated_options = {
          coerce_into: 'Ably::Models::DeviceDetails',
          async_blocking_operations: params.delete(:async_blocking_operations),
        }

        response = client.get('/push/deviceRegistrations', IdiomaticRubyWrapper(params).as_json)

        Ably::Models::PaginatedResult.new(response, '', client, paginated_options)
      end

      # Save and register device
      #
      # @param [Ably::Models::DeviceDetails, Hash]  device   the device details to save
      #
      # @return [void]
      #
      def save(device)
        device_details = DeviceDetails(device)
        raise ArgumentError, "Device ID is required yet is empty" if device_details.id.nil? || device_details == ''

        client.put("/push/deviceRegistrations/#{device_details.id}", device_details.as_json)
      end

      # Remove device
      #
      # @param [String, Ably::Models::DeviceDetails]  device_id  the device to remove
      #
      # @return [void]
      #
      def remove(device_id)
        device_id = device_id.id if device_id.kind_of?(Ably::Models::DeviceDetails)
        raise ArgumentError, "device_id must be a string or DeviceDetails object" unless device_id.kind_of?(String)

        client.delete("/push/deviceRegistrations/#{device_id}", {})
      end

      # Remove device matching where params
      #
      # @param [Hash] params   the filter params for the remove request
      # @option params [String]   :client_id  remove devices registered to a client identifier. Cannot be used with +device_id+ param
      # @option params [String]   :device_id  remove device with this unique device ID. Cannot be used with +client_id+ param
      #
      # @return [void]
      #
      def remove_where(params = {})
        filter = if params.kind_of?(Ably::Models::DeviceDetails)
          { 'deviceId' => params.id }
        else
          raise ArgumentError, "params must be a Hash" unless params.kind_of?(Hash)
          raise ArgumentError, "device_id filter cannot be specified alongside a client_id filter. Use one or the other" if params[:client_id] && params[:device_id]
          IdiomaticRubyWrapper(params).as_json
        end
        client.delete("/push/deviceRegistrations", filter)
      end
    end
  end
end
