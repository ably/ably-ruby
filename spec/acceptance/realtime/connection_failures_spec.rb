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

      context 'authentication failure' do
        let(:missing_key) { 'not_an_app.invalid_key_id:invalid_key_value' }
        let(:client_options) do
          default_options.merge(api_key: missing_key, log_level: :none)
        end

        context 'when API key is invalid' do
          it 'sets the #error_reason to the failed reason' do
            run_reactor do
              connection.on(:failed) do |error|
                expect(connection.state).to eq(:failed)
                expect(error.status).to eq(404)
                expect(error.code).to eq(40400) # not found
                stop_reactor
              end
            end
          end
        end
      end

      context 'retrying new connections' do
        let(:client_failure_options) { default_options.merge(log_level: :none) }

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

          context '#error_reason' do
            [:disconnected, :suspended, :failed].each do |state|
              it "contains the error when state is #{state}" do
                run_reactor do
                  connection.on(state) do |error|
                    expect(connection.error_reason).to eq(error)
                    expect(connection.error_reason.code).to eql(80000)
                    stop_reactor
                  end
                end
              end
            end

            it 'resets the error state when :connected' do
              run_reactor do
                connection.once(:disconnected) do |error|
                  # fix the host so that the connection connects
                  allow(connection).to receive(:host).and_return(TestApp.instance.host)
                  connection.once(:connected) do
                    expect(connection.error_reason).to be_nil
                    stop_reactor
                  end
                end
              end
            end

            it 'resets the error state when :closed' do
              run_reactor do
                connection.once(:disconnected) do |error|
                  connection.close do
                    expect(connection.error_reason).to be_nil
                    stop_reactor
                  end
                end
              end
            end
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
                  expect { connection.close }.to raise_error Ably::Exceptions::StateChangeError, /Unable to transition from failed => closing/
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
        let(:client_options) { default_options.merge(log_level: :none) }

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
          it 'retains connection_id and member_id' do
            run_reactor do
              previous_connection_id, previous_member_id = nil, nil

              connection.once(:connected) do
                previous_connection_id = connection.id
                previous_member_id     = connection.member_id
                connection.transport.close_connection_after_writing

                connection.once(:connected) do
                  expect(connection.member_id).to eql(previous_member_id)
                  expect(connection.id).to eql(previous_connection_id)
                  stop_reactor
                end
              end
            end
          end

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

      context 'fallback hosts' do
        let(:retry_every_for_tests)       { 0.1 }
        let(:max_time_in_state_for_tests) { 0.3 }

        before do
          # Reconfigure client library retry periods and timeouts so that tests run quickly
          stub_const 'Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG',
                      Ably::Realtime::Connection::ConnectionManager::CONNECT_RETRY_CONFIG.merge(
                        disconnected: { retry_every: retry_every_for_tests, max_time_in_state: max_time_in_state_for_tests },
                        suspended:    { retry_every: retry_every_for_tests, max_time_in_state: max_time_in_state_for_tests },
                      )
        end

        let(:expected_retry_attempts) { (max_time_in_state_for_tests / retry_every_for_tests).round }
        let(:retry_count_for_one_state)  { 1 + expected_retry_attempts } # initial connect then disconnected
        let(:retry_count_for_all_states) { 1 + expected_retry_attempts * 2 } # initial connection, disconnected & then suspended

        context 'with custom realtime websocket host' do
          let(:expected_host) { 'this.host.doesn.not.exist' }
          let(:client_options) { default_options.merge(realtime_host: expected_host, log_level: :none) }

          it 'never uses a fallback host' do
            run_reactor do
              expect(EventMachine).to receive(:connect).exactly(retry_count_for_all_states).times do |host|
                expect(host).to eql(expected_host)
                raise EventMachine::ConnectionError
              end

              connection.on(:failed) do
                stop_reactor
              end
            end
          end
        end

        context 'with non-production environment' do
          let(:environment)    { 'sandbox' }
          let(:expected_host)  { "#{environment}-#{Ably::Realtime::Client::DOMAIN}" }
          let(:client_options) { default_options.merge(environment: environment, log_level: :none) }

          it 'never uses a fallback host' do
            run_reactor do
              expect(EventMachine).to receive(:connect).exactly(retry_count_for_all_states).times do |host|
                expect(host).to eql(expected_host)
                raise EventMachine::ConnectionError
              end

              connection.on(:failed) do
                stop_reactor
              end
            end
          end
        end

        context 'with production environment' do
          let(:custom_hosts)   { %w(A.ably-realtime.com B.ably-realtime.com) }
          before do
            stub_const 'Ably::FALLBACK_HOSTS', custom_hosts
          end

          let(:expected_host)  { Ably::Realtime::Client::DOMAIN }
          let(:client_options) { default_options.merge(environment: nil, log_level: :none) }

          let(:fallback_hosts_used) { Array.new }

          it 'uses a fallback host on every subsequent disconnected attempt until suspended' do
            run_reactor do
              request = 0
              expect(EventMachine).to receive(:connect).exactly(retry_count_for_one_state).times do |host|
                if request == 0
                  expect(host).to eql(expected_host)
                else
                  expect(custom_hosts).to include(host)
                  fallback_hosts_used << host
                end
                request += 1
                raise EventMachine::ConnectionError
              end

              connection.on(:suspended) do
                expect(fallback_hosts_used.uniq).to match_array(custom_hosts)
                stop_reactor
              end
            end
          end

          it 'uses the primary host when suspended, and a fallback host on every subsequent suspended attempt' do
            run_reactor do
              request = 0
              expect(EventMachine).to receive(:connect).exactly(retry_count_for_all_states).times do |host|
                if request == 0 || request == expected_retry_attempts + 1
                  expect(host).to eql(expected_host)
                else
                  expect(custom_hosts).to include(host)
                  fallback_hosts_used << host
                end
                request += 1
                raise EventMachine::ConnectionError
              end

              connection.on(:failed) do
                expect(fallback_hosts_used.uniq).to match_array(custom_hosts)
                stop_reactor
              end
            end
          end
        end
      end
    end
  end
end
