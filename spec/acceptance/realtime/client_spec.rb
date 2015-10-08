# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Client, :event_machine do
  vary_by_protocol do
    let(:default_options) do
      { key: api_key, environment: environment, protocol: protocol }
    end

    let(:client_options) { default_options }
    let(:connection)     { subject.connection }
    let(:auth_params)    { subject.auth.auth_params_sync }

    subject              { auto_close Ably::Realtime::Client.new(client_options) }

    context 'initialization' do
      context 'basic auth' do
        it 'is enabled by default with a provided :key option' do
          connection.on(:connected) do
            expect(auth_params[:key]).to_not be_nil
            expect(auth_params[:access_token]).to be_nil
            expect(subject.auth.current_token_details).to be_nil
            stop_reactor
          end
        end

        context ':tls option' do
          context 'set to false to force a plain-text connection' do
            let(:client_options) { default_options.merge(tls: false, log_level: :none) }

            it 'fails to connect because a private key cannot be sent over a non-secure connection' do
              connection.on(:connected) { raise 'Should not have connected' }

              connection.on(:failed) do |connection_state_change|
                expect(connection_state_change.reason).to be_a(Ably::Exceptions::InsecureRequest)
                stop_reactor
              end
            end
          end
        end
      end

      context 'token auth' do
        [true, false].each do |tls_enabled|
          context "with TLS #{tls_enabled ? 'enabled' : 'disabled'}" do
            let(:capability)      { { :foo => ["publish"] } }
            let(:token_client)    { auto_close Ably::Realtime::Client.new(default_options) }
            let(:token_details)   { token_client.auth.request_token_sync(capability: capability) }
            let(:client_options)  { default_options.merge(token: token_details.token) }

            context 'and a pre-generated Token provided with the :token option' do
              it 'connects using token auth' do
                connection.on(:connected) do
                  expect(auth_params[:access_token]).to_not be_nil
                  expect(auth_params[:key]).to be_nil
                  expect(subject.auth.current_token_details).to be_nil
                  stop_reactor
                end
              end
            end

            context 'with valid :key and :use_token_auth option set to true' do
              let(:client_options)  { default_options.merge(use_token_auth: true) }

              it 'automatically authorises on connect and generates a token' do
                connection.on(:connected) do
                  expect(subject.auth.current_token_details).to_not be_nil
                  expect(auth_params[:access_token]).to_not be_nil
                  stop_reactor
                end
              end
            end

            context 'with client_id' do
              let(:client_options) do
                default_options.merge(client_id: random_str)
              end
              it 'connects using token auth' do
                run_reactor do
                  connection.on(:connected) do
                    expect(connection.state).to eq(:connected)
                    expect(auth_params[:access_token]).to_not be_nil
                    expect(auth_params[:key]).to be_nil
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        context 'with a Proc for the :auth_callback option' do
          let(:client_id) { random_str }
          let(:auth)      { subject.auth }

          subject do
            auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: Proc.new do
              @block_called = true
              auth.create_token_request_sync(client_id: client_id)
            end))
          end

          it 'calls the Proc' do
            connection.on(:connected) do
              expect(@block_called).to eql(true)
              stop_reactor
            end
          end

          it 'uses the token request returned from the callback when requesting a new token' do
            connection.on(:connected) do
              expect(auth.current_token_details.client_id).to eql(client_id)
              stop_reactor
            end
          end
        end
      end
    end

    context '#connection' do
      it 'provides access to the Connection object' do
        expect(subject.connection).to be_a(Ably::Realtime::Connection)
        stop_reactor
      end
    end

    context '#channels' do
      it 'provides access to the Channels collection object' do
        expect(subject.channels).to be_a(Ably::Realtime::Channels)
        stop_reactor
      end
    end

    context '#auth' do
      it 'provides access to the Realtime::Auth object' do
        expect(subject.auth).to be_a(Ably::Realtime::Auth)
        stop_reactor
      end
    end
  end
end
