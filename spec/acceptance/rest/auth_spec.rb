# encoding: utf-8
require 'spec_helper'

describe Ably::Auth do
  include Ably::Modules::Conversions

  def hmac_for(token_request_attributes, secret)
    token_request = if token_request_attributes.kind_of?(Ably::Models::IdiomaticRubyWrapper)
      token_request_attributes
    else
      Ably::Models::IdiomaticRubyWrapper.new(token_request_attributes)
    end

    text = [
      :key_name,
      :ttl,
      :capability,
      :client_id,
      :timestamp,
      :nonce
    ].map { |key| "#{token_request.attributes[key]}\n" }.join("")

    encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, secret, text)
    )
  end

  vary_by_protocol do
    let(:default_options) { { environment: environment, protocol: protocol } }
    let(:client_options)  { default_options.merge(key: api_key) }
    let(:client) do
      Ably::Rest::Client.new(client_options)
    end
    let(:auth) { client.auth }
    let(:content_type) do
      if protocol == :msgpack
        'application/x-msgpack'
      else
        'application/json'
      end
    end

    def request_body_includes(request, protocol, key, val)
      body = if protocol == :msgpack
        MessagePack.unpack(request.body)
      else
        JSON.parse(request.body)
      end
      body[convert_to_mixed_case(key)].to_s == val.to_s
    end

    def serialize(object, protocol)
      if protocol == :msgpack
        MessagePack.pack(object)
      else
        JSON.dump(object)
      end
    end

    it 'has immutable options' do
      expect { auth.options['key_name'] = 'new_name' }.to raise_error RuntimeError, /can't modify frozen.*Hash/
    end

    describe '#request_token' do
      let(:ttl)        { 30 * 60 }
      let(:capability) { { :foo => ['publish'] } }

      let(:token_details) do
        auth.request_token(
          ttl:        ttl,
          capability: capability
        )
      end

      it 'creates a TokenRequest automatically and sends it to Ably to obtain a token', webmock: true do
        token_request_stub = stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
          to_return(status: 201, body: serialize({}, protocol), headers: { 'Content-Type' => content_type })
        expect(auth).to receive(:create_token_request).and_call_original
        auth.request_token

        expect(token_request_stub).to have_been_requested
      end

      it 'returns a valid TokenDetails object in the expected format with valid issued and expires attributes' do
        expect(token_details).to be_a(Ably::Models::TokenDetails)
        expect(token_details.token).to match(/^#{app_id}\.[\w-]+$/)
        expect(token_details.key_name).to match(/^#{key_name}$/)
        expect(token_details.issued).to be_within(2).of(Time.now)
        expect(token_details.expires).to be_within(2).of(Time.now + ttl)
      end

      %w(client_id capability nonce timestamp ttl).each do |token_param|
        context "with token_param :#{token_param}", :webmock do
          def coerce_if_time_value(field_name, value, params = {})
            multiply = params[:multiply]
            return value unless %w(timestamp ttl).include?(field_name)
            value.to_i * (multiply ? multiply : 1)
          end

          let(:random)         { coerce_if_time_value(token_param, random_int_str) }
          let(:token_params)   { { token_param.to_sym => random } }

          let(:token_response) { {} }
          let!(:request_token_stub) do
            stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
              with do |request|
                request_body_includes(request, protocol, token_param, coerce_if_time_value(token_param, random, multiply: 1000))
              end.to_return(
                :status => 201,
                :body => serialize(token_response, protocol),
                :headers => { 'Content-Type' => content_type }
              )
          end

          before { auth.request_token token_params }

          it "overrides default and uses camelCase notation for attributes" do
            expect(request_token_stub).to have_been_requested
          end
        end
      end

      context 'with :key option', :webmock do
        let(:key_name)      { "app.#{random_str}" }
        let(:key_secret)    { random_str }
        let(:nonce)         { random_str }
        let(:auth_options)  { { key: "#{key_name}:#{key_secret}" } }
        let(:token_params)  { { nonce: nonce, timestamp: Time.now } }
        let(:token_request) { auth.create_token_request(token_params, auth_options) }
        let(:mac) do
          hmac_for(token_request, key_secret)
        end

        let(:token_response) { {} }
        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
            with do |request|
              request_body_includes(request, protocol, 'mac', mac)
            end.to_return(
              :status => 201,
              :body => serialize(token_response, protocol),
              :headers => { 'Content-Type' => content_type })
        end

        let!(:token) { auth.request_token(token_params, auth_options) }

        specify 'key_name is used in request and signing uses key_secret' do
          expect(request_token_stub).to have_been_requested
        end
      end

      context 'with :key_name & :key_secret options', :webmock do
        let(:key_name)      { "app.#{random_str}" }
        let(:key_secret)    { random_str }
        let(:nonce)         { random_str }

        let(:auth_options)  { { key_name: key_name, key_secret: key_secret } }
        let(:token_params)  { { nonce: nonce, timestamp: Time.now } }
        let(:token_request) { auth.create_token_request(token_params, auth_options) }
        let(:mac) do
          hmac_for(token_request, key_secret)
        end

        let(:token_response) { {} }
        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
            with do |request|
              request_body_includes(request, protocol, 'mac', mac)
            end.to_return(
              :status => 201,
              :body => serialize(token_response, protocol),
              :headers => { 'Content-Type' => content_type })
        end

        let!(:token) { auth.request_token(token_params, auth_options) }

        specify 'key_name is used in request and signing uses key_secret' do
          expect(request_token_stub).to have_been_requested
        end
      end

      context 'with :query_time option' do
        let(:options) { { query_time: true } }

        it 'queries the server for the time (#RSA10k)' do
          expect(client).to receive(:time).and_call_original
          auth.request_token({}, options)
        end
      end

      context 'without :query_time option' do
        let(:options) { { query_time: false } }

        it 'does not query the server for the time' do
          expect(client).to_not receive(:time)
          auth.request_token({}, options)
        end
      end

      context 'with :auth_url option merging', :webmock do
        context 'with existing configured auth options' do
          let(:client_id)    { random_str }
          let(:auth_url)     { "https://www.fictitious.com/#{random_str}" }
          let(:auth_method)  { :get }
          let(:auth_params)  { { key: 'val', client_id: 'isOverridenByClient' } }
          let(:auth_headers) { { 'Header-X' => 'val1', 'Header-Y' => 'val2' } }

          let(:base_options) do
            default_options.merge(
              client_id:    client_id,
              auth_url:     auth_url,
              auth_params:  auth_params,
              auth_headers: auth_headers
            )
          end
          let(:client_options) { base_options }

          let!(:auth_request) do
            stub_request(auth_method, auth_url).to_return(
              :status => 201,
              :body => '123123.12312321321312321', # token string
              :headers => { 'Content-Type' => 'text/plain' }
            )
          end

          let(:request_token_auth_options) { Hash.new }
          let(:request_token_token_params) { Hash.new }
          after do
            client.auth.request_token(request_token_token_params, request_token_auth_options)
            expect(auth_request).to have_been_requested
          end

          context 'using unspecified :auth_method' do
            it 'requests a token using a GET request with provided headers, and merges client_id into auth_params' do
              auth_request.with(headers: auth_headers)
              auth_request.with(query: auth_params.merge(client_id: client_id))
            end

            context 'with provided token_params' do
              let(:request_token_token_params) { { client_id: 'custom', key2: 'val2' } }

              it 'merges provided token_params with existing auth_params and client_id' do
                auth_request.with(query: auth_params.merge(client_id: client_id).merge(request_token_token_params))
              end
            end

            context 'with provided auth option auth_params and auth_headers' do
              let(:request_token_auth_options) { { auth_params: {}, auth_headers: {} } }

              it 'replaces any preconfigured auth_params' do
                auth_request.with(query: {}.merge(client_id: client_id))
                auth_request.with(headers: { 'Accept'=>'*/*' }) # mock library needs at least one header, accept is default
              end
            end
          end

          context 'using :get :auth_method and query params in the URL' do
            let(:auth_method) { :get }
            let(:client_options) { base_options.merge(auth_method: :get, auth_url: "#{auth_url}?urlparam=true") }

            it 'requests a token using a GET request with provided headers, and merges client_id into auth_params and existing URL querystring into new URL querystring' do
              auth_request.with(headers: auth_headers)
              auth_request.with(query: auth_params.merge(client_id: client_id).merge(urlparam: 'true'))
            end
          end

          context 'using :post :auth_method' do
            let(:auth_method) { :post }
            let(:client_options) { base_options.merge(auth_method: :post) }

            it 'requests a token using a POST request with provided headers, and merges client_id into auth_params as form-encoded post data' do
              auth_request.with(headers: auth_headers)
              auth_request.with(body: auth_params.merge(client_id: client_id))
            end
          end
        end
      end

      context 'with :auth_url option', :webmock do
        let(:auth_url)          { 'https://www.fictitious.com/get_token' }
        let(:auth_url_response) { { keyName: key_name }.to_json }
        let(:token_response)    { {} }
        let(:query_params)      { nil }
        let(:headers)           { nil }
        let(:auth_method)       { :get }
        let(:auth_options) do
          {
            auth_url:     auth_url,
            auth_params:  query_params,
            auth_headers: headers,
            auth_method:  auth_method
          }
        end

        let!(:auth_url_request_stub) do
          stub = stub_request(auth_method, auth_url)
          stub.with(:query => query_params) unless query_params.nil?
          stub.with(:headers => headers) unless headers.nil?
          stub.to_return(
            :status => 201,
            :body => auth_url_response,
            :headers => { 'Content-Type' => auth_url_content_type }
          )
        end
        let(:auth_url_content_type) { 'application/json' }

        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
            with do |request|
              request_body_includes(request, protocol, 'key_name', key_name)
            end.to_return(
              :status => 201,
              :body => serialize(token_response, protocol),
              :headers => { 'Content-Type' => content_type }
            )
        end

        context 'when response from :auth_url is a valid token request' do
          let!(:token) { auth.request_token({}, auth_options) }

          it 'requests a token from :auth_url using an HTTP GET request' do
            expect(request_token_stub).to have_been_requested
            expect(auth_url_request_stub).to have_been_requested
          end

          it 'returns a valid token generated from the token request' do
            expect(token).to be_a(Ably::Models::TokenDetails)
          end

          context 'with :query_params' do
            let(:query_params) { { 'key' => random_str } }

            it 'requests a token from :auth_url with the :query_params' do
              expect(request_token_stub).to have_been_requested
              expect(auth_url_request_stub).to have_been_requested
            end
          end

          context 'with :headers' do
            let(:headers) { { 'key' => random_str } }
            it 'requests a token from :auth_url with the HTTP headers set' do
              expect(request_token_stub).to have_been_requested
              expect(auth_url_request_stub).to have_been_requested
            end
          end

          context 'with POST' do
            let(:auth_method) { :post }
            it 'requests a token from :auth_url using an HTTP POST instead of the default GET' do
              expect(request_token_stub).to have_been_requested
              expect(auth_url_request_stub).to have_been_requested
            end
          end
        end

        context 'when response from :auth_url is a token details object' do
          let(:token) { 'J_0Tlg.D7AVZkdOZW-PqNNGvCSp38' }
          let(:issued) { Time.now }
          let(:expires) { Time.now + 60}
          let(:capability) { {'foo'=>['publish']} }
          let(:capability_str) { JSON.dump(capability) }
          let(:auth_url_response) do
            {
              'token' => token,
              'key_name' => 'J_0Tlg.NxCRig',
              'issued' => issued.to_i * 1000,
              'expires' => expires.to_i  * 1000,
              'capability'=> capability_str
            }.to_json
          end

          let!(:token_details) { auth.request_token({}, auth_options) }

          it 'returns TokenDetails created from the token JSON' do
            expect(auth_url_request_stub).to have_been_requested
            expect(request_token_stub).to_not have_been_requested
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.token).to eql(token)
            expect(token_details.expires).to be_within(1).of(expires)
            expect(token_details.issued).to be_within(1).of(issued)
            expect(token_details.capability).to eql(capability)
          end
        end

        context 'when response from :auth_url is text/plain content type and a token string' do
          let(:token) { 'J_0Tlg.D7AVZkdOZW-PqNNGvCSp38' }
          let(:auth_url_content_type) { 'text/plain' }
          let(:auth_url_response) { token }

          let!(:token_details) { auth.request_token({}, auth_options) }

          it 'returns TokenDetails created from the token JSON' do
            expect(auth_url_request_stub).to have_been_requested
            expect(request_token_stub).to_not have_been_requested
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.token).to eql(token)
          end
        end

        context 'when response is invalid' do
          context '500' do
            let!(:auth_url_request_stub) do
              stub_request(auth_method, auth_url).to_return(:status => 500)
            end

            it 'raises ServerError' do
              expect { auth.request_token({}, auth_options) }.to raise_error(Ably::Exceptions::AuthenticationFailed)
            end
          end

          context 'XML' do
            let!(:auth_url_request_stub) do
              stub_request(auth_method, auth_url).
                to_return(:status => 201, :body => '<xml></xml>', :headers => { 'Content-Type' => 'application/xml' })
            end

            it 'raises InvalidResponseBody' do
              expect { auth.request_token({}, auth_options) }.to raise_error(Ably::Exceptions::AuthenticationFailed, /Content Type.*not supported/)
            end
          end
        end
      end

      context 'with a Proc for the :auth_callback option' do
        context 'that returns a TokenRequest' do
          let(:client_id) { random_str }
          let(:ttl)       { 8888 }
          let(:auth_callback) do
            Proc.new do |token_params_arg|
              @block_called = true
              expect(token_params_arg).to eq(token_params)
              auth.create_token_request(client_id: client_id)
            end
          end
          let(:token_params) { { ttl: ttl } }
          let!(:request_token) do
            auth.request_token(token_params, auth_callback: auth_callback)
          end

          it 'calls the Proc with token_params when authenticating to obtain the request token' do
            expect(@block_called).to eql(true)
          end

          it 'uses the token request returned from the callback when requesting a new token' do
            expect(request_token.client_id).to eql(client_id)
          end

          context 'when authorized' do
            before { auth.authorize(token_params, auth_callback: auth_callback) }

            it "sets Auth#client_id to the new token's client_id" do
              expect(auth.client_id).to eql(client_id)
            end

            it "sets Client#client_id to the new token's client_id" do
              expect(client.client_id).to eql(client_id)
            end
          end
        end

        context 'that returns a TokenDetails JSON object' do
          let(:client_id)   { random_str }
          let(:token_params){ { client_id: client_id } }
          let(:token)       { 'J_0Tlg.D7AVZkdOZW-PqNNGvCSp38' }
          let(:issued)      { Time.now }
          let(:expires)     { Time.now + 60}
          let(:capability)  { {'foo'=>['publish']} }
          let(:capability_str) { JSON.dump(capability) }

          let!(:token_details) do
            auth.request_token(token_params, auth_callback: auth_callback)
          end

          let(:auth_callback) do
            lambda do |token_params_arg|
              @block_called = true
              @block_params = token_params_arg
              {
                'token' => token,
                'keyName' => 'J_0Tlg.NxCRig',
                'clientId' => client_id,
                'issued' => issued.to_i * 1000,
                'expires' => expires.to_i * 1000,
                'capability'=> capability_str
              }
            end
          end

          it 'calls the lambda when authenticating to obtain the request token' do
            expect(@block_called).to eql(true)
            expect(@block_params).to include(token_params)
          end

          it 'uses the token request returned from the callback when requesting a new token' do
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.token).to eql(token)
            expect(token_details.client_id).to eql(client_id)
            expect(token_details.expires).to be_within(1).of(expires)
            expect(token_details.issued).to be_within(1).of(issued)
            expect(token_details.capability).to eql(capability)
          end

          context 'when authorized' do
            before { auth.authorize(token_params, auth_callback: auth_callback) }

            it "sets Auth#client_id to the new token's client_id" do
              expect(auth.client_id).to eql(client_id)
            end

            it "sets Client#client_id to the new token's client_id" do
              expect(client.client_id).to eql(client_id)
            end
          end
        end

        context 'that returns a TokenDetails object' do
          let(:client_id)   { random_str }

          let!(:token_details) do
            auth.request_token({}, auth_callback: lambda do |token_params|
              auth.create_token_request(client_id: client_id)
            end)
          end

          it 'uses the token request returned from the callback when requesting a new token' do
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.client_id).to eql(client_id)
          end
        end

        context 'that returns a Token string' do
          let(:second_client) { Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol) }
          let(:token) { second_client.auth.request_token.token }

          let!(:token_details) do
            auth.request_token({}, auth_callback: lambda do |token_params|
              token
            end)
          end

          it 'uses the token request returned from the callback when requesting a new token' do
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.token).to eql(token)
          end
        end
      end

      context 'persisted option of token params', api_private: true do
        context 'when set to true', api_private: true do
          let(:token_details) { auth.request_token(persisted: true) }

          it 'returns a token with a short token ID that is used to look up the token details' do
            expect(token_details.token.length).to be < 64
            expect(token_details.token).to match(/^#{app_id}\.A/)
          end
        end

        context 'when omitted', api_private: true do
          let(:token_details) { auth.request_token }

          it 'returns a literal token' do
            expect(token_details.token.length).to be > 64
          end
        end
      end

      context 'with auth_option :client_id' do
        let(:client_id) { random_str }
        let(:token_details) { auth.request_token({}, client_id: client_id) }

        it 'returns a token with the client_id' do
          expect(token_details.client_id).to eql(client_id)
        end
      end

      context 'with token_param :client_id' do
        let(:client_id) { random_str }
        let(:token_details) { auth.request_token(client_id: client_id) }

        it 'returns a token with the client_id' do
          expect(token_details.client_id).to eql(client_id)
        end
      end
    end

    context 'before #authorize has been called' do
      it 'has no current_token_details' do
        expect(auth.current_token_details).to be_nil
      end
    end

    describe '#authorize (#RSA10, #RSA10j)' do
      context 'when called for the first time since the client has been instantiated' do
        let(:auth_options) do
          { auth_url: 'http://somewhere.com/' }
        end
        let(:token_params) do
          { ttl: 55 }
        end

        it 'passes all auth_options and token_params to #request_token' do
          expect(auth).to receive(:request_token).with(token_params, auth_options)
          auth.authorize token_params, auth_options
        end

        it 'returns a valid token' do
          expect(auth.authorize).to be_a(Ably::Models::TokenDetails)
        end

        it 'issues a new token every time (#RSA10a)' do
          expect { auth.authorize }.to change { auth.current_token_details }
        end
      end

      context 'query_time: true with authorize' do
        let(:local_time)  { @now - 60 }
        let(:server_time) { @now }

        before do
          @now = Time.now
          allow(Time).to receive(:now).and_return(local_time)
        end

        it 'only queries the server time once and then works out the offset, query_time option is never persisted (#RSA10k)' do
          expect(client).to receive(:time).once.and_return(server_time)

          auth.authorize({}, query_time: true)
          auth.authorize({})
          expect(auth.auth_options).to_not have_key(:query_time)
        end
      end

      context 'query_time: true ClientOption when instanced' do
        let(:local_time)  { @now - 60 }
        let(:server_time) { @now }

        let(:client_options)  { default_options.merge(key: api_key, query_time: true) }

        before do
          @now = Time.now
          allow(Time).to receive(:now).and_return(local_time)
        end

        it 'only queries the server time once and then works out the offset, query_time option is never persisted (#RSA10k)' do
          expect(client).to receive(:time).once.and_return(server_time)

          auth.authorize({})
          auth.authorize({})
          auth.authorize({})
          expect(auth.auth_options).to_not have_key(:query_time)
        end
      end

      context 'TokenParams argument' do
        let(:default_token_params) { { ttl: 23 } }

        before do
          auth.authorize default_token_params
        end

        it 'has no effect on the defaults when null and TokenParam defaults remain the same' do
          old_token = auth.current_token_details
          auth.authorize
          expect(old_token).to_not eql(auth.current_token_details)
          expect(auth.token_params[:ttl]).to eql(23)
        end

        it 'updates defaults when present and all previous configured TokenParams are discarded (#RSA10g)' do
          old_token = auth.current_token_details
          auth.authorize({ client_id: 'bob' })
          expect(old_token).to_not eql(auth.current_token_details)
          expect(auth.token_params[:ttl]).to_not eq(23)
          expect(auth.token_params[:client_id]).to eql('bob')
        end

        it 'updates Auth#token_params attribute with an immutable hash' do
          auth.authorize({ client_id: 'bob' })
          expect { auth.token_params['key_name'] = 'new_name' }.to raise_error RuntimeError, /can't modify frozen.*Hash/
        end

        it 'uses TokenParams#timestamp for this request but obtains a new timestamp for subsequence requests (#RSA10g)' do
          timestamp = Time.now.to_i
          expect(auth).to receive(:create_token_request).with({ timestamp: Time.now.to_i }, {}).once.and_call_original
          expect(auth).to receive(:create_token_request).with({}, {}).once.and_call_original
          auth.authorize(timestamp: Time.now.to_i)
          auth.authorize
        end
      end

      context 'AuthOptions argument' do
        let(:token_ttl) { 2 }
        let(:auth_callback) { lambda do |token_params|
          auth.create_token_request(ttl: token_ttl)
        end }
        let(:default_auth_options) { { auth_callback: auth_callback } }

        before do
          stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0 # allow token to be used even if about to expire
          stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0) # Ensure tokens issued expire immediately after issue

          auth.authorize(nil, default_auth_options)
          @old_token = auth.current_token_details
          sleep token_ttl + 0.5
        end

        it 'has no effect on the defaults when null and AuthOptions defaults remain the same' do
          auth.authorize(nil, nil)
          expect(@old_token).to_not eql(auth.current_token_details)
          expect(auth.options[:auth_callback]).to eql(auth_callback)
        end

        it 'updates defaults when present and all previous configured AuthOptions are discarded (#RSA10g)' do
          auth.authorize(nil, auth_method: :post)
          expect(@old_token).to_not eql(auth.current_token_details)
          expect(auth.options[:auth_callback]).to be_nil
          expect(auth.options[:auth_method]).to eql(:post)
        end

        it 'updates Auth#options attribute with an immutable hash' do
          auth.authorize(nil, auth_callback: lambda { |token_params| '1231232.12321:12321312' })
          expect { auth.options['key_name'] = 'new_name' }.to raise_error RuntimeError, /can't modify frozen.*Hash/
        end

        it 'uses AuthOptions#query_time for this request and will not query_time for subsequent requests (#RSA10g)' do
          expect(client).to receive(:time).once.and_call_original
          auth.authorize({}, query_time: true)
          auth.authorize
        end

        it 'uses AuthOptions#query_time for this request and will query_time again if provided subsequently' do
          expect(client).to receive(:time).twice.and_call_original
          auth.authorize({}, query_time: true)
          auth.authorize({}, query_time: true)
        end
      end

      context 'with previous authorisation' do
        before do
          auth.authorize
          expect(auth.current_token_details).to_not be_expired
        end

        it 'requests a new token if token is expired' do
          allow(auth.current_token_details).to receive(:expired?).and_return(true)
          expect(auth).to receive(:request_token)
          expect { auth.authorize }.to change { auth.current_token_details }
        end

        it 'issues a new token every time #authorize is called' do
          expect { auth.authorize({}) }.to change { auth.current_token_details }
        end
      end

      it 'updates the persisted token params that are then used for subsequent authorize requests' do
        expect(auth.token_params[:ttl]).to_not eql(26)
        auth.authorize(ttl: 26)
        expect(auth.token_params[:ttl]).to eql(26)
      end

      it 'updates the persisted auth options that are then used for subsequent authorize requests' do
        auth_url = "https://echo.ably.io/?type=text&body=#{auth.request_token.token}"
        expect(auth.options[:auth_url]).to be_nil
        auth.authorize({}, auth_url: auth_url)
        expect(auth.options[:auth_url]).to eql(auth_url)
      end

      context 'with a lambda for the :auth_callback option' do
        let(:client_id) { random_str }
        let!(:token) do
          auth.authorize({}, auth_callback: lambda do |token_params|
            @block_called ||= 0
            @block_called += 1
            auth.create_token_request(client_id: client_id)
          end)
        end

        it 'calls the lambda' do
          expect(@block_called).to eql(1)
        end

        it 'uses the token request returned from the callback when requesting a new token' do
          expect(token.client_id).to eql(client_id)
        end

        context 'for every subsequent #request_token' do
          context 'without a :auth_callback lambda' do
            it 'calls the originally provided block' do
              auth.request_token
              expect(@block_called).to eql(2)
            end
          end

          context 'with a provided block' do
            it 'does not call the originally provided lambda and calls the new #request_token :auth_callback lambda' do
              auth.request_token({}, auth_callback: lambda { |token_params| @request_block_called = true; auth.create_token_request })
              expect(@block_called).to eql(1)
              expect(@request_block_called).to eql(true)
            end
          end
        end
      end

      context 'with an explicit token string that expires' do
        context 'and a lambda for the :auth_callback option to provide a means to renew the token' do
          before do
            # Ensure a soon to expire token is not treated as expired
            stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0
            old_token_defaults = Ably::Auth::TOKEN_DEFAULTS
            stub_const 'Ably::Auth::TOKEN_DEFAULTS', old_token_defaults.merge(renew_token_buffer: 0)
            @block_called = 0
          end

          let(:token_client)   { Ably::Rest::Client.new(default_options.merge(key: api_key, default_token_params: { ttl: 3 })) }
          let(:client_options) {
            default_options.merge(token: token_client.auth.request_token.token, auth_callback: lambda do |token_params|
              @block_called += 1
              token_client.auth.create_token_request
            end)
          }

          it 'calls the lambda once the token has expired and the new token is used' do
            client.stats
            expect(@block_called).to eql(0)
            sleep 3.5
            expect { client.stats }.to change { client.auth.current_token_details }
            expect(@block_called).to eql(1)
          end
        end
      end

      context 'with an explicit ClientOptions client_id' do
        let(:client_id)       { random_str }
        let(:client_options)  { default_options.merge(auth_callback: lambda { |token_params| auth_token_object }, client_id: client_id) }
        let(:auth_client)     { Ably::Rest::Client.new(default_options.merge(key: api_key, client_id: 'invalid')) }

        context 'and an incompatible client_id in a TokenDetails object passed to the auth callback' do
          let(:auth_token_object) { auth_client.auth.request_token }

          it 'rejects a TokenDetails object with an incompatible client_id and raises an exception' do
            expect { client.auth.authorize({}) }.to raise_error Ably::Exceptions::IncompatibleClientId
          end
        end

        context 'and an incompatible client_id in a TokenRequest object passed to the auth callback and raises an exception' do
          let(:auth_token_object) { auth_client.auth.create_token_request }

          it 'rejects a TokenRequests object with an incompatible client_id and raises an exception' do
            expect { client.auth.authorize({}) }.to raise_error Ably::Exceptions::IncompatibleClientId
          end
        end

        context 'and a token string without any retrievable client_id' do
          let(:auth_token_object) { auth_client.auth.request_token(client_id: 'different').token }

          it 'rejects a TokenRequests object with an incompatible client_id and raises an exception' do
            client.auth.authorize({})
            expect(client.client_id).to eql(client_id)
          end
        end
      end
    end

    describe '#create_token_request' do
      let(:ttl)          { 60 * 60 }
      let(:capability)   { { "foo" => ["publish"] } }
      let(:token_params) { Hash.new }

      subject { auth.create_token_request(token_params) }

      it 'returns a TokenRequest object' do
        expect(subject).to be_a(Ably::Models::TokenRequest)
      end

      it 'returns a TokenRequest that can be passed to a client that can use it for authentication without an API key' do
        auth_callback = proc { |token_params| subject }
        client_without_api_key = Ably::Rest::Client.new(default_options.merge(auth_callback: auth_callback))
        expect(client_without_api_key.auth).to be_using_token_auth
        expect { client_without_api_key.auth.authorize }.to_not raise_error
      end

      it 'uses the key name from the client' do
        expect(subject['keyName']).to eql(key_name)
      end

      it 'specifies no TTL (#RSA5)' do
        expect(subject['ttl']).to be_nil
      end

      context 'with a :ttl option below the Token expiry buffer that ensures tokens are renewed 15s before they expire as they are considered expired' do
        let(:ttl) { 1 }
        let(:token_params) { { ttl: ttl } }

        it 'uses the Token expiry buffer default + 10s to allow for a token request in flight' do
          expect(subject['ttl']).to be > 1
          expect(subject['ttl']).to be > Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER
        end
      end

      it 'specifies no capability (#RSA6)' do
        expect(subject['capability']).to be_nil
      end

      context 'the nonce' do
        it 'is unique for every request' do
          unique_nonces = 100.times.map { auth.create_token_request['nonce'] }
          expect(unique_nonces.uniq.length).to eql(100)
        end

        it 'is at least 16 characters' do
          expect(subject['nonce'].length).to be >= 16
        end
      end

      %w(ttl nonce client_id).each do |attribute|
        context "with token param :#{attribute}" do
          let(:token_param) { random_int_str(1_000_000_000).to_i }
          before do
            token_params[attribute.to_sym] = token_param
          end
          it "overrides default" do
            expect(subject.public_send(attribute).to_s).to eql(token_param.to_s)
          end
        end
      end

      context 'when specifying capability' do
        before do
          token_params[:capability] = capability
        end

        it 'overrides the default' do
          expect(subject.capability).to eql(capability)
        end

        it 'uses these capabilities when Ably issues an actual token' do
          auth_callback = lambda { |token_params| subject }
          client_without_api_key = Ably::Rest::Client.new(default_options.merge(auth_callback: auth_callback))
          client_without_api_key.auth.authorize
          expect(client_without_api_key.auth.current_token_details.capability).to eql(capability)
        end
      end

      context 'with additional invalid attributes' do
        let(:token_params) { { nonce: 'valid', is_not_used_by_token_request: 'invalid' } }
        specify 'are ignored' do
          expect(subject.attributes.keys).to_not include(:is_not_used_by_token_request)
          expect(subject.attributes.keys).to_not include(convert_to_mixed_case(:is_not_used_by_token_request))
          expect(subject.attributes.keys).to include(:nonce)
          expect(subject.nonce).to eql('valid')
        end
      end

      context 'when required fields are missing' do
        let(:client) { Ably::Rest::Client.new(auth_url: 'http://example.com', protocol: protocol) }

        it 'should raise an exception if key secret is missing' do
          expect { auth.create_token_request({}, key_name: 'name') }.to raise_error Ably::Exceptions::TokenRequestFailed
        end

        it 'should raise an exception if key name is missing' do
          expect { auth.create_token_request({}, key_secret: 'secret') }.to raise_error Ably::Exceptions::TokenRequestFailed
        end
      end

      context 'timestamp attribute' do
        context 'with :query_time auth_option' do
          let(:time)         { Time.now - 30 }
          let(:auth_options) { { query_time: true } }

          subject { auth.create_token_request({}, auth_options) }

          it 'queries the server for the timestamp' do
            expect(client).to receive(:time).and_return(time)
            expect(subject['timestamp']).to be_within(1).of(time.to_f * 1000)
          end
        end

        context 'with :timestamp option' do
          let(:token_request_time) { Time.now + 5 }
          let(:token_params)       { { timestamp: token_request_time } }

          it 'uses the provided timestamp in the token request' do
            expect(subject['timestamp']).to be_within(1).of(token_request_time.to_f * 1000)
          end
        end

        it 'is a Time object in Ruby and is set to the local time' do
          expect(subject.timestamp.to_f).to be_within(1).of(Time.now.to_f)
        end
      end

      context 'signing' do
        let(:token_attributes) do
          {
            key_name:   random_str,
            ttl:        random_int_str.to_i,
            capability: random_str,
            client_id:  random_str,
            timestamp:  random_int_str.to_i,
            nonce:      random_str
          }
        end
        let(:client_options) { default_options.merge(key_name: token_attributes.fetch(:key_name), key_secret: key_secret) }
        let(:token_params)   { token_attributes }

        # TokenRequest expects times in milliseconds, whereas create_token_request assumes Ruby default of seconds
        let(:token_request_attributes) do
          token_attributes.merge(timestamp: token_attributes[:timestamp] * 1000, ttl: token_attributes[:ttl] * 1000)
        end

        it 'generates a valid HMAC' do
          hmac = hmac_for(Ably::Models::TokenRequest(token_request_attributes).attributes, key_secret)
          expect(subject['mac']).to eql(hmac)
        end

        context 'lexicographic ordering of channels and operations' do
          let(:token_attributes) do
            {
              key_name:   key_name,
              ttl:        600,
              capability: {
                "channel2" => ["subscribe", "publish"],
                "channel1" => ["subscribe", "history"]
              },
              client_id:  random_str,
              nonce:      random_str,
              timestamp:  Time.now.to_i
            }
          end

          let(:token_attributes_ordered) do
            token_attributes.merge(capability: {
              "channel1" => ["history", "subscribe"],
              "channel2" => ["publish", "subscribe"]
            })
          end

          specify 'HMAC is lexicographic ordered and thus the HMAC is identical' do
            hmac = auth.create_token_request(token_attributes).mac
            hmac_ordered = auth.create_token_request(token_attributes_ordered).mac
            expect(hmac).to eql(hmac_ordered)
          end

          it 'is valid when used for authentication' do
            auth_callback = lambda do |callback|
              auth.create_token_request(token_attributes)
            end
            client = Ably::Rest::Client.new(auth_callback: auth_callback, environment: environment, protocol: protocol)
            client.auth.authorize
          end
        end
      end
    end

    context 'using token authentication' do
      let(:capability) { { :foo => ["publish"] } }

      describe 'with :token option' do
        let(:ttl) { 60 * 60 }
        let(:token_details) do
          auth.request_token(
            ttl:        ttl,
            capability: capability
          )
        end
        let(:token) { token_details.token }
        let(:token_auth_client) do
          Ably::Rest::Client.new(token: token, environment: environment, protocol: protocol)
        end

        it 'authenticates successfully using the provided :token' do
          expect(token_auth_client.channel('foo').publish('event', 'data')).to be_truthy
        end

        it 'disallows publishing on unspecified capability channels' do
          expect { token_auth_client.channel('bar').publish('event', 'data') }.to raise_error do |error|
            expect(error).to be_a(Ably::Exceptions::UnauthorizedRequest)
            expect(error.status).to eql(401)
            expect(error.code).to eql(40160)
          end
        end

        it 'fails if timestamp is invalid' do
          expect { auth.request_token(timestamp: Time.now - 180) }.to raise_error do |error|
            expect(error).to be_a(Ably::Exceptions::UnauthorizedRequest)
            expect(error.status).to eql(401)
            expect(error.code).to eql(40104)
          end
        end

        it 'cannot be renewed automatically' do
          expect(token_auth_client.auth).to_not be_token_renewable
        end

        context 'and the token expires' do
          let(:ttl) { 1 }

          before do
            stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0 # allow token to be used even if about to expire
            stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0) # Ensure tokens issued expire immediately after issue

            @token = auth.request_token(ttl: ttl)
            WebMock.enable!
            WebMock.disable_net_connect!

            token_expired = {
              "error" => {
                "statusCode" => 401,
                "code" => 40140,
                "message" => "Token expired"
              }
            }

            stub_request(:post, "https://#{environment}-rest.ably.io/channels/foo/publish").
              to_return(status: 401, body: token_expired.to_json, headers: { 'Content-Type' => 'application/json' })
          end

          after do
            WebMock.allow_net_connect!
            WebMock.disable!
          end

          let(:token) { @token.token }

          it 'should indicate an error and not retry the request (#RSA4a)' do
            sleep ttl + 1
            expect { token_auth_client.channels.get('foo').publish 'event' }.to raise_error(Ably::Exceptions::TokenExpired)
          end
        end
      end

      context 'when implicit as a result of using :client_id' do
        let(:client_id) { '999' }
        let(:client) do
          Ably::Rest::Client.new(key: api_key, client_id: client_id, environment: environment, protocol: protocol)
        end
        let(:token) { 'unique-token' }
        let(:token_response) do
          {
            token: token
          }.to_json
        end

        context 'and requests to the Ably server are mocked', :webmock do
          let!(:request_token_stub) do
            stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
              to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
          end
          let!(:publish_message_stub) do
            stub_request(:post, "#{client.endpoint}/channels/foo/publish").
              with(headers: { 'Authorization' => "Bearer #{encode64(token)}" }).
              to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })
          end

          it 'will send a token request to the server' do
            client.channel('foo').publish('event', 'data')
            expect(request_token_stub).to have_been_requested
          end
        end

        describe 'a token is created' do
          let(:token) { client.auth.current_token_details }

          it 'before a request is made' do
            expect(token).to be_nil
          end

          it 'when a message is published' do
            expect(client.channel('foo').publish('event', 'data')).to be_truthy
          end

          it 'with capability and TTL defaults (#TK2a, #TK2b)' do
            client.channel('foo').publish('event', 'data')

            expect(token).to be_a(Ably::Models::TokenDetails)
            capability_with_str_key = { "*" => ["*"] } # Ably default is all capabilities
            capability = Hash[capability_with_str_key.keys.map(&:to_s).zip(capability_with_str_key.values)]
            expect(token.capability).to eq(capability)
            expect(token.expires.to_i).to be_within(2).of(Time.now.to_i + 60 * 60) # Ably default is 1hr
            expect(token.client_id).to eq(client_id)
          end

          specify '#client_id contains the client_id' do
            expect(client.auth.client_id).to eql(client_id)
          end
        end
      end

      context 'when token expires' do
        before do
          stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0 # allow token to be used even if about to expire
          stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0) # Ensure tokens issued expire immediately after issue
        end

        after do
          WebMock.allow_net_connect!
          WebMock.disable!
        end

        let(:client_options) { default_options.merge(use_token_auth: true, key: api_key, query_time: true, default_token_params: { ttl: 2 }) }
        let(:channel) { client.channels.get(random_str) }
        let(:token_expired_response) do
          {
            "error" => {
              "statusCode" => 401,
              "code" => 40140,
              "message" => "Token expired"
            }
          }
        end

        it 'automatically renews the token (#RSA4b)' do
          expect(auth.current_token_details).to be_nil
          channel.publish 'event'
          token = auth.current_token_details
          expect(token).to_not be_nil
          sleep 2.5
          channel.publish 'event'
          expect(auth.current_token_details).to_not eql(token)
        end

        it 'fails if the token renewal fails (#RSA4b)' do
          expect(auth.current_token_details).to be_nil
          channel.publish 'event'
          token = auth.current_token_details
          expect(token).to_not be_nil
          sleep 2.5
          WebMock.enable!
          WebMock.disable_net_connect!
          stub_request(:post, "https://#{environment}-rest.ably.io/keys/#{TestApp.instance.key_name}/requestToken").
              to_return(status: 401, body: token_expired_response.to_json, headers: { 'Content-Type' => 'application/json' })
          expect { channel.publish 'event' }.to raise_error Ably::Exceptions::TokenExpired
          expect(auth.current_token_details).to eql(token)
        end
      end

      context 'when :client_id is provided in a token' do
        let(:client_id) { '123' }
        let(:token) do
          Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol).auth.request_token(client_id: client_id)
        end
        let(:client) do
          Ably::Rest::Client.new(token: token, environment: environment, protocol: protocol)
        end

        specify '#client_id contains the client_id' do
          expect(client.auth.client_id).to eql(client_id)
        end
      end
    end

    describe '#client_id_validated?' do
      let(:auth) { Ably::Rest::Client.new(default_options.merge(key: api_key)).auth }

      context 'when using basic auth' do
        let(:client_options) { default_options.merge(key: api_key) }

        it 'is false as basic auth users do not have an identity' do
          expect(client.auth).to_not be_client_id_validated
        end
      end

      context 'when using a token auth string for a token with a client_id' do
        let(:client_options) { default_options.merge(token: auth.request_token(client_id: 'present').token) }

        it 'is false as identification is not possible from an opaque token string' do
          expect(client.auth).to_not be_client_id_validated
        end
      end

      context 'when using a token' do
        context 'with a client_id' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: 'present')) }

          it 'is true' do
            expect(client.auth).to be_client_id_validated
          end
        end

        context 'with no client_id (anonymous)' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: nil)) }

          it 'is true' do
            expect(client.auth).to be_client_id_validated
          end
        end

        context 'with a wildcard client_id (anonymous)' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: '*')) }

          it 'is false' do
            expect(client.auth).to be_client_id_validated
          end
        end
      end

      context 'when using a token request with a client_id' do
        let(:client_options) { default_options.merge(token: auth.create_token_request(client_id: 'present')) }

        it 'is not true as identification is not confirmed until authenticated' do
          expect(client.auth).to_not be_client_id_validated
        end

        context 'after authentication' do
          before { client.channel('test').publish('a') }

          it 'is true as identification is completed during implicit authentication' do
            expect(client.auth).to be_client_id_validated
          end
        end
      end
    end

    context 'when using a :key and basic auth' do
      specify '#using_token_auth? is false' do
        expect(auth).to_not be_using_token_auth
      end

      specify '#key attribute contains the key string' do
        expect(auth.key).to eql(api_key)
      end

      specify '#using_basic_auth? is true' do
        expect(auth).to be_using_basic_auth
      end
    end

    context 'deprecated #authorise', :prevent_log_stubbing do
      let(:client_options)  { default_options.merge(key: api_key, logger: custom_logger_object, use_token_auth: true) }
      let(:custom_logger_object) { TestLogger.new }

      it 'logs a deprecation warning (#RSA10l)' do
        client.auth.authorise
        expect(custom_logger_object.logs.find { |severity, message| message.match(/authorise.*deprecated/i)} ).to_not be_nil
      end

      it 'returns a valid token (#RSA10l)' do
        response = client.auth.authorise
        expect(response).to be_a(Ably::Models::TokenDetails)
      end
    end

    # RSC1, RSC1a, RSA3c, RSA3d
    context 'when using JWT' do
      let(:auth_url) { 'https://echo.ably.io/createJWT' }
      let(:token) { Faraday.get("#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}").body }
      let(:client) { Ably::Rest::Client.new(token: token, environment: environment, protocol: protocol) }

      it 'authenticates correctly using the JWT token generated by the echo server' do
        expect(client.stats).to_not be_nil()
      end

      context 'when the JWT embeds an Ably token' do
        let(:token) { Faraday.post(auth_url, { keyName: key_name, keySecret: key_secret, jwtType: :embedded }).body }

        it 'authenticates correctly using the embedded token' do
          expect(client.stats).to_not be_nil()
        end

        context 'and the requested token is encrypted' do
          let(:token) { Faraday.post(auth_url, { keyName: key_name, keySecret: key_secret, jwtType: :embedded, encrypted: 1 }).body }

          it 'authenticates correctly using the embedded token' do
            expect(client.stats).to_not be_nil()
          end
        end
      end

      # RSA4f, RSA8c
      context 'when the token requested is returned with application/jwt content type' do
        let(:auth_rest_client) { Ably::Rest::Client.new(default_options.merge(key: api_key)) }
        let(:auth_params) { { keyName: key_name, keySecret: key_secret, returnType: 'jwt' } }
        let(:token) { auth_rest_client.auth.request_token({ }, { auth_url: auth_url, auth_params: auth_params }).token }
        it 'authenticates correctly and pulls stats' do
          expect(client.stats).to_not be_nil()
        end
      end
    end
  end
end
