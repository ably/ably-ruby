require "json"

module Ably
  module Rest
    module Middleware
      class Exceptions < Faraday::Response::Middleware
       def call(env)
          @app.call(env).on_complete do
            if env[:status] >= 400
              begin
                error = JSON.parse(env[:body])['error']
                if error
                  message = "#{error['message']} (status: #{error['statusCode']}, code: #{error['code']})"
                else
                  message = env[:body]
                end
              rescue JSON::ParserError
                message = env[:body]
              end

              message = "Unknown server error" if message.to_s.strip == ''

              if env[:status] >= 500
                raise Ably::ServerError, message
              else
                raise Ably::InvalidRequest, message
              end
            end
          end
        end
      end
    end
  end
end
