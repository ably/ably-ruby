require "base64"
require "json"
require "faraday"

require "ably/rest/middleware/parse_json"

module Ably
  module Rest
    # Wrapper for the Ably REST API
    class Client
      def initialize(options)
        @api_key = options[:api_key]
      end

      # Perform an HTTP GET request to the API
      def get(path)
        request(:get, path)
      end

      # Perform an HTTP POST request to the API
      def post(path, params)
        request(:post, path, params)
      end

      # Return a Channel for the given name
      #
      # @param name [String] The name of the channel
      # @return [Ably::Rest::Channel]
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

      # Return a Faraday::Connection to use to make HTTP requests
      #
      # @return [Faraday::Connection]
      def connection
        @connection ||= Faraday.new(Ably::Rest.api_endpoint, connection_options)
      end

      # Return a Hash of connection options to initiate the Faraday::Connection with
      #
      # @return [Hash]
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

      # Return a Faraday middleware stack to initiate the Faraday::Connection with
      #
      # @see http://mislav.uniqpath.com/2011/07/faraday-advanced-http/
      def middleware
        @middleware ||= Faraday::Builder.new do |builder|
          # Convert request params to "www-form-urlencoded"
          builder.use Faraday::Request::UrlEncoded

          # Parse JSON response bodies
          builder.use Ably::Rest::Middleware::ParseJson

          # Set Faraday's HTTP adapter
          builder.adapter Faraday.default_adapter
        end
      end

      def encode64(text)
        Base64.encode64(text).gsub("\n", '')
      end
    end
  end
end
