module Ably::Realtime::Models
  # An exception type encapsulating error information containing
  # an Ably-specific error code and generic status code.
  #
  # @!attribute [r] message
  #   @return [String] Additional reason information, where available
  # @!attribute [r] code
  #   @return [Integer] Ably error code (see ably-common/protocol/errors.json)
  # @!attribute [r] status
  #   @return [Integer] HTTP Status Code corresponding to this error, where applicable
  # @!attribute [r] json
  #   @return [Hash] Access the protocol message Hash object ruby'fied to use symbolized keys
  #
  class ErrorInfo
    include Shared
    include Ably::Modules::Conversions

    def initialize(json_object)
      @raw_json_object = json_object
      @json_object     = rubify(@raw_json_object).freeze
    end

    %w( message code status ).each do |attribute|
      define_method attribute do
        json[attribute.to_sym]
      end
    end

    def json
      @json_object
    end
    alias_method :to_json, :json

    def to_s
      "Error: #{message} (code: #{code}, status: #{status})"
    end
  end
end
