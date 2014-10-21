require 'faraday'
require 'json'

module Ably
  module Rest
    module Middleware
      class ParseJson < Faraday::Response::Middleware
        def on_complete(env)
          env.body = parse(env.body) unless env.response_headers['Ably-Middleware-Parsed'] == true
        end

        def parse(body)
          JSON.parse(body)
        rescue JSON::ParserError => e
          raise Ably::Exceptions::InvalidResponseBody, "Expected JSON response: #{e.message}"
        end
      end
    end
  end
end
