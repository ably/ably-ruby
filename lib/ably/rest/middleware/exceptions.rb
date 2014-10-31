require "json"

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

            message = "Unknown server error" if message.to_s.strip == ''

            if env.status >= 500
              raise Ably::Exceptions::ServerError, message
            else
              raise Ably::Exceptions::InvalidRequest.new(message, error_status_code, error_code)
            end
          end
        end
      end
    end
  end
end
