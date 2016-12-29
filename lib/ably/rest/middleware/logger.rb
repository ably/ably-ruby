require 'faraday'

module Ably
  module Rest
    module Middleware
      class Logger < Faraday::Response::Middleware
        extend Forwardable

        def initialize(app, logger = nil)
          super(app)
          @logger = logger || begin
            require 'logger'
            ::Logger.new(STDOUT)
          end
        end

        def_delegators :@logger, :debug, :info, :warn, :error, :fatal

        def call(env)
          debug { "=> URL: #{env.method} #{env.url}, Headers: #{dump_headers env.request_headers}" }
          debug { "=> Body: #{body_for(env)}" }
          super
        end

        def on_complete(env)
          debug "<= Status: #{env.status}, Headers: #{dump_headers env.response_headers}"
          debug "<= Body: #{body_for(env)}"
        end

        private
        def dump_headers(headers)
          headers.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
        end

        def body_for(env)
          return '' if !env.body || env.body.empty?

          if env.request_headers['Content-Type'] == 'application/x-msgpack'
            MessagePack.unpack(env.body)
          else
            env.body
          end

        rescue StandardError
          readable_body(env.body)
        end

        def readable_body(body)
          if body.respond_to?(:encoding) && body.encoding == Encoding::ASCII_8BIT
            body.unpack('H*')
          else
            body
          end
        end
      end
    end
  end
end
