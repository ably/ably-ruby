# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Connection do
  include RSpec::EventMachine

  let(:connection) { client.connection }

  [:json, :msgpack].each do |protocol|
    context "failures over #{protocol}" do
      let(:default_options) do
        { api_key: api_key, environment: environment, protocol: protocol }
      end

      let(:client_options) { default_options }
      let(:client) do
        Ably::Realtime::Client.new(client_options)
      end

      context 'retrying new connections' do
        let(:client_failure_options) { default_options.merge(log_level: :fatal) }

        context 'with invalid app part of the key' do
          let(:missing_key) { 'not_an_app.invalid_key_id:invalid_key_value' }
          let(:client_options) do
            client_failure_options.merge(api_key: missing_key)
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
          let(:client_options) do
            client_failure_options.merge(api_key: invalid_key)
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
            # Reconfigure client library retry periods and timeouts so that tests run quickly
            stub_const 'Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG',
                        Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG.merge(
                          disconnected: { retry_every: retry_every_for_tests, max_time_in_state: max_time_in_state_for_tests },
                          suspended:    { retry_every: retry_every_for_tests, max_time_in_state: max_time_in_state_for_tests },
                        )
          end

          let(:expected_retry_attempts) { (max_time_in_state_for_tests / retry_every_for_tests).round }
          let(:state_changes)           { Hash.new { |hash, key| hash[key] = 0 } }
          let(:timer)                   { Hash.new }

          let(:client_options) do
            client_failure_options.merge(realtime_host: 'non.existent.host')
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

                connection.on(:closed) do
                  expect(connection.state).to eq(:closed)
                  stop_reactor
                end

                connection.close
              end
            end
          end

          it 'enters the suspended state after multiple attempts to connect' do
            run_reactor do
              connection.on(:failed) { raise 'Connection should not have reached :failed state yet' }

              count_state_changes && start_timer

              connection.once(:suspended) do
                expect(connection.state).to eq(:suspended)

                expect(state_changes[:connecting]).to   eql(expected_retry_attempts)
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

                connection.on(:closed) do
                  expect(connection.state).to eq(:closed)
                  stop_reactor
                end

                connection.close
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

          context 'when entering the failed state' do
            it 'should disallow a transition to closed when requested' do
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
        end

        specify '#open times out automatically and attempts a reconnect' do
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

      context 'resuming existing connections' do
        let(:channel_name) { SecureRandom.hex }
        let(:channel) { client.channel(channel_name) }
        let(:publishing_client) do
          Ably::Realtime::Client.new(client_options)
        end
        let(:publishing_client_channel) { publishing_client.channel(channel_name) }
        let(:client_options) { default_options.merge(log_level: :fatal) }

        it 'reconnects automatically when disconnected message received from the server' do
          run_reactor do
            connection.on(:suspended) { raise 'Connection should not have reached :suspended state' }
            connection.on(:failed)    { raise 'Connection should not have reached :failed state' }

            connection.once(:connected) do
              connection.once(:disconnected) do
                connection.once(:connected) do
                  state_history = connection.state_history.map { |transition| transition[:state].to_sym }
                  expect(state_history).to eql([:connecting, :connected, :disconnected, :connecting, :connected])
                  stop_reactor
                end
              end
              protocol_message = Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Disconnected.to_i)
              connection.__incoming_protocol_msgbus__.publish :protocol_message, protocol_message
            end
          end
        end

        it 'reconnects automatically when websocket transport is disconnected' do
          run_reactor do
            connection.on(:suspended) { raise 'Connection should not have reached :suspended state' }
            connection.on(:failed)    { raise 'Connection should not have reached :failed state' }

            connection.once(:connected) do
              connection.once(:disconnected) do
                connection.once(:connected) do
                  state_history = connection.state_history.map { |transition| transition[:state].to_sym }
                  expect(state_history).to eql([:connecting, :connected, :disconnected, :connecting, :connected])
                  stop_reactor
                end
              end
              connection.transport.close_connection_after_writing
            end
          end
        end

        context 'resumes connection when disconnected' do
          it 'retains channel subscription state' do
            run_reactor do
              messages_received = false

              channel.subscribe('event') do |message|
                expect(message.data).to eql('message')
                stop_reactor
              end

              channel.attach do
                publishing_client_channel.attach do
                  connection.transport.close_connection_after_writing

                  connection.once(:connected) do
                    publishing_client_channel.publish 'event', 'message'
                  end
                end
              end
            end
          end

          it 'receives server-side messages that were queued whilst disconnected' do
            run_reactor do
              messages_received = false

              channel.subscribe('event') do |message|
                expect(message.data).to eql('message')
                messages_received = true
              end

              channel.attach do
                publishing_client_channel.attach do
                  connection.transport.off # remove all event handlers that detect socket connection state has changed
                  connection.transport.close_connection_after_writing

                  publishing_client_channel.publish('event', 'message') do
                    EventMachine.add_timer(1) do
                      expect(messages_received).to eql(false)
                      # simulate connection dropped to re-establish web socket
                      connection.transition_state_machine :disconnected
                    end
                  end

                  # subsequent connection will receive message sent whilst disconnected
                  connection.once(:connected) do
                    EventMachine.add_timer(1) do
                      expect(messages_received).to eql(true)
                      stop_reactor
                    end
                  end
                end
              end
            end
          end
        end
      end
    end
  end
end
