# encoding: utf-8
require 'spec_helper'
require 'webrick'

describe Ably::Rest::Client do
  vary_by_protocol do
    let(:default_options) { { environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }

    let(:client) { Ably::Rest::Client.new(client_options) }

    http_defaults = Ably::Rest::Client::HTTP_DEFAULTS

    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end

    context '#initialize' do
      let(:client_id)     { random_str }
      let(:token_request) { client.auth.create_token_request({}, key_name: key_name, key_secret: key_secret, client_id: client_id) }

      context 'with only an API key' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(key: api_key)) }

        it 'uses basic authentication' do
          expect(client.auth).to be_using_basic_auth
        end
      end

      context 'with an explicit string :token' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(token: random_str)) }

        it 'uses token authentication' do
          expect(client.auth).to be_using_token_auth
        end
      end

      context 'with :use_token_auth set to true' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(key: api_key, use_token_auth: true)) }

        it 'uses token authentication' do
          expect(client.auth).to be_using_token_auth
        end
      end

      context 'with a :client_id configured' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(key: api_key, client_id: random_str)) }

        it 'uses token authentication' do
          expect(client.auth).to be_using_token_auth
        end
      end

      context 'with an invalid wildcard "*" :client_id' do
        it 'raises an exception' do
          expect { Ably::Rest::Client.new(client_options.merge(key: api_key, client_id: '*')) }.to raise_error ArgumentError
        end
      end

      context 'with an :auth_callback Proc' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(auth_callback: Proc.new { token_request })) }

        it 'calls the auth Proc to get a new token' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(client_id)
        end

        it 'uses token authentication' do
          expect(client.auth).to be_using_token_auth
        end
      end

      context 'with an :auth_callback Proc (clientId provided in library options instead of as a token_request param)' do
        let(:client) { Ably::Rest::Client.new(client_options.merge(client_id: client_id, auth_callback: Proc.new { token_request })) }
        let(:token_request) { client.auth.create_token_request({}, key_name: key_name, key_secret: key_secret) }

        it 'correctly sets the clientId on the token' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(client_id)
        end
      end

      context 'with an auth URL' do
        let(:client_options)    { default_options.merge(key: api_key, auth_url: token_request_url, auth_method: :get) }
        let(:token_request_url) { 'http://get.token.request.com/' }

        it 'uses token authentication' do
          expect(client.auth).to be_using_token_auth
        end

        context 'before any REST request' do
          before do
            expect(client.auth).to receive(:token_request_from_auth_url).with(token_request_url, hash_including(:auth_method => :get), anything).once do
              client.auth.create_token_request(client_id: client_id)
            end
          end

          it 'sends an HTTP request to the provided auth URL to get a new token' do
            expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
            expect(client.auth.current_token_details.client_id).to eql(client_id)
          end
        end
      end

      context 'auth headers', webmock: true do
        let(:channel_name)        { random_str }
        let(:history_params)      { { 'direction' => 'backwards', 'limit' => 100 } }
        let(:history_querystring) { history_params.map { |k, v| "#{k}=#{v}" }.join("&") }

        context 'with basic auth', webmock: true do
          let(:client_options)      { default_options.merge(key: api_key) }

          let!(:get_message_history_stub) do
            stub_request(:get, "https://#{environment}-#{Ably::Rest::Client::DOMAIN}/channels/#{channel_name}/messages?#{history_querystring}").
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
            stub_request(:get, "#{http_protocol}://#{environment}-#{Ably::Rest::Client::DOMAIN}/channels/#{channel_name}/messages?#{history_querystring}").
              with(headers: { 'Authorization' => "Bearer #{encode64(token_string)}" }).
              to_return(body: [], headers: { 'Content-Type' => 'application/json' })
          end

          context 'without specifying protocol' do
            let(:http_protocol) { 'https' }

            it 'sends the token string over HTTPS in the Authorization Bearer header with Base64 encoding' do
              client.channel(channel_name).history history_params
              expect(get_message_history_stub).to have_been_requested
            end
          end

          context 'when setting constructor ClientOption :tls to false' do
            let(:client_options) { default_options.merge(token: token_string, tls: false) }
            let(:http_protocol)  { 'http' }

            it 'sends the token string over HTTP in the Authorization Bearer header with Base64 encoding' do
              client.channel(channel_name).history history_params
              expect(get_message_history_stub).to have_been_requested
            end
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
      let(:client_id)       { random_str }
      let(:client_id_2)     { client_id }
      let(:token_request_1) { client.auth.create_token_request({}, token_request_options.merge(client_id: client_id)) }
      let(:token_request_2) { client.auth.create_token_request({}, token_request_options.merge(client_id: client_id_2)) }

      # If token expires against whilst runnig tests in a slower CI environment then use this token
      let(:token_request_next) { client.auth.create_token_request({}, token_request_options.merge(client_id: random_str)) }

      context 'when expired' do
        before do
          # Ensure tokens issued expire immediately after issue
          stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0)
        end

        let(:token_request_options) { { key_name: key_name, key_secret: key_secret, token_params: { ttl: Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER } } }

        it 'creates a new token automatically when the old token expires' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(token_request_1.client_id)

          sleep 1

          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token_details }
          expect(client.auth.current_token_details.client_id).to eql(token_request_2.client_id)
        end

        context 'with a different client_id in the subsequent token' do
          let(:client_id_2) { random_str }

          it 'fails to authenticate and raises an exception' do
            client.channel('channel_name').publish('event', 'message')
            sleep 1
            expect { client.channel('channel_name').publish('event', 'message') }.to raise_error(Ably::Exceptions::IncompatibleClientId)
          end
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
      context 'defaults' do
        let(:client_options) { default_options.merge(key: api_key, environment: 'production') }

        context 'for default host' do
          it "is configured to timeout connection opening in #{http_defaults.fetch(:open_timeout)} seconds" do
            expect(client.connection.options.open_timeout).to eql(http_defaults.fetch(:open_timeout))
          end

          it "is configured to timeout connection requests in #{http_defaults.fetch(:request_timeout)} seconds" do
            expect(client.connection.options.timeout).to eql(http_defaults.fetch(:request_timeout))
          end
        end

        context 'for the fallback hosts' do
          it "is configured to timeout connection opening in #{http_defaults.fetch(:open_timeout)} seconds" do
            expect(client.fallback_connection.options.open_timeout).to eql(http_defaults.fetch(:open_timeout))
          end

          it "is configured to timeout connection requests in #{http_defaults.fetch(:request_timeout)} seconds" do
            expect(client.fallback_connection.options.timeout).to eql(http_defaults.fetch(:request_timeout))
          end
        end
      end

      context 'with custom http_open_timeout and http_request_timeout options' do
        let(:http_open_timeout)    { 999 }
        let(:http_request_timeout) { 666 }
        let(:client_options)       { default_options.merge(key: api_key, http_open_timeout: http_open_timeout, http_request_timeout: http_request_timeout, environment: 'production') }

        context 'for default host' do
          it 'is configured to use custom open timeout' do
            expect(client.connection.options.open_timeout).to eql(http_open_timeout)
          end

          it 'is configured to use custom request timeout' do
            expect(client.connection.options.timeout).to eql(http_request_timeout)
          end
        end

        context 'for the fallback hosts' do
          it "is configured to timeout connection opening in #{http_defaults.fetch(:open_timeout)} seconds" do
            expect(client.fallback_connection.options.open_timeout).to eql(http_open_timeout)
          end

          it "is configured to timeout connection requests in #{http_defaults.fetch(:request_timeout)} seconds" do
            expect(client.fallback_connection.options.timeout).to eql(http_request_timeout)
          end
        end
      end
    end

    context 'fallback hosts', :webmock do
      let(:path)           { '/channels/test/publish' }
      let(:publish_block)  { proc { client.channel('test').publish('event', 'data') } }

      context 'configured' do
        let(:client_options) { default_options.merge(key: api_key, environment: 'production') }

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
          stub_request(:post, "https://#{environment}-#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
            raise Faraday::TimeoutError.new('timeout error message')
          end
        end

        it 'does not retry failed requests with fallback hosts when there is a connection error' do
          expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionTimeout
        end
      end

      context 'when environment is production' do
        let(:custom_hosts)       { %w(A.ably-realtime.com B.ably-realtime.com) }
        let(:max_retry_count)    { 2 }
        let(:max_retry_duration) { 0.5 }
        let(:fallback_block)     { Proc.new { raise Faraday::SSLError.new('ssl error message') } }
        let(:client_options) do
          default_options.merge(
            environment: nil,
            key: api_key,
            http_max_retry_duration: max_retry_duration,
            http_max_retry_count: max_retry_count
          )
        end

        before do
          stub_const 'Ably::FALLBACK_HOSTS', custom_hosts
        end

        let!(:first_fallback_request_stub) do
          stub_request(:post, "https://#{custom_hosts[0]}#{path}").to_return(&fallback_block)
        end

        let!(:second_fallback_request_stub) do
          stub_request(:post, "https://#{custom_hosts[1]}#{path}").to_return(&fallback_block)
        end

        context 'and connection times out' do
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
              raise Faraday::TimeoutError.new('timeout error message')
            end
          end

          it "tries fallback hosts #{http_defaults.fetch(:max_retry_count)} times" do
            expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionError, /ssl error message/
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end

          context "and the total request time exeeds #{http_defaults.fetch(:max_retry_duration)} seconds" do
            let!(:default_host_request_stub) do
              stub_request(:post, "https://#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
                sleep max_retry_duration * 1.5
                raise Faraday::TimeoutError.new('timeout error message')
              end
            end

            it 'makes no further attempts to any fallback hosts' do
              expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionTimeout
              expect(default_host_request_stub).to have_been_requested
              expect(first_fallback_request_stub).to_not have_been_requested
              expect(second_fallback_request_stub).to_not have_been_requested
            end
          end
        end

        context 'and connection fails' do
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{Ably::Rest::Client::DOMAIN}#{path}").to_return do
              raise Faraday::ConnectionFailed.new('connection failure error message')
            end
          end

          it "tries fallback hosts #{http_defaults.fetch(:max_retry_count)} times" do
            expect { publish_block.call }.to raise_error Ably::Exceptions::ConnectionError, /ssl error message/
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end
        end

        context 'and basic authentication fails' do
          let(:status) { 401 }
          let!(:default_host_request_stub) do
            stub_request(:post, "https://#{Ably::Rest::Client::DOMAIN}#{path}").to_return(
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
            expect { publish_block.call }.to raise_error(Ably::Exceptions::UnauthorizedRequest)
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
            stub_request(:post, "https://#{Ably::Rest::Client::DOMAIN}#{path}").to_return(&fallback_block)
          end

          it 'attempts the fallback hosts as this is an authentication failure' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::ServerError)
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end
        end
      end

      context 'when environment is production and server returns a 50x error' do
        let(:custom_hosts)       { %w(A.foo.com B.foo.com) }
        let(:max_retry_count)    { 2 }
        let(:max_retry_duration) { 0.5 }
        let(:fallback_block)     { Proc.new { raise Faraday::SSLError.new('ssl error message') } }
        let(:production_options) do
          default_options.merge(
            environment: nil,
            key: api_key,
            http_max_retry_duration: max_retry_duration,
            http_max_retry_count: max_retry_count
          )
        end

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
          stub_request(:post, "https://#{Ably::Rest::Client::DOMAIN}#{path}").to_return(&fallback_block)
        end

        context 'with custom fallback hosts provided' do
          let!(:first_fallback_request_stub) do
            stub_request(:post, "https://#{custom_hosts[0]}#{path}").to_return(&fallback_block)
          end

          let!(:second_fallback_request_stub) do
            stub_request(:post, "https://#{custom_hosts[1]}#{path}").to_return(&fallback_block)
          end

          let(:client_options) {
            production_options.merge(fallback_hosts: custom_hosts)
          }

          it 'attempts the fallback hosts as this is an authentication failure (#RSC15b, #TO3k6)' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::ServerError)
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end
        end

        context 'with an empty array of fallback hosts provided (#RSC15b, #TO3k6)' do
          let(:client_options) {
            production_options.merge(fallback_hosts: [])
          }

          it 'does not attempt the fallback hosts as this is an authentication failure' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::ServerError)
            expect(default_host_request_stub).to have_been_requested
          end
        end

        context 'using a local web-server', webmock: false do
          let(:primary_host) { 'local-rest.ably.io' }
          let(:fallbacks) { ['local.ably.io', 'localhost'] }
          let(:port) { rand(10000) + 2000 }
          let(:channel_name) { 'foo' }
          let(:request_timeout) { 3 }

          after do
            @web_server.shutdown
          end

          context 'and timing out the primary host' do
            before do
              @web_server = WEBrick::HTTPServer.new(:Port => port, :SSLEnable => false)
              @web_server.mount_proc "/channels/#{channel_name}/publish" do |req, res|
                if req.header["host"].first.include?(primary_host)
                  @primary_host_requested = true
                  sleep request_timeout + 0.5
                else
                  @fallback_request_count ||= 0
                  @fallback_request_count += 1
                  if @fallback_request_count <= fail_fallback_request_count
                    sleep request_timeout + 0.5
                  else
                    res.status = 200
                    res['Content-Type'] = 'application/json'
                    res.body = '{}'
                  end
                end
              end
              Thread.new do
                @web_server.start
              end
            end

            context 'with request timeout less than max_retry_duration' do
              let(:client_options) do
                default_options.merge(
                  rest_host: primary_host,
                  fallback_hosts: fallbacks,
                  token: 'fake.token',
                  port: port,
                  tls: false,
                  http_request_timeout: request_timeout,
                  max_retry_duration: request_timeout * 3
                )
              end
              let(:fail_fallback_request_count) { 1 }

              it 'tries one of the fallback hosts' do
                client.channel(channel_name).publish('event', 'data')
                expect(@primary_host_requested).to be_truthy
                expect(@fallback_request_count).to eql(2)
              end
            end

            context 'with request timeout less than max_retry_duration' do
              let(:client_options) do
                default_options.merge(
                  rest_host: primary_host,
                  fallback_hosts: fallbacks,
                  token: 'fake.token',
                  port: port,
                  tls: false,
                  http_request_timeout: request_timeout,
                  max_retry_duration: request_timeout / 2
                )
              end
              let(:fail_fallback_request_count) { 0 }

              it 'tries one of the fallback hosts' do
                client.channel(channel_name).publish('event', 'data')
                expect(@primary_host_requested).to be_truthy
                expect(@fallback_request_count).to eql(1)
              end
            end
          end

          context 'and failing the primary host' do
            before do
              @web_server = WEBrick::HTTPServer.new(:Port => port, :SSLEnable => false)
              @web_server.mount_proc "/channels/#{channel_name}/publish" do |req, res|
                if req.header["host"].first.include?(primary_host)
                  @primary_host_requested = true
                  res.status = 500
                else
                  @fallback_request_count ||= 0
                  @fallback_request_count += 1
                  if @fallback_request_count <= fail_fallback_request_count
                    res.status = 500
                  else
                    res.status = 200
                    res['Content-Type'] = 'application/json'
                    res.body = '{}'
                  end
                end
              end
              Thread.new do
                @web_server.start
              end
            end

            let(:client_options) do
              default_options.merge(
                rest_host: primary_host,
                fallback_hosts: fallbacks,
                token: 'fake.token',
                port: port,
                tls: false
              )
            end
            let(:fail_fallback_request_count) { 1 }

            it 'tries one of the fallback hosts' do
              client.channel(channel_name).publish('event', 'data')
              expect(@primary_host_requested).to be_truthy
              expect(@fallback_request_count).to eql(2)
            end
          end
        end
      end

      context 'when environment is not production and server returns a 50x error' do
        let(:custom_hosts)       { %w(A.foo.com B.foo.com) }
        let(:max_retry_count)    { 2 }
        let(:max_retry_duration) { 0.5 }
        let(:fallback_block)     { Proc.new { raise Faraday::SSLError.new('ssl error message') } }
        let(:env)                { 'custom-env' }
        let(:production_options) do
          default_options.merge(
            environment: env,
            key: api_key,
            http_max_retry_duration: max_retry_duration,
            http_max_retry_count: max_retry_count
          )
        end

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
          stub_request(:post, "https://#{env}-#{Ably::Rest::Client::DOMAIN}#{path}").to_return(&fallback_block)
        end

        context 'with custom fallback hosts provided (#RSC15b, #TO3k6)' do
          let!(:first_fallback_request_stub) do
            stub_request(:post, "https://#{custom_hosts[0]}#{path}").to_return(&fallback_block)
          end

          let!(:second_fallback_request_stub) do
            stub_request(:post, "https://#{custom_hosts[1]}#{path}").to_return(&fallback_block)
          end

          let(:client_options) {
            production_options.merge(fallback_hosts: custom_hosts)
          }

          it 'attempts the fallback hosts as this is an authentication failure' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::ServerError)
            expect(default_host_request_stub).to have_been_requested
            expect(first_fallback_request_stub).to have_been_requested
            expect(second_fallback_request_stub).to have_been_requested
          end
        end

        context 'with an empty array of fallback hosts provided (#RSC15b, #TO3k6)' do
          let(:client_options) {
            production_options.merge(fallback_hosts: [])
          }

          it 'does not attempt the fallback hosts as this is an authentication failure' do
            expect { publish_block.call }.to raise_error(Ably::Exceptions::ServerError)
            expect(default_host_request_stub).to have_been_requested
          end
        end

        context 'with fallback_hosts_use_default: true (#RSC15b, #TO3k7)' do
          let(:custom_hosts) { Ably::FALLBACK_HOSTS[0...2] }

          before do
            stub_const 'Ably::FALLBACK_HOSTS', custom_hosts
          end

          let(:client_options) {
            production_options.merge(fallback_hosts_use_default: true)
          }

          let!(:first_fallback_request_stub) do
            stub_request(:post, "https://#{Ably::FALLBACK_HOSTS[0]}#{path}").to_return(&fallback_block)
          end

          let!(:second_fallback_request_stub) do
            stub_request(:post, "https://#{Ably::FALLBACK_HOSTS[1]}#{path}").to_return(&fallback_block)
          end

          let(:client_options) {
            production_options.merge(fallback_hosts: custom_hosts)
          }

          it 'attempts the default fallback hosts as this is an authentication failure' do
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
            stub_request(:post, "https://#{custom_host}#{path}").to_return do
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
          expect { client.auth.request_token }.to raise_error Ably::Exceptions::ConnectionTimeout
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
            expect { client.auth.request_token }.to raise_error Ably::Exceptions::ConnectionTimeout
            expect(custom_host_request_stub).to have_been_requested
          end
        end
      end
    end

    context 'HTTP configuration options' do
      let(:client_options) { default_options.merge(key: api_key) }

      context 'defaults' do
        specify '#http_open_timeout is 4s' do
          expect(client.http_defaults[:open_timeout]).to eql(4)
        end

        specify '#http_request_timeout is 15s' do
          expect(client.http_defaults[:request_timeout]).to eql(15)
        end

        specify '#http_max_retry_count is 3' do
          expect(client.http_defaults[:max_retry_count]).to eql(3)
        end

        specify '#http_max_retry_duration is 10s' do
          expect(client.http_defaults[:max_retry_duration]).to eql(10)
        end
      end

      context 'configured' do
        let(:client_options) do
          default_options.merge(
            key: api_key,
            http_open_timeout: 1,
            http_request_timeout: 2,
            http_max_retry_count: 33,
            http_max_retry_duration: 4
          )
        end

        specify '#http_open_timeout uses provided value' do
          expect(client.http_defaults[:open_timeout]).to eql(1)
        end

        specify '#http_request_timeout uses provided value' do
          expect(client.http_defaults[:request_timeout]).to eql(2)
        end

        specify '#http_max_retry_count uses provided value' do
          expect(client.http_defaults[:max_retry_count]).to eql(33)
        end

        specify '#http_max_retry_duration uses provided value' do
          expect(client.http_defaults[:max_retry_duration]).to eql(4)
        end
      end

      it 'is frozen' do
        expect(client.http_defaults).to be_frozen
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

    context 'version headers', :webmock do
      [nil, 'foo'].each do |variant|
        context "with variant #{variant ? variant : 'none'}" do
          if variant
            before do
              Ably.lib_variant = variant
            end

            after do
              Ably.lib_variant = nil
            end
          end

          let(:client_options) { default_options.merge(key: api_key) }
          let!(:publish_message_stub) do
            lib = ['ruby']
            lib << variant if variant
            lib << Ably::VERSION


            stub_request(:post, "#{client.endpoint}/channels/foo/publish").
              with(headers: {
                'X-Ably-Version' => Ably::PROTOCOL_VERSION,
                'X-Ably-Lib' => lib.join('-')
              }).
              to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })
          end

          it 'sends a protocol version and lib version header' do
            client.channels.get('foo').publish("event")
            expect(publish_message_stub).to have_been_requested
          end
        end
      end
    end

    context '#request (#RSC19*)' do
      let(:client_options) { default_options.merge(key: api_key) }

      context 'get' do
        it 'returns an HttpPaginatedResponse object' do
          response = client.request(:get, 'time')
          expect(response).to be_a(Ably::Models::HttpPaginatedResponse)
          expect(response.status_code).to eql(200)
        end

        context '404 request to invalid URL' do
          it 'returns an object with 404 status code and error message' do
            response = client.request(:get, 'does-not-exist')
            expect(response).to be_a(Ably::Models::HttpPaginatedResponse)
            expect(response.error_message).to match(/Could not find/)
            expect(response.error_code).to eql(40400)
            expect(response.status_code).to eql(404)
          end
        end

        context 'paged results' do
          let(:channel_name) { random_str }

          it 'provides paging' do
            10.times do
              client.request(:post, "/channels/#{channel_name}/publish", {}, { 'name' => 'test' })
            end
            response = client.request(:get, "/channels/#{channel_name}/messages", { limit: 2 })
            expect(response.items.length).to eql(2)
            expect(response).to be_has_next
            next_page = response.next
            expect(next_page.items.length).to eql(2)
            expect(next_page).to be_has_next
            first_page_ids = response.items.map { |message| message['id'] }.uniq.sort
            next_page_ids = next_page.items.map { |message| message['id'] }.uniq.sort
            expect(first_page_ids).to_not eql(next_page_ids)
            next_page = next_page.next
            expect(next_page.items.length).to eql(2)
          end
        end
      end
    end
  end
end
