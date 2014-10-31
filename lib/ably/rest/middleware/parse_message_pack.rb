require 'faraday'
require 'msgpack'

module Ably
  module Rest
    module Middleware
      class ParseMessagePack < Faraday::Response::Middleware
        def on_complete(env)
          if env.response_headers['Content-Type'] == 'application/x-msgpack'
            env.body = parse(env.body) unless env.response_headers['Ably-Middleware-Parsed'] == true
            env.response_headers['Ably-Middleware-Parsed'] = true
          end
        end

        def parse(body)
          if body.length > 0
            MessagePack.unpack(body)
          else
            body
          end
        rescue MessagePack::MalformedFormatError => e
          raise Ably::Exceptions::InvalidResponseBody, "Expected MessagePack response: #{e.message}"
        end
      end
    end
  end
end
