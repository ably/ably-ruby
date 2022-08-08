# frozen_string_literal: true

require "faraday"
require "json"

module Ably
  module Rest
    module Middleware
      # FailIfUnsupportedMimeType provides the top-level class to be instanced for the Ably library
      #
      class FailIfUnsupportedMimeType < Faraday::Middleware
        def on_complete(env)
          return if env.response_headers["Ably-Middleware-Parsed"] == true
          # Ignore empty body with success status code for no body response
          return if env.body.to_s.empty? && env.status == 204

          raise Ably::Exceptions::InvalidResponseBody, "Content Type #{env.response_headers["Content-Type"]} is not supported by this client library" unless (500..599).cover?(env.status)
        end
      end
    end
  end
end
