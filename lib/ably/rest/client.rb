require 'faraday'
require 'json'
require 'logger'

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

      # Configuration for connection retry attempts
      CONNECTION_RETRY = {
        single_request_open_timeout: 4,
        single_request_timeout: 15,
        cumulative_request_open_timeout: 10,
        max_retry_attempts: 3
      }.freeze

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

      # The custom host that is being used if it was provided with the option `:rest_host` when the {Client} was created
      # @return [String,Nil]
      attr_reader :custom_host

      # The registered encoders that are used to encode and decode message payloads
      # @return [Array<Ably::Models::MessageEncoder::Base>]
      # @api private
      attr_reader :encoders

      # The additional options passed to this Client's #initialize method not available as attributes of this class
      # @return [Hash]
      # @api private
      attr_reader :options

      # Creates a {Ably::Rest::Client Rest Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param [Hash,String] options an options Hash used to configure the client and the authentication, or String with an API key or Token ID
      # @option options (see Ably::Auth#authorise)
      # @option options [Boolean]                 :tls                 TLS is used by default, providing a value of false disables TLS.  Please note Basic Auth is disallowed without TLS as secrets cannot be transmitted over unsecured connections.
      # @option options [String]                  :key                 API key comprising the key ID and key secret in a single string
      # @option options [Boolean]                 :use_token_auth      Will force Basic Auth if set to false, and TOken auth if set to true
      # @option options [String]                  :environment         Specify 'sandbox' when testing the client library against an alternate Ably environment
      # @option options [Symbol]                  :protocol            Protocol used to communicate with Ably, :json and :msgpack currently supported. Defaults to :msgpack
      # @option options [Boolean]                 :use_binary_protocol Protocol used to communicate with Ably, defaults to true and uses MessagePack protocol.  This option will overide :protocol option
      # @option options [Logger::Severity,Symbol] :log_level           Log level for the standard Logger that outputs to STDOUT.  Defaults to Logger::ERROR, can be set to :fatal (Logger::FATAL), :error (Logger::ERROR), :warn (Logger::WARN), :info (Logger::INFO), :debug (Logger::DEBUG) or :none
      # @option options [Logger]                  :logger              A custom logger can be used however it must adhere to the Ruby Logger interface, see http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html
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
      #    client = Ably::Rest::Client.new(key: 'key.id:secret', client_id: 'john')
      #
      def initialize(options, &token_request_block)
        raise ArgumentError, 'Options Hash is expected' if options.nil?

        options = options.clone
        if options.kind_of?(String)
          options = if options.match(/^[\w]{2,}\.[\w]{2,}:[\w]{2,}$/)
            { key: options }
          else
            { token_id: options }
          end
        end

        @tls           = options.delete(:tls) == false ? false : true
        @environment   = options.delete(:environment) # nil is production
        @protocol      = options.delete(:protocol) || :msgpack
        @debug_http    = options.delete(:debug_http)
        @log_level     = options.delete(:log_level) || ::Logger::ERROR
        @custom_logger = options.delete(:logger)
        @custom_host   = options.delete(:rest_host)

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

        @options  = options.freeze
        @auth     = Auth.new(self, options, &token_request_block)
        @channels = Ably::Rest::Channels.new(self)
        @encoders = []

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
      # @option options [Symbol]       :by         `:minute`, `:hour`, `:day` or `:month`. Defaults to `:minute`
      #
      # @return [Ably::Models::PaginatedResource<Ably::Models::Stats>] An Array of Stats
      #
      def stats(options = {})
        options = {
          :direction => :backwards,
          :by        => :minute,
          :limit     => 100
        }.merge(options)

        [:start, :end].each { |option| options[option] = as_since_epoch(options[option]) if options.has_key?(option) }

        paginated_options = {
          coerce_into: 'Ably::Models::Stats'
        }

        url = '/stats'
        response = get(url, options)

        Ably::Models::PaginatedResource.new(response, url, self, paginated_options)
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
      def get(path, params = {}, options = {})
        request(:get, path, params, options)
      end

      # Perform an HTTP POST request to the API using configured authentication
      #
      # @return [Faraday::Response]
      def post(path, params, options = {})
        request(:post, path, params, options)
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
      def register_encoder(encoder)
        encoder_klass = if encoder.kind_of?(String)
          encoder.split('::').inject(Kernel) do |base, klass_name|
            base.public_send(:const_get, klass_name)
          end
        else
          encoder
        end

        raise "Encoder must inherit from `Ably::Models::MessageEncoders::Base`" unless encoder_klass.ancestors.include?(Ably::Models::MessageEncoders::Base)

        encoders << encoder_klass.new(self)
      end

      # @!attribute [r] protocol_binary?
      # @return [Boolean] True of the transport #protocol communicates with Ably with a binary protocol
      def protocol_binary?
        protocol == :msgpack
      end

      # Connection used to make HTTP requests
      #
      # @param [Hash] options
      # @option options [Boolean] :use_fallback when true, one of the fallback connections is used randomly, see {Ably::FALLBACK_HOSTS}
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
      # Note, each request uses a random and then subsequent random {Ably::FALLBACK_HOSTS fallback host}
      #
      # @return [Faraday::Connection]
      #
      # @api private
      def fallback_connection
        unless @fallback_connections
          @fallback_connections = Ably::FALLBACK_HOSTS.shuffle.map { |host| Faraday.new(endpoint_for_host(host).to_s, connection_options) }
        end
        @fallback_index ||= 0

        @fallback_connections[@fallback_index % @fallback_connections.count].tap do
          @fallback_index += 1
        end
      end

      private
      def request(method, path, params = {}, options = {})
        options = options.clone
        if options.delete(:disable_automatic_reauthorise) == true
          send_request(method, path, params, options)
        else
          reauthorise_on_authorisation_failure do
            send_request(method, path, params, options)
          end
        end
      end

      # Sends HTTP request to connection end point
      # Connection failures will automatically be reattempted until thresholds are met
      def send_request(method, path, params, options)
        max_retry_attempts = CONNECTION_RETRY.fetch(:max_retry_attempts)
        cumulative_timeout = CONNECTION_RETRY.fetch(:cumulative_request_open_timeout)
        requested_at       = Time.now
        retry_count        = 0

        begin
          use_fallback = can_fallback_to_alternate_ably_host? && retry_count > 0

          connection(use_fallback: use_fallback).send(method, path, params) do |request|
            unless options[:send_auth_header] == false
              request.headers[:authorization] = auth.auth_header
            end
          end

        rescue Faraday::TimeoutError, Faraday::ClientError => error
          time_passed = Time.now - requested_at
          if can_fallback_to_alternate_ably_host? && retry_count < max_retry_attempts && time_passed <= cumulative_timeout
            retry_count += 1
            retry
          end

          case error
            when Faraday::TimeoutError
              raise Ably::Exceptions::ConnectionTimeoutError.new(error.message, nil, 80014, error)
            when Faraday::ClientError
              raise Ably::Exceptions::ConnectionError.new(error.message, nil, 80000, error)
          end
        end
      end

      def reauthorise_on_authorisation_failure
        yield
      rescue Ably::Exceptions::InvalidRequest => e
        if e.code == 40140
          if auth.token_renewable?
            auth.authorise force: true
            yield
          else
            raise Ably::Exceptions::InvalidToken.new(e.message, e.status, e.code)
          end
        else
          raise e
        end
      end

      def endpoint_for_host(host)
        URI::Generic.build(
          scheme: use_tls? ? 'https' : 'http',
          host:   host
        )
      end

      # Return a Hash of connection options to initiate the Faraday::Connection with
      #
      # @return [Hash]
      def connection_options
        @connection_options ||= {
          builder: middleware,
          headers: {
            content_type: mime_type,
            accept:       mime_type,
            user_agent:   user_agent
          },
          request: {
            open_timeout: CONNECTION_RETRY.fetch(:single_request_open_timeout),
            timeout:      CONNECTION_RETRY.fetch(:single_request_timeout)
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
          builder.adapter Faraday.default_adapter
        end
      end

      def can_fallback_to_alternate_ably_host?
        !custom_host && !environment
      end

      def initialize_default_encoders
        Ably::Models::MessageEncoders.register_default_encoders self
      end
    end
  end
end
