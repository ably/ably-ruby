require "json"

module Ably
  module Rest
    module Middleware
      class ParseJson < Faraday::Response::Middleware
        def parse(body)
          JSON.parse(body, symbolize_names: true)
        rescue JSON::ParserError => e
          raise InvalidResponseBody, "Expected JSON response. #{e.message}"
        end
      end
    end
  end
end
