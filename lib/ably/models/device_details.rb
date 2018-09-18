module Ably::Modules
  module Conversions
    private
    # Convert device_details argument to a {Ably::Models::DeviceDetails} object
    #
    # @param device_details [Ably::Models::DeviceDetails,Hash,nil] A device details object
    #
    # @return [Ably::Models::DeviceDetails]
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
  # An object representing a devices details, used currently for push notifications
  #
  # @!attribute [r] id
  #   @return [String] Unique device identifier assigned randomly by the device
  # @!attribute [r] platform
  #   @return [String] Device platform such as android, ios or browser
  # @!attribute [r] form_factor
  #   @return [String] Device form factor such as phone, tablet, watch
  # @!attribute [r] client_id
  #   @return [String] The authenticated client identifier for this device. See {https://www.ably.io/documentation/general/authentication#identified-clients auth documentation}.
  # @!attribute [r] metadata
  #   @return [Hash] Arbitrary metadata that can be associated with a device
  # @!attribute [r] device_secret
  #   @return [String] This secret is used internally by Ably client libraries to authenticate with Ably when push registration updates are required such as when the GCM token expires and needs renewing
  # @!attribute [r] push
  #   @return [DevicePushDetails] The push notification specific properties for this device allowing push notifications to be delivered to the device
  #
  class DeviceDetails < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    # @param hash_object   [Hash,nil]  Device detail attributes
    #a
    def initialize(hash_object = {})
      @raw_hash_object = hash_object || {}
      @hash_object     = IdiomaticRubyWrapper(hash_object)
    end

    %w(id platform form_factor client_id device_secret).each do |attribute|
      define_method attribute do
        attributes[attribute.to_sym]
      end

      define_method "#{attribute}=" do |val|
        unless val.nil? || val.kind_of?(String)
          raise ArgumentError, "#{attribute} must be nil or a string value"
        end
        attributes[attribute.to_sym] = val
      end
    end

    def metadata
      attributes[:metadata] || {}
    end

    def metadata=(val)
      unless val.nil? || val.kind_of?(Hash)
        raise ArgumentError, "metadata must be nil or a Hash value"
      end
      attributes[:metadata] = val
    end

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
