module Ably::Modules
  module Conversions
    private
    # Convert device_push_details argument to a {Ably::Models::DevicePushDetails} object
    #
    # @param device_push_details [Ably::Models::DevicePushDetails,Hash,nil] A device push notification details object
    #
    # @return [Ably::Models::DevicePushDetails]
    def DevicePushDetails(device_push_details)
      case device_push_details
      when Ably::Models::DevicePushDetails
        device_push_details
      else
        Ably::Models::DevicePushDetails.new(device_push_details)
      end
    end
  end
end

module Ably::Models
  # An object with the push notification details for {DeviceDetails} object
  #
  # @!attribute [r] transport_type
  #   @return [String] Transport type for push notifications such as gcm, apns, web
  # @!attribute [r] state
  #   @return [String] The current state of this push target such as Active, Failing or Failed
  # @!attribute [r] error_reason
  #   @return [ErrorInfo] If the state is Failing of Failed, this field may optionally contain a reason
  # @!attribute [r] metadata
  #   @return [Hash] Arbitrary metadata that can be associated with this object
  #
  class DevicePushDetails < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    # @param hash_object   [Hash,nil]  Device push detail attributes
    #a
    def initialize(hash_object = {})
      @raw_hash_object = hash_object || {}
      @hash_object     = IdiomaticRubyWrapper(@raw_hash_object)
    end

    %w(state).each do |attribute|
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

    def recipient
      attributes[:recipient] || {}
    end

    def recipient=(val)
      unless val.nil? || val.kind_of?(Hash)
        raise ArgumentError, "recipient must be nil or a Hash value"
      end
      attributes[:recipient] = val
    end

    def error_reason
      attributes[:error_reason]
    end

    def error_reason=(val)
      unless val.nil? || val.kind_of?(Hash) || val.kind_of?(Ably::Models::ErrorInfo)
        raise ArgumentError, "error_reason must be nil, a Hash value or a ErrorInfo object"
      end

      attributes[:error_reason] = if val.nil?
        nil
      else
        ErrorInfo(val)
      end
    end

    def attributes
      @hash_object
    end
  end
end
