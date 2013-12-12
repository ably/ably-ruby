require "json"

module Ably
  module Rest
    module Middleware
      class ParseJson < Faraday::Response::Middleware
        def parse(body)
          JSON.parse(body, symbolize_names: true)
        end
      end
    end
  end
end
