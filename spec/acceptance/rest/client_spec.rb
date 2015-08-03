# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Client do
  vary_by_protocol do
    let(:default_options) { { environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }

    let(:client) { Ably::Rest::Client.new(client_options) }

    connection_retry = Ably::Rest::Client::CONNECTION_RETRY

    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end

    context '#initialize' do
      let(:client_id)     { random_str }
      let(:token_request) { client.auth.create_token_request(key_name: key_name, key_secret: key_secret, client_id: client_id) }

      context 'with an :auth_callback Proc' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(auth_callback: Proc.new { token_request })) }

        it 'calls the auth Proc to get a new token' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(client_id)
        end
      end

      context 'with an auth URL' do
        let(:client_options) { default_options.merge(auth_url: token_request_url, auth_method: :get) }
        let(:token_request_url) { 'http://get.token.request.com/' }

        before do
          allow(client.auth).to receive(:token_request_from_auth_url).with(token_request_url, :auth_method => :get).and_return(token_request)
        end

        it 'sends an HTTP request to the provided URL to get a new token' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(client_id)
        end
      end

      context 'auth headers', webmock: true do
        let(:channel_name)        { random_str }
        let(:history_params)      { { 'direction' => 'backwards', 'limit' => 100 } }
        let(:history_querystring) { history_params.map { |k, v| "#{k}=#{v}" }.join("&") }

        context 'with basic auth', webmock: true do
          let(:client_options)      { default_options.merge(key: api_key) }

          let!(:get_message_history_stub) do
            stub_request(:get, "https://#{api_key}@#{environment}-#{Ably::Rest::Client::DOMAIN}/channels/#{channel_name}/messages?#{history_querystring}").
              to_return(body: [], headers: { 'Content-Type' => 'application/json' })
          end

          it 'sends the API key in authentication part of the secure URL (the Authorization: Basic header is not used with the Faraday HTTP library by default)' do
            client.channel(channel_name).history history_params
            expect(get_message_history_stub).to have_been_requested
          end
        end

        context 'with token auth', webmock: true do
          let(:token_string)   { random_str }
          let(:client_options) { default_options.merge(token: token_string) }

          let!(:get_message_history_stub) do
            stub_request(:get, "https://#{environment}-#{Ably::Rest::Client::DOMAIN}/channels/#{channel_name}/messages?#{history_querystring}").
              with(headers: { 'Authorization' => "Bearer #{encode64(token_string)}" }).
              to_return(body: [], headers: { 'Content-Type' => 'application/json' })
          end

          it 'sends the token string in the Authorization Bearer header with Base64 encoding' do
            client.channel(channel_name).history history_params
            expect(get_message_history_stub).to have_been_requested
          end
        end
      end
    end

    context 'using tokens' do
      let(:client) do
        Ably::Rest::Client.new(client_options.merge(auth_callback: Proc.new do
          @request_index ||= 0
          @request_index += 1
          send("token_request_#{@request_index > 2 ? 'next' : @request_index}")
        end))
      end
      let(:token_request_1) { client.auth.create_token_request(token_request_options.merge(client_id: random_str)) }
      let(:token_request_2) { client.auth.create_token_request(token_request_options.merge(client_id: random_str)) }

      # If token expires against whilst runnig tests in a slower CI environment then use this token
      let(:token_request_next) { client.auth.create_token_request(token_request_options.merge(client_id: random_str)) }

      context 'when expired' do
        let(:token_request_options) { { key_name: key_name, key_secret: key_secret, ttl: Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER } }

        it 'creates a new token automatically when the old token expires' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(token_request_1.client_id)

          sleep 1

          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(token_request_2.client_id)
        end
      end

      context 'when token has not expired' do
        let(:token_request_options) { { key_name: key_name, key_secret: key_secret, ttl: 3600 } }

        it 'reuses the existing token for every request' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(token_request_1.client_id)

          sleep 1

          expect { client.channel('channel_name').publish('event', 'message') }.to_not change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(token_request_1.client_id)
        end
      end
    end

    context 'connection transport' do
      let(:client_options) { default_options.merge(key: api_key) }

      context 'for default host' do
        it "is configured to timeout connection opening in #{connection_retry.fetch(:single_request_open_timeout)} seconds" do
          expect(client.connection.options.open_timeout).to eql(connection_retry.fetch(:single_request_open_timeout))
        end

        it "is configured to timeout connection requests in #{connection_retry.fetch(:single_request_timeout)} seconds" do
          expect(client.connection.options.timeout).to eql(connection_retry.fetch(:single_request_timeout))
        end
      end

      context 'for the fallback hosts' do
        it "is configured to timeout connection opening in #{connection_retry.fetch(:single_request_open_timeout)} seconds" do
          expect(client.fallback_connection.options.open_timeout).to eql(connection_retry.fetch(:single_request_open_timeout))
        end

        it "is configured to timeout connection requests in #{connection_retry.fetch(:single_request_timeout)} seconds" do
          expect(client.fallback_connection.options.timeout).to eql(connection_retry.fetch(:single_request_timeout))
        end
      end
    end

    context 'fallback hosts', :webmock do
      let(:path)           { '/channels/test/publish' }
      let(:publish_block)  { proc { client.channel('test').publish('event', 'data') } }

      context 'configured' do
        let(:client_options) { default_options.merge(key: api_key) }

        it 'should make connection attempts to A.ably-realtime.com, B.ably-realtime.com, C.ably-realtime.com, D.ably-realtime.com, E.ably-realtime.com' do
          hosts = []
          5.times do
            hosts << client.fallback_connection.host
          end
          expect(hosts).to match_array(%w(A.ably-realtime.com B.ably-realtime.com C.ably-realtime.com D.ably-realtime.com E.ably-realtime.com))
        end
      end

      context 'when environment is NOT production' do
        let(:client_options) { default_options.merge(environment: 'sandbox', key: api_key) }
        let!(:default_host_request_stub) do
          stub_request(:post, "https://#{api_key}@#{environment}-#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
            raise Faraday::TimeoutError.new('timeout error message')
          end
        end

        it 'does not retry failed requests with fallback hosts when there is a connection error' do
          expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionTimeoutError
        end
      end

      context 'when environment is production' do
        let(:custom_hosts)       { %w(A.ably-realtime.com B.ably-realtime.com) }
        let(:max_attempts)       { 2 }
        let(:cumulative_timeout) { 0.5 }
        let(:client_options)     { default_options.merge(environment: nil, key: api_key) }
        let(:fallback_block)     { Proc.new { raise Faraday::SSLError.new('ssl error message') } }

        before do
          stub_const 'Ably::FALLBACK_HOSTS', custom_hosts
          stub_const 'Ably::Rest::Client::CONNECTION_RETRY', {
            single_request_open_timeout: 4,
            single_request_timeout: 15,
            cumulative_request_open_timeout: cumulative_timeout,
            max_retry_attempts: max_attempts
          }
        end

        let!(:first_fallback_request_stub) do
          stub_request(:post, "https://#{api_key}@#{custom_hosts[0]}#{path}").to_return(&fallback_block)
        end

        let!(:second_fallback_request_stub) do
          stub_request(:post, "https://#{api_key}@#{custom_hosts[1]}#{path}").to_return(&fallback_block)
        end

        context 'and connection times out' do
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
              raise Faraday::TimeoutError.new('timeout error message')
            end
          end

          it "tries fallback hosts #{connection_retry[:max_retry_attempts]} times" do
            expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionError, /ssl error message/
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end

          context "and the total request time exeeds #{connection_retry[:cumulative_request_open_timeout]} seconds" do
            let!(:default_host_request_stub) do
              stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
                sleep cumulative_timeout * 1.5
                raise Faraday::TimeoutError.new('timeout error message')
              end
            end

            it 'makes no further attempts to any fallback hosts' do
              expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionTimeoutError
              expect(default_host_request_stub).to have_been_requested
              expect(first_fallback_request_stub).to_not have_been_requested
              expect(second_fallback_request_stub).to_not have_been_requested
            end
          end
        end

        context 'and connection fails' do
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
              raise Faraday::ConnectionFailed.new('connection failure error message')
            end
          end

          it "tries fallback hosts #{connection_retry[:max_retry_attempts]} times" do
            expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionError, /ssl error message/
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end
        end

        context 'and basic authentication fails' do
          let(:status) { 401 }
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return(
              headers: { 'Content-Type' => 'application/json' },
              status: status,
              body: {
	              "error" => {
		              "statusCode" => 401,
		              "code" => 40101,
		              "message" => "Invalid credentials"
	              }
              }.to_json
            )
          end

          it 'does not attempt the fallback hosts as this is an authentication failure' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::InvalidRequest)
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to_not have_been_requested
            expect(second_fallback_request_stub).to_not have_been_requested
          end
        end

        context 'and server returns a 50x error' do
          let(:status) { 502 }
          let(:fallback_block) do
            Proc.new do
              {
                headers: { 'Content-Type' => 'text/html' },
                status: status
              }
            end
          end
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{api_key}@#{Ably::Rest::Client::DOMAIN}#{path}").to_return(&fallback_block)
          end

          it 'attempts the fallback hosts as this is an authentication failure' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::ServerError)
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end
        end
      end
    end

    context 'with a custom host' do
      let(:custom_host)   { 'host.does.not.exist' }
      let(:client_options) { default_options.merge(key: api_key, rest_host: custom_host) }
      let(:capability)     { { :foo => ["publish"] } }

      context 'that does not exist' do
        it 'fails immediately and raises a Faraday Error' do
          expect { client.channel('test').publish('event', 'data') }.to raise_error Ably::Exceptions::ConnectionError
        end

        context 'fallback hosts', :webmock do
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

      context 'that times out', :webmock do
        let(:path) { '/keys/app_id.key_name/requestToken' }
        let!(:custom_host_request_stub) do
          stub_request(:post, "https://#{custom_host}#{path}").to_return do
            raise Faraday::TimeoutError.new('timeout error message')
          end
        end

        it 'fails immediately and raises a Faraday Error' do
          expect { client.auth.request_token }.to raise_error Ably::Exceptions::ConnectionTimeoutError
        end

        context 'fallback hosts' do
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

    context '#auth' do
      let(:dummy_auth_url) { 'http://dummy.url' }
      let(:unique_ttl)     { 1234 }
      let(:client_options) { default_options.merge(auth_url: dummy_auth_url, ttl: unique_ttl) }


      it 'is provides access to the Auth object' do
        expect(client.auth).to be_kind_of(Ably::Auth)
      end

      it 'configures the Auth object with all ClientOptions passed to client in the initializer' do
        expect(client.auth.options[:ttl]).to eql(unique_ttl)
        expect(client.auth.options[:auth_url]).to eql(dummy_auth_url)
      end
    end
  end
end
