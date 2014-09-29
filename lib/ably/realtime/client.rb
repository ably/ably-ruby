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
    # @!attribute [r] tls
    #   (see Ably::Rest::Client#tls)
    # @!attribute [r] environment
    #   (see Ably::Rest::Client#environment)
    class Client
      include Ably::Modules::Callbacks
      extend Forwardable

      DOMAIN = 'realtime.ably.io'

      attr_reader :channels, :auth
      def_delegators :auth, :client_id, :auth_options
      def_delegators :@rest_client, :tls, :environment, :use_tls?

      # Creates a {Ably::Realtime::Client Realtime Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param (see Ably::Rest::Client#initialize)
      # @option options (see Ably::Rest::Client#initialize)
      # @option options [Boolean] :queue_messages If false, this disables the default behaviour whereby the library queues messages on a connection in the disconnected or connecting states
      # @option options [Boolean] :echo_messages  If false, prevents messages originating from this connection being echoed back on the same connection
      # @option options [String]  :recover        This option allows a connection to inherit the state of a previous connection that may have existed under an different instance of the Realtime library.
      # @option options [Boolean] :debug_http     Send HTTP & websocket debugging information for all messages/requests sent and received to STDOUT
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
      def initialize(options)
        @rest_client    = Ably::Rest::Client.new(options)
        @auth           = @rest_client.auth
        @message_serial = 0

        on(:attached) do |protocol_message|
          channel = channel(protocol_message.channel)

          channel.trigger(:attached)
        end

        on(:message) do |protocol_message|
          channel = channel(protocol_message.channel)

          protocol_message.messages.each do |message|
            channel.trigger(:message, message)
          end
        end
      end

      def token
        @token ||= rest_client.request_token
      end

      # Return a Realtime Channel for the given name
      #
      # @param name [String] The name of the channel
      # @return [Ably::Realtime::Channel]
      def channel(name)
        @channels ||= {}
        @channels[name] ||= Ably::Realtime::Channel.new(self, name)
      end

      def send_messages(channel_name, messages)
        payload = {
          action:   Models::ProtocolMessage.action!(:message),
          channel:  channel_name,
          messages: messages
        }

        payload.merge!(clientId: client_id) unless client_id.nil?

        connection.send(payload)
      end

      def attach_to_channel(channel_name)
        payload = {
          action:  Models::ProtocolMessage.action!(:attach),
          channel: channel_name
        }

        connection.send(payload)
      end

      # Default Ably Realtime endpoint used for all requests
      #
      # @return [URI::Generic]
      def endpoint
        URI::Generic.build(
          scheme: use_tls? ? "wss" : "ws",
          host:   [environment, DOMAIN].compact.join('-')
        )
      end

      def connection
        @connection ||= begin
          host = endpoint.host
          port = use_tls? ? 443 : 80

          EventMachine.connect(host, port, Connection, self)
        end
      end

      # When true, will send HTTP & websocket debugging information for all messages/requests sent and received to STDOUT
      #
      # @return [Boolean]
      def debug_http?
        rest_client.debug_http?
      end

      def log_http(message)
        $stdout.puts "#{Time.now.strftime('%H:%M:%S')} #{message}" if debug_http?
      end

      private
      attr_reader :rest_client
    end
  end
end

