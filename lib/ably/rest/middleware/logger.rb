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
          debug "=> Body: #{env.body}"
          super
        end

        def on_complete(env)
          debug "<= Status: #{env.status}, Headers: #{dump_headers env.response_headers}"
          debug "<= Body: #{env.body}"
        end

        private
        def dump_headers(headers)
          headers.map { |k, v| "#{k}: #{v.inspect}" }.join(", ")
        end
      end
    end
  end
end
