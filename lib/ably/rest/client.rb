require "json"
require "faraday"

require "ably/rest/middleware/exceptions"
require "ably/rest/middleware/parse_json"

module Ably
  module Rest
    # Client for the Ably REST API
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

      attr_reader :tls, :environment, :auth, :channels
      def_delegators :auth, :client_id, :auth_options

      # Creates a {Ably::Rest::Client Rest Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param [Hash,String] options an options Hash used to configure the client and the authentication, or String with an API key
      # @option options (see Ably::Auth#authorise)
      # @option options [Boolean] :tls          TLS is used by default, providing a value of false disbles TLS.  Please note Basic Auth is disallowed without TLS as secrets cannot be transmitted over unsecured connections.
      # @option options [String]  :api_key      API key comprising the key ID and key secret in a single string
      # @option options [String]  :environment  Specify 'sandbox' when testing the client library against an alternate Ably environment
      # @option options [Boolean] :debug_http   Send HTTP debugging information from Faraday for all HTTP requests to STDOUT
      #
      # @yield (see Ably::Auth#authorise)
      # @yieldparam (see Ably::Auth#authorise)
      # @yieldreturn (see Ably::Auth#authorise)
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
        options = options.dup

        if options.kind_of?(String)
          options = { api_key: options }
        end

        @tls                 = options.delete(:tls) == false ? false : true
        @environment         = options.delete(:environment) # nil is production
        @debug_http          = options.delete(:debug_http)

        @auth     = Auth.new(self, options, &auth_block)
        @channels = Ably::Rest::Channels.new(self)
      end

      # Return a REST {Ably::Rest::Channel} for the given name
      #
      # @param (see Ably::Rest::Channels#get)
      #
      # @return (see Ably::Rest::Channels#get)
      def channel(name, channel_options = {})
        channels.get(name, channel_options)
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
        reauthorise_on_authorisation_failure do
          connection.send(method, path, params) do |request|
            unless options[:send_auth_header] == false
              request.headers[:authorization] = auth.auth_header
            end
          end
        end
      end

      def reauthorise_on_authorisation_failure
        attempts = 0
        begin
          yield
        rescue Ably::Exceptions::InvalidRequest => e
          attempts += 1
          if attempts == 1 && e.code == 40140 && auth.token_renewable?
            auth.authorise force: true
            retry
          else
            raise Ably::Exceptions::InvalidToken.new(e.message, status: e.status, code: e.code)
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
