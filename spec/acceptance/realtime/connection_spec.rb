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

      it 'connects automatically' do
        run_reactor do
          connection.on(:connected) do
            expect(connection.state).to eq(:connected)
            stop_reactor
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

      skip '#close disconnects, closes the connection immediately and changes the connection state to closed'

      specify '#close(graceful: true) gracefully waits for the server to close the connection' do
        run_reactor(8) do
          connection.close
          connection.on(:closed) do
            expect(connection.state).to eq(:closed)
            stop_reactor
          end
        end
      end

      it 'receives a heart beat' do
        run_reactor(20) do
          connection.on(:connected) do
            connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.action == :heartbeat
                expect(protocol_message.action).to eq(:heartbeat)
                stop_reactor
              end
            end
          end
        end
      end

      skip 'echos a heart beat'

      skip 'connects, closes gracefully and reconnects on #connect'

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
    end
  end
end
