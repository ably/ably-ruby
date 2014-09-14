require "json"
require "faraday"

require "ably/rest/middleware/exceptions"
require "ably/rest/middleware/parse_json"

module Ably
  module Rest
    # Wrapper for the Ably REST API
    class Client
      include Ably::Support

      DOMAIN = "rest.ably.io"

      attr_reader :token, :token_id, :tls, :key_id, :key_secret, :client_id

      def initialize(options)
        unless options.has_key?(:token)
          raise ArgumentError, "api_key is missing" unless options.has_key?(:api_key)
          raise ArgumentError, "api_key is invalid" unless options[:api_key].to_s.match(/[\w_-]+\.[\w_-]+:[\w_-]+/)
        end

        @key_id, @key_secret = options[:api_key].split(':') if options[:api_key]
        @token_id            = options[:token]
        @client_id           = options[:client_id]
        @tls                 = options[:tls] || true
        @environment         = options[:environment] # nil is production
        @debug_http          = options[:debug_http]
      end

      # Perform an HTTP GET request to the API
      def get(path, params = {}, options = {})
        request(:get, path, params, options)
      end

      # Perform an HTTP POST request to the API
      def post(path, params, options = {})
        request(:post, path, params, options)
      end

      # Return a REST Channel for the given name
      #
      # @param name [String] The name of the channel
      # @return [Ably::Rest::Channel]
      def channel(name)
        @channels ||= {}
        @channels[name] ||= Ably::Rest::Channel.new(self, name)
      end

      # Return the stats for the application
      #
      # @return [Array] An Array of hashes representing the stats
      def stats(params = {})
        default_params = {
          :direction => :forwards,
          :by        => :minute
        }

        response = get("/stats", default_params.merge(params))

        response.body
      end

      # Return the Ably service time
      #
      # @return [Time] The time as reported by the Ably service
      def time
        response = get('/time', {}, send_auth_header: false)

        Time.at(response.body.first / 1000.0)
      end

      def auth
        @auth ||= Auth.new(self)
      end

      def use_tls?
        @tls == true
      end

      def endpoint
        URI::Generic.build(
          scheme: use_tls? ? "https" : "http",
          host:   [@environment, DOMAIN].compact.join('-')
        )
      end

      private
      def request(method, path, params = {}, options = {})
        connection.send(method, path, params) do |request|
          unless options[:send_auth_header] == false
            request.headers[:authorization] = auth_header
          end
        end
      end

      # Return a Faraday::Connection to use to make HTTP requests
      #
      # @return [Faraday::Connection]
      def connection
        @connection ||= Faraday.new(endpoint.to_s, connection_options)
      end

      # Return a Hash of connection options to initiate the Faraday::Connection with
      #
      # @return [Hash]
      def connection_options
        @connection_options ||= {
          builder: middleware,
          headers: {
            accept:     "application/json",
            user_agent: user_agent
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
        @middleware ||= Faraday::RackBuilder.new do |builder|
          # Convert request params to "www-form-urlencoded"
          builder.use Faraday::Request::UrlEncoded

          # Parse JSON response bodies
          builder.use Ably::Rest::Middleware::ParseJson

          # Log HTTP requests if debug_http option set
          builder.response :logger if @debug_http

          # Raise exceptions if response code is invalid
          builder.use Ably::Rest::Middleware::Exceptions

          # Set Faraday's HTTP adapter
          builder.adapter Faraday.default_adapter
        end
      end

      def auth_header
        if token_id
          token_auth_header
        else
          if @client_id
            @token = auth.request_token
            token_auth_header
          else
            basic_auth_header
          end
        end
      end

      def token_id
        (@token && @token.id) || @token_id
      end

      def basic_auth_header
        "Basic #{encode64("#{@key_id}:#{@key_secret}")}"
      end

      def token_auth_header
        "Bearer #{encode64(token_id)}"
      end
    end
  end
end
