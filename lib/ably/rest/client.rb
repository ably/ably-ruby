require 'faraday'
require 'json'
require 'logger'
require 'uri'

require 'ably/rest/middleware/exceptions'

module Ably
  module Rest
    # Client for the Ably REST API
    #
    # @!attribute [r] client_id
    #   @return [String] A client ID, used for identifying this client for presence purposes
    # @!attribute [r] auth_options
    #   @return [Hash] {Ably::Auth} options configured for this client
    #
    class Client
      include Ably::Modules::Conversions
      include Ably::Modules::HttpHelpers
      extend Forwardable

      # Default Ably domain for REST
      DOMAIN = 'rest.ably.io'

      # Configuration for HTTP timeouts and HTTP request reattempts to fallback hosts
      HTTP_DEFAULTS = {
        open_timeout:       4,
        request_timeout:    10,
        max_retry_duration: 15,
        max_retry_count:    3
      }.freeze

      FALLBACK_RETRY_TIMEOUT = 10 * 60

      def_delegators :auth, :client_id, :auth_options

      # Custom environment to use such as 'sandbox' when testing the client library against an alternate Ably environment
      # @return [String]
      attr_reader :environment

      # The protocol configured for this client, either binary `:msgpack` or text based `:json`
      # @return [Symbol]
      attr_reader :protocol

      # {Ably::Auth} authentication object configured for this connection
      # @return [Ably::Auth]
      attr_reader :auth

      # The collection of {Ably::Rest::Channel}s that have been created
      # @return [Aby::Rest::Channels]
      attr_reader :channels

      # Log level configured for this {Client}
      # @return [Logger::Severity]
      attr_reader :log_level

      # The custom host that is being used if it was provided with the option +:rest_host+ when the {Client} was created
      # @return [String,Nil]
      attr_reader :custom_host

      # The custom port for non-TLS requests if it was provided with the option +:port+ when the {Client} was created
      # @return [Integer,Nil]
      attr_reader :custom_port

      # The custom TLS port for TLS requests if it was provided with the option +:tls_port+ when the {Client} was created
      # @return [Integer,Nil]
      attr_reader :custom_tls_port

      # The immutable configured HTTP defaults for this client.
      # See {#initialize} for the configurable HTTP defaults prefixed with +http_+
      # @return [Hash]
      attr_reader :http_defaults

      # The registered encoders that are used to encode and decode message payloads
      # @return [Array<Ably::Models::MessageEncoder::Base>]
      # @api private
      attr_reader :encoders

      # The additional options passed to this Client's #initialize method not available as attributes of this class
      # @return [Hash]
      # @api private
      attr_reader :options

      # The list of fallback hosts to be used by this client
      # if empty or nil then fallback host functionality is disabled
      attr_reader :fallback_hosts

      # Whether the {Client} has to add a random identifier to the path of a request
      # @return [Boolean]
      attr_reader :add_request_ids

      # Retries are logged by default to warn and error. When true, retries are logged at info level
      # @return [Boolean]
      # @api private
      attr_reader :log_retries_as_info

      # True when idempotent publishing is enabled for all messages published via REST.
      # When this feature is enabled, the client library will add a unique ID to every published message (without an ID)
      # ensuring any failed published attempts (due to failures such as HTTP requests failing mid-flight) that are
      # automatically retried will not result in duplicate messages being published to the Ably platform.
      # Note: This is a beta unsupported feature!
      # @return [Boolean]
      attr_reader :idempotent_rest_publishing

      # Creates a {Ably::Rest::Client Rest Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param [Hash,String] options an options Hash used to configure the client and the authentication, or String with an API key or Token ID
      # @option options [Boolean]                 :tls                 (true) When false, TLS is disabled. Please note Basic Auth is disallowed without TLS as secrets cannot be transmitted over unsecured connections.
      # @option options [String]                  :key                 API key comprising the key name and key secret in a single string
      # @option options [String]                  :token               Token string or {Models::TokenDetails} used to authenticate requests
      # @option options [String]                  :token_details       {Models::TokenDetails} used to authenticate requests
      # @option options [Boolean]                 :use_token_auth      Will force Basic Auth if set to false, and Token auth if set to true
      # @option options [String]                  :environment         Specify 'sandbox' when testing the client library against an alternate Ably environment
      # @option options [Symbol]                  :protocol            (:msgpack) Protocol used to communicate with Ably, :json and :msgpack currently supported
      # @option options [Boolean]                 :use_binary_protocol (true) When true will use the MessagePack binary protocol, when false it will use JSON encoding. This option will overide :protocol option
      # @option options [Logger::Severity,Symbol] :log_level           (Logger::WARN) Log level for the standard Logger that outputs to STDOUT. Can be set to :fatal (Logger::FATAL), :error (Logger::ERROR), :warn (Logger::WARN), :info (Logger::INFO), :debug (Logger::DEBUG) or :none
      # @option options [Logger]                  :logger              A custom logger can be used however it must adhere to the Ruby Logger interface, see http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html
      # @option options [String]                  :client_id           client ID identifying this connection to other clients
      # @option options [String]                  :auth_url            a URL to be used to GET or POST a set of token request params, to obtain a signed token request
      # @option options [Hash]                    :auth_headers        a set of application-specific headers to be added to any request made to the +auth_url+
      # @option options [Hash]                    :auth_params         a set of application-specific query params to be added to any request made to the +auth_url+
      # @option options [Symbol]                  :auth_method         (:get) HTTP method to use with +auth_url+, must be either +:get+ or +:post+
      # @option options [Proc]                    :auth_callback       when provided, the Proc will be called with the token params hash as the first argument, whenever a new token is required.
      #                                                                The Proc should return a token string, {Ably::Models::TokenDetails} or JSON equivalent, {Ably::Models::TokenRequest} or JSON equivalent
      # @option options [Boolean]                 :query_time          when true will query the {https://www.ably.io Ably} system for the current time instead of using the local time
      # @option options [Hash]                    :default_token_params   convenience to pass in +token_params+ that will be used as a default for all token requests. See {Auth#create_token_request}
      #
      # @option options [Integer]                 :http_open_timeout       (4 seconds) timeout in seconds for opening an HTTP connection for all HTTP requests
      # @option options [Integer]                 :http_request_timeout    (10 seconds) timeout in seconds for any single complete HTTP request and response
      # @option options [Integer]                 :http_max_retry_count    (3) maximum number of fallback host retries for HTTP requests that fail due to network issues or server problems
      # @option options [Integer]                 :http_max_retry_duration (15 seconds) maximum elapsed time in which fallback host retries for HTTP requests will be attempted i.e. if the first default host attempt takes 5s, and then the subsequent fallback retry attempt takes 7s, no further fallback host attempts will be made as the total elapsed time of 12s exceeds the default 10s limit
      #
      # @option options [Boolean]                 :fallback_hosts_use_default  (false) When true, forces the user of fallback hosts even if a non-default production endpoint is being used
      # @option options [Array<String>]           :fallback_hosts              When an array of fallback hosts are provided, these fallback hosts are always used if a request fails to the primary endpoint. If an empty array is provided, the fallback host functionality is disabled
      # @option options [Integer]                 :fallback_retry_timeout     (600 seconds) amount of time in seconds a REST client will continue to use a working fallback host when the primary fallback host has previously failed
      #
      # @option options [Boolean]                 :add_request_ids             (false) When true, adds a unique request_id to each request sent to Ably servers. This is handy when reporting issues, because you can refer to a specific request.
      # @option options [Boolean]                 :idempotent_rest_publishing  (false if ver < 1.2) When true, idempotent publishing is enabled for all messages published via REST
      #
      # @return [Ably::Rest::Client]
      #
      # @example
      #    # create a new client authenticating with basic auth
      #    client = Ably::Rest::Client.new('key.id:secret')
      #
      #    # create a new client and configure a client ID used for presence
      #    client = Ably::Rest::Client.new(key: 'key.id:secret', client_id: 'john')
      #
      def initialize(options)
        raise ArgumentError, 'Options Hash is expected' if options.nil?

        options = options.clone
        if options.kind_of?(String)
          options = if options.match(Auth::API_KEY_REGEX)
            { key: options }
          else
            { token: options }
          end
        end

        @realtime_client     = options.delete(:realtime_client)
        @tls                 = options.delete(:tls) == false ? false : true
        @environment         = options.delete(:environment) # nil is production
        @environment         = nil if [:production, 'production'].include?(@environment)
        @protocol            = options.delete(:protocol) || :msgpack
        @debug_http          = options.delete(:debug_http)
        @log_level           = options.delete(:log_level) || ::Logger::WARN
        @custom_logger       = options.delete(:logger)
        @custom_host         = options.delete(:rest_host)
        @custom_port         = options.delete(:port)
        @custom_tls_port     = options.delete(:tls_port)
        @add_request_ids     = options.delete(:add_request_ids)
        @log_retries_as_info = options.delete(:log_retries_as_info)
        @idempotent_rest_publishing = options.delete(:idempotent_rest_publishing) || Ably.major_minor_version_numeric > 1.1


        if options[:fallback_hosts_use_default] && options[:fallback_jhosts]
          raise ArgumentError, "fallback_hosts_use_default cannot be set to trye when fallback_jhosts is also provided"
        end
        @fallback_hosts = case
        when options.delete(:fallback_hosts_use_default)
          Ably::FALLBACK_HOSTS
        when options_fallback_hosts = options.delete(:fallback_hosts)
          options_fallback_hosts
        when environment || custom_host || options[:realtime_host] || custom_port || custom_tls_port
          []
        else
          Ably::FALLBACK_HOSTS
        end

        options[:fallback_retry_timeout] ||= FALLBACK_RETRY_TIMEOUT

        # Take option keys prefixed with `http_`, remove the http_ and
        # check if the option exists in HTTP_DEFAULTS.  If so, update http_defaults
        @http_defaults = HTTP_DEFAULTS.dup
        options.each do |key, val|
          if http_key = key[/^http_(.+)/, 1]
            @http_defaults[http_key.to_sym] = val if val && @http_defaults.has_key?(http_key.to_sym)
          end
        end
        @http_defaults.freeze

        if @log_level == :none
          @custom_logger = Ably::Models::NilLogger.new
        else
          @log_level = ::Logger.const_get(log_level.to_s.upcase) if log_level.kind_of?(Symbol) || log_level.kind_of?(String)
        end

        options.delete(:use_binary_protocol).tap do |use_binary_protocol|
          if use_binary_protocol == true
            @protocol = :msgpack
          elsif use_binary_protocol == false
            @protocol = :json
          end
        end
        raise ArgumentError, 'Protocol is invalid.  Must be either :msgpack or :json' unless [:msgpack, :json].include?(@protocol)

        token_params = options.delete(:default_token_params) || {}
        @options = options
        init_auth_options = options.select do |key, _|
          Auth::AUTH_OPTIONS_KEYS.include?(key.to_s)
        end

        @auth     = Auth.new(self, token_params, init_auth_options)
        @channels = Ably::Rest::Channels.new(self)
        @encoders = []

        options.freeze

        initialize_default_encoders
      end

      # Return a REST {Ably::Rest::Channel} for the given name
      #
      # @param (see Ably::Rest::Channels#get)
      #
      # @return (see Ably::Rest::Channels#get)
      def channel(name, channel_options = {})
        channels.get(name, channel_options)
      end

      # Retrieve the Stats for the application
      #
      # @param [Hash] options the options for the stats request
      # @option options [Integer,Time] :start      Ensure earliest time or millisecond since epoch for any stats retrieved is +:start+
      # @option options [Integer,Time] :end        Ensure latest time or millisecond since epoch for any stats retrieved is +:end+
      # @option options [Symbol]       :direction  +:forwards+ or +:backwards+, defaults to +:backwards+
      # @option options [Integer]      :limit      Maximum number of messages to retrieve up to 1,000, defaults to 100
      # @option options [Symbol]       :unit       `:minute`, `:hour`, `:day` or `:month`. Defaults to `:minute`
      #
      # @return [Ably::Models::PaginatedResult<Ably::Models::Stats>] An Array of Stats
      #
      def stats(options = {})
        options = {
          :direction => :backwards,
          :unit      => :minute,
          :limit     => 100
        }.merge(options)

        [:start, :end].each { |option| options[option] = as_since_epoch(options[option]) if options.has_key?(option) }
        raise ArgumentError, ":end must be equal to or after :start" if options[:start] && options[:end] && (options[:start] > options[:end])

        paginated_options = {
          coerce_into: 'Ably::Models::Stats'
        }

        url = '/stats'
        response = get(url, options)

        Ably::Models::PaginatedResult.new(response, url, self, paginated_options)
      end

      # Retrieve the Ably service time
      #
      # @return [Time] The time as reported by the Ably service
      def time
        response = get('/time', {}, send_auth_header: false)

        as_time_from_epoch(response.body.first)
      end

      # @!attribute [r] use_tls?
      # @return [Boolean] True if client is configured to use TLS for all Ably communication
      def use_tls?
        @tls == true
      end

      # Perform an HTTP GET request to the API using configured authentication
      #
      # @return [Faraday::Response]
      #
      # @api private
      def get(path, params = {}, options = {})
        raw_request(:get, path, params, options)
      end

      # Perform an HTTP POST request to the API using configured authentication
      #
      # @return [Faraday::Response]
      #
      # @api private
      def post(path, params, options = {})
        raw_request(:post, path, params, options)
      end

      # Perform an HTTP PUT request to the API using configured authentication
      #
      # @return [Faraday::Response]
      #
      # @api private
      def put(path, params, options = {})
        raw_request(:put, path, params, options)
      end

      # Perform an HTTP DELETE request to the API using configured authentication
      #
      # @return [Faraday::Response]
      #
      # @api private
      def delete(path, params, options = {})
        raw_request(:delete, path, params, options)
      end

      # Perform an HTTP request to the Ably API
      # This is a convenience for customers who wish to use bleeding edge REST API functionality
      # that is either not documented or is not included in the API for our client libraries.
      # The REST client library provides a function to issue HTTP requests to the Ably endpoints
      # with all the built in functionality of the library such as authentication, paging,
      # fallback hosts, MsgPack and JSON support etc.
      #
      # @param method  [Symbol]    The HTTP method symbol such as +:get+, +:post+, +:put+
      # @param path    [String]    The path of the URL such +/channel/foo/publish+
      # @param params  [Hash, nil] Optional querystring params
      # @param body    [Hash, nil] Optional body for the POST or PUT request, must be nil or a JSON-like object
      # @param headers [Hash, nil] Optional additional headers
      #
      # @return [Ably::Models::HttpPaginatedResponse<>]
      def request(method, path, params = {}, body = nil, headers = {}, options = {})
        raise "Method #{method.to_s.upcase} not supported" unless [:get, :put, :post].include?(method.to_sym)

        response = case method.to_sym
        when :get
          reauthorize_on_authorization_failure do
            send_request(method, path, params, headers: headers)
          end
        when :post
          path_with_params = Addressable::URI.new
          path_with_params.query_values = params || {}
          query = path_with_params.query
          reauthorize_on_authorization_failure do
            send_request(method, "#{path}#{"?#{query}" unless query.nil? || query.empty?}", body, headers: headers)
          end
        end

        paginated_options = {
          async_blocking_operations: options.delete(:async_blocking_operations),
        }

        Ably::Models::HttpPaginatedResponse.new(response, path, self, paginated_options)

      rescue Exceptions::ResourceMissing, Exceptions::ForbiddenRequest, Exceptions::ResourceMissing => e
        response = Models::HttpPaginatedResponse::ErrorResponse.new(e.status, e.code, e.message)
        Models::HttpPaginatedResponse.new(response, path, self)
      rescue Exceptions::TokenExpired, Exceptions::UnauthorizedRequest => e
        response = Models::HttpPaginatedResponse::ErrorResponse.new(e.status, e.code, e.message)
        Models::HttpPaginatedResponse.new(response, path, self)
      rescue Exceptions::InvalidRequest, Exceptions::ServerError => e
        response = Models::HttpPaginatedResponse::ErrorResponse.new(e.status, e.code, e.message)
        Models::HttpPaginatedResponse.new(response, path, self)
      end

      # The local device detilas
      # @return [Ably::Models::LocalDevice]
      #
      # @note This is unsupported in the Ruby library
      def device
        raise Ably::Exceptions::PushNotificationsNotSupported, 'This device does not support receiving or subscribing to push notifications. The local device object is not unavailable'
      end

      # Push notification object for publishing and managing push notifications
      # @return [Ably::Rest::Push]
      def push
        @push ||= Push.new(self)
      end

      # @!attribute [r] endpoint
      # @return [URI::Generic] Default Ably REST endpoint used for all requests
      def endpoint
        endpoint_for_host(custom_host || [@environment, DOMAIN].compact.join('-'))
      end

      # @!attribute [r] logger
      # @return [Logger] The {Ably::Logger} for this client.
      #                  Configure the log_level with the `:log_level` option, refer to {Client#initialize}
      def logger
        @logger ||= Ably::Logger.new(self, log_level, @custom_logger)
      end

      # @!attribute [r] mime_type
      # @return [String] Mime type used for HTTP requests
      def mime_type
        case protocol
        when :json
          'application/json'
        else
          'application/x-msgpack'
        end
      end

      # Register a message encoder and decoder that implements Ably::Models::MessageEncoders::Base interface.
      # Message encoders are used to encode and decode message payloads automatically.
      # @note Encoders and decoders are processed in the order they are added so the first encoder will be given priority when encoding and decoding
      #
      # @param [Ably::Models::MessageEncoders::Base] encoder
      # @return [void]
      #
      # @api private
      def register_encoder(encoder, options = {})
        encoders << Ably::Models::MessageEncoders.encoder_from(encoder, options)
      end

      # @!attribute [r] protocol_binary?
      # @return [Boolean] True of the transport #protocol communicates with Ably with a binary protocol
      def protocol_binary?
        protocol == :msgpack
      end

      # Connection used to make HTTP requests
      #
      # @param [Hash] options
      # @option options [Boolean] :use_fallback when true, one of the fallback connections is used randomly, see the default {Ably::FALLBACK_HOSTS}
      #
      # @return [Faraday::Connection]
      #
      # @api private
      def connection(options = {})
        if options[:use_fallback]
          fallback_connection
        else
          @connection ||= Faraday.new(endpoint.to_s, connection_options)
        end
      end

      # Fallback connection used to make HTTP requests.
      # Note, each request uses a random and then subsequent random {Ably::FALLBACK_HOSTS fallback hosts}
      # are used (unless custom fallback hosts are provided with fallback_hosts)
      #
      # @return [Faraday::Connection]
      #
      # @api private
      def fallback_connection
        unless defined?(@fallback_connections) && @fallback_connections
          @fallback_connections = fallback_hosts.shuffle.map { |host| Faraday.new(endpoint_for_host(host).to_s, connection_options) }
        end
        @fallback_index ||= 0

        @fallback_connections[@fallback_index % @fallback_connections.count].tap do
          @fallback_index += 1
        end
      end

      # Library Ably version user agent
      # @api private
      def lib_version_id
        @lib_version_id ||= [
          'ruby',
          Ably.lib_variant,
          Ably::VERSION
        ].compact.join('-')
      end

      # Allowable duration for an external auth request
      # For REST client this defaults to request_timeout
      # For Realtime clients this defaults to 250ms less than the realtime_request_timeout
      #   ensuring an auth failure will be triggered before the realtime request timeout fires
      #   which would lead to a misleading error message (connection timeout as opposed to auth request timeout)
      # @api private
      def auth_request_timeout
        if @realtime_client
          @realtime_client.connection.defaults.fetch(:realtime_request_timeout) - 0.25
        else
          http_defaults.fetch(:request_timeout)
        end
      end

      # If the primary host endpoint fails, and a subsequent fallback host succeeds, the fallback
      #   host that succeeded is used for +ClientOption+ +fallback_retry_timeout+ seconds to avoid
      #   retries to known failing hosts for a short period of time.
      # See https://github.com/ably/docs/pull/554, spec id #RSC15f
      #
      # @return [nil, String]  Returns nil (falsey) if the primary host is being used, or the currently used host if a fallback host is currently preferred
      def using_preferred_fallback_host?
        if preferred_fallback_connection && (preferred_fallback_connection.fetch(:expires_at) > Time.now)
          preferred_fallback_connection.fetch(:connection_object).host
        end
      end

      private

      attr_reader :preferred_fallback_connection

      # See #using_preferred_fallback_host? for context
      def set_preferred_fallback_connection(connection)
        @preferred_fallback_connection = if connection == @connection
          # If the succeeded connection is in fact the primary connection (tried after a failed fallback)
          #   then clear the preferred fallback connection
          nil
        else
          {
            expires_at: Time.now + options.fetch(:fallback_retry_timeout),
            connection_object: connection,
          }
        end
      end

      def get_preferred_fallback_connection_object
        preferred_fallback_connection.fetch(:connection_object) if using_preferred_fallback_host?
      end

      def raw_request(method, path, params = {}, options = {})
        options = options.clone
        if options.delete(:disable_automatic_reauthorize) == true
          send_request(method, path, params, options)
        else
          reauthorize_on_authorization_failure do
            send_request(method, path, params, options)
          end
        end
      end

      # Sends HTTP request to connection end point
      # Connection failures will automatically be reattempted until thresholds are met
      def send_request(method, path, params, options)
        max_retry_count    = http_defaults.fetch(:max_retry_count)
        max_retry_duration = http_defaults.fetch(:max_retry_duration)
        requested_at       = Time.now
        retry_count        = 0
        retry_sequence_id  = nil
        request_id         = SecureRandom.urlsafe_base64(10) if add_request_ids

        preferred_fallback_connection_for_first_request = get_preferred_fallback_connection_object

        begin
          use_fallback = can_fallback_to_alternate_ably_host? && (retry_count > 0)

          conn = if preferred_fallback_connection_for_first_request
            case retry_count
            when 0
              preferred_fallback_connection_for_first_request
            when 1
              # Ensure the root host is used first if the preferred fallback fails, see #RSC15f
              connection(use_fallback: false)
            end
          end || connection(use_fallback: use_fallback) # default to normal connection selection process if not preferred connection set

          conn.send(method, path, params) do |request|
            if add_request_ids
              request.params[:request_id] = request_id
              request.options.context = {} if request.options.context.nil?
              request.options.context[:request_id] = request_id
            end
            unless options[:send_auth_header] == false
              request.headers[:authorization] = auth.auth_header
              if options[:headers]
                options[:headers].map do |key, val|
                  request.headers[key] = val
                end
              end
            end
          end.tap do
            if retry_count > 0
              retry_log_severity = log_retries_as_info ? :info : :warn
              logger.public_send(retry_log_severity) do
                "Ably::Rest::Client - Request SUCCEEDED after #{retry_count} #{retry_count > 1 ? 'retries' : 'retry' } for" \
                " #{method} #{path} #{params} (seq ##{retry_sequence_id}, time elapsed #{(Time.now.to_f - requested_at.to_f).round(2)}s)"
              end
              set_preferred_fallback_connection conn
            end
          end

        rescue Faraday::TimeoutError, Faraday::ClientError, Ably::Exceptions::ServerError => error
          retry_sequence_id ||= SecureRandom.urlsafe_base64(4)
          time_passed = Time.now - requested_at

          if can_fallback_to_alternate_ably_host? && (retry_count < max_retry_count) && (time_passed <= max_retry_duration)
            retry_count += 1
            retry_log_severity = log_retries_as_info ? :info : :warn
            logger.public_send(retry_log_severity) { "Ably::Rest::Client - Retry #{retry_count} for #{method} #{path} #{params} as initial attempt failed (seq ##{retry_sequence_id}): #{error}" }
            retry
          end

          retry_log_severity = log_retries_as_info ? :info : :error
          logger.public_send(retry_log_severity) do
            "Ably::Rest::Client - Request FAILED after #{retry_count} #{retry_count > 1 ? 'retries' : 'retry' } for" \
            " #{method} #{path} #{params} (seq ##{retry_sequence_id}, time elapsed #{(Time.now.to_f - requested_at.to_f).round(2)}s)"
          end

          case error
            when Faraday::TimeoutError
              raise Ably::Exceptions::ConnectionTimeout.new(error.message, nil, Ably::Exceptions::Codes::CONNECTION_TIMED_OUT, error, { request_id: request_id })
            when Faraday::ClientError
              # request_id is also available in the request context
              raise Ably::Exceptions::ConnectionError.new(error.message, nil, Ably::Exceptions::Codes::CONNECTION_FAILED, error, { request_id: request_id })
            else
              raise error
          end
        end
      end

      def reauthorize_on_authorization_failure
        yield
      rescue Ably::Exceptions::TokenExpired => e
        if auth.token_renewable?
          auth.authorize
          yield
        else
          raise e
        end
      end

      def endpoint_for_host(host)
        port = if use_tls?
          custom_tls_port
        else
          custom_port
        end

        raise ArgumentError, "Custom port must be an Integer or nil" if port && !port.kind_of?(Integer)

        options = {
          scheme: use_tls? ? 'https' : 'http',
          host:   host
        }
        options.merge!(port: port) if port

        URI::Generic.build(options)
      end

      # Return a Hash of connection options to initiate the Faraday::Connection with
      #
      # @return [Hash]
      def connection_options
        @connection_options ||= {
          builder: middleware,
          headers: {
            content_type:       mime_type,
            accept:             mime_type,
            user_agent:         user_agent,
            'X-Ably-Version' => Ably::PROTOCOL_VERSION,
            'X-Ably-Lib'     => lib_version_id
          },
          request: {
            open_timeout: http_defaults.fetch(:open_timeout),
            timeout:      http_defaults.fetch(:request_timeout)
          }
        }
      end

      # Return a Faraday middleware stack to initiate the Faraday::Connection with
      #
      # @see http://mislav.uniqpath.com/2011/07/faraday-advanced-http/
      def middleware
        @middleware ||= Faraday::RackBuilder.new do |builder|
          setup_outgoing_middleware builder

          # Raise exceptions if response code is invalid
          builder.use Ably::Rest::Middleware::Exceptions

          setup_incoming_middleware builder, logger, fail_if_unsupported_mime_type: true

          # Set Faraday's HTTP adapter
          builder.adapter :excon
        end
      end

      def can_fallback_to_alternate_ably_host?
        fallback_hosts && !fallback_hosts.empty?
      end

      def initialize_default_encoders
        Ably::Models::MessageEncoders.register_default_encoders self, binary_protocol: protocol == :msgpack
      end
    end
  end
end
