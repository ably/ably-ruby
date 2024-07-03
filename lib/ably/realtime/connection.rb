require 'securerandom'

module Ably
  module Realtime
    # Enables the management of a connection to Ably.
    #
    class Connection
      include Ably::Modules::EventEmitter
      include Ably::Modules::Conversions
      include Ably::Modules::SafeYield
      extend Ably::Modules::Enum
      using Ably::Util::AblyExtensions


      # The current {Ably::Realtime::Connection::STATE} of the connection.
      # Describes the realtime [Connection]{@link Connection} object states.
      #
      # @spec RTN4d
      #
      # INITIALIZED		A connection with this state has been initialized but no connection has yet been attempted.
      # CONNECTING		A connection attempt has been initiated. The connecting state is entered as soon as the library
      #               has completed initialization, and is reentered each time connection is re-attempted following disconnection.
      # CONNECTED		  A connection exists and is active.
      # DISCONNECTED		A temporary failure condition. No current connection exists because there is no network connectivity
      #                 or no host is available. The disconnected state is entered if an established connection is dropped,
      #                 or if a connection attempt was unsuccessful. In the disconnected state the library will periodically
      #                 attempt to open a new connection (approximately every 15 seconds), anticipating that the connection
      #                 will be re-established soon and thus connection and channel continuity will be possible.
      #                 In this state, developers can continue to publish messages as they are automatically placed
      #                 in a local queue, to be sent as soon as a connection is reestablished. Messages published by
      #                 other clients while this client is disconnected will be delivered to it upon reconnection,
      #                 so long as the connection was resumed within 2 minutes. After 2 minutes have elapsed, recovery
      #                 is no longer possible and the connection will move to the SUSPENDED state.
      # SUSPENDED		  A long term failure condition. No current connection exists because there is no network connectivity
      #               or no host is available. The suspended state is entered after a failed connection attempt if
      #               there has then been no connection for a period of two minutes. In the suspended state, the library
      #               will periodically attempt to open a new connection every 30 seconds. Developers are unable to
      #               publish messages in this state. A new connection attempt can also be triggered by an explicit
      #               call to {Ably::Realtime::Connection#connect}. Once the connection has been re-established,
      #               channels will be automatically re-attached. The client has been disconnected for too long for them
      #               to resume from where they left off, so if it wants to catch up on messages published by other clients
      #               while it was disconnected, it needs to use the History API.
      # CLOSING		  An explicit request by the developer to close the connection has been sent to the Ably service.
      #             If a reply is not received from Ably within a short period of time, the connection is forcibly
      #             terminated and the connection state becomes CLOSED.
      # CLOSED		  The connection has been explicitly closed by the client. In the closed state, no reconnection attempts
      #             are made automatically by the library, and clients may not publish messages. No connection state is
      #             preserved by the service or by the library. A new connection attempt can be triggered by an explicit
      #             call to {Ably::Realtime::Connection#connect}, which results in a new connection.
      # FAILED		  This state is entered if the client library encounters a failure condition that it cannot recover from.
      #             This may be a fatal connection error received from the Ably service, for example an attempt to connect
      #             with an incorrect API key, or a local terminal error, for example the token in use has expired
      #             and the library does not have any way to renew it. In the failed state, no reconnection attempts
      #             are made automatically by the library, and clients may not publish messages. A new connection attempt
      #             can be triggered by an explicit call to {Ably::Realtime::Connection#connect}.
      #
      # @return [Ably::Realtime::Connection::STATE]
      #
      STATE = ruby_enum('STATE',
        :initialized,
        :connecting,
        :connected,
        :disconnected,
        :suspended,
        :closing,
        :closed,
        :failed
      )

      # Describes the events emitted by a {Ably::Realtime::Connection} object. An event is either an UPDATE or a {Ably::Realtime::Connection::STATE}.
      #
      # UPDATE	RTN4h	An event for changes to connection conditions for which the {Ably::Realtime::Connection::STATE} does not change.
      #
      EVENT = ruby_enum('EVENT',
        STATE.to_sym_arr + [:update]
      )

      include Ably::Modules::StateEmitter
      include Ably::Modules::UsesStateMachine
      ensure_state_machine_emits 'Ably::Models::ConnectionStateChange'

      # Defaults for automatic connection recovery and timeouts
      DEFAULTS = {
        channel_retry_timeout:      15, # when a channel becomes SUSPENDED, after this delay in seconds, the channel will automatically attempt to reattach if the connection is CONNECTED
        disconnected_retry_timeout: 15, # when the connection enters the DISCONNECTED state, after this delay in milliseconds, if the state is still DISCONNECTED, the client library will attempt to reconnect automatically
        suspended_retry_timeout:    30, # when the connection enters the SUSPENDED state, after this delay in milliseconds, if the state is still SUSPENDED, the client library will attempt to reconnect automatically
        connection_state_ttl:       120, # the duration that Ably will persist the connection state when a Realtime client is abruptly disconnected
        max_connection_state_ttl:   nil, # allow a max TTL to be passed in, usually for CI test purposes thus overiding any connection_state_ttl sent from Ably
        realtime_request_timeout:   10,  # default timeout when establishing a connection, or sending a HEARTBEAT, CONNECT, ATTACH, DETACH or CLOSE ProtocolMessage
        websocket_heartbeats_disabled: false,
      }.freeze

      # Max number of messages to bundle in a single ProtocolMessage
      MAX_PROTOCOL_MESSAGE_BATCH_SIZE = 50

      # A unique public identifier for this connection, used to identify this member.
      #
      # @spec RTN8
      #
      # @return [String]
      #
      attr_reader :id

      # A unique private connection key used to recover or resume a connection, assigned by Ably.
      # When recovering a connection explicitly, the recoveryKey is used in the recover client options as it contains
      # both the key and the last message serial. This private connection key can also be used by other REST clients
      # to publish on behalf of this client. See the publishing over REST on behalf of a realtime client docs for more info.
      #
      # @spec RTN9
      #
      # @return [String]
      #
      attr_reader :key

      # An {Ably::Models::ErrorInfo} object describing the last error received if a connection failure occurs.
      #
      # @spec RTN14a
      #
      # @return [Ably::Models::ErrorInfo,Ably::Exceptions::BaseAblyException]
      #
      attr_reader :error_reason

      # Connection details of the currently established connection
      # @return [Ably::Models::ConnectionDetails]
      attr_reader :details

      # {Ably::Realtime::Client} associated with this connection
      # @return [Ably::Realtime::Client]
      attr_reader :client

      # Underlying socket transport used for this connection, for internal use by the client library
      # @return [Ably::Realtime::Connection::WebsocketTransport]
      # @api private
      attr_reader :transport

      # The Connection manager responsible for creating, maintaining and closing the connection and underlying transport
      # @return [Ably::Realtime::Connection::ConnectionManager]
      # @api private
      attr_reader :manager

      # An internal queue used to manage unsent outgoing messages. You should never interface with this array directly
      # @return [Array]
      # @api private
      attr_reader :__outgoing_message_queue__

      # An internal queue used to manage sent messages. You should never interface with this array directly
      # @return [Array]
      # @api private
      attr_reader :__pending_message_ack_queue__

      # Configured recovery and timeout defaults for this {Connection}.
      # See the configurable options in {Ably::Realtime::Client#initialize}.
      # The defaults are immutable
      # @return [Hash]
      attr_reader :defaults

      # @api public
      def initialize(client, options)
        @client                        = client
        @__outgoing_message_queue__    = []
        @__pending_message_ack_queue__ = []

        @defaults = DEFAULTS.dup
        options.each do |key, val|
          @defaults[key] = val if DEFAULTS.has_key?(key)
        end if options.kind_of?(Hash)
        @defaults.freeze

        Client::IncomingMessageDispatcher.new client, self
        Client::OutgoingMessageDispatcher.new client, self

        @state_machine = ConnectionStateMachine.new(self)
        @state         = STATE(state_machine.current_state)
        @manager       = ConnectionManager.new(self)

        @current_host = client.endpoint.host

        reset_client_msg_serial
      end

      # Causes the connection to close, entering the {Ably::Realtime::Connection::STATE} CLOSING state.
      # Once closed, the library does not attempt to re-establish the connection without an explicit call to
      # {Ably::Realtime::Connection#connect}.
      #
      # @spec RTN12
      #
      # @yield block is called as soon as this connection is in the Closed state
      #
      # @return [EventMachine::Deferrable]
      #
      def close(&success_block)
        unless closing? || closed?
          unless can_transition_to?(:closing)
            return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, exception_for_state_change_to(:closing))
          end
          transition_state_machine :closing
        end
        deferrable_for_state_change_to(STATE.Closed, &success_block)
      end

      # Explicitly calling connect() is unnecessary unless the autoConnect attribute of
      # the ClientOptions object is false. Unless already connected or connecting,
      # this method causes the connection to open, entering the {Ably::Realtime::Connection::STATE} CONNECTING state.
      #
      # @spec RTC1b, RTN3, RTN11
      #
      # @yield block is called as soon as this connection is in the Connected state
      #
      # @return [EventMachine::Deferrable]
      #
      def connect(&success_block)
        unless connecting? || connected?
          unless can_transition_to?(:connecting)
            return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, exception_for_state_change_to(:connecting))
          end
          # If connect called in a suspended block, we want to ensure the other callbacks have finished their work first
          EventMachine.next_tick { transition_state_machine :connecting if can_transition_to?(:connecting) }
        end

        Ably::Util::SafeDeferrable.new(logger).tap do |deferrable|
          deferrable.callback do
            yield if block_given?
          end
          succeed_callback = deferrable.method(:succeed)
          fail_callback    = deferrable.method(:fail)

          unsafe_once(:connected) do
            deferrable.succeed
            off(&fail_callback)
          end

          unsafe_once(:failed, :closed, :closing) do
            deferrable.fail
            off(&succeed_callback)
          end
        end
      end

      # When connected, sends a heartbeat ping to the Ably server and executes the callback with any error
      # and the response time in milliseconds when a heartbeat ping request is echoed from the server.
      # This can be useful for measuring true round-trip latency to the connected Ably server.
      #
      # @spec RTN13
      #
      # @yield [Integer] if a block is passed to this method, then this block will be called once the ping heartbeat is received with the time elapsed in seconds.
      #                  If the ping is not received within an acceptable timeframe, the block will be called with +nil+ as he first argument
      #
      # @example
      #    client = Ably::Rest::Client.new(key: 'key.id:secret')
      #    client.connection.ping do |elapsed_s|
      #      puts "Ping took #{elapsed_s}s"
      #    end
      #
      # @return [Ably::Util::SafeDeferrable]
      #
      def ping(&block)
        if initialized? || suspended? || closing? || closed? || failed?
          error = Ably::Models::ErrorInfo.new(message: "Cannot send a ping when the connection is #{state}", code: Ably::Exceptions::Codes::DISCONNECTED)
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        Ably::Util::SafeDeferrable.new(logger).tap do |deferrable|
          started = nil
          finished = false
          ping_id = SecureRandom.hex(16)
          heartbeat_action = Ably::Models::ProtocolMessage::ACTION.Heartbeat

          wait_for_ping = lambda do |protocol_message|
            next if finished
            if protocol_message.action == heartbeat_action && protocol_message.id == ping_id
              finished = true
              __incoming_protocol_msgbus__.unsubscribe(:protocol_message, &wait_for_ping)
              time_passed = Time.now.to_f - started.to_f
              deferrable.succeed time_passed
              safe_yield block, time_passed if block_given?
            end
          end

          once_or_if(STATE.Connected) do
            next if finished
            started = Time.now
            send_protocol_message action: heartbeat_action.to_i, id: ping_id
            __incoming_protocol_msgbus__.subscribe :protocol_message, &wait_for_ping
          end

          once_or_if([:suspended, :closing, :closed, :failed]) do
            next if finished
            finished = true
            deferrable.fail Ably::Models::ErrorInfo.new(message: "Ping failed as connection has changed state to #{state}", code: Ably::Exceptions::Codes::DISCONNECTED)
          end

          EventMachine.add_timer(defaults.fetch(:realtime_request_timeout)) do
            next if finished
            finished = true
            __incoming_protocol_msgbus__.unsubscribe(:protocol_message, &wait_for_ping)
            error_msg = "Ping timed out after #{defaults.fetch(:realtime_request_timeout)}s"
            logger.warn { error_msg }
            deferrable.fail Ably::Models::ErrorInfo.new(message: error_msg, code: Ably::Exceptions::Codes::TIMEOUT_ERROR)
            safe_yield block, nil if block_given?
          end
        end
      end

      # @yield [Boolean] True if an internet connection check appears to be up following an HTTP request to a reliable CDN
      # @return [EventMachine::Deferrable]
      # @api private
      def internet_up?
        url = "http#{'s' if client.use_tls?}:#{Ably::INTERNET_CHECK.fetch(:url)}"
        EventMachine::DefaultDeferrable.new.tap do |deferrable|
          EventMachine::AblyHttpRequest::HttpRequest.new(url, tls: { verify_peer: true }).get.tap do |http|
            http.errback do
              yield false if block_given?
              deferrable.fail Ably::Exceptions::ConnectionFailed.new("Unable to connect to #{url}", nil, Ably::Exceptions::Codes::CONNECTION_FAILED)
            end
            http.callback do
              EventMachine.next_tick do
                result = http.response_header.status == 200 && http.response.strip == Ably::INTERNET_CHECK.fetch(:ok_text)
                yield result if block_given?
                if result
                  deferrable.succeed
                else
                  deferrable.fail Ably::Exceptions::ConnectionFailed.new("Unexpected response from #{url} (#{http.response_header.status})", 400, Ably::Exceptions::Codes::BAD_REQUEST)
                end
              end
            end
          end
        end
      end

      # The recovery key string can be used by another client to recover this connection's state in the
      # recover client options property. See connection state recover options for more information.
      #
      # @spec RTN16b, RTN16c
      #
      # @deprecated Use {#create_recovery_key} instead
      #
      def recovery_key
        logger.warn "[DEPRECATION] recovery_key is deprecated, use create_recovery_key method instead"
        create_recovery_key
      end

      # The recovery key string can be used by another client to recover this connection's state in the recover client
      # options property. See connection state recover options for more information.
      #
      # @spec RTN16g, RTN16c
      #
      # @return [String] a json string which incorporates the @connectionKey@, the current @msgSerial@ and collection
      # of pairs of channel @name@ and current @channelSerial@ for every currently attached channel
      def create_recovery_key
        if key.nil_or_empty? || state == :closing || state == :closed || state == :failed || state == :suspended
          return nil #RTN16g2
        end
        RecoveryKeyContext.new(key, client_msg_serial, client.channels.get_channel_serials).to_json
      end

      # Following a new connection being made, the connection ID, connection key
      # need to match the details provided by the server.
      #
      # @return [void]
      # @api private
      def configure_new(connection_id, connection_key)
        @id            = connection_id
        @key           = connection_key
      end

      # Disable automatic resume of a connection
      # @return [void]
      # @api private
      def reset_resume_info
        @key    = nil
        @id     = nil
      end

      # @!attribute [r] __outgoing_protocol_msgbus__
      # @return [Ably::Util::PubSub] Client library internal outgoing protocol message bus
      # @api private
      def __outgoing_protocol_msgbus__
        @__outgoing_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # @!attribute [r] __incoming_protocol_msgbus__
      # @return [Ably::Util::PubSub] Client library internal incoming protocol message bus
      # @api private
      def __incoming_protocol_msgbus__
        @__incoming_protocol_msgbus__ ||= create_pub_sub_message_bus
      end

      # Determines the correct host name to use for the next connection attempt and updates current_host
      # @yield [String] The host name used for this connection, for network connection failures a {Ably::FALLBACK_HOSTS fallback host} is used to route around networking or intermittent problems if an Internet connection is available
      # @api private
      def determine_host
        raise ArgumentError, 'Block required' unless block_given?

        if should_use_fallback_hosts?
          internet_up? do |internet_is_up_result|
            @current_host = if internet_is_up_result
              client.fallback_endpoint.host
            else
              client.endpoint.host
            end
            yield current_host
          end
        else
          @current_host = client.endpoint.host
          yield current_host
        end
      end

      # @return [String] The current host that is configured following a call to method {#determine_host}
      # @api private
      attr_reader :current_host

      # @!attribute [r] port
      # @return [Integer] The default port used for this connection
      def port
        client.use_tls? ? client.custom_tls_port || 443 : client.custom_port || 80
      end

      # @!attribute [r] logger
      # @return [Logger] The {Ably::Logger} for this client.
      #                  Configure the log_level with the `:log_level` option, refer to {Ably::Realtime::Client#initialize}
      def logger
        client.logger
      end

      # Add protocol message to the outgoing message queue and notify the dispatcher that a message is
      # ready to be sent
      #
      # @param [Ably::Models::ProtocolMessage] protocol_message
      # @return [void]
      # @api private
      def send_protocol_message(protocol_message)
        add_message_serial_if_ack_required_to(protocol_message) do
          Ably::Models::ProtocolMessage.new(protocol_message, logger: logger).tap do |message|
            add_message_to_outgoing_queue message
            notify_message_dispatcher_of_new_message message
            logger.debug { "Connection: Prot msg queued =>: #{message.action} #{message}" }
          end
        end
      end

      # @api private
      def add_message_to_outgoing_queue(protocol_message)
        __outgoing_message_queue__ << protocol_message
      end

      # @api private
      def notify_message_dispatcher_of_new_message(protocol_message)
        __outgoing_protocol_msgbus__.publish :protocol_message, protocol_message
      end

      # @return [EventMachine::Deferrable]
      # @api private
      def create_websocket_transport
        EventMachine::DefaultDeferrable.new.tap do |websocket_deferrable|
          # Getting auth params can be blocking so uses a Deferrable
          client.auth.auth_params.tap do |auth_deferrable|
            auth_deferrable.callback do |auth_params|
              url_params = auth_params.merge(
                'format' =>     client.protocol,
                'echo' =>       client.echo_messages,
                'v' =>          Ably::PROTOCOL_VERSION, # RSC7a
                'agent' =>      client.rest_client.agent
              )

              # Use native websocket heartbeats if possible, but allow Ably protocol heartbeats
              url_params['heartbeats'] = if defaults.fetch(:websocket_heartbeats_disabled)
                'true'
              else
                'false'
              end
              # RSA7e1
              url_params['clientId'] = client.auth.client_id_for_request_sync if client.auth.client_id_for_request_sync
              url_params.merge!(client.transport_params)

              if !key.nil_or_empty? and connection_state_available?
                url_params.merge! resume: key
                logger.debug { "Resuming connection with key #{key}" }
              elsif !client.recover.nil_or_empty?
                recovery_context = RecoveryKeyContext.from_json(client.recover, logger)
                unless recovery_context.nil?
                  key = recovery_context.connection_key
                  logger.debug { "Recovering connection with key #{key}" }
                  url_params.merge! recover: key
                end
              end

              url = URI(client.endpoint).tap do |endpoint|
                endpoint.query = URI.encode_www_form(url_params)
              end

              determine_host do |host|
                # Ensure the hostname matches the fallback host name
                url.hostname = host
                url.port = port

                begin
                  logger.debug { "Connection: Opening socket connection to #{host}:#{port}/#{url.path}?#{url.query}" }
                  @transport = create_transport(host, port, url) do |websocket_transport|
                    websocket_deferrable.succeed websocket_transport
                  end
                rescue EventMachine::ConnectionError => error
                  websocket_deferrable.fail error
                end
              end
            end

            auth_deferrable.errback do |error|
              websocket_deferrable.fail error
            end
          end
        end
      end

      # @api private
      def release_websocket_transport
        @transport = nil
      end

      # @api private
      def set_failed_connection_error_reason(error)
        @error_reason = error
      end

      # @api private
      def clear_error_reason
        @error_reason = nil
      end

      # @api private
      def set_connection_details(connection_details)
        @details = connection_details
      end

      # Returns false if messages cannot be published as a result of message queueing being disabled
      # @api private
      def can_publish_messages?
        connected? ||
          ( (initialized? || connecting? || disconnected?) && client.queue_messages )
      end

      # @api private
      def create_transport(host, port, url, &block)
        logger.debug { "Connection: EventMachine connecting to #{host}:#{port} with URL: #{url}" }
        EventMachine.connect(host, port, WebsocketTransport, self, url.to_s, &block)
      end

      # @api private
      def connection_state_ttl
        defaults[:max_connection_state_ttl] || # undocumented max TTL configuration
          (details && details.connection_state_ttl) ||
          defaults.fetch(:connection_state_ttl)
      end

      def connection_state_ttl=(val)
        @connection_state_ttl = val
      end

      # @api private
      def heartbeat_interval
        # See RTN23a
        (details && details.max_idle_interval).to_i +
          defaults.fetch(:realtime_request_timeout)
      end

      # Resets the client message serial (msgSerial) sent to Ably for each new {Ably::Models::ProtocolMessage}
      # (see #client_msg_serial)
      # @api private
      def reset_client_msg_serial
        @client_msg_serial = -1
      end

      # Sets the client message serial from recover clientOption.
      # @api private
      def set_msg_serial_from_recover=(value)
        @client_msg_serial = value
      end

      # When a hearbeat or any other message from Ably is received
      # we know it's alive, see #RTN23
      # @api private
      def set_connection_confirmed_alive
        @last_liveness_event = Time.now
        manager.reset_liveness_timer
      end

      # @api private
      def time_since_connection_confirmed_alive?
        Time.now.to_i - @last_liveness_event.to_i
      end

      # As we are using a state machine, do not allow change_state to be used
      # #transition_state_machine must be used instead
      private :change_state

      private

      # The client message serial (msgSerial) is incremented for every message that is published that requires an ACK.
      # A message serial number does not guarantee a message has been received, only sent.
      # @return [Integer] starting at -1 indicating no messages sent, 0 when the first message is sent
      def client_msg_serial
        @client_msg_serial
      end

      def create_pub_sub_message_bus
        Ably::Util::PubSub.new(
          coerce_into: lambda do |event|
            raise KeyError, "Expected :protocol_message, :#{event} is disallowed" unless event == :protocol_message
            :protocol_message
          end
        )
      end

      def add_message_serial_if_ack_required_to(protocol_message)
        if Ably::Models::ProtocolMessage.ack_required?(protocol_message[:action])
          add_message_serial_to(protocol_message) { yield }
        else
          yield
        end
      end

      def add_message_serial_to(protocol_message)
        @client_msg_serial += 1
        protocol_message[:msgSerial] = client_msg_serial
        yield
      rescue StandardError => e
        @client_msg_serial -= 1
        raise e
      end

      # Simply wait until the next EventMachine tick to ensure Connection initialization is complete
      def when_initialized
        EventMachine.next_tick { yield }
      end

      def connection_state_available?
        return true if connected?

        return false if time_since_connection_confirmed_alive? > connection_state_ttl + details.max_idle_interval

        connected_last = state_history.reverse.find { |connected| connected.fetch(:state) == :connected }
        if connected_last.nil?
          false
        else
          true
        end
      end

      def production?
        client.environment.nil? || client.environment == :production
      end

      def custom_port?
        if client.use_tls?
          !!client.custom_tls_port
        else
          !!client.custom_port
        end
      end

      def custom_host?
        !!client.custom_realtime_host
      end

      def should_use_fallback_hosts?
        if client.fallback_hosts && !client.fallback_hosts.empty?
          if connecting? && previous_state && !disconnected_from_connected_state?
            use_fallback_if_disconnected? || use_fallback_if_suspended?
          end
        end
      end

      def disconnected_from_connected_state?
        most_recent_state_changes = state_history.last(3).first(2) # Ignore current state

        # A valid connection was disconnected
        most_recent_state_changes.last.fetch(:state) == Connection::STATE.Disconnected &&
          most_recent_state_changes.first.fetch(:state) == Connection::STATE.Connected
      end

      def use_fallback_if_disconnected?
        second_reconnect_attempt_for(:disconnected, 1)
      end

      def use_fallback_if_suspended?
        second_reconnect_attempt_for(:suspended, 2) # on first suspended state use default Ably host again
      end

      def second_reconnect_attempt_for(state, first_attempt_count)
        previous_state == state && manager.retry_count_for_state(state) >= first_attempt_count
      end
    end
  end
end

require 'ably/realtime/connection/connection_manager'
require 'ably/realtime/connection/connection_state_machine'
require 'ably/realtime/connection/websocket_transport'
require 'ably/realtime/recovery_key_context'
