# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Client, :event_machine do
  vary_by_protocol do
    let(:default_options) do
      { key: api_key, environment: environment, protocol: protocol }
    end

    let(:client_options) { default_options }
    let(:connection)     { subject.connection }
    let(:auth_params)    { subject.auth.auth_params }

    subject              { Ably::Realtime::Client.new(client_options) }

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
          context 'set to false to forec a plain-text connection' do
            let(:client_options) { default_options.merge(tls: false, log_level: :none) }

            it 'fails to connect because a private key cannot be sent over a non-secure connection' do
              connection.on(:connected) { raise 'Should not have connected' }

              connection.on(:failed) do |error|
                expect(error).to be_a(Ably::Exceptions::InsecureRequestError)
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
            let(:token_details)   { Ably::Realtime::Client.new(default_options).auth.request_token(capability: capability) }
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

        context 'with token_request_block' do
          let(:client_id) { random_str }
          let(:auth)      { subject.auth }

          subject do
            Ably::Realtime::Client.new(client_options.merge(auth_callback: Proc.new do
              @block_called = true
              auth.create_token_request(client_id: client_id)
            end))
          end

          it 'calls the block' do
            connection.on(:connected) do
              expect(@block_called).to eql(true)
              stop_reactor
            end
          end

          it 'uses the token request when requesting a new token' do
            connection.on(:connected) do
              expect(auth.current_token_details.client_id).to eql(client_id)
              stop_reactor
            end
          end
        end
      end
    end
  end
end
