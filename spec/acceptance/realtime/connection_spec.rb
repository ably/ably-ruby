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
              EventMachine.add_timer(0.1) do # allow for all subscribers on incoming message bes
                expect(connection.state).to eq(:closed)
                expect(@error_emitted).to_not eql(true)
                expect(@closed_message_from_server_received).to_not eql(true)
                expect(@closing_state_emitted).to eql(true)
                stop_reactor
              end
            end
          end
        end

        specify '#close changes state to closing and waits for the server to confirm connection is closed with a ProtocolMessage' do
          run_reactor(8) do
            connection.on(:connected) do
              connection.close
              log_connection_changes

              connection.on(:closed) do
                EventMachine.add_timer(0.1) do # allow for all subscribers on incoming message bes
                  expect(connection.state).to eq(:closed)
                  expect(@error_emitted).to_not eql(true)
                  expect(@closed_message_from_server_received).to eql(true)
                  expect(@closing_state_emitted).to eql(true)
                  stop_reactor
                end
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
          let(:client) do
            Ably::Realtime::Client.new(default_options.merge(ws_host: 'non.existent.host'))
          end

          it 'enters the failed state and returns an authorization error' do
            run_reactor do
              connection.on(:failed) do |error|
                expect(connection.state).to eq(:failed)
                expect(error.code).to eq(80000)
                expect(error.status).to be_nil
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

      it 'emits a ConnectionError if a state transition is unsupported' do
        run_reactor do
          connection.connect do
            connection.transition_state_machine(:initialized)
          end

          connection.on(:error) do |error|
            expect(error).to be_a(Ably::Exceptions::ConnectionError)
            stop_reactor
          end
        end
      end
    end
  end
end
