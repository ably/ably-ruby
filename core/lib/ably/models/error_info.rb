module Ably::Modules
  module Conversions
    private
    # Convert error_details argument to a {ErrorInfo} object
    #
    # @param error_details [ErrorInfo,Hash] Error info attributes
    #
    # @return [ErrorInfo]
    #
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
  class ErrorInfo < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    def initialize(hash_object)
      @raw_hash_object = hash_object
      @hash_object     = IdiomaticRubyWrapper(hash_object.clone.freeze)
    end

    # Ably error code.
    #
    # @spec TI1
    #
    # @return [Integer]
    #
    def code
      attributes[:code]
    end

    # This is included for REST responses to provide a URL for additional help on the error code.
    #
    # @spec TI4
    #
    # @return [String]
    #
    def href
      attributes[:href]
    end

    # Additional message information, where available.
    #
    # @spec TI1
    #
    # @return [String]
    #
    def message
      attributes[:message]
    end

    # Information pertaining to what caused the error where available.
    #
    # @spec TI1
    #
    # @return [Ably::Models::ErrorInfo]
    #
    def cause
      attributes[:cause]
    end

    # HTTP Status Code corresponding to this error, where applicable.
    #
    # @spec TI1
    #
    # @return [Integer]
    #
    def status_code
      attributes[:status_code]
    end

    # If a request fails, the request ID must be included in the ErrorInfo returned to the user.
    #
    # @spec RSC7c
    #
    # @return [String]
    #
    def request_id
      attributes[:request_id]
    end
    alias_method :status, :status_code

    def attributes
      @hash_object
    end

    def to_s
      error_href = href || (code ? "https://help.ably.io/error/#{code}" : '')
      see_msg = " -> see #{error_href} for help" unless message.to_s.include?(error_href.to_s)
      "<Error: #{message} (code: #{code}, http status: #{status} request_id: #{request_id} cause: #{cause})>#{see_msg}"
    end
  end
end
