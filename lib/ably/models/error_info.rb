module Ably::Modules
  module Conversions
    private
    # Convert error_details argument to a {ErrorInfo} object
    #
    # @param error_details [ErrorInfo,Hash] Error info attributes
    #
    # @return [ErrorInfo]
    def ErrorInfo(error_details)
      case error_details
      when Ably::Models::ErrorInfo
        error_details
      else
        Ably::Models::ErrorInfo.new(error_details)
      end
    end
  end
end

module Ably::Models
  # An exception type encapsulating error information containing
  # an Ably-specific error code and generic status code.
  #
  # @!attribute [r] message
  #   @return [String] Additional reason information, where available
  # @!attribute [r] code
  #   @return [Integer] Ably error code (see ably-common/protocol/errors.json)
  # @!attribute [r] status
  #   @return [Integer] HTTP Status Code corresponding to this error, where applicable
  # @!attribute [r] attributes
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class ErrorInfo < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    def initialize(hash_object)
      @raw_hash_object = hash_object
      @hash_object     = IdiomaticRubyWrapper(hash_object.clone.freeze)
    end

    %w(message code href status_code).each do |attribute|
      define_method attribute do
        attributes[attribute.to_sym]
      end
    end
    alias_method :status, :status_code

    def attributes
      @hash_object
    end

    def to_s
      error_href = href || (code ? "https://help.ably.io/error/#{code}" : '')
      see_msg = " -> see #{error_href} for help" unless message.to_s.include?(error_href.to_s)
      "<Error: #{message} (code: #{code}, http status: #{status})>#{see_msg}"
    end
  end
end
