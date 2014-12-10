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
          debug "=> URL: #{env.method} #{env.url}, Headers: #{dump_headers env.request_headers}"
          debug ">= Body: #{body_for(env)}"
          @app.call env
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
          "Error displaying body: (as hex) '#{env.body.unpack('H*')}'"
        end
      end
    end
  end
end
