require 'faraday'

module Ably
  module Rest
    module Middleware
      class Logger < Faraday::Response::Middleware
        def on_complete(env)
          $stdout.puts "Received body: #{env.body}"
        end
      end
    end
  end
end
