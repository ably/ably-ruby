require 'uri'
require 'ably/realtime/channel/publisher'

module Ably
  module Realtime
    # Client for the Ably Realtime API
    #
    # @!attribute [r] client_id
    #   (see Ably::Rest::Client#client_id)
    # @!attribute [r] auth_options
    #   (see Ably::Rest::Client#auth_options)
    # @!attribute [r] environment
    #   (see Ably::Rest::Client#environment)
    # @!attribute [r] channels
    #   @return [Aby::Realtime::Channels] The collection of {Ably::Realtime::Channel}s that have been created
    # @!attribute [r] encoders
    #   (see Ably::Rest::Client#encoders)
    # @!attribute [r] protocol
    #   (see Ably::Rest::Client#protocol)
    # @!attribute [r] protocol_binary?
    #   (see Ably::Rest::Client#protocol_binary?)
    #
    class Client
      include Ably::Modules::AsyncWrapper
      include Ably::Realtime::Channel::Publisher
      include Ably::Modules::Conversions

      extend Forwardable

      DOMAIN = 'realtime.ably.io'

      # The collection of {Ably::Realtime::Channel}s that have been created
      # @return [Aby::Realtime::Channels]
      attr_reader :channels

      # (see Ably::Rest::Client#auth)
      attr_reader :auth

      # The underlying connection for this client
      # @return [Aby::Realtime::Connection]
      attr_reader :connection

      # The {Ably::Rest::Client REST client} instantiated with the same credentials and configuration that is used for all REST operations such as authentication
      # @return [Ably::Rest::Client]
      # @private
      attr_reader :rest_client

      # When false the client suppresses messages originating from this connection being echoed back on the same connection. Defaults to true
      # @return [Boolean]
      attr_reader :echo_messages

      # If false, this disables the default behaviour whereby the library queues messages on a connection in the disconnected or connecting states. Defaults to true
      # @return [Boolean]
      attr_reader :queue_messages

      # The custom realtime websocket host that is being used if it was provided with the option `:ws_host` when the {Client} was created
      # @return [String,Nil]
      attr_reader :custom_realtime_host

      # When true, as soon as the client library is instantiated it will connect to Ably.  If this attribute is false, a connection must be opened explicitly
      # @return [Boolean]
      attr_reader :auto_connect

      # When a recover option is specified a connection inherits the state of a previous connection that may have existed under a different instance of the Realtime library, please refer to the API documentation for further information on connection state recovery
      # @return [String,Nil]
      attr_reader :recover

      def_delegators :auth, :client_id, :auth_options
      def_delegators :@rest_client, :encoders
      def_delegators :@rest_client, :use_tls?, :protocol, :protocol_binary?
      def_delegators :@rest_client, :environment, :custom_host, :custom_port, :custom_tls_port
      def_delegators :@rest_client, :log_level

      # Creates a {Ably::Realtime::Client Realtime Client} and configures the {Ably::Auth} object for the connection.
      #
      # @param (see Ably::Rest::Client#initialize)
      # @option options (see Ably::Rest::Client#initialize)
      # @option options [Proc]                    :auth_callback       when provided, the Proc will be called with the token params hash as the first argument, whenever a new token is required.
      #                                                                Whilst the proc is called synchronously, it does not block the EventMachine reactor as it is run in a separate thread.
      #                                                                The Proc should return a token string, {Ably::Models::TokenDetails} or JSON equivalent, {Ably::Models::TokenRequest} or JSON equivalent
      # @option options [Boolean] :queue_messages If false, this disables the default behaviour whereby the library queues messages on a connection in the disconnected or connecting states
      # @option options [Boolean] :echo_messages  If false, prevents messages originating from this connection being echoed back on the same connection
      # @option options [String]  :recover        When a recover option is specified a connection inherits the state of a previous connection that may have existed under a different instance of the Realtime library, please refer to the API documentation for further information on connection state recovery
      # @option options [Boolean] :auto_connect   By default as soon as the client library is instantiated it will connect to Ably. You can optionally set this to false and explicitly connect.
      #
      # @option options [Integer] :channel_retry_timeout       (15 seconds). When a channel becomes SUSPENDED, after this delay in seconds, the channel will automatically attempt to reattach if the connection is CONNECTED
      # @option options [Integer] :disconnected_retry_timeout  (15 seconds). When the connection enters the DISCONNECTED state, after this delay in seconds, if the state is still DISCONNECTED, the client library will attempt to reconnect automatically
      # @option options [Integer] :suspended_retry_timeout     (30 seconds). When the connection enters the SUSPENDED state, after this delay in seconds, if the state is still SUSPENDED, the client library will attempt to reconnect automatically
      # @option options [Boolean] :disable_websocket_heartbeats   WebSocket heartbeats are more efficient than protocol level heartbeats, however they can be disabled for development purposes
      #
      # @return [Ably::Realtime::Client]
      #
      # @example
      #    # create a new client authenticating with basic auth
      #    client = Ably::Realtime::Client.new('key.id:secret')
      #
      #    # create a new client and configure a client ID used for presence
      #    client = Ably::Realtime::Client.new(key: 'key.id:secret', client_id: 'john')
      #
      def initialize(options)
        raise ArgumentError, 'Options Hash is expected' if options.nil?

        options = options.clone
        if options.kind_of?(String)
          options = if options.match(Ably::Auth::API_KEY_REGEX)
            { key: options }
          else
            { token: options }
          end
        end

        @rest_client           = Ably::Rest::Client.new(options.merge(realtime_client: self))
        @echo_messages         = rest_client.options.fetch(:echo_messages, true) == false ? false : true
        @queue_messages        = rest_client.options.fetch(:queue_messages, true) == false ? false : true
        @custom_realtime_host  = rest_client.options[:realtime_host] || rest_client.options[:ws_host]
        @auto_connect          = rest_client.options.fetch(:auto_connect, true) == false ? false : true
        @recover               = rest_client.options[:recover]

        raise ArgumentError, "Recovery key '#{recover}' is invalid" if recover && !recover.match(Connection::RECOVER_REGEX)

        @auth       = Ably::Realtime::Auth.new(self)
        @channels   = Ably::Realtime::Channels.new(self)
        @connection = Ably::Realtime::Connection.new(self, options)
      end

      # Return a {Ably::Realtime::Channel Realtime Channel} for the given name
      #
      # @param (see Ably::Realtime::Channels#get)
      # @return (see Ably::Realtime::Channels#get)
      #
      def channel(name, channel_options = {})
        channels.get(name, channel_options)
      end

      # Retrieve the Ably service time
      #
      # @yield [Time] The time as reported by the Ably service
      # @return [Ably::Util::SafeDeferrable]
      #
      def time(&success_callback)
        async_wrap(success_callback) do
          rest_client.time
        end
      end

      # Retrieve the stats for the application
      #
      # @param (see Ably::Rest::Client#stats)
      # @option options (see Ably::Rest::Client#stats)
      #
      # @yield [Ably::Models::PaginatedResult<Ably::Models::Stats>] An Array of Stats
      #
      # @return [Ably::Util::SafeDeferrable]
      #
      def stats(options = {}, &success_callback)
        async_wrap(success_callback) do
          rest_client.stats(options)
        end
      end

      # (see Ably::Realtime::Connection#close)
      def close(&block)
        connection.close(&block)
      end

      # (see Ably::Realtime::Connection#connect)
      def connect(&block)
        connection.connect(&block)
      end

      # Push notification object for publishing and managing push notifications
      # @return [Ably::Realtime::Push]
      def push
        @push ||= Push.new(self)
      end

      # (see Ably::Rest::Client#request)
      # @yield [Ably::Models::HttpPaginatedResponse<>] An Array of Stats
      #
      # @return [Ably::Util::SafeDeferrable]
      def request(method, path, params = {}, body = nil, headers = {}, &callback)
        async_wrap(callback) do
          rest_client.request(method, path, params, body, headers, async_blocking_operations: true)
        end
      end

      # Publish one or more messages to the specified channel.
      #
      # This method allows messages to be efficiently published to Ably without instancing a {Ably::Realtime::Channel} object.
      # If you want to publish a high rate of messages to Ably without instancing channels or using the REST API, then this method
      # is recommended. However, channel options such as encryption are not supported with this method.  If you need to specify channel options
      # we recommend you use the {Ably::Realtime::Channel} +publish+ method without attaching to each channel, unless you also want to subscribe
      # to published messages on that channel.
      #
      # Note: This feature is still in beta. As such, we cannot guarantee the API will not change in future.
      #
      # @param channel [String]   The channel name you want to publish the message(s) to
      # @param name [String, Array<Ably::Models::Message|Hash>, nil]   The event name of the message to publish, or an Array of [Ably::Model::Message] objects or [Hash] objects with +:name+ and +:data+ pairs
      # @param data [String, ByteArray, nil]   The message payload unless an Array of [Ably::Model::Message] objects passed in the first argument
      # @param attributes [Hash, nil]   Optional additional message attributes such as :client_id or :connection_id, applied when name attribute is nil or a string
      #
      # @yield [Ably::Models::Message,Array<Ably::Models::Message>] On success, will call the block with the {Ably::Models::Message} if a single message is published, or an Array of {Ably::Models::Message} when multiple messages are published
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
      #
      # @example
      #   # Publish a single message
      #   client.publish 'activityChannel', click', { x: 1, y: 2 }
      #
      #   # Publish an array of message Hashes
      #   messages = [
      #     { name: 'click', { x: 1, y: 2 } },
      #     { name: 'click', { x: 2, y: 3 } }
      #   ]
      #   client.publish 'activityChannel', messages
      #
      #   # Publish an array of Ably::Models::Message objects
      #   messages = [
      #     Ably::Models::Message(name: 'click', { x: 1, y: 2 })
      #     Ably::Models::Message(name: 'click', { x: 2, y: 3 })
      #   ]
      #   client.publish 'activityChannel', messages
      #
      #   client.publish('activityChannel', 'click', 'body') do |message|
      #     puts "#{message.name} event received with #{message.data}"
      #   end
      #
      #   client.publish('activityChannel', 'click', 'body').errback do |error, message|
      #     puts "#{message.name} was not received, error #{error.message}"
      #   end
      #
      def publish(channel_name, name, data = nil, attributes = {}, &success_block)
        if !connection.can_publish_messages?
          error = Ably::Exceptions::MessageQueueingDisabled.new("Message cannot be published. Client is not allowed to queue messages when connection is in state #{connection.state}")
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        messages = if name.kind_of?(Enumerable)
          name
        else
          name = ensure_utf_8(:name, name, allow_nil: true)
          ensure_supported_payload data
          [{ name: name, data: data }.merge(attributes)]
        end

        if messages.length > Realtime::Connection::MAX_PROTOCOL_MESSAGE_BATCH_SIZE
          error = Ably::Exceptions::InvalidRequest.new("It is not possible to publish more than #{Realtime::Connection::MAX_PROTOCOL_MESSAGE_BATCH_SIZE} messages with a single publish request.")
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        enqueue_messages_on_connection(self, messages, channel_name).tap do |deferrable|
          deferrable.callback(&success_block) if block_given?
        end
      end

      # @!attribute [r] endpoint
      # @return [URI::Generic] Default Ably Realtime endpoint used for all requests
      def endpoint
        endpoint_for_host(custom_realtime_host || [environment, DOMAIN].compact.join('-'))
      end

      # (see Ably::Rest::Client#register_encoder)
      def register_encoder(encoder)
        rest_client.register_encoder encoder
      end

      # (see Ably::Rest::Client#fallback_hosts)
      def fallback_hosts
        rest_client.fallback_hosts
      end

      # (see Ably::Rest::Client#logger)
      def logger
        @logger ||= Ably::Logger.new(self, log_level, rest_client.logger.custom_logger)
      end

      # Disable connection recovery, typically used after a connection has been recovered
      # @return [void]
      # @api private
      def disable_automatic_connection_recovery
        @recover = nil
      end

      # @!attribute [r] fallback_endpoint
      # @return [URI::Generic] Fallback endpoint used to connect to the realtime Ably service. Note, after each connection attempt, a new random {Ably::FALLBACK_HOSTS fallback host} or provided fallback hosts are used
      # @api private
      def fallback_endpoint
        unless defined?(@fallback_endpoints) && @fallback_endpoints
          @fallback_endpoints = fallback_hosts.shuffle.map { |fallback_host| endpoint_for_host(fallback_host) }
          @fallback_endpoints << endpoint # Try the original host last if all fallbacks have been used
        end

        fallback_endpoint_index = connection.manager.retry_count_for_state(:disconnected) + connection.manager.retry_count_for_state(:suspended) - 1

        @fallback_endpoints[fallback_endpoint_index % @fallback_endpoints.count]
      end

      # The local device detilas
      # @return [Ably::Models::LocalDevice]
      #
      # @note This is unsupported in the Ruby library
      def device
        raise Ably::Exceptions::PushNotificationsNotSupported, 'This device does not support receiving or subscribing to push notifications. The local device object is not unavailable'
      end

      private
      def endpoint_for_host(host)
        port = if use_tls?
          custom_tls_port
        else
          custom_port
        end

        raise ArgumentError, "Custom port must be an Integer or nil" if port && !port.kind_of?(Integer)

        options = {
          scheme: use_tls? ? 'wss' : 'ws',
          host:   host
        }
        options.merge!(port: port) if port

        URI::Generic.build(options)
      end
    end
  end
end
