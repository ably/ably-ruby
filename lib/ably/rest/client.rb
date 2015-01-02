require 'faraday'
require 'json'
require 'logger'

require 'ably/rest/middleware/exceptions'

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
    # @!attribute [r] environment
    #   @return [String] May contain 'sandbox' when testing the client library against an alternate Ably environment
    # @!attribute [r] log_level
    #   @return [Logger::Severity] Log level configured for this {Client}
    # @!attribute [r] channels
    #   @return [Aby::Rest::Channels] The collection of {Ably::Rest::Channel}s that have been created
    # @!attribute [r] protocol
    #   @return [Symbol] The protocol configured for this client, either binary `:msgpack` or text based `:json`
    #
    class Client
      include Ably::Modules::Conversions
      include Ably::Modules::HttpHelpers
      extend Forwardable

      DOMAIN = 'rest.ably.io'

      attr_reader :environment, :protocol, :auth, :channels, :log_level
      def_delegators :auth, :client_id, :auth_options

      # @api private
      # The registered encoders that are used to encode and decode message payloads
      # @return [Array<Ably::Models::MessageEncoder::Base>]
      attr_reader :encoders

      # The additional options passed to this Client's #initialize method not available as attributes of this class
      # @return [Hash]
      # @api private
      attr_reader :options

      # Creates a {Ably::Rest::Client Rest Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param [Hash,String] options an options Hash used to configure the client and the authentication, or String with an API key
      # @option options (see Ably::Auth#authorise)
      # @option options [Boolean]                 :tls                 TLS is used by default, providing a value of false disbles TLS.  Please note Basic Auth is disallowed without TLS as secrets cannot be transmitted over unsecured connections.
      # @option options [String]                  :api_key             API key comprising the key ID and key secret in a single string
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
      #    client = Ably::Rest::Client.new(api_key: 'key.id:secret', client_id: 'john')
      #
      def initialize(options, &auth_block)
        raise ArgumentError, 'Options Hash is expected' if options.nil?

        options = options.clone
        if options.kind_of?(String)
          options = { api_key: options }
        end

        @tls           = options.delete(:tls) == false ? false : true
        @environment   = options.delete(:environment) # nil is production
        @protocol      = options.delete(:protocol) || :msgpack
        @debug_http    = options.delete(:debug_http)
        @log_level     = options.delete(:log_level) || ::Logger::ERROR
        @custom_logger = options.delete(:logger)

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
        @auth     = Auth.new(self, options, &auth_block)
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

      # Retrieve the stats for the application
      #
      # @return [Array] An Array of hashes representing the stats
      def stats(params = {})
        default_params = {
          :direction => :forwards,
          :by        => :minute
        }

        response = get("/stats", default_params.merge(params))

        response.body.map do |stat|
          IdiomaticRubyWrapper(stat)
        end
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
        URI::Generic.build(
          scheme: use_tls? ? "https" : "http",
          host:   [@environment, DOMAIN].compact.join('-')
        )
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
            raise Ably::Exceptions::InvalidToken.new(e.message, e.status, e.code)
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
            content_type: mime_type,
            accept:       mime_type,
            user_agent:   user_agent
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
          setup_outgoing_middleware builder

          # Raise exceptions if response code is invalid
          builder.use Ably::Rest::Middleware::Exceptions

          setup_incoming_middleware builder, logger, fail_if_unsupported_mime_type: true

          # Set Faraday's HTTP adapter
          builder.adapter Faraday.default_adapter
        end
      end

      def initialize_default_encoders
        Ably::Models::MessageEncoders.register_default_encoders self
      end
    end
  end
end
