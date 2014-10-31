module Ably
  module Realtime
    # Client for the Ably Realtime API
    #
    # @!attribute [r] auth
    #   (see Ably::Rest::Client#auth)
    # @!attribute [r] client_id
    #   (see Ably::Rest::Client#client_id)
    # @!attribute [r] auth_options
    #   (see Ably::Rest::Client#auth_options)
    # @!attribute [r] environment
    #   (see Ably::Rest::Client#environment)
    # @!attribute [r] channels
    #   @return [Aby::Realtime::Channels] The collection of {Ably::Realtime::Channel}s that have been created
    # @!attribute [r] rest_client
    #   @return [Ably::Rest::Client] The {Ably::Rest::Client REST client} instantiated with the same credentials and configuration that is used for all REST operations such as authentication
    # @!attribute [r] echo_messages
    #   @return [Boolean] If false, suppresses messages originating from this connection being echoed back on the same connection.  Defaults to true
    class Client
      extend Forwardable

      DOMAIN = 'realtime.ably.io'

      attr_reader :channels, :auth, :rest_client, :echo_messages
      def_delegators :auth, :client_id, :auth_options
      def_delegators :@rest_client, :environment, :use_tls?, :protocol
      def_delegators :@rest_client, :logger, :log_level
      def_delegators :@rest_client, :time, :stats

      # Creates a {Ably::Realtime::Client Realtime Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param (see Ably::Rest::Client#initialize)
      # @option options (see Ably::Rest::Client#initialize)
      # @option options [Boolean] :queue_messages If false, this disables the default behaviour whereby the library queues messages on a connection in the disconnected or connecting states
      # @option options [Boolean] :echo_messages  If false, prevents messages originating from this connection being echoed back on the same connection
      # @option options [String]  :recover        This option allows a connection to inherit the state of a previous connection that may have existed under an different instance of the Realtime library.
      #
      # @yield (see Ably::Rest::Client#initialize)
      # @yieldparam (see Ably::Rest::Client#initialize)
      # @yieldreturn (see Ably::Rest::Client#initialize)
      #
      # @return [Ably::Realtime::Client]
      #
      # @example
      #    # create a new client authenticating with basic auth
      #    client = Ably::Realtime::Client.new('key.id:secret')
      #
      #    # create a new client and configure a client ID used for presence
      #    client = Ably::Realtime::Client.new(api_key: 'key.id:secret', client_id: 'john')
      #
      def initialize(options, &auth_block)
        @rest_client    = Ably::Rest::Client.new(options, &auth_block)
        @auth           = @rest_client.auth
        @channels       = Ably::Realtime::Channels.new(self)
        @echo_messages  = @rest_client.options.fetch(:echo_messages, true) == false ? false : true
      end

      # Return a {Ably::Realtime::Channel Realtime Channel} for the given name
      #
      # @param (see Ably::Realtime::Channels#get)
      #
      # @return (see Ably::Realtime::Channels#get)
      def channel(name, channel_options = {})
        channels.get(name, channel_options)
      end

      # (see Ably::Rest::Client#time)
      def time
        rest_client.time
      end

      # (see Ably::Rest::Client#stats)
      def stats(params = {})
        rest_client.stats(params)
      end

      # (see Ably::Realtime::Connection#close)
      def close(&block)
        connection.close(&block)
      end

      # @!attribute [r] endpoint
      # @return [URI::Generic] Default Ably Realtime endpoint used for all requests
      def endpoint
        URI::Generic.build(
          scheme: use_tls? ? "wss" : "ws",
          host:   [environment, DOMAIN].compact.join('-')
        )
      end

      # @!attribute [r] connection
      # @return [Aby::Realtime::Connection] The underlying connection for this client
      def connection
        @connection ||= Connection.new(self)
      end
    end
  end
end

