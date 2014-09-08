require "json"

module Ably
  module Rest
    module Middleware
      class Exceptions < Faraday::Response::Middleware
        def call(env)
          @app.call(env).on_complete do
            if env[:status] >= 400
              error_status_code = nil
              error_code = nil

              begin
                error = JSON.parse(env[:body])['error']
                error_status_code = error['statusCode'].to_i if error['statusCode']
                error_code = error['code'].to_i if error['code']

                if error
                  message = "#{error['message']} (status: #{error_status_code}, code: #{error_code})"
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
                raise Ably::InvalidRequest.new(message, status: error_status_code, code: error_code)
              end
            end
          end
        end
      end
    end
  end
end
