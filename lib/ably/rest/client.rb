require "json"
require "faraday"

require "ably/rest/middleware/exceptions"
require "ably/rest/middleware/parse_json"

module Ably
  module Rest
    # Wrapper for the Ably REST API
    #
    # @!attribute [r] auth
    #   @return {Ably::Auth} authentication object configured for this connection
    # @!attribute [r] client_id
    #   @return [String] A client ID, used for identifying this client for presence purposes
    # @!attribute [r] auth_options
    #   @return [Hash] {Ably::Auth} options configured for this client
    # @!attribute [r] tls
    #   @return [Boolean] True if client is configured to use TLS for all Ably communication
    # @!attribute [r] environment
    #   @return [String] May contain 'sandbox' when testing the client library against an alternate Ably environment
    class Client
      include Ably::Support
      extend Forwardable

      DOMAIN = "rest.ably.io"

      attr_reader :tls, :environment, :auth
      def_delegator :auth, :client_id, :auth_options

      # Creates a {Ably::Rest::Client Rest Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param [Hash,String] options an options Hash used to configure the client and the authentication, or String with an API key
      # @option options [Boolean] :tls          TLS is used by default, providing a value of false disbles TLS.  Please note Basic Auth is disallowed without TLS as secrets cannot be transmitted over unsecured connections.
      # @option options [String]  :api_key      API key comprising the key ID and key secret in a single string
      # @option options [String]  :key_id       key ID for the designated application (defaults to client key_id)
      # @option options [String]  :key_secret   key secret for the designated application used to sign token requests (defaults to client key_secret)
      # @option options [String]  :client_id    client ID identifying this connection to other clients (defaults to client client_id if configured)
      # @option options [String]  :auth_url     a URL to be used to GET or POST a set of token request params, to obtain a signed token request.
      # @option options [Hash]    :auth_headers a set of application-specific headers to be added to any request made to the authUrl
      # @option options [Hash]    :auth_params  a set of application-specific query params to be added to any request made to the authUrl
      # @option options [Symbol]  :auth_method  HTTP method to use with auth_url, must be either `:get` or `:post` (defaults to :get)
      # @option options [Integer] :ttl          validity time in seconds for the requested {Ably::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
      # @option options [Hash]    :capability   canonicalised representation of the resource paths and associated operations
      # @option options [Boolean] :query_time   when true will query the {https://ably.io Ably} system for the current time instead of using the local time
      # @option options [Integer] :timestamp    the time of the of the request in seconds since the epoch
      # @option options [String]  :nonce        an unquoted, unescaped random string of at least 16 characters
      # @option options [String]  :environment  Specify 'sandbox' when testing the client library against an alternate Ably environment
      # @option options [Boolean] :debug_http   Send HTTP debugging information from Faraday for all HTTP requests to STDOUT
      #
      # @yield [options] (optional) if an auth block is passed to this method, then this block will be called to create a new token request object
      # @yieldparam [Hash] options options passed to request_token will be in turn sent to the block in this argument
      # @yieldreturn [Hash] valid token request object, see {#create_token_request}
      #
      # @return [Ably::Rest::Client]
      #
      # @example
      #    # create a new client authenticating with basic auth
      #    client = Ably::Rest::Client.new('key.id:secret')
      #
      #    # create a new client and configure a client ID used for presence
      #    client = Ably::Rest::Client.new(api_key: 'key.id:secret', client_id: 'john')
      #
      def initialize(options, &auth_block)
        if options.kind_of?(String)
          options = { api_key: options }
        end

        @tls                 = options.delete(:tls) == false ? false : true
        @environment         = options.delete(:environment) # nil is production
        @debug_http          = options.delete(:debug_http)

        @auth = Auth.new(self, options, &auth_block)
      end

      # Return a REST {Ably::Rest::Channel} for the given name
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

      # True if client is configured to use TLS for all Ably communication
      #
      # @return [Boolean]
      def use_tls?
        @tls == true
      end

      # Perform an HTTP GET request to the API using configured authentication
      #
      # @return [Faraday::Response]
      def get(path, params = {}, options = {})
        request(:get, path, params, options)
      end

      # Perform an HTTP POST request to the API using configured authentication
      #
      # @return [Faraday::Response]
      def post(path, params, options = {})
        request(:post, path, params, options)
      end

      # Default Ably REST endpoint used for all requests
      #
      # @return [URI::Generic]
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
            request.headers[:authorization] = auth.auth_header
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
    end
  end
end
