# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Client do
  include RSpec::EventMachine

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) do
        { api_key: api_key, environment: environment, protocol: protocol }
      end

      let(:client_options) { default_options }
      let(:connection)     { subject.connection }
      let(:auth_params)    { subject.auth.auth_params }

      subject              { Ably::Realtime::Client.new(client_options) }

      context 'with API key' do
        it 'connects using basic auth by default' do
          run_reactor do
            connection.on(:connected) do
              expect(connection.state).to eq(:connected)
              expect(auth_params[:key_id]).to_not be_nil
              expect(auth_params[:access_token]).to be_nil
              stop_reactor
            end
          end
        end

        context 'with TLS disabled' do
          let(:client_options) { default_options.merge(tls: false) }

          it 'fails to connect because the key cannot be sent over a non-secure connection' do
            run_reactor do
              connection.on(:failed) do |error|
                expect(error).to be_a(Ably::Exceptions::InsecureRequestError)
                stop_reactor
              end
            end
          end
        end
      end

      [true, false].each do |tls_enabled|
        context "with TLS #{tls_enabled ? 'enabled' : 'disabled'}" do
          context 'with token provided' do
            let(:capability) { { :foo => ["publish"] } }
            let(:token)      { Ably::Realtime::Client.new(default_options).auth.request_token(capability: capability) }
            let(:client_options) do
              { token_id: token.id, environment: environment, protocol: protocol, tls: tls_enabled }
            end

            it 'connects using token auth' do
              run_reactor do
                connection.on(:connected) do
                  expect(connection.state).to eq(:connected)
                  expect(auth_params[:access_token]).to_not be_nil
                  expect(auth_params[:key_id]).to be_nil
                  stop_reactor
                end
              end
            end
          end

          context 'with API key and token auth set to true' do
            skip 'automatically generates a token and connects using token auth'
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
                  expect(auth_params[:key_id]).to be_nil
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
