module Ably::Modules
  module Conversions
    private
    # Convert device_push_details argument to a {Ably::Models::DevicePushDetails} object
    #
    # @param device_push_details [Ably::Models::DevicePushDetails,Hash,nil] A device push notification details object
    #
    # @return [Ably::Models::DevicePushDetails]
    #
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
  class DevicePushDetails < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    # @param hash_object   [Hash,nil]  Device push detail attributes
    #
    def initialize(hash_object = {})
      @raw_hash_object = hash_object || {}
      @hash_object     = IdiomaticRubyWrapper(@raw_hash_object)
    end

    # The current state of the push registration.
    #
    # @spec PCP4
    #
    # @return [Symbol]
    #
    def state
      attributes[:state]
    end

    def state=(val)
      unless val.nil? || val.kind_of?(String)
        raise ArgumentError, "#{attribute} must be nil or a string value"
      end
      attributes[:state] = val
    end

    # A JSON object of key-value pairs that contains of the push transport and address.
    #
    # @spec PCP3
    #
    # @return [Hash, nil]
    #
    def recipient
      attributes[:recipient] || {}
    end

    def recipient=(val)
      unless val.nil? || val.kind_of?(Hash)
        raise ArgumentError, "recipient must be nil or a Hash value"
      end
      attributes[:recipient] = val
    end

    # An {Ably::Models::ErrorInfo} object describing the most recent error when the state is Failing or Failed.
    #
    # @spec PCP2
    #
    # @return [Ably::Models::ErrorInfo]
    #
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
