require 'faraday'
require 'json'

module Ably
  module Rest
    module Middleware
      # Encode the body of the message according to the mime type
      class Encoder < ::Faraday::Response::Middleware
        CONTENT_TYPE = 'Content-Type'.freeze unless defined? CONTENT_TYPE

        def call(env)
          encode env if env.body
          @app.call env
        end

        private
        def encode(env)
          env.body = case request_type(env)
          when 'application/x-msgpack'
            to_msgpack(env.body)
          when 'application/json', '', nil
            env.request_headers[CONTENT_TYPE] = 'application/json'
            to_json(env.body)
          else
            env.body
          end
        end

        def to_msgpack(body)
          body.to_msgpack
        end

        def to_json(body)
          if body.kind_of?(String)
            body
          else
            body.to_json
          end
        end

        def request_type(env)
          type = env.request_headers[CONTENT_TYPE].to_s
          type = type.split(';', 2).first if type.index(';')
          type
        end
      end
    end
  end
end
