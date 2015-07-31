require 'faraday'
require 'json'

module Ably
  module Rest
    module Middleware
      class FailIfUnsupportedMimeType < Faraday::Response::Middleware
        def on_complete(env)
          unless env.response_headers['Ably-Middleware-Parsed'] == true
            unless  (500..599).include?(env.status)
              raise Ably::Exceptions::InvalidResponseBody,
                    "Content Type #{env.response_headers['Content-Type']} is not supported by this client library"
            end
          end
        end
      end
    end
  end
end
