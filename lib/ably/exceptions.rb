module Ably
  module Exceptions
    # An invalid request was received by Ably
    #
    # @!attribute [r] message
    #   @return [String] Error message from Ably
    # @!attribute [r] status
    #   @return [String] HTTP status code of error
    # @!attribute [r] code
    #   @return [String] Ably specific error code
    class InvalidRequest < StandardError
      attr_reader :status, :code
      def initialize(message, status: nil, code: nil)
        super message
        @status = status
        @code = code
      end
    end

    # The HTTP request has returned a 500 error
    class ServerError < StandardError; end

    # PagedResource cannot retrieve the page
    class InvalidPageError < StandardError; end

    # The expected response from the server was invalid
    class InvalidResponseBody < StandardError; end

    # The request cannot be performed because it is insecure
    class InsecureRequestError < StandardError; end

    # The token request could not be created
    class TokenRequestError < StandardError; end

    # The token is invalid
    class InvalidToken < InvalidRequest; end
  end
end
