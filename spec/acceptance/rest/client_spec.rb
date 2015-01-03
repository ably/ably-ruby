# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Client do
  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) { { environment: environment, protocol: protocol } }
      let(:client_options)  { default_options }

      let(:client) { Ably::Rest::Client.new(client_options) }

      context '#initialize' do
        context 'with an auth block' do
          let(:client) { Ably::Rest::Client.new(client_options) { token_request } }
          let(:token_request) { client.auth.create_token_request(key_id: key_id, key_secret: key_secret, client_id: client_id) }
          let(:client_id) { 'unique_client_id' }

          it 'calls the block to get a new token' do
            expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token }
            expect(client.auth.current_token.client_id).to eql(client_id)
          end
        end

        context 'with an auth URL' do
          let(:client_options) { default_options.merge(auth_url: token_request_url, auth_method: :get) }
          let(:token_request_url) { 'http://get.token.request.com/' }
          let(:token_request) { client.auth.create_token_request(key_id: key_id, key_secret: key_secret, client_id: client_id) }
          let(:client_id) { 'unique_client_id' }

          before do
            allow(client.auth).to receive(:token_request_from_auth_url).with(token_request_url, :auth_method => :get).and_return(token_request)
          end

          it 'sends an HTTP request to get a new token' do
            expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token }
            expect(client.auth.current_token.client_id).to eql(client_id)
          end
        end
      end

      context 'token expiry' do
        let(:client) do
          Ably::Rest::Client.new(client_options) do
            @request_index ||= 0
            @request_index += 1
            send("token_request_#{@request_index}")
          end
        end
        let(:token_request_1) { client.auth.create_token_request(token_request_options.merge(client_id: random_str)) }
        let(:token_request_2) { client.auth.create_token_request(token_request_options.merge(client_id: random_str)) }

        context 'when expired' do
          let(:token_request_options) { { key_id: key_id, key_secret: key_secret, ttl: Ably::Models::Token::TOKEN_EXPIRY_BUFFER } }

          it 'creates a new token automatically when the old token expires' do
            expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token }
            expect(client.auth.current_token.client_id).to eql(token_request_1[:client_id])

            sleep 1

            expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token }
            expect(client.auth.current_token.client_id).to eql(token_request_2[:client_id])
          end
        end

        context 'token authentication with long expiry token' do
          let(:token_request_options) { { key_id: key_id, key_secret: key_secret, ttl: 3600 } }

          it 'creates a new token automatically when the old token expires' do
            expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token }
            expect(client.auth.current_token.client_id).to eql(token_request_1[:client_id])

            sleep 1

            expect { client.channel('channel_name').publish('event', 'message') }.to_not change { client.auth.current_token }
            expect(client.auth.current_token.client_id).to eql(token_request_1[:client_id])
          end
        end
      end

      context 'connection' do
        let(:client_options) { default_options.merge(api_key: api_key) }

        context 'primary' do
          specify 'open timeout matches configuration' do
            expect(client.connection.options.open_timeout).to eql(Ably::Rest::Client::CONNECTION_RETRY.fetch(:single_request_open_timeout))
          end

          specify 'request timeout matches configuration' do
            expect(client.connection.options.timeout).to eql(Ably::Rest::Client::CONNECTION_RETRY.fetch(:single_request_timeout))
          end
        end

        context 'fallback' do
          specify 'open timeout matches configuration' do
            expect(client.fallback_connection.options.open_timeout).to eql(Ably::Rest::Client::CONNECTION_RETRY.fetch(:single_request_open_timeout))
          end

          specify 'request timeout matches configuration' do
            expect(client.fallback_connection.options.timeout).to eql(Ably::Rest::Client::CONNECTION_RETRY.fetch(:single_request_timeout))
          end
        end
      end

      context 'fallback hosts', webmock: true do
        let(:custom_hosts)       { %w(A.ably-realtime.com B.ably-realtime.com) }
        let(:max_attempts)       { 2 }
        let(:cumulative_timeout) { 0.5 }

        let(:path)           { '/channels/test/publish' }

        before do
          stub_const 'Ably::FALLBACK_HOSTS', custom_hosts
          stub_const 'Ably::Rest::Client::CONNECTION_RETRY', {
            single_request_open_timeout: 4,
            single_request_timeout: 15,
            cumulative_request_open_timeout: cumulative_timeout,
            max_retry_attempts: max_attempts
          }
        end

        let(:publish_block) { proc { client.channel('test').publish('event', 'data') } }

        context 'environment is not production' do
          let(:client_options) { default_options.merge(environment: 'sandbox', api_key: api_key) }
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{api_key}@#{environment}-#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
              raise Faraday::TimeoutError.new('timeout error message')
            end
          end

          it 'does not retry with fallback hosts when there is a connection error' do
            expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionTimeoutError
          end
        end

        context 'environment is production' do
          let(:client_options) { default_options.merge(environment: nil, api_key: api_key) }

          let!(:first_fallback_request_stub) do
            stub_request(:post, "https://#{api_key}@#{custom_hosts[0]}#{path}").to_return do
              raise Faraday::SSLError.new('ssl error message')
            end
          end
          let!(:second_fallback_request_stub) do
            stub_request(:post, "https://#{api_key}@#{custom_hosts[1]}#{path}").to_return do
              raise Faraday::SSLError.new('ssl error message')
            end
          end

          context 'when connection times out' do
            let!(:default_host_request_stub) do
              stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
                raise Faraday::TimeoutError.new('timeout error message')
              end
            end

            it 'tries fallback hosts for CONNECTION_RETRY[:max_retry_attempts]' do
              expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionError, /ssl error message/
              expect(default_host_request_stub).to have_been_requested
              expect(first_fallback_request_stub).to have_been_requested
              expect(second_fallback_request_stub).to have_been_requested
            end

            context 'and all request time exeeds CONNECTION_RETRY[:cumulative_request_open_timeout]' do
              let!(:default_host_request_stub) do
                stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
                  sleep cumulative_timeout * 1.5
                  raise Faraday::TimeoutError.new('timeout error message')
                end
              end

              it 'stops further attempts to any fallback hosts' do
                expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionTimeoutError
                expect(default_host_request_stub).to have_been_requested
                expect(first_fallback_request_stub).to_not have_been_requested
                expect(second_fallback_request_stub).to_not have_been_requested
              end
            end
          end

          context 'when connection fails' do
            let!(:default_host_request_stub) do
              stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
                raise Faraday::ConnectionFailed.new('connection failure error message')
              end
            end

            it 'tries fallback hosts for CONNECTION_RETRY[:max_retry_attempts]' do
              expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionError, /ssl error message/
              expect(default_host_request_stub).to have_been_requested
              expect(first_fallback_request_stub).to have_been_requested
              expect(second_fallback_request_stub).to have_been_requested
            end
          end
        end
      end

      context 'with a custom host' do
        let(:custom_host)   { 'host.does.not.exist' }
        let(:client_options) { default_options.merge(api_key: api_key, rest_host: custom_host) }
        let(:capability)     { { :foo => ["publish"] } }

        context 'that does not exist' do
          it 'fails immediately and raises a Faraday Error' do
            expect { client.channel('test').publish('event', 'data') }.to raise_error Ably::Exceptions::ConnectionError
          end

          context 'and fallback hosts', webmock: true do
            let(:path) { '/channels/test/publish' }

            let!(:custom_host_request_stub) do
              stub_request(:post, "https://#{api_key}@#{custom_host}#{path}").to_return do
                raise Faraday::ConnectionFailed.new('connection failure error message')
              end
            end

            before do
              Ably::FALLBACK_HOSTS.each do |host|
                stub_request(:post, "https://#{host}#{path}").to_return do
                  raise 'Fallbacks should not be used with custom hosts'
                end
              end
            end

            specify 'are never used' do
              expect { client.channel('test').publish('event', 'data') }.to raise_error Ably::Exceptions::ConnectionError
              expect(custom_host_request_stub).to have_been_requested
            end
          end
        end

        context 'that times out', webmock: true do
          let(:path) { '/keys/app_id.key_id/requestToken' }
          let!(:custom_host_request_stub) do
            stub_request(:post, "https://#{custom_host}#{path}").to_return do
              raise Faraday::TimeoutError.new('timeout error message')
            end
          end

          it 'fails immediately and raises a Faraday Error' do
            expect { client.auth.request_token }.to raise_error Ably::Exceptions::ConnectionTimeoutError
          end

          context 'and fallback hosts' do
            before do
              Ably::FALLBACK_HOSTS.each do |host|
                stub_request(:post, "https://#{host}#{path}").to_return do
                  raise 'Fallbacks should not be used with custom hosts'
                end
              end
            end

            specify 'are never used' do
              expect { client.auth.request_token }.to raise_error Ably::Exceptions::ConnectionTimeoutError
              expect(custom_host_request_stub).to have_been_requested
            end
          end
        end
      end
    end
  end
end
