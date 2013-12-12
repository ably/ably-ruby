require "base64"
require "json"
require "faraday"

require "ably/rest/middleware/parse_json"

module Ably
  module Rest
    class Client
      def initialize(options)
        @api_key = options[:api_key]
      end

      def get(path)
        request(:get, path)
      end

      def post(path, params)
        request(:post, path, params)
      end

      def channel(name)
        @channels ||= {}
        @channels[name] ||= Channel.new(self, name)
      end

      private
      def request(method, path, params = {})
        connection.send(method, path, params) do |request|
          request.headers[:authorization] = "Basic #{encode64(@api_key)}"
        end
      end

      def connection
        @connection ||= Faraday.new(Ably::Rest.api_endpoint, connection_options)
      end

      def connection_options
        @connection_options ||= {
          builder: middleware,
          headers: {
            accept:     "appliation/json",
            user_agent: "Ably Ruby client #{Ably::VERSION}"
          },
          request: {
            open_timeout: 5,
            timeout:      10
          }
        }
      end

      def middleware
        @middleware ||= Faraday::Builder.new do |builder|
          builder.use Faraday::Request::UrlEncoded
          builder.use Ably::Rest::Middleware::ParseJson
          builder.adapter Faraday.default_adapter
        end
      end

      def encode64(text)
        Base64.encode64(text).gsub("\n", '')
      end
    end
  end
end
