require 'securerandom'

module Ably
  module Realtime
    # The Connection class represents the connection associated with an Ably Realtime instance.
    # The Connection object exposes the lifecycle and parameters of the realtime connection.
    #
    # Connections will always be in one of the following states:
    #
    #   initialized:  0
    #   connecting:   1
    #   connected:    2
    #   disconnected: 3
    #   suspended:    4
    #   closing:      5
    #   closed:       6
    #   failed:       7
    #
    # Note that the states are available as Enum-like constants:
    #
    #   Connection::STATE.Initialized
    #   Connection::STATE.Connecting
    #   Connection::STATE.Connected
    #   Connection::STATE.Disconnected
    #   Connection::STATE.Suspended
    #   Connection::STATE.Closing
    #   Connection::STATE.Closed
    #   Connection::STATE.Failed
    #
    # @example
    #    client = Ably::Realtime::Client.new('key.id:secret')
    #    client.connection.on(:connected) do
    #      puts "Connected with connection ID: #{client.connection.id}"
    #    end
    #
    # @!attribute [r] state
    #   @return [Ably::Realtime::Connection::STATE] connection state
    #
    class Connection
      include Ably::Modules::EventEmitter
      include Ably::Modules::Conversions
      include Ably::Modules::SafeYield
      extend Ably::Modules::Enum

      # ConnectionState
      # The permited states for this connection
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

      # ConnectionEvent
      # The permitted connection events that are emitted for this connection
      EVENT = ruby_enum('EVENT',
        STATE.to_sym_arr + [:update]
      )

      include Ably::Modules::StateEmitter
      include Ably::Modules::UsesStateMachine
      ensure_state_machine_emits 'Ably::Models::ConnectionStateChange'

      # Expected format for a connection recover key
      RECOVER_REGEX = /^(?<recover>[^:]+):(?<connection_serial>[^:]+):(?<msg_serial>\-?\d+)$/

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

      # A unique public identifier for this connection, used to identify this member in presence events and messages
      # @return [String]
      attr_reader :id

      # A unique private connection key used to recover this connection, assigned by Ably
      # @return [String]
      attr_reader :key

      # The serial number of the last message to be received on this connection, used to recover or resume a connection
      # @return [Integer]
      attr_reader :serial

      # When a connection failure occurs this attribute contains the Ably Exception
      # @return [Ably::Models::ErrorInfo,Ably::Exceptions::BaseAblyException]
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

        # If a recover client options is provided, then we need to ensure that the msgSerial matches the
        # recover serial immediately at client library instantiation. This is done immediately so that any queued
        # publishes use the correct serial number for these queued messages as well.
        # There is no harm if the msgSerial is higher than expected if the recover fails.
        recovery_msg_serial = connection_recover_parts && connection_recover_parts[:msg_serial].to_i
        if recovery_msg_serial
          @client_msg_serial = recovery_msg_serial
        else
          reset_client_msg_serial
        end

        Client::IncomingMessageDispatcher.new client, self
        Client::OutgoingMessageDispatcher.new client, self

        @state_machine = ConnectionStateMachine.new(self)
        @state         = STATE(state_machine.current_state)
        @manager       = ConnectionManager.new(self)

        @current_host = client.endpoint.host
      end

      # Causes the connection to close, entering the closed state, from any state except
      # the failed state. Once closed, the library will not attempt to re-establish the
      # connection without a call to {Connection#connect}.
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

      # Causes the library to attempt connection.  If it was previously explicitly
      # closed by the user, or was closed as a result of an unrecoverable error, a new connection will be opened.
      # Succeeds when connection is established i.e. state is @Connected@
      # Fails when state becomes either @Closing@, @Closed@ or @Failed@
      #
      # Note that if the connection remains in the disconnected ans suspended states indefinitely,
      # the Deferrable or block provided may never be called
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

      # Sends a ping to Ably and yields the provided block when a heartbeat ping request is echoed from the server.
      # This can be useful for measuring true roundtrip client to Ably server latency for a simple message, or checking that an underlying transport is responding currently.
      # The elapsed time in seconds is passed as an argument to the block and represents the time taken to echo a ping heartbeat once the connection is in the `:connected` state.
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
          EventMachine::HttpRequest.new(url).get.tap do |http|
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

      # @!attribute [r] recovery_key
      # @return [String] recovery key that can be used by another client to recover this connection with the :recover option
      def recovery_key
        "#{key}:#{serial}:#{client_msg_serial}" if connection_resumable?
      end

      # Following a new connection being made, the connection ID, connection key
      # and connection serial need to match the details provided by the server.
      #
      # @return [void]
      # @api private
      def configure_new(connection_id, connection_key, connection_serial)
        @id            = connection_id
        @key           = connection_key

        update_connection_serial connection_serial
      end

      # Store last received connection serial so that the connection can be resumed from the last known point-in-time
      # @return [void]
      # @api private
      def update_connection_serial(connection_serial)
        @serial = connection_serial
      end

      # Disable automatic resume of a connection
      # @return [void]
      # @api private
      def reset_resume_info
        @key    = nil
        @serial = nil
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
                format:     client.protocol,
                echo:       client.echo_messages,
                v:          Ably::PROTOCOL_VERSION,
                lib:        client.rest_client.lib_version_id,
              )

              # Use native websocket heartbeats if possible, but allow Ably protocol heartbeats
              url_params['heartbeats'] = if defaults.fetch(:websocket_heartbeats_disabled)
                'true'
              else
                'false'
              end

              url_params['clientId'] = client.auth.client_id if client.auth.has_client_id?

              if connection_resumable?
                url_params.merge! resume: key, connection_serial: serial
                logger.debug { "Resuming connection key #{key} with serial #{serial}" }
              elsif connection_recoverable?
                url_params.merge! recover: connection_recover_parts[:recover], connectionSerial: connection_recover_parts[:connection_serial]
                logger.debug { "Recovering connection with key #{client.recover}" }
                unsafe_once(:connected, :closed, :failed) do
                  client.disable_automatic_connection_recovery
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

      # Executes registered callbacks for a successful connection resume event
      # @api private
      def trigger_resumed
        resume_callbacks.each(&:call)
      end

      # Provides a simple hook to inject a callback when a connection is successfully resumed
      # @api private
      def on_resume(&callback)
        resume_callbacks << callback
      end

      # Remove a registered connection resume callback
      # @api private
      def off_resume(&callback)
        resume_callbacks.delete(callback)
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
      # Note that this is different to the connection serial that contains the last known serial number
      # received from the server.
      #
      # A message serial number does not guarantee a message has been received, only sent.
      # A connection serial guarantees the server has received the message and is thus used for connection recovery and resumes.
      # @return [Integer] starting at -1 indicating no messages sent, 0 when the first message is sent
      def client_msg_serial
        @client_msg_serial
      end

      def resume_callbacks
        @resume_callbacks ||= []
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

      def connection_resumable?
        !key.nil? && !serial.nil? && connection_state_available?
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

      def connection_recoverable?
        connection_recover_parts
      end

      def connection_recover_parts
        client.recover.to_s.match(RECOVER_REGEX)
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
