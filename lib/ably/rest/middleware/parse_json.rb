require "json"

module Ably
  module Rest
    module Middleware
      class ParseJson < Faraday::Response::Middleware
        def parse(body)
          JSON.parse(body)
        end
      end
    end
  end
end
