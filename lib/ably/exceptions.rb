module Ably
  module Exceptions
    # Base Ably exception class that contains status and code values used by Ably
    # Refer to https://github.com/ably/ably-common/blob/master/protocol/errors.json
    #
    # @!attribute [r] message
    #   @return [String] Error message from Ably
    # @!attribute [r] status
    #   @return [String] HTTP status code of error
    # @!attribute [r] code
    #   @return [String] Ably specific error code
    class BaseAblyException < StandardError
      attr_reader :status, :code
      def initialize(message, status = nil, code = nil)
        super message
        @status = status
        @code = code
      end
    end

    # An invalid request was received by Ably
    class InvalidRequest < BaseAblyException; end

    # Ably Protocol message received that is invalid
    class ProtocolError < BaseAblyException; end

    # Encryption or Decryption failure
    class CipherError < BaseAblyException; end

    # Encoding or decoding failure
    class EncoderError < BaseAblyException; end

    # Connection error from Realtime or REST service
    class ConnectionError < BaseAblyException
      def initialize(message, status = nil, code = nil, base_error = nil)
        super message, status, code
        @base_error = base_error
      end
    end

    # Connection Timeout accessing Realtime or REST service
    class ConnectionTimeoutError < ConnectionError; end

    # Connection closed unexpectedly
    class ConnectionClosedError < ConnectionError; end

    # Invalid State Change error on a {https://github.com/gocardless/statesman Statesman State Machine}
    class StateChangeError < BaseAblyException; end

    # The state of the object is not suitable for this operation
    class IncompatibleStateForOperation < BaseAblyException; end

    # A generic Ably exception taht supports a status & code.
    # See https://github.com/ably/ably-common/blob/master/protocol/errors.json for a list of Ably errors
    class Standard < BaseAblyException; end

    # The HTTP request has returned a 500 error
    class ServerError < BaseAblyException; end

    # PaginatedResult cannot retrieve the page
    class InvalidPageError < BaseAblyException; end

    # The expected response from the server was invalid
    class InvalidResponseBody < BaseAblyException; end

    # The request cannot be performed because it is insecure
    class InsecureRequestError < BaseAblyException; end

    # The token request could not be created
    class TokenRequestError < BaseAblyException; end

    # The token has expired
    class TokenExpired < BaseAblyException; end

    # The message could not be delivered to the server
    class MessageDeliveryError < BaseAblyException; end

    # The data payload type is not supported
    class UnsupportedDataTypeError < BaseAblyException; end
  end
end
