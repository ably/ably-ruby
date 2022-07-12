# frozen_string_literal: true

require 'faraday'
require 'json'

module Ably
  module Rest
    module Middleware
      # ParseJson provides the top-level class to be instanced for the Ably library
      #
      class ParseJson < Faraday::Middleware
        def on_complete(env)
          return unless env.response_headers['Content-Type'] == 'application/json'

          env.body = parse(env.body) unless env.response_headers['Ably-Middleware-Parsed'] == true
          env.response_headers['Ably-Middleware-Parsed'] = true
        end

        def parse(body)
          if body.empty?
            body
          else
            JSON.parse(body)
          end
        rescue JSON::ParserError => e
          raise Ably::Exceptions::InvalidResponseBody, "Expected JSON response: #{e.message}"
        end
      end
    end
  end
end
