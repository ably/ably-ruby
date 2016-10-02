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
                  expect(subject.auth.current_token_details).to be_a(Ably::Models::TokenDetails)
                  stop_reactor
                end
              end
            end

            context 'with valid :key and :use_token_auth option set to true' do
              let(:client_options)  { default_options.merge(use_token_auth: true) }

              it 'automatically authorizes on connect and generates a token' do
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

          context 'when the returned token has a client_id' do
            it "sets Auth#client_id to the new token's client_id immediately when connecting" do
              subject.auth.authorize do
                expect(subject.connection).to be_connecting
                expect(subject.auth.client_id).to eql(client_id)
                stop_reactor
              end
            end

            it "sets Client#client_id to the new token's client_id immediately when connecting" do
              subject.auth.authorize do
                expect(subject.connection).to be_connecting
                expect(subject.client_id).to eql(client_id)
                stop_reactor
              end
            end
          end

          context 'with a wildcard client_id token' do
            subject                 { auto_close Ably::Realtime::Client.new(client_options) }
            let(:client_options)    { default_options.merge(auth_callback: Proc.new { auth_token_object }, client_id: client_id) }
            let(:rest_auth_client)  { Ably::Rest::Client.new(default_options.merge(key: api_key)) }
            let(:auth_token_object) { rest_auth_client.auth.request_token(client_id: '*') }

            context 'and an explicit client_id in ClientOptions' do
              let(:client_id) { random_str }

              it 'allows uses the explicit client_id in the connection' do
                connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                  if protocol_message.action == :connected
                    expect(protocol_message.connection_details.client_id).to eql(client_id)
                    @valid_client_id = true
                  end
                end
                subject.connect do
                  EM.add_timer(0.5) { stop_reactor if @valid_client_id }
                end
              end
            end

            context 'and client_id omitted in ClientOptions' do
              let(:client_options) { default_options.merge(auth_callback: Proc.new { auth_token_object }) }

              it 'uses the token provided clientId in the connection' do
                connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                  if protocol_message.action == :connected
                    expect(protocol_message.connection_details.client_id).to eql('*')
                    @valid_client_id = true
                  end
                end
                subject.connect do
                  EM.add_timer(0.5) { stop_reactor if @valid_client_id }
                end
              end
            end
          end
        end

        context 'with an invalid wildcard "*" :client_id' do
          it 'raises an exception' do
            expect { Ably::Realtime::Client.new(client_options.merge(key: api_key, client_id: '*')) }.to raise_error ArgumentError
            stop_reactor
          end
        end
      end

      context 'realtime connection settings' do
        context 'defaults' do
          specify 'disconnected_retry_timeout is 15s' do
            expect(subject.connection.defaults[:disconnected_retry_timeout]).to eql(15)
            stop_reactor
          end

          specify 'suspended_retry_timeout is 30s' do
            expect(subject.connection.defaults[:suspended_retry_timeout]).to eql(30)
            stop_reactor
          end
        end

        context 'overriden in ClientOptions' do
          let(:client_options) { default_options.merge(disconnected_retry_timeout: 1, suspended_retry_timeout: 2) }

          specify 'disconnected_retry_timeout is updated' do
            expect(subject.connection.defaults[:disconnected_retry_timeout]).to eql(1)
            stop_reactor
          end

          specify 'suspended_retry_timeout is updated' do
            expect(subject.connection.defaults[:suspended_retry_timeout]).to eql(2)
            stop_reactor
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

    context '#request (#RSC19*)' do
      let(:client_options) { default_options.merge(key: api_key) }

      context 'get' do
        it 'returns an HttpPaginatedResponse object' do
          subject.request(:get, 'time').callback do |response|
            expect(response).to be_a(Ably::Models::HttpPaginatedResponse)
            expect(response.status_code).to eql(200)
            stop_reactor
          end
        end

        context '404 request to invalid URL' do
          it 'returns an object with 404 status code and error message' do
            subject.request(:get, 'does-not-exist').callback do |response|
              expect(response).to be_a(Ably::Models::HttpPaginatedResponse)
              expect(response.error_message).to match(/Could not find/)
              expect(response.error_code).to eql(40400)
              expect(response.status_code).to eql(404)
              stop_reactor
            end
          end
        end

        context 'paged results' do
          let(:channel_name) { random_str }

          it 'provides paging' do
            10.times do
              subject.rest_client.request(:post, "/channels/#{channel_name}/publish", {}, { 'name' => 'test' })
            end

            subject.request(:get, "/channels/#{channel_name}/messages", { limit: 2 }).callback do |response|
              expect(response.items.length).to eql(2)
              expect(response).to be_has_next
              response.next do |next_page|
                expect(next_page.items.length).to eql(2)
                expect(next_page).to be_has_next
                first_page_ids = response.items.map { |message| message['id'] }.uniq.sort
                next_page_ids = next_page.items.map { |message| message['id'] }.uniq.sort
                expect(first_page_ids).to_not eql(next_page_ids)
                next_page.next do |third_page|
                  expect(third_page.items.length).to eql(2)
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
