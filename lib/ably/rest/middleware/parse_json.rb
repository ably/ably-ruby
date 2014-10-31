require 'faraday'
require 'json'

module Ably
  module Rest
    module Middleware
      class ParseJson < Faraday::Response::Middleware
        def on_complete(env)
          if env.response_headers['Content-Type'] == 'application/json'
            env.body = parse(env.body) unless env.response_headers['Ably-Middleware-Parsed'] == true
            env.response_headers['Ably-Middleware-Parsed'] = true
          end
        end

        def parse(body)
          if body.length > 0
            JSON.parse(body)
          else
            body
          end
        rescue JSON::ParserError => e
          raise Ably::Exceptions::InvalidResponseBody, "Expected JSON response: #{e.message}"
        end
      end
    end
  end
end
