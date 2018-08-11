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
        rescue MessagePack::UnknownExtTypeError => e
          raise Ably::Exceptions::InvalidResponseBody, "MessagePack::UnknownExtTypeError body could not be decoded: #{e.message}. Got Base64:\n#{base64_body(body)}"
        rescue MessagePack::MalformedFormatError => e
          raise Ably::Exceptions::InvalidResponseBody, "MessagePack::MalformedFormatError body could not be decoded: #{e.message}. Got Base64:\n#{base64_body(body)}"
        end

        def base64_body(body)
          Base64.encode64(body)
        rescue => err
          "[#{err.message}! Could not base64 encode body: '#{body}']"
        end
      end
    end
  end
end
