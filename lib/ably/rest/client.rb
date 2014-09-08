require "base64"
require "securerandom"
require "json"
require "faraday"

require "ably/token"
require "ably/rest/middleware/exceptions"
require "ably/rest/middleware/parse_json"

module Ably
  module Rest
    # Wrapper for the Ably REST API
    class Client
      DOMAIN = "rest.ably.io"

      TOKEN_DEFAULTS = {
        capability: { "*" => ["*"] },
        ttl:        1 * 60 * 60
      }

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

      # Request a Token which can be used to make authenticated requests
      def request_token(params = {})
        params = {
          id:         @key_id,
          client_id:  @client_id,
          ttl:        TOKEN_DEFAULTS[:ttl],
          timestamp:  Time.now.to_i,
          capability: TOKEN_DEFAULTS[:capability],
          nonce:      SecureRandom.hex
        }.merge(params)

        if params[:capability].is_a?(Hash)
          params[:capability] = params[:capability].to_json
        end

        params[:mac] = sign_params(params, @key_secret)

        response = post("/keys/#{@key_id}/requestToken", params, send_auth_header: false)

        Ably::Token.new(response.body[:access_token])
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
            @token = request_token
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

      def encode64(text)
        Base64.encode64(text).gsub("\n", '')
      end

      # Sign the request params using the secret
      def sign_params(params, secret)
        text = params.values_at(
          :id,
          :ttl,
          :capability,
          :client_id,
          :timestamp,
          :nonce
        ).map { |t| "#{t}\n" }.join("")

        encode64(
          Digest::HMAC.digest(text, secret, Digest::SHA256)
        )
      end
    end
  end
end
