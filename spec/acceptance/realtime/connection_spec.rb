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

      let(:client) do
        Ably::Realtime::Client.new(default_options)
      end

      context 'with API key' do
        it 'connects automatically' do
          run_reactor do
            connection.on(:connected) do
              expect(connection.state).to eq(:connected)
              expect(client.auth.auth_params[:key_id]).to_not be_nil
              expect(client.auth.auth_params[:access_token]).to be_nil
              stop_reactor
            end
          end
        end
      end

      context 'with client_id resulting in token auth' do
        let(:default_options) do
          { api_key: api_key, environment: environment, protocol: protocol, client_id: random_str }
        end
        it 'connects automatically' do
          run_reactor do
            connection.on(:connected) do
              expect(connection.state).to eq(:connected)
              expect(client.auth.auth_params[:access_token]).to_not be_nil
              expect(client.auth.auth_params[:key_id]).to be_nil
              stop_reactor
            end
          end
        end
      end

      context 'initialization phases' do
        let(:phases) { [:initialized, :connecting, :connected] }
        let(:events_triggered) { [] }

        it 'are triggered in order' do
          test_expectation = Proc.new do
            expect(events_triggered).to eq(phases)
            stop_reactor
          end

          run_reactor do
            phases.each do |phase|
              connection.on(phase) do
                events_triggered << phase
                test_expectation.call if events_triggered.length == phases.length
              end
            end
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

      context '#connect' do
        it 'ignores subsequent connect requests' do
          run_reactor do
            connection.on(:connected) do
              3.times { connection.connect }
              expect(connection).to be_connected
              stop_reactor
            end
          end
        end
      end

      context '#close' do
        it 'ignores subsequent close requests' do
          run_reactor do
            connection.on(:connected) do
              connection.close do
                3.times { connection.close }
                expect(connection).to be_closed
                stop_reactor
              end
            end
          end
        end
      end

      context 'connection closing' do
        def log_connection_changes
          connection.on(:closing) do
            @closing_state_emitted = true
          end

          connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
            @closed_message_from_server_received = true if protocol_message.action == :closed
          end

          connection.on(:error) do
            @error_emitted = true
          end
        end

        specify '#close before connection is opened closes the connection immediately and changes the connection state to closing & then immediately closed' do
          run_reactor(8) do
            connection.close
            log_connection_changes

            connection.on(:closed) do
              expect(connection.state).to eq(:closed)

              EventMachine.add_timer(0.1) do # allow for all subscribers on incoming message bes
                expect(@error_emitted).to_not eql(true)
                expect(@closed_message_from_server_received).to_not eql(true)
                expect(@closing_state_emitted).to eql(true)
                stop_reactor
              end
            end
          end
        end

        specify '#close changes state to closing and waits for the server to confirm connection is closed with a ProtocolMessage' do
          run_reactor do
            connection.on(:connected) do
              connection.close
              log_connection_changes

              connection.on(:closed) do
                expect(connection.state).to eq(:closed)

                EventMachine.add_timer(0.1) do # allow for all subscribers on incoming message bus
                  expect(@error_emitted).to_not eql(true)
                  expect(@closed_message_from_server_received).to eql(true)
                  expect(@closing_state_emitted).to eql(true)
                  stop_reactor
                end
              end
            end
          end
        end

        specify '#close changes state to closing and will force close the connection within TIMEOUTS[:close] if CLOSED is not received' do
          run_reactor(8) do
            stub_const 'Ably::Realtime::Connection::ConnectionManager::TIMEOUTS',
                        Ably::Realtime::Connection::ConnectionManager::TIMEOUTS.merge(close: 2)

            connection.on(:connected) do
              # Stop all incoming & outgoing ProtocolMessages from being processed
              connection.__outgoing_protocol_msgbus__.unsubscribe
              connection.__incoming_protocol_msgbus__.unsubscribe

              close_requested_at = Time.now
              connection.close
              log_connection_changes

              connection.on(:closed) do
                expect(Time.now - close_requested_at).to be >= Ably::Realtime::Connection::ConnectionManager::TIMEOUTS.fetch(:close)
                expect(connection.state).to eq(:closed)
                expect(@error_emitted).to_not eql(true)
                expect(@closed_message_from_server_received).to_not eql(true)
                expect(@closing_state_emitted).to eql(true)
                stop_reactor
              end
            end
          end
        end
      end

      it 'echoes a heart beat with #ping' do
        run_reactor do
          connection.on(:connected) do
            connection.ping do |time_elapsed|
              expect(time_elapsed).to be > 0
              stop_reactor
            end
          end
        end
      end

      it 'when not connected, it raises an exception with #ping' do
        run_reactor do
          expect { connection.ping }.to raise_error RuntimeError, /Cannot send a ping when connection/
          stop_reactor
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

      context 'failures' do
        context 'with invalid app part of the key' do
          let(:missing_key) { 'not_an_app.invalid_key_id:invalid_key_value' }
          let(:client) do
            Ably::Realtime::Client.new(default_options.merge(api_key: missing_key))
          end

          it 'enters the failed state and returns a not found error' do
            run_reactor do
              connection.on(:failed) do |error|
                expect(connection.state).to eq(:failed)
                expect(error.status).to eq(404)
                stop_reactor
              end
            end
          end
        end

        context 'with invalid key ID part of the key' do
          let(:invalid_key) { "#{app_id}.invalid_key_id:invalid_key_value" }
          let(:client) do
            Ably::Realtime::Client.new(default_options.merge(api_key: invalid_key))
          end

          it 'enters the failed state and returns an authorization error' do
            run_reactor do
              connection.on(:failed) do |error|
                expect(connection.state).to eq(:failed)
                expect(error.status).to eq(401)
                stop_reactor
              end
            end
          end
        end

        context 'with invalid WebSocket host' do
          let(:retry_every_for_tests)       { 0.2 }
          let(:max_time_in_state_for_tests) { 0.6 }

          before do
            stub_const 'Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG',
                        Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG.merge(
                          disconnected: { retry_every: retry_every_for_tests, max_time_in_state: max_time_in_state_for_tests },
                          suspended:    { retry_every: retry_every_for_tests, max_time_in_state: max_time_in_state_for_tests },
                        )
          end

          let(:expected_retry_attempts) { (max_time_in_state_for_tests / retry_every_for_tests).round }
          let(:state_changes)           { Hash.new { |hash, key| hash[key] = 0 } }
          let(:timer)                   { Hash.new }

          let(:client) do
            Ably::Realtime::Client.new(default_options.merge(ws_host: 'non.existent.host'))
          end

          def count_state_changes
            EventMachine.next_tick do
              %w(connecting disconnected failed suspended).each do |state|
                connection.on(state.to_sym) { state_changes[state.to_sym] += 1 }
              end
            end
          end

          def start_timer
            timer[:start] = Time.now
          end

          def time_passed
            Time.now.to_f - timer[:start].to_f
          end

          it 'enters the disconnected state and then transitions to closed when requested' do
            run_reactor do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }
              connection.on(:failed)    { raise 'Connection should not have reached :failed state yet' }

              connection.once(:disconnected) do
                expect(connection.state).to eq(:disconnected)
                connection.close

                connection.on(:closed) do
                  expect(connection.state).to eq(:closed)
                  stop_reactor
                end
              end
            end
          end

          it 'enters the suspended state after multiple attempts to connect' do
            run_reactor do
              connection.on(:failed) { raise 'Connection should not have reached :failed state yet' }
              count_state_changes && start_timer

              connection.once(:suspended) do
                expect(connection.state).to eq(:suspended)

                expect(state_changes[:connecting]).to   eql(expected_retry_attempts + 1) # add one to account for initial connect
                expect(state_changes[:disconnected]).to eql(expected_retry_attempts)

                expect(time_passed).to be > max_time_in_state_for_tests
                stop_reactor
              end
            end
          end

          it 'enters the suspended state and transitions to closed when requested' do
            run_reactor do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }

              connection.once(:suspended) do
                expect(connection.state).to eq(:suspended)
                connection.close

                connection.on(:closed) do
                  expect(connection.state).to eq(:closed)
                  stop_reactor
                end
              end
            end
          end

          it 'enters the failed state after multiple attempts when in the suspended state' do
            run_reactor do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }

              connection.once(:suspended) do
                count_state_changes && start_timer

                connection.on(:failed) do
                  expect(connection.state).to eq(:failed)

                  expect(state_changes[:connecting]).to   eql(expected_retry_attempts)
                  expect(state_changes[:suspended]).to    eql(expected_retry_attempts)
                  expect(state_changes[:disconnected]).to eql(0)

                  expect(time_passed).to be > max_time_in_state_for_tests
                  stop_reactor
                end
              end
            end
          end

          it 'enters the failed state and should disallow a transition to closed when requested' do
            run_reactor do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }

              connection.once(:failed) do
                expect(connection.state).to eq(:failed)
                expect { connection.close }.to raise_error Ably::Exceptions::ConnectionStateChangeError, /Unable to transition from failed => closing/
                stop_reactor
              end
            end
          end
        end

        specify 'connection#open times out automatically and attempts a reconnect' do
          run_reactor do
            stub_const 'Ably::Realtime::Connection::ConnectionManager::TIMEOUTS',
                        Ably::Realtime::Connection::ConnectionManager::TIMEOUTS.merge(open: 2)

            connection.on(:connected) { raise "Connection should not open in this test as CONNECTED ProtocolMessage is never received" }

            started_at = Time.now

            connection.on(:connecting) do
              connection.__incoming_protocol_msgbus__.unsubscribe
            end

            connection.on(:disconnected) do
              expect(Time.now.to_f - started_at.to_f).to be > 2
              connection.on(:connecting) do
                stop_reactor
              end
            end
          end
        end
      end

      it 'opens many connections simultaneously' do
        run_reactor(15) do
          count, connected_ids = 25, []

          clients = count.times.map do
            Ably::Realtime::Client.new(default_options)
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
