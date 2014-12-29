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

    # The token is invalid
    class InvalidToken < BaseAblyException; end

    # Ably Protocol message received that is invalid
    class ProtocolError < BaseAblyException; end

    # Encryption or Decryption failure
    class CipherError < BaseAblyException; end

    # Encoding or decoding failure
    class EncoderError < BaseAblyException; end

    # Connection error
    class ConnectionError < BaseAblyException; end

    # Invalid Connection State Change error
    class ConnectionStateChangeError < BaseAblyException; end

    # A generic Ably exception taht supports a status & code.
    # See https://github.com/ably/ably-common/blob/master/protocol/errors.json for a list of Ably errors
    class Standard < BaseAblyException; end

    # The HTTP request has returned a 500 error
    class ServerError < StandardError; end

    # PaginatedResource cannot retrieve the page
    class InvalidPageError < StandardError; end

    # The expected response from the server was invalid
    class InvalidResponseBody < StandardError; end

    # The request cannot be performed because it is insecure
    class InsecureRequestError < StandardError; end

    # The token request could not be created
    class TokenRequestError < StandardError; end
  end
end
