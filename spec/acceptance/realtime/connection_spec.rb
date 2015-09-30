# encoding: utf-8
require 'spec_helper'
require 'ostruct'

describe Ably::Realtime::Connection, :event_machine do
  let(:connection) { client.connection }

  vary_by_protocol do
    let(:default_options) do
      { key: api_key, environment: environment, protocol: protocol }
    end

    let(:client_options) { default_options }
    let(:client)         { Ably::Realtime::Client.new(client_options) }

    before(:example) do
      EventMachine.add_shutdown_hook do
        connection.off # minimise side effects of callbacks from finished test calling stop_reactor
      end
    end

    context 'intialization' do
      it 'connects automatically' do
        connection.on(:connected) do
          expect(connection.state).to eq(:connected)
          stop_reactor
        end
      end

      context 'with :auto_connect option set to false' do
        let(:client) do
          Ably::Realtime::Client.new(default_options.merge(auto_connect: false))
        end

        it 'does not connect automatically' do
          EventMachine.add_timer(1) do
            expect(connection).to be_initialized
            stop_reactor
          end
          client
        end

        it 'connects when method #connect is called' do
          connection.connect do
            expect(connection).to be_connected
            stop_reactor
          end
        end
      end

      context 'with token auth' do
        before do
          # Reduce token expiry buffer to zero so that a token expired? predicate is exact
          # Normally there is a buffer so that a token expiring soon is considered expired
          @original_token_expiry_buffer = Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER
          stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0
        end

        let(:original_token_expiry_buffer) { @original_token_expiry_buffer }

        context 'for renewable tokens' do
          context 'that are valid for the duration of the test' do
            context 'with valid pre authorised token expiring in the future' do
              it 'uses the existing token created by Auth' do
                client.auth.authorise(ttl: 300)
                expect(client.auth).to_not receive(:request_token)
                connection.once(:connected) do
                  stop_reactor
                end
              end
            end

            context 'with implicit authorisation' do
              let(:client_options) { default_options.merge(client_id: 'force_token_auth') }

              it 'uses the token created by the implicit authorisation' do
                expect(client.rest_client.auth).to receive(:request_token).once.and_call_original

                connection.once(:connected) do
                  stop_reactor
                end
              end
            end
          end

          context 'that expire' do
            let(:client_options) { default_options.merge(log_level: :none) }

            before do
              expect(client.rest_client.time.to_f).to be_within(2).of(Time.now.to_i), "Local clock is out of sync with Ably"
            end

            before do
              # Ensure tokens issued expire immediately after issue
              @original_renew_token_buffer = Ably::Auth::TOKEN_DEFAULTS.fetch(:renew_token_buffer)
              stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0)

              # Authorise synchronously to ensure token has been issued
              client.auth.authorise_sync(ttl: ttl)
            end

            let(:original_renew_token_buffer) { @original_renew_token_buffer }

            context 'opening a new connection' do
              context 'with recently expired token' do
                let(:ttl) { 2 }

                it 'renews the token on connect without changing connection state' do
                  connection.once(:connecting) do
                    sleep ttl + 0.1
                    expect(client.auth.current_token_details).to be_expired
                    expect(client.rest_client.auth).to receive(:authorise).at_least(:once).and_call_original
                    connection.once(:connected) do
                      expect(client.auth.current_token_details).to_not be_expired
                      stop_reactor
                    end
                    connection.once_state_changed do
                      raise "Invalid state #{connection.state}" unless connection.state == :connected
                    end
                  end
                end
              end

              context 'with immediately expiring token' do
                let(:ttl) { 0.001 }

                it 'renews the token on connect, and only makes one subsequent attempt to obtain a new token' do
                  expect(client.rest_client.auth).to receive(:authorise).at_least(:twice).and_call_original
                  connection.once(:disconnected) do
                    connection.once(:failed) do |connection_state_change|
                      expect(connection_state_change.reason.code).to eql(40140) # token expired
                      stop_reactor
                    end
                  end
                end

                it 'uses the primary host for subsequent connection and auth requests' do
                  EventMachine.add_timer(1) do # wait for token to expire
                    connection.once(:disconnected) do
                      expect(client.rest_client.connection).to receive(:post).
                                                                 with(/requestToken$/, anything).
                                                                 at_least(:once).
                                                                 and_call_original

                      expect(client.rest_client).to_not receive(:fallback_connection)
                      expect(client).to_not receive(:fallback_endpoint)

                      connection.once(:failed) do
                        connection.off
                        stop_reactor
                      end
                    end
                  end
                end
              end
            end

            context 'when connected with a valid non-expired token' do
              context 'that then expires following the connection being opened' do
                let(:ttl)     { 5 }
                let(:channel) { client.channel('test') }

                context 'the server' do
                  it 'disconnects the client, and the client automatically renews the token and then reconnects', em_timeout: 15 do
                    original_token = client.auth.current_token_details
                    expect(original_token).to_not be_expired

                    connection.once(:connected) do
                      started_at = Time.now
                      connection.once(:disconnected) do |connection_state_change|
                        expect(connection_state_change.reason.code).to eq(40140) # Token expired

                        # Token has expired, so now ensure it is not used again
                        stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', original_token_expiry_buffer
                        stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: original_renew_token_buffer)

                        connection.once(:connected) do
                          expect(client.auth.current_token_details).to_not be_expired
                          expect(Time.now - started_at >= ttl)
                          expect(original_token).to be_expired
                          stop_reactor
                        end
                      end
                    end

                    connection.unsafe_once(:failed) { |error| fail error.inspect }

                    channel.attach
                  end
                end

                skip 'retains connection state'
                skip 'changes state to failed if a new token cannot be issued'
              end
            end
          end
        end

        context 'for non-renewable tokens' do
          context 'that are expired' do
            before do
              stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0)
            end

            let!(:expired_token_details) do
              # Request a token synchronously
              Ably::Realtime::Client.new(default_options).auth.request_token_sync(ttl: 0.01)
            end

            context 'opening a new connection' do
              let(:client_options) { default_options.merge(key: nil, token: expired_token_details.token, log_level: :none) }

              it 'transitions state to failed', em_timeout: 10 do
                EventMachine.add_timer(1) do # wait for token to expire
                  expect(expired_token_details).to be_expired
                  connection.once(:connected) { raise 'Connection should never connect as token has expired' }
                  connection.once(:failed) do
                    expect(client.connection.error_reason.code).to eql(40140)
                    stop_reactor
                  end
                end
              end
            end

            context 'when connected' do
              skip 'transitions state to failed'
            end
          end
        end
      end
    end

    context 'initialization state changes' do
      let(:phases) { [:connecting, :connected] }
      let(:events_emitted) { [] }
      let(:test_expectation) do
        Proc.new do
          expect(events_emitted).to eq(phases)
          stop_reactor
        end
      end

      def expect_ordered_phases
        phases.each do |phase|
          connection.on(phase) do
            events_emitted << phase
            test_expectation.call if events_emitted.length == phases.length
          end
        end
      end

      context 'with implicit #connect' do
        it 'are emitted in order' do
          expect_ordered_phases
        end
      end

      context 'with explicit #connect' do
        it 'are emitted in order' do
          expect_ordered_phases
          connection.connect
        end
      end
    end

    context '#connect' do
      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        expect(connection.connect).to be_a(Ably::Util::SafeDeferrable)
        stop_reactor
      end

      it 'calls the Deferrable callback on success' do
        connection.connect.callback do |connection|
          expect(connection).to be_a(Ably::Realtime::Connection)
          expect(connection.state).to eq(:connected)
          stop_reactor
        end
      end

      context 'when already connected' do
        it 'does nothing and no further state changes are emitted' do
          connection.once(:connected) do
            connection.once_state_changed { raise 'State should not have changed' }
            3.times { connection.connect }
            EventMachine.add_timer(1) do
              expect(connection).to be_connected
              connection.off
              stop_reactor
            end
          end
        end
      end

      describe 'connection#id' do
        it 'is null before connecting' do
          expect(connection.id).to be_nil
          stop_reactor
        end
      end

      describe 'connection#key' do
        it 'is null before connecting' do
          expect(connection.key).to be_nil
          stop_reactor
        end
      end

      describe 'once connected' do
        let(:connection2) {  Ably::Realtime::Client.new(client_options).connection }

        describe 'connection#id' do
          it 'is a string' do
            connection.connect do
              expect(connection.id).to be_a(String)
              stop_reactor
            end
          end

          it 'is unique from the connection#key' do
            connection.connect do
              expect(connection.id).to_not eql(connection.key)
              stop_reactor
            end
          end

          it 'is unique for every connection' do
            when_all(connection.connect, connection2.connect) do
              expect(connection.id).to_not eql(connection2.id)
              stop_reactor
            end
          end
        end

        describe 'connection#key' do
          it 'is a string' do
            connection.connect do
              expect(connection.key).to be_a(String)
              stop_reactor
            end
          end

          it 'is unique from the connection#id' do
            connection.connect do
              expect(connection.key).to_not eql(connection.id)
              stop_reactor
            end
          end

          it 'is unique for every connection' do
            when_all(connection.connect, connection2.connect) do
              expect(connection.key).to_not eql(connection2.key)
              stop_reactor
            end
          end
        end
      end

      context 'following a previous connection being opened and closed' do
        it 'reconnects and is provided with a new connection ID and connection key from the server' do
          connection.connect do
            connection_id  = connection.id
            connection_key = connection.key

            connection.close do
              connection.connect do
                expect(connection.id).to_not eql(connection_id)
                expect(connection.key).to_not eql(connection_key)
                stop_reactor
              end
            end
          end
        end
      end

      context 'when closing' do
        it 'raises an exception before the connection is closed' do
          connection.connect do
            connection.once(:closing) do
              expect { connection.connect }.to raise_error Ably::Exceptions::InvalidStateChange
              stop_reactor
            end
            connection.close
          end
        end
      end
    end

    describe '#serial connection serial' do
      let(:channel) { client.channel(random_str) }

      it 'is set to -1 when a new connection is opened' do
        connection.connect do
          expect(connection.serial).to eql(-1)
          stop_reactor
        end
      end

      context 'when a message is sent but the ACK has not yet been received' do
        it 'the sent message msgSerial is 0 but the connection serial remains at -1' do
          channel.attach do
            connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              connection.__outgoing_protocol_msgbus__.unsubscribe
              expect(protocol_message['msgSerial']).to eql(0)
              expect(connection.serial).to eql(-1)
              stop_reactor
            end
            channel.publish('event', 'data')
          end
        end
      end

      it 'is set to 0 when a message sent ACK is received' do
        channel.publish('event', 'data') do
          expect(connection.serial).to eql(0)
          stop_reactor
        end
      end

      it 'is set to 1 when the second message sent ACK is received' do
        channel.publish('event', 'data') do
          channel.publish('event', 'data') do
            expect(connection.serial).to eql(1)
            stop_reactor
          end
        end
      end
    end

    context '#close' do
      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        connection.connect do
          expect(connection.close).to be_a(Ably::Util::SafeDeferrable)
          stop_reactor
        end
      end

      it 'calls the Deferrable callback on success' do
        connection.connect do
          connection.close.callback do |connection|
            expect(connection).to be_a(Ably::Realtime::Connection)
            expect(connection.state).to eq(:closed)
            stop_reactor
          end
        end
      end

      context 'when already closed' do
        it 'does nothing and no further state changes are emitted' do
          connection.once(:connected) do
            connection.close do
              connection.once_state_changed { raise 'State should not have changed' }
              3.times { connection.close }
              EventMachine.add_timer(1) do
                expect(connection).to be_closed
                connection.off
                stop_reactor
              end
            end
          end
        end
      end

      context 'when connection state is' do
        let(:events) { Hash.new }

        def log_connection_changes
          connection.on(:closing) { events[:closing_emitted] = true }
          connection.on(:error)   { events[:error_emitted] = true }

          connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
            events[:closed_message_from_server_received] = true if protocol_message.action == :closed
          end
        end

        context ':initialized' do
          it 'changes the connection state to :closing and then immediately :closed without sending a ProtocolMessage CLOSE' do
            connection.on(:closed) do
              expect(connection.state).to eq(:closed)

              EventMachine.add_timer(1) do # allow for all subscribers on incoming message bes
                expect(events[:error_emitted]).to_not eql(true)
                expect(events[:closed_message_from_server_received]).to_not eql(true)
                expect(events[:closing_emitted]).to eql(true)
                stop_reactor
              end
            end

            log_connection_changes
            connection.close
          end
        end

        context ':connected' do
          it 'changes the connection state to :closing and waits for the server to confirm connection is :closed with a ProtocolMessage' do
            connection.on(:connected) do
              connection.on(:closed) do
                EventMachine.add_timer(1) do # allow for all subscribers on incoming message bus
                  expect(events[:error_emitted]).to_not eql(true)
                  expect(events[:closed_message_from_server_received]).to eql(true)
                  expect(events[:closing_emitted]).to eql(true)
                  stop_reactor
                end
              end

              log_connection_changes
              connection.close
            end
          end

          context 'with an unresponsive connection' do
            let(:stubbed_timeout) { 2 }

            before do
              stub_const 'Ably::Realtime::Connection::ConnectionManager::TIMEOUTS',
                          Ably::Realtime::Connection::ConnectionManager::TIMEOUTS.merge(close: stubbed_timeout)

              connection.on(:connected) do
                # Prevent all incoming & outgoing ProtocolMessages from being processed by the client library
                connection.__outgoing_protocol_msgbus__.unsubscribe
                connection.__incoming_protocol_msgbus__.unsubscribe
              end
            end

            it 'force closes the connection when a :closed ProtocolMessage response is not received' do
              connection.on(:connected) do
                close_requested_at = Time.now

                connection.on(:closed) do
                  expect(Time.now - close_requested_at).to be >= stubbed_timeout
                  expect(connection.state).to eq(:closed)
                  expect(events[:error_emitted]).to_not eql(true)
                  expect(events[:closed_message_from_server_received]).to_not eql(true)
                  expect(events[:closing_emitted]).to eql(true)
                  stop_reactor
                end

                log_connection_changes
                connection.close
              end
            end
          end
        end
      end
    end

    context '#ping' do
      it 'echoes a heart beat' do
        connection.on(:connected) do
          connection.ping do |time_elapsed|
            expect(time_elapsed).to be > 0
            stop_reactor
          end
        end
      end

      context 'when not connected' do
        it 'raises an exception' do
          expect { connection.ping }.to raise_error RuntimeError, /Cannot send a ping when connection/
          stop_reactor
        end
      end

      context 'with a success block that raises an exception' do
        it 'catches the exception and logs the error' do
          connection.on(:connected) do
            expect(connection.logger).to receive(:error).with(/Forced exception/) do
              stop_reactor
            end
            connection.ping { raise 'Forced exception' }
          end
        end
      end
    end

    context 'recovery' do
      let(:channel_name) { random_str }
      let(:channel) { client.channel(channel_name) }
      let(:publishing_client) do
        Ably::Realtime::Client.new(client_options)
      end
      let(:publishing_client_channel) { publishing_client.channel(channel_name) }
      let(:client_options) { default_options.merge(log_level: :fatal) }

      before do
        # Reconfigure client library retry periods and timeouts so that tests run quickly
        stub_const 'Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG',
                    Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG.merge(
                      disconnected: { retry_every: 0.1, max_time_in_state: 0.2 },
                      suspended:    { retry_every: 0.1, max_time_in_state: 0.2 },
                    )
      end

      describe '#recovery_key' do
        def self.available_states
          [:connecting, :connected, :disconnected, :suspended, :failed]
        end
        let(:available_states) { self.class.available_states}
        let(:states)           { Hash.new }
        let(:client_options)   { default_options.merge(log_level: :none) }

        it 'is composed of connection key and serial that is kept up to date with each message ACK received' do
          connection.on(:connected) do
            expected_serial = -1
            expect(connection.key).to_not be_nil
            expect(connection.serial).to eql(expected_serial)

            client.channel('test').attach do |channel|
              channel.publish('event', 'data') do
                expected_serial += 1 # attach message received
                expect(connection.serial).to eql(expected_serial)

                channel.publish('event', 'data') do
                  expected_serial += 1 # attach message received
                  expect(connection.serial).to eql(expected_serial)

                  expect(connection.recovery_key).to eql("#{connection.key}:#{connection.serial}")
                  stop_reactor
                end
              end
            end
          end
        end

        it "is available when connection is in one of the states: #{available_states.join(', ')}" do
          connection.once(:connected) do
            allow(client).to receive(:endpoint).and_return(
              URI::Generic.build(
                scheme: 'wss',
                host:   'this.host.does.not.exist.com'
              )
            )

            connection.transition_state_machine! :disconnected
          end

          available_states.each do |state|
            connection.on(state) do
              states[state.to_sym] = true if connection.recovery_key
            end
          end

          connection.once(:failed) do
            expect(states.keys).to match_array(available_states)
            stop_reactor
          end
        end

        it 'is nil when connection is explicitly CLOSED' do
          connection.once(:connected) do
            connection.close do
              expect(connection.recovery_key).to be_nil
              stop_reactor
            end
          end
        end
      end

      context "opening a new connection using a recently disconnected connection's #recovery_key" do
        context 'connection#id and connection#key after recovery' do
          let(:client_options)   { default_options.merge(log_level: :none) }

          it 'remains the same' do
            previous_connection_id  = nil
            previous_connection_key = nil

            connection.once(:connected) do
              previous_connection_id  = connection.id
              previous_connection_key = connection.key
              connection.transition_state_machine! :failed
            end

            connection.once(:failed) do
              recover_client = Ably::Realtime::Client.new(default_options.merge(recover: client.connection.recovery_key))
              recover_client.connection.on(:connected) do
                expect(recover_client.connection.key).to eql(previous_connection_key)
                expect(recover_client.connection.id).to eql(previous_connection_id)
                stop_reactor
              end
            end
          end

          it 'does not call a resume callback', api_private: true do
            connection.once(:connected) do
              connection.transition_state_machine! :failed
            end

            connection.once(:failed) do
              recover_client = Ably::Realtime::Client.new(default_options.merge(recover: client.connection.recovery_key))
              recover_client.connection.on_resume do
                raise 'Should not call the resume callback'
              end
              recover_client.connection.on(:connected) do
                EventMachine.add_timer(0.5) { stop_reactor }
              end
            end
          end
        end

        context 'when messages have been sent whilst the old connection is disconnected' do
          describe 'the new connection' do
            let(:client_options)   { default_options.merge(log_level: :none) }

            it 'recovers server-side queued messages' do
              channel.attach do |message|
                connection.transition_state_machine! :failed
              end

              connection.on(:failed) do
                publishing_client_channel.publish('event', 'message') do
                  recover_client = Ably::Realtime::Client.new(default_options.merge(recover: client.connection.recovery_key))
                  recover_client.channel(channel_name).attach do |recover_client_channel|
                    recover_client_channel.subscribe('event') do |message|
                      expect(message.data).to eql('message')
                      stop_reactor
                    end
                  end
                end
              end
            end
          end
        end
      end

      context 'with :recover option' do
        context 'with invalid syntax' do
          let(:invaid_client_options) { default_options.merge(recover: 'invalid') }

          it 'raises an exception' do
            expect { Ably::Realtime::Client.new(invaid_client_options) }.to raise_error ArgumentError, /Recover/
            stop_reactor
          end
        end

        context 'with invalid formatted value sent to server' do
          let(:client_options) { default_options.merge(recover: 'not-a-valid-connection-key:1', log_level: :none) }

          it 'emits a fatal error on the connection object, sets the #error_reason and disconnects' do
            connection.once(:error) do |error|
              expect(connection.state).to eq(:failed)
              expect(error.message).to match(/Invalid connection key/)
              expect(connection.error_reason.message).to match(/Invalid connection key/)
              expect(connection.error_reason.code).to eql(40006)
              expect(connection.error_reason).to eql(error)
              stop_reactor
            end
          end
        end

        context 'with expired (missing) value sent to server' do
          let(:client_options) { default_options.merge(recover: '0123456789abcdef:0', log_level: :fatal) }

          it 'emits an error on the connection object, sets the #error_reason, yet will connect anyway' do
            connection.once(:error) do |error|
              expect(connection.state).to eq(:connected)
              expect(error.message).to match(/Invalid connection key/i)
              expect(connection.error_reason.message).to match(/Invalid connection key/i)
              expect(connection.error_reason.code).to eql(80008)
              expect(connection.error_reason).to eql(error)
              stop_reactor
            end
          end
        end
      end
    end

    context 'with many connections simultaneously', em_timeout: 15 do
      let(:connection_count) { 40 }
      let(:connection_ids)   { [] }
      let(:connection_keys)  { [] }

      it 'opens each with a unique connection#id and connection#key' do
        connection_count.times.map do
          Ably::Realtime::Client.new(client_options)
        end.each do |client|
          client.connection.on(:connected) do
            connection_ids  << client.connection.id
            connection_keys << client.connection.key
            next unless connection_ids.count == connection_count

            expect(connection_ids.uniq.count).to eql(connection_count)
            expect(connection_keys.uniq.count).to eql(connection_count)
            stop_reactor
          end
        end
      end
    end

    context 'when a state transition is unsupported' do
      let(:client_options) { default_options.merge(log_level: :none) } # silence FATAL errors

      it 'emits a InvalidStateChange' do
        connection.connect do
          connection.transition_state_machine :initialized
        end

        connection.on(:error) do |error|
          expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
          stop_reactor
        end
      end
    end

    context 'protocol failure' do
      let(:client_options) { default_options.merge(protocol: :json) }

      context 'receiving an invalid ProtocolMessage' do
        it 'emits an error on the connection and logs a fatal error message' do
          connection.connect do
            connection.transport.send(:driver).emit 'message', OpenStruct.new(data: { action: 500 }.to_json)
          end

          expect(client.logger).to receive(:fatal).with(/Invalid Protocol Message/)
          connection.on(:error) do |error|
            expect(error.message).to match(/Invalid Protocol Message/)
            stop_reactor
          end
        end
      end
    end

    context 'undocumented method' do
      context '#internet_up?' do
        it 'returns a Deferrable' do
          expect(connection.internet_up?).to be_a(EventMachine::Deferrable)
          stop_reactor
        end

        context 'internet up URL protocol' do
          let(:http_request) { double('EventMachine::HttpRequest', get: EventMachine::DefaultDeferrable.new) }

          context 'when using TLS for the connection' do
            let(:client_options) { default_options.merge(tls: true) }

            it 'uses TLS for the Internet check to https://internet-up.ably-realtime.com/is-the-internet-up.txt' do
              expect(EventMachine::HttpRequest).to receive(:new).with('https://internet-up.ably-realtime.com/is-the-internet-up.txt').and_return(http_request)
              connection.internet_up?
              stop_reactor
            end
          end

          context 'when using a non-secured connection' do
            let(:client_options) { default_options.merge(tls: false, use_token_auth: true) }

            it 'uses TLS for the Internet check to http://internet-up.ably-realtime.com/is-the-internet-up.txt' do
              expect(EventMachine::HttpRequest).to receive(:new).with('http://internet-up.ably-realtime.com/is-the-internet-up.txt').and_return(http_request)
              connection.internet_up?
              stop_reactor
            end
          end
        end

        context 'when the Internet is up' do
          let(:client_options) { default_options.merge(tls: false, use_token_auth: true) }

          context 'with a TLS connection' do
            let(:client_options) { default_options.merge(tls: true) }

            it 'checks the Internet up URL over TLS' do
              expect(EventMachine::HttpRequest).to receive(:new).with("https:#{Ably::INTERNET_CHECK.fetch(:url)}").and_return(double('request', get: EventMachine::DefaultDeferrable.new))
              connection.internet_up?
              stop_reactor
            end
          end

          context 'with a non-TLS connection' do
            let(:client_options) { default_options.merge(tls: false, use_token_auth: true) }

            it 'checks the Internet up URL over TLS' do
              expect(EventMachine::HttpRequest).to receive(:new).with("http:#{Ably::INTERNET_CHECK.fetch(:url)}").and_return(double('request', get: EventMachine::DefaultDeferrable.new))
              connection.internet_up?
              stop_reactor
            end
          end

          it 'calls the block with true' do
            connection.internet_up? do |result|
              expect(result).to be_truthy
              EventMachine.add_timer(0.2) { stop_reactor }
            end
          end

          it 'calls the success callback of the Deferrable' do
            connection.internet_up?.callback do
              EventMachine.add_timer(0.2) { stop_reactor }
            end
            connection.internet_up?.errback do |error|
              raise "Could not perform the Internet up check. Are you connected to the Internet? #{error}"
            end
          end
        end

        context 'when the Internet is down' do
          before do
            stub_const 'Ably::INTERNET_CHECK', { url: '//does.not.exist.com', ok_text: 'no.way.this.will.match' }
          end

          it 'calls the block with false' do
            connection.internet_up? do |result|
              expect(result).to be_falsey
              stop_reactor
            end
          end

          it 'calls the failure callback of the Deferrable' do
            connection.internet_up?.errback do
              stop_reactor
            end
          end
        end
      end
    end

    describe 'state change side effects' do
      let(:channel)        { client.channels.get(random_str) }
      let(:client_options) { default_options.merge(:log_level => :error) }

      context 'when connection enters the :disconnected state' do
        it 'queues messages to be sent and all channels remain attached' do
          channel.attach do
            connection.once(:disconnected) do
              expect(connection.__outgoing_message_queue__).to be_empty
              channel.publish 'test'

              EventMachine.next_tick do
                expect(connection.__outgoing_message_queue__).to_not be_empty
              end

              connection.once(:connected) do
                EventMachine.add_timer(0.1) do
                  expect(connection.__outgoing_message_queue__).to be_empty
                  stop_reactor
                end
              end
            end

            connection.transport.close_connection_after_writing
          end
        end
      end

      context 'when connection enters the :suspended state' do
        let(:client_options) { default_options.merge(:log_level => :fatal) }

        before do
          # Reconfigure client library retry periods so that client stays in suspended state
          stub_const 'Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG',
                      Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG.merge(
                        disconnected: { retry_every: 0.01, max_time_in_state: 0.05 },
                        suspended: { retry_every: 60, max_time_in_state: 60 }
                      )
        end

        it 'detaches the channels and prevents publishing of messages on those channels' do
          channel.attach do
            channel.once(:detached) do
              expect { channel.publish 'test' }.to raise_error(Ably::Exceptions::ChannelInactive)
              stop_reactor
            end

            close_connection_proc = Proc.new do
              EventMachine.add_timer(0.001) do
                if connection.transport.nil?
                  close_connection_proc.call
                else
                  connection.transport.close_connection_after_writing
                end
              end
            end

            # Keep disconnecting the websocket transport after it attempts reconnection
            connection.on(:connecting) do
              close_connection_proc.call
            end
            close_connection_proc.call
          end
        end
      end

      context 'when connection enters the :failed state' do
        let(:client_options) { default_options.merge(:key => 'will.not:authenticate', log_level: :none) }

        it 'sets all channels to failed and prevents publishing of messages on those channels' do
          channel.attach
          channel.once(:failed) do
            expect { channel.publish 'test' }.to raise_error(Ably::Exceptions::ChannelInactive)
            stop_reactor
          end
        end
      end
    end

    context 'connection state change' do
      it 'emits a ConnectionStateChange object' do
        connection.on(:connected) do |connection_state_change|
          expect(connection_state_change).to be_a(Ably::Models::ConnectionStateChange)
          stop_reactor
        end
      end

      context 'ConnectionStateChange object' do
        it 'has current state' do
          connection.on(:connected) do |connection_state_change|
            expect(connection_state_change.current).to eq(:connected)
            stop_reactor
          end
        end

        it 'has a previous state' do
          connection.on(:connected) do |connection_state_change|
            expect(connection_state_change.previous).to eq(:connecting)
            stop_reactor
          end
        end

        it 'contains a private API protocol_message attribute that is used for special state change events', :api_private do
          connection.on(:connected) do |connection_state_change|
            expect(connection_state_change.protocol_message).to be_a(Ably::Models::ProtocolMessage)
            expect(connection_state_change.reason).to be_nil
            stop_reactor
          end
        end

        it 'has an empty reason when there is no error' do
          connection.on(:closed) do |connection_state_change|
            expect(connection_state_change.reason).to be_nil
            stop_reactor
          end
          connection.connect do
            connection.close
          end
        end

        context 'on failure' do
          let(:client_options) { default_options.merge(log_level: :none) }

          it 'has a reason Error object when there is an error on the connection' do
            connection.on(:failed) do |connection_state_change|
              expect(connection_state_change.reason).to be_a(Ably::Exceptions::BaseAblyException)
              stop_reactor
            end
            connection.connect do
              error = Ably::Exceptions::ConnectionFailed.new('forced failure', 500, 50000)
              client.connection.manager.error_received_from_server error
            end
          end
        end

        context 'retry_in' do
          let(:client_options) { default_options.merge(log_level: :error) }

          it 'is nil when a retry is not required' do
            connection.on(:connected) do |connection_state_change|
              expect(connection_state_change.retry_in).to be_nil
              stop_reactor
            end
          end

          it 'is 0 when first attempt to connect fails' do
            connection.once(:connecting) do
              connection.once(:disconnected) do |connection_state_change|
                expect(connection_state_change.retry_in).to eql(0)
                stop_reactor
              end
              EventMachine.add_timer(0.005) { connection.transport.unbind }
            end
          end

          it 'is 0 when an immediate reconnect will occur' do
            connection.once(:connected) do
              connection.once(:disconnected) do |connection_state_change|
                expect(connection_state_change.retry_in).to eql(0)
                stop_reactor
              end
              connection.transport.unbind
            end
          end

          it 'contains the next retry period when an immediate reconnect will not occur' do
            connection.once(:connected) do
              connection.once(:connecting) do
                connection.once(:disconnected) do |connection_state_change|
                  expect(connection_state_change.retry_in).to be > 0
                  stop_reactor
                end
                EventMachine.add_timer(0.005) { connection.transport.unbind }
              end
              connection.transport.unbind
            end
          end
        end
      end
    end
  end
end
