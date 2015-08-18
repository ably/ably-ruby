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

      def to_s
        message = [super]
        if status || code
          additional_info = []
          additional_info << "code: #{code}" if code
          additional_info << "http status: #{status}" if status
          message << "(#{additional_info.join(', ')})"
        end
        message.join(' ')
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

      def to_s
        message = [super]
        message << "#{@base_error}" if @base_error
        message.join(' < ')
      end
    end

    # Connection Timeout accessing Realtime or REST service
    class ConnectionTimeout < ConnectionError; end

    # Connection closed unexpectedly
    class ConnectionClosed < ConnectionError; end

    # Connection suspended
    class ConnectionSuspended < ConnectionError; end

    # Connection failed
    class ConnectionFailed < ConnectionError; end

    # Invalid State Change error on a {https://github.com/gocardless/statesman Statesman State Machine}
    class InvalidStateChange < BaseAblyException; end

    # A generic Ably exception taht supports a status & code.
    # See https://github.com/ably/ably-common/blob/master/protocol/errors.json for a list of Ably errors
    class Standard < BaseAblyException; end

    # The HTTP request has returned a 500 error
    class ServerError < BaseAblyException; end

    # PaginatedResult cannot retrieve the page
    class PageMissing < BaseAblyException; end

    # The expected response from the server was invalid
    class InvalidResponseBody < BaseAblyException; end

    # The request cannot be performed because it is insecure
    class InsecureRequest < BaseAblyException; end

    # The token request could not be created
    class TokenRequestFailed < BaseAblyException; end

    # The token has expired
    class TokenExpired < BaseAblyException; end

    # The message could not be delivered to the server
    class MessageDeliveryFailed < BaseAblyException; end

    # The client has been configured to not queue messages i.e. only publish down an active connection
    class MessageQueueingDisabled < BaseAblyException; end

    # The data payload type is not supported
    class UnsupportedDataType < BaseAblyException; end

    # When a channel is detached / failed, certain operations are not permitted such as publishing messages
    class ChannelInactive < BaseAblyException; end
  end
end
