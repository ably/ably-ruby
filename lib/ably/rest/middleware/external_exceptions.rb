# frozen_string_literal: true

require "faraday"

module Ably
  module Rest
    module Middleware
      # HTTP exceptions raised due to a status code error on a 3rd party site
      # Used by auth calls
      class ExternalExceptions < Faraday::Middleware
        def on_complete(env)
          return unless env.status >= 400

          error_status_code = env.status
          message = "Error #{error_status_code}: #{(env.body || "")[0...200]}"

          raise Ably::Exceptions::ServerError, message if error_status_code >= 500

          raise Ably::Exceptions::InvalidRequest, message
        end
      end
    end
  end
end
