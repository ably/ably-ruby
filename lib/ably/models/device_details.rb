module Ably::Modules
  module Conversions
    private
    # Convert device_details argument to a {Ably::Models::DeviceDetails} object
    #
    # @param device_details [Ably::Models::DeviceDetails,Hash,nil] A device details object
    #
    # @return [Ably::Models::DeviceDetails]
    #
    def DeviceDetails(device_details)
      case device_details
      when Ably::Models::DeviceDetails
        device_details
      else
        Ably::Models::DeviceDetails.new(device_details)
      end
    end
  end
end

module Ably::Models
  # Contains the properties of a device registered for push notifications.
  #
  class DeviceDetails < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    # @param hash_object   [Hash,nil]  Device detail attributes
    #
    def initialize(hash_object = {})
      @raw_hash_object = hash_object || {}
      @hash_object     = IdiomaticRubyWrapper(hash_object)
    end

    # A unique ID generated by the device.
    #
    # @spec PCD2
    #
    def id
      attributes[:id]
    end

    # The DevicePlatform associated with the device.
    # Describes the platform the device uses, such as android or ios.
    #
    # @spec PCD6
    #
    # @return [String]
    #
    def platform
      attributes[:platform]
    end

    # The client ID the device is connected to Ably with.
    #
    # @spec PCD3
    #
    # @return [String]
    #
    def client_id
      attributes[:client_id]
    end

    # The DeviceFormFactor object associated with the device.
    # Describes the type of the device, such as phone or tablet.
    #
    # @spec PCD4
    #
    # @return [String]
    #
    def form_factor
      attributes[:form_factor]
    end

    def device_secret
      attributes[:device_secret]
    end

    %w(id platform form_factor client_id device_secret).each do |attribute|
      define_method "#{attribute}=" do |val|
        unless val.nil? || val.kind_of?(String)
          raise ArgumentError, "#{attribute} must be nil or a string value"
        end
        attributes[attribute.to_sym] = val
      end
    end

    # A JSON object of key-value pairs that contains metadata for the device.
    #
    # @spec PCD5
    #
    # @return [Hash, nil]
    #
    def metadata
      attributes[:metadata] || {}
    end

    def metadata=(val)
      unless val.nil? || val.kind_of?(Hash)
        raise ArgumentError, "metadata must be nil or a Hash value"
      end
      attributes[:metadata] = val
    end

    # The {Ably::Models::DevicePushDetails} object associated with the device.
    # Describes the details of the push registration of the device.
    #
    # @spec PCD7
    #
    # @return [Ably::Models::DevicePushDetails]
    #
    def push
      DevicePushDetails(attributes[:push] || {})
    end

    def push=(val)
      unless val.nil? || val.kind_of?(Hash) || val.kind_of?(Ably::Models::DevicePushDetails)
        raise ArgumentError, "push must be nil, a Hash value or a DevicePushDetails object"
      end
      attributes[:push] = DevicePushDetails(val)
    end

    def attributes
      @hash_object
    end
  end
end
