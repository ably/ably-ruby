require 'faraday'
require 'json'

module Ably
  module Rest
    module Middleware
      # HTTP exceptions raised by Ably due to an error status code
      # Ably returns JSON/Msgpack error codes and messages so include this if possible in the exception messages
      class Exceptions < Faraday::Response::Middleware
        def on_complete(env)
          if env.status >= 400
            error_status_code = env.status
            error_code = nil

            if env.body.kind_of?(Hash)
              error = env.body.fetch('error', {})
              error_status_code = error['statusCode'].to_i if error['statusCode']
              error_code = error['code'].to_i if error['code']

              if error
                message = "#{error['message']} (status: #{error_status_code}, code: #{error_code})"
              else
                message = env.body
              end
            else
              message = env.body
            end

            message = 'Unknown server error' if message.to_s.strip == ''
            request_id = env.request.context[:request_id] if env.request.context
            exception_args = [message, error_status_code, error_code, nil, { request_id: request_id }]

            if env.status >= 500
              raise Ably::Exceptions::ServerError.new(*exception_args)
            elsif env.status == 401
              if Ably::Exceptions::TOKEN_EXPIRED_CODE.include?(error_code)
                raise Ably::Exceptions::TokenExpired.new(*exception_args)
              else
                raise Ably::Exceptions::UnauthorizedRequest.new(*exception_args)
              end
            elsif env.status == 403
              raise Ably::Exceptions::ForbiddenRequest.new(*exception_args)
            elsif env.status == 404
              raise Ably::Exceptions::ResourceMissing.new(*exception_args)
            else
              raise Ably::Exceptions::InvalidRequest.new(*exception_args)
            end
          end
        end
      end
    end
  end
end
