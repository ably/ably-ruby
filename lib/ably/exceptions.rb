require 'ably/modules/exception_codes'

module Ably
  module Exceptions
    TOKEN_EXPIRED_CODE = 40140..40149

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
      attr_reader :status, :code, :request_id

      def initialize(message, status = nil, code = nil, base_exception = nil, options = {})
        super message

        @base_exception = base_exception
        @status = status
        @status ||= base_exception.status if base_exception && base_exception.respond_to?(:status)
        @status ||= options[:fallback_status]
        @code = code
        @code ||= base_exception.code if base_exception && base_exception.respond_to?(:code)
        @code ||= options[:fallback_code]
        @request_id ||= options[:request_id]
      end

      def to_s
        message = [super]
        if status || code
          additional_info = []
          additional_info << "code: #{code}" if code
          additional_info << "http status: #{status}" if status
          additional_info << "base exception: #{@base_exception.class}" if @base_exception
          additional_info << "request_id: #{request_id}" if request_id
          message << "(#{additional_info.join(', ')})"
          message << "-> see https://help.ably.io/error/#{code} for help" if code
        end
        message.join(' ')
      end

      def as_json(*args)
        {
          message: "#{self.class}: #{message}",
          status: @status,
          code: @code
        }.delete_if { |key, val| val.nil? }
      end
    end

    # An invalid request was received by Ably
    class InvalidRequest < BaseAblyException; end

    class InvalidCredentials < BaseAblyException; end

    # Similar to 403 Forbidden, but specifically for use when authentication is required and has failed or has not yet been provided
    class UnauthorizedRequest < BaseAblyException; end

    # The request was a valid request, but Ably is refusing to respond to it
    class ForbiddenRequest < BaseAblyException; end

    # The requested resource could not be found but may be available again in the future
    class ResourceMissing < BaseAblyException; end

    # Ably Protocol message received that is invalid
    class ProtocolError < BaseAblyException; end

    # Encryption or Decryption failure
    class CipherError < BaseAblyException; end

    # Encoding or decoding failure
    class EncoderError < BaseAblyException; end

    # Connection error from Realtime or REST service
    class ConnectionError < BaseAblyException
      def initialize(message, status = nil, code = nil, base_exception = nil, options = {})
        super message, status, code, base_exception, options
      end

      def to_s
        message = [super]
        if @base_exception
          message << "#{@base_exception}"
          if @base_exception.respond_to?(:message) && @base_exception.message.match(/certificate verify failed/i)
            message << "See https://goo.gl/eKvfcR to resolve this issue."
          end
        end
        message.join(' < ')
      end
    end

    # Connection Timeout accessing Realtime or REST service
    class ConnectionTimeout < ConnectionError; end

    # Transport closed unexpectedly
    class TransportClosed < ConnectionError; end

    # Connection closed unexpectedly
    class ConnectionClosed < ConnectionError; end

    # Connection suspended
    class ConnectionSuspended < ConnectionError; end

    # Connection failed
    class ConnectionFailed < ConnectionError; end

    class AuthenticationFailed < ConnectionError; end

    # Invalid State Change error on a {https://github.com/gocardless/statesman Statesman State Machine}
    class InvalidStateChange < BaseAblyException; end

    class InvalidState < BaseAblyException; end

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

    # The token has expired, 40140..40149
    class TokenExpired < BaseAblyException; end

    # The message could not be delivered to the server
    class MessageDeliveryFailed < BaseAblyException; end

    # The client has been configured to not queue messages i.e. only publish down an active connection
    class MessageQueueingDisabled < BaseAblyException; end

    # The data payload type is not supported
    class UnsupportedDataType < BaseAblyException; end

    # When a channel is detached / failed, certain operations are not permitted such as publishing messages
    class ChannelInactive < BaseAblyException; end

    class IncompatibleClientId < BaseAblyException
      def initialize(messages, status = 400, code = Ably::Exceptions::Codes::INVALID_CLIENT_ID, *args)
        super(message, status, code, *args)
      end
    end

    # Token request has missing or invalid attributes
    class InvalidTokenRequest < BaseAblyException; end

    class PushNotificationsNotSupported < BaseAblyException; end
  end
end
