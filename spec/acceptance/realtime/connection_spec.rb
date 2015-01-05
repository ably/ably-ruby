# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Connection do
  include RSpec::EventMachine

  let(:connection) { client.connection }

  [:json, :msgpack].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) do
        { api_key: api_key, environment: environment, protocol: protocol }
      end

      let(:client_options) { default_options }
      let(:client) do
        Ably::Realtime::Client.new(client_options)
      end

      after do
        connection.off # minimise side effects of callbacks from finished test calling stop_reactor
      end

      context 'new connection' do
        it 'connects automatically' do
          run_reactor do
            connection.on(:connected) do
              expect(connection.state).to eq(:connected)
              stop_reactor
            end
          end
        end

        context 'with connect_automatically option set to false' do
          let(:client) do
            Ably::Realtime::Client.new(default_options.merge(connect_automatically: false))
          end

          it 'does not connect automatically' do
            run_reactor do
              EventMachine.add_timer(1) do
                expect(connection).to be_initialized
                stop_reactor
              end
              client
            end
          end

          it 'connects on #connect' do
            run_reactor do
              connection.connect do
                expect(connection).to be_connected
                stop_reactor
              end
            end
          end
        end
      end

      context 'initialization phases' do
        let(:phases) { [:connecting, :connected] }
        let(:events_triggered) { [] }
        let(:test_expectation) do
          Proc.new do
            expect(events_triggered).to eq(phases)
            stop_reactor
          end
        end

        def expect_ordered_phases
          phases.each do |phase|
            connection.on(phase) do
              events_triggered << phase
              test_expectation.call if events_triggered.length == phases.length
            end
          end
        end

        context 'with implicit #connect' do
          it 'are triggered in order' do
            run_reactor do
              expect_ordered_phases
            end
          end
        end

        context 'with explicit #connect' do
          it 'are triggered in order' do
            run_reactor do
              expect_ordered_phases
              connection.connect
            end
          end
        end
      end

      context 'repeated requests to' do
        def fail_if_state_changes(&block)
          connection.once(:connected, :closing, :connecting) do
            raise "State should not have changed: #{connection.state}"
          end
          yield
          connection.off
        end

        context '#connect' do
          it 'are ignored and no further state changes are emitted' do
            run_reactor do
              connection.once(:connected) do
                fail_if_state_changes do
                  3.times { connection.connect }
                  expect(connection).to be_connected
                end
                stop_reactor
              end
            end
          end
        end

        context '#close' do
          it 'are ignored and no further state changes are emitted' do
            run_reactor do
              connection.once(:connected) do
                connection.close do
                  fail_if_state_changes do
                    3.times { connection.close }
                    expect(connection).to be_closed
                  end
                  stop_reactor
                end
              end
            end
          end
        end
      end

      context '#close' do
        let(:events) { Hash.new }

        def log_connection_changes
          connection.on(:closing) { events[:closing_emitted] = true }
          connection.on(:error)   { events[:error_emitted] = true }

          connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
            events[:closed_message_from_server_received] = true if protocol_message.action == :closed
          end
        end

        specify 'before connection is opened closes the connection immediately and changes the connection state to closing & then immediately closed' do
          run_reactor(8) do
            connection.on(:closed) do
              expect(connection.state).to eq(:closed)

              EventMachine.add_timer(0.1) do # allow for all subscribers on incoming message bes
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

        specify 'changes state to closing and waits for the server to confirm connection is closed with a ProtocolMessage' do
          run_reactor do
            connection.on(:connected) do
              connection.on(:closed) do
                expect(connection.state).to eq(:closed)

                EventMachine.add_timer(0.1) do # allow for all subscribers on incoming message bus
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
        end

        specify '#close changes state to closing and will force close the connection within TIMEOUTS[:close] if CLOSED is not received' do
          run_reactor(8) do
            stub_const 'Ably::Realtime::Connection::ConnectionManager::TIMEOUTS',
                        Ably::Realtime::Connection::ConnectionManager::TIMEOUTS.merge(close: 2)

            connection.on(:connected) do
              # Prevent all incoming & outgoing ProtocolMessages from being processed by the client library
              connection.__outgoing_protocol_msgbus__.unsubscribe
              connection.__incoming_protocol_msgbus__.unsubscribe

              close_requested_at = Time.now

              connection.on(:closed) do
                expect(Time.now - close_requested_at).to be >= Ably::Realtime::Connection::ConnectionManager::TIMEOUTS.fetch(:close)
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

      context '#ping' do
        it 'echoes a heart beat' do
          run_reactor do
            connection.on(:connected) do
              connection.ping do |time_elapsed|
                expect(time_elapsed).to be > 0
                stop_reactor
              end
            end
          end
        end

        it 'when not connected, it raises an exception' do
          run_reactor do
            expect { connection.ping }.to raise_error RuntimeError, /Cannot send a ping when connection/
            stop_reactor
          end
        end
      end

      it 'connects, closes the connection, and then reconnects with a new connection ID' do
        run_reactor(15) do
          connection.connect do
            connection_id = connection.id
            connection.close do
              connection.connect do
                expect(connection.id).to_not eql(connection_id)
                stop_reactor
              end
            end
          end
        end
      end

      context 'connection recovery' do
        let(:channel_name) { SecureRandom.hex }
        let(:channel) { client.channel(channel_name) }
        let(:publishing_client) do
          Ably::Realtime::Client.new(client_options)
        end
        let(:publishing_client_channel) { publishing_client.channel(channel_name) }
        let(:client_options) { default_options.merge(log_level: :fatal) }

        it 'ensures connection id and serial is up to date when sending messages' do
          run_reactor do
            connection.on(:connected) do
              expected_serial = -1
              expect(connection.id).to_not be_nil
              expect(connection.serial).to eql(expected_serial)

              client.channel('test').attach do |channel|
                channel.publish('event', 'data') do
                  expected_serial += 1 # attach message received
                  expect(connection.serial).to eql(expected_serial)

                  channel.publish('event', 'data') do
                    expected_serial += 1 # attach message received
                    expect(connection.serial).to eql(expected_serial)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        context '#recovery_key for use with recover option' do
          before do
            # Reconfigure client library retry periods and timeouts so that tests run quickly
            stub_const 'Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG',
                        Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG.merge(
                          disconnected: { retry_every: 0.1, max_time_in_state: 0.2 },
                          suspended:    { retry_every: 0.1, max_time_in_state: 0.2 },
                        )
          end

          def self.available_states
            [:connecting, :connected, :disconnected, :suspended, :failed]
          end
          let(:available_states) { self.class.available_states}
          let(:states)           { Hash.new }
          let(:client_options)   { default_options.merge(log_level: :none) }

          it "is available for #{available_states.join(', ')} states" do
            run_reactor do
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

        context 'with messages sent whilst disconnected' do
          let(:client_options)   { default_options.merge(log_level: :none) }

          it 'recovers server-side queued messages' do
            run_reactor do
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

        context 'recover client option' do
          context 'syntax invalid' do
            let(:invaid_client_options) { default_options.merge(recover: 'invalid') }

            it 'raises an exception' do
              run_reactor do
                expect { Ably::Realtime::Client.new(invaid_client_options) }.to raise_error ArgumentError, /Recover/
                stop_reactor
              end
            end
          end

          context 'invalid value' do
            let(:client_options) { default_options.merge(recover: 'invalid:key', log_level: :fatal) }

            skip 'moves to state :failed when recover option is invalid' do
              run_reactor do
                connection.on(:failed) do |error|
                  expect(connection.state).to eq(:failed)
                  expect(connection.error_reason.message).to match(/Recover/)
                  expect(connection.error_reason).to eql(error)
                  stop_reactor
                end
              end
            end
          end
        end
      end

      context 'token auth' do
        before do
          # Reduce token expiry buffer to zero so that a token expired? predicate is exact
          # Normally there is a buffer so that a token expiring soon is considered expired
          stub_const 'Ably::Models::Token::TOKEN_EXPIRY_BUFFER', 0
        end

        context 'for renewable tokens' do
          context 'that are valid for the duration of the test' do
            context 'with valid pre authorised token expiring in the future' do
              it 'uses the existing token created by Auth' do
                run_reactor do
                  client.auth.authorise(ttl: 300)
                  expect(client.auth).to_not receive(:request_token)
                  connection.once(:connected) do
                    stop_reactor
                  end
                end
              end
            end

            context 'with implicit authorisation' do
              let(:client_options) { default_options.merge(client_id: 'force_token_auth') }
              it 'uses the token created by the implicit authorisation' do
                run_reactor do
                  expect(client.auth).to receive(:request_token).once.and_call_original
                  connection.once(:connected) do
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'that expire' do
            let(:client_options) { default_options.merge(log_level: :none) }

            before do
              client.auth.authorise(ttl: ttl)
            end

            context 'opening a new connection' do
              context 'with recently expired token' do
                let(:ttl) { 2 }

                it 'renews the token on connect' do
                  run_reactor do
                    sleep ttl + 0.1
                    expect(client.auth.current_token).to be_expired
                    expect(client.auth).to receive(:authorise).once.and_call_original
                    connection.once(:connected) do
                      expect(client.auth.current_token).to_not be_expired
                      stop_reactor
                    end
                  end
                end
              end

              context 'with immediately expiring token' do
                let(:ttl) { 0.01 }

                it 'renews the token on connect, and only makes one subequent attempt to obtain a new token' do
                  run_reactor do
                    expect(client.auth).to receive(:authorise).twice.and_call_original
                    connection.once(:disconnected) do
                      connection.once(:failed) do |error|
                        expect(error.code).to eql(40140) # token expired
                        stop_reactor
                      end
                    end
                  end
                end

                it 'uses the primary host for subsequent connection and auth requests' do
                  run_reactor do
                    sleep 1
                    connection.once(:disconnected) do
                      expect(client.rest_client.connection).to receive(:post).with(/requestToken$/, anything).and_call_original

                      expect(client.rest_client).to_not receive(:fallback_connection)
                      expect(client).to_not receive(:fallback_endpoint)

                      connection.once(:failed) do
                        stop_reactor
                      end
                    end
                  end
                end
              end
            end

            context 'when connected' do
              context 'with a new successful token request' do
                let(:ttl)     { 3 }
                let(:channel) { client.channel('test') }

                skip 'changes state to disconnected, renews the token and then reconnects' do
                  run_reactor(10) do
                    expect(client.auth.current_token).to_not be_expired

                    channel.attach
                    connection.once(:connected) do
                      sleep ttl
                      expect(client.auth.current_token).to be_expired

                      channel.publish('event', 'data') do
                        connection.once(:disconnected) do |error|
                          expect(Time.now - started_at >= ttl)
                          expect(error.code).to eql(40140) # token expired
                          connection.once(:connected) do
                            stop_reactor
                          end
                        end
                      end
                    end
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
            let!(:expired_token) do
              Ably::Realtime::Client.new(default_options).auth.request_token(ttl: 0.01)
            end

            context 'opening a new connection' do
              let(:client_options) { default_options.merge(api_key: nil, token_id: expired_token.id, log_level: :none) }

              it 'transitions state to failed' do
                run_reactor(10) do
                  sleep 0.5
                  expect(expired_token).to be_expired
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

      it 'opens many connections simultaneously' do
        run_reactor(15) do
          count, connected_ids = 25, []

          clients = count.times.map do
            Ably::Realtime::Client.new(client_options)
          end

          clients.each do |client|
            client.connection.on(:connected) do
              connected_ids << client.connection.id

              if connected_ids.count == 25
                expect(connected_ids.uniq.count).to eql(25)
                stop_reactor
              end
            end
          end
        end
      end

      context 'when state transition is unsupported' do
        let(:client_options) { default_options.merge(log_level: :none) } # silence FATAL errors

        it 'emits a ConnectionStateChangeError if a state transition is unsupported' do
          run_reactor do
            connection.connect do
              connection.transition_state_machine(:initialized)
            end

            connection.on(:error) do |error|
              expect(error).to be_a(Ably::Exceptions::ConnectionStateChangeError)
              stop_reactor
            end
          end
        end
      end
    end
  end
end
