# encoding: utf-8
require 'spec_helper'

describe Ably::Auth do
  include Ably::Modules::Conversions

  def hmac_for(token_request_attributes, secret)
    token_request= Ably::Models::IdiomaticRubyWrapper.new(token_request_attributes)

    text = [
      :key_name,
      :ttl,
      :capability,
      :client_id,
      :timestamp,
      :nonce
    ].map { |key| "#{token_request.hash[key]}\n" }.join("")

    encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, secret, text)
    )
  end

  vary_by_protocol do
    let(:client) do
      Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol)
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
        MessagePack.pack(token_response)
      else
        JSON.dump(token_response)
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

      it 'returns a valid requested token in the expected format with valid issued and expires attributes' do
        expect(token_details.token).to match(/^#{app_id}\.[\w-]+$/)
        expect(token_details.key_name).to match(/^#{key_name}$/)
        expect(token_details.issued).to be_within(2).of(Time.now)
        expect(token_details.expires).to be_within(2).of(Time.now + ttl)
      end

      %w(client_id capability nonce timestamp ttl).each do |option|
        context "with option :#{option}", :webmock do
          def coerce_if_time_value(field_name, value, multiply: false)
            return value unless %w(timestamp ttl).include?(field_name)
            value.to_i * (multiply ? multiply : 1)
          end

          let(:random)         { coerce_if_time_value(option, random_int_str) }
          let(:options)        { { option.to_sym => random } }

          let(:token_response) { {} }
          let!(:request_token_stub) do
            stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").
              with do |request|
                request_body_includes(request, protocol, option, coerce_if_time_value(option, random, multiply: 1000))
              end.to_return(
                :status => 201,
                :body => serialize(token_response, protocol),
                :headers => { 'Content-Type' => content_type }
              )
          end

          before { auth.request_token options }

          it "overrides default and uses camelCase notation for attributes" do
            expect(request_token_stub).to have_been_requested
          end
        end
      end

      context 'with :key option', :webmock do
        let(:key_name)      { "app.#{random_str}" }
        let(:key_secret)    { random_str }
        let(:nonce)         { random_str }
        let(:token_options) { { key: "#{key_name}:#{key_secret}", nonce: nonce, timestamp: Time.now } }
        let(:token_request) { auth.create_token_request(token_options) }
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

        let!(:token) { puts token_options; auth.request_token(token_options) }

        specify 'key_name is used in request and signing uses key_secret' do
          expect(request_token_stub).to have_been_requested
        end
      end

      context 'with :key_name & :key_secret options', :webmock do
        let(:key_name)      { "app.#{random_str}" }
        let(:key_secret)    { random_str }
        let(:nonce)         { random_str }

        let(:name_secret_token_options) { { key_name: key_name, key_secret: key_secret, nonce: nonce, timestamp: Time.now } }
        let(:token_request) { auth.create_token_request(name_secret_token_options) }
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

        let!(:token) { auth.request_token(name_secret_token_options); }

        specify 'key_name is used in request and signing uses key_secret' do
          expect(request_token_stub).to have_been_requested
        end
      end

      context 'with :query_time option' do
        let(:options) { { query_time: true } }

        it 'queries the server for the time' do
          expect(client).to receive(:time).and_call_original
          auth.request_token(options)
        end
      end

      context 'without :query_time option' do
        let(:options) { { query_time: false } }

        it 'does not query the server for the time' do
          expect(client).to_not receive(:time)
          auth.request_token(options)
        end
      end

      context 'with :auth_url option', :webmock do
        let(:auth_url)          { 'https://www.fictitious.com/get_token' }
        let(:auth_url_response) { { keyName: key_name }.to_json }
        let(:token_response)    { {} }
        let(:query_params)      { nil }
        let(:headers)           { nil }
        let(:auth_method)       { :get }
        let(:options) do
          {
            auth_url: auth_url,
            auth_params: query_params,
            auth_headers: headers,
            auth_method: auth_method
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
          let!(:token) { auth.request_token(options) }

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

          let!(:token_details) { auth.request_token(options) }

          it 'returns TokenDetails created from the token JSON' do
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

          let!(:token_details) { auth.request_token(options) }

          it 'returns TokenDetails created from the token JSON' do
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
              expect { auth.request_token options }.to raise_error(Ably::Exceptions::ServerError)
            end
          end

          context 'XML' do
            let!(:auth_url_request_stub) do
              stub_request(auth_method, auth_url).
                to_return(:status => 201, :body => '<xml></xml>', :headers => { 'Content-Type' => 'application/xml' })
            end

            it 'raises InvalidResponseBody' do
              expect { auth.request_token options }.to raise_error(Ably::Exceptions::InvalidResponseBody)
            end
          end
        end
      end

      context 'with a token_request_block' do
        context 'that returns a TokenRequest' do
          let(:client_id) { random_str }
          let(:options) { { client_id: client_id } }
          let!(:request_token) do
            auth.request_token(options.merge(auth_callback: Proc.new do |block_options|
              @block_called = true
              @block_options = block_options
              auth.create_token_request(client_id: client_id)
            end))
          end

          it 'calls the block when authenticating to obtain the request token' do
            expect(@block_called).to eql(true)
            expect(@block_options).to include(options)
          end

          it 'uses the token request from the block when requesting a new token' do
            expect(request_token.client_id).to eql(client_id)
          end
        end

        context 'that returns a TokenDetails JSON object' do
          let(:client_id)   { random_str }
          let(:options)     { { client_id: client_id } }
          let(:token)       { 'J_0Tlg.D7AVZkdOZW-PqNNGvCSp38' }
          let(:issued)      { Time.now }
          let(:expires)     { Time.now + 60}
          let(:capability)  { {'foo'=>['publish']} }
          let(:capability_str) { JSON.dump(capability) }

          let!(:token_details) do
            auth.request_token(options.merge(auth_callback: Proc.new do |block_options|
              @block_called = true
              @block_options = block_options
              {
                'token' => token,
                'keyName' => 'J_0Tlg.NxCRig',
                'clientId' => client_id,
                'issued' => issued.to_i * 1000,
                'expires' => expires.to_i * 1000,
                'capability'=> capability_str
              }
            end))
          end

          it 'calls the block when authenticating to obtain the request token' do
            expect(@block_called).to eql(true)
            expect(@block_options).to include(options)
          end

          it 'uses the token request from the block when requesting a new token' do
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.token).to eql(token)
            expect(token_details.client_id).to eql(client_id)
            expect(token_details.expires).to be_within(1).of(expires)
            expect(token_details.issued).to be_within(1).of(issued)
            expect(token_details.capability).to eql(capability)
          end
        end

        context 'that returns a TokenDetails object' do
          let(:client_id)   { random_str }

          let!(:token_details) do
            auth.request_token(auth_callback: Proc.new do |block_options|
              auth.create_token_request({
                client_id: client_id
              })
            end)
          end

          it 'uses the token request from the block when requesting a new token' do
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.client_id).to eql(client_id)
          end
        end

        context 'that returns a Token string' do
          let(:second_client) { Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol) }
          let(:token) { second_client.auth.request_token.token }

          let!(:token_details) do
            auth.request_token(auth_callback: Proc.new do |block_options|
              token
            end)
          end

          it 'uses the token request from the block when requesting a new token' do
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.token).to eql(token)
          end
        end
      end

      context 'persisted option', api_private: true do
        context 'when set to true', api_private: true do
          let(:options) { { persisted: true } }
          let(:token_details) { auth.request_token(options) }

          it 'returns a token with a short token ID that is used to look up the token details' do
            expect(token_details.token.length).to be < 64
            expect(token_details.token).to match(/^#{app_id}\.A/)
          end
        end

        context 'when omitted', api_private: true do
          let(:options) { { } }
          let(:token_details) { auth.request_token(options) }

          it 'returns a literal token' do
            expect(token_details.token.length).to be > 64
          end
        end
      end

      context 'with client_id' do
        let(:client_id) { random_str }
        let(:token_details) { auth.request_token(client_id: client_id) }

        it 'returns a token with the client_id' do
          expect(token_details.client_id).to eql(client_id)
        end
      end
    end

    context 'before #authorise has been called' do
      it 'has no current_token_details' do
        expect(auth.current_token_details).to be_nil
      end
    end

    describe '#authorise' do
      context 'when called for the first time since the client has been instantiated' do
        let(:request_options) do
          { auth_url: 'http://somewhere.com/' }
        end

        it 'passes all options to #request_token' do
          expect(auth).to receive(:request_token).with(request_options)
          auth.authorise request_options
        end

        it 'returns a valid token' do
          expect(auth.authorise).to be_a(Ably::Models::TokenDetails)
        end

        it 'issues a new token if option :force => true' do
          expect { auth.authorise(force: true) }.to change { auth.current_token_details }
        end
      end

      context 'with previous authorisation' do
        before do
          auth.authorise
          expect(auth.current_token_details).to_not be_expired
        end

        it 'does not request a token if current_token_details has not expired' do
          expect(auth).to_not receive(:request_token)
          auth.authorise
        end

        it 'requests a new token if token is expired' do
          allow(auth.current_token_details).to receive(:expired?).and_return(true)
          expect(auth).to receive(:request_token)
          expect { auth.authorise }.to change { auth.current_token_details }
        end

        it 'issues a new token if option :force => true' do
          expect { auth.authorise(force: true) }.to change { auth.current_token_details }
        end
      end

      it 'updates the persisted auth options that are then used for subsequent authorise requests' do
        expect(auth.options[:ttl]).to_not eql(26)
        auth.authorise(ttl: 26)
        expect(auth.options[:ttl]).to eql(26)
      end

      context 'with token_request_block' do
        let(:client_id) { random_str }
        let!(:token) do
          auth.authorise(auth_callback: Proc.new do
            @block_called ||= 0
            @block_called += 1
            auth.create_token_request(client_id: client_id)
          end)
        end

        it 'calls the block' do
          expect(@block_called).to eql(1)
        end

        it 'uses the token request returned from the block when requesting a new token' do
          expect(token.client_id).to eql(client_id)
        end

        context 'for every subsequent #request_token' do
          context 'without a provided block' do
            it 'calls the originally provided block' do
              auth.request_token
              expect(@block_called).to eql(2)
            end
          end

          context 'with a provided block' do
            it 'does not call the originally provided block and calls the new #request_token block' do
              auth.request_token(auth_callback: Proc.new { @request_block_called = true; auth.create_token_request })
              expect(@block_called).to eql(1)
              expect(@request_block_called).to eql(true)
            end
          end
        end
      end
    end

    describe '#create_token_request' do
      let(:ttl)           { 60 * 60 }
      let(:capability)    { { :foo => ["publish"] } }
      let(:token_request_options)       { Hash.new }
      subject { auth.create_token_request(token_request_options) }

      it 'uses the key name from the client' do
        expect(subject['keyName']).to eql(key_name)
      end

      it 'uses the default TTL' do
        expect(subject['ttl']).to eql(Ably::Auth::TOKEN_DEFAULTS.fetch(:ttl) * 1000)
      end

      it 'uses the default capability' do
        expect(subject['capability']).to eql(Ably::Auth::TOKEN_DEFAULTS.fetch(:capability).to_json)
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
        context "with option :#{attribute}" do
          let(:option_value) { random_int_str(1_000_000_000).to_i }
          before do
            token_request_options[attribute.to_sym] = option_value
          end
          it "overrides default" do
            expect(subject.public_send(attribute).to_s).to eql(option_value.to_s)
          end
        end
      end

      context 'with additional invalid attributes' do
        let(:token_request_options) { { nonce: 'valid', is_not_used_by_token_request: 'invalid' } }
        specify 'are ignored' do
          expect(subject.hash.keys).to_not include(:is_not_used_by_token_request)
          expect(subject.hash.keys).to_not include(convert_to_mixed_case(:is_not_used_by_token_request))
          expect(subject.hash.keys).to include(:nonce)
          expect(subject.nonce).to eql('valid')
        end
      end

      context 'when required fields are missing' do
        let(:client) { Ably::Rest::Client.new(auth_url: 'http://example.com', protocol: protocol) }

        it 'should raise an exception if key secret is missing' do
          expect { auth.create_token_request(key_name: 'name') }.to raise_error Ably::Exceptions::TokenRequestError
        end

        it 'should raise an exception if key name is missing' do
          expect { auth.create_token_request(key_secret: 'secret') }.to raise_error Ably::Exceptions::TokenRequestError
        end
      end

      context 'with :query_time option' do
        let(:time)    { Time.now - 30 }
        let(:token_request_options) { { query_time: true } }

        it 'queries the server for the timestamp' do
          expect(client).to receive(:time).and_return(time)
          expect(subject['timestamp']).to be_within(1).of(time.to_f * 1000)
        end
      end

      context 'with :timestamp option' do
        let(:token_request_time) { Time.now + 5 }
        let(:token_request_options) { { timestamp: token_request_time } }

        it 'uses the provided timestamp in the token request' do
          expect(subject['timestamp']).to be_within(1).of(token_request_time.to_f * 1000)
        end
      end

      context 'signing' do
        let(:token_request_options) do
          {
            key_name:   random_str,
            ttl:        random_int_str.to_i,
            capability: random_str,
            client_id:  random_str,
            timestamp:  random_int_str.to_i,
            nonce:      random_str
          }
        end

        # TokenRequest expects times in milliseconds, whereas create_token_request assumes Ruby default of seconds
        let(:token_request_attributes) do
          token_request_options.merge(timestamp: token_request_options[:timestamp] * 1000, ttl: token_request_options[:ttl] * 1000)
        end

        it 'generates a valid HMAC' do
          hmac = hmac_for(Ably::Models::TokenRequest(token_request_attributes).hash, key_secret)
          expect(subject['mac']).to eql(hmac)
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
            expect(error).to be_a(Ably::Exceptions::InvalidRequest)
            expect(error.status).to eql(401)
            expect(error.code).to eql(40160)
          end
        end

        it 'fails if timestamp is invalid' do
          expect { auth.request_token(timestamp: Time.now - 180) }.to raise_error do |error|
            expect(error).to be_a(Ably::Exceptions::InvalidRequest)
            expect(error.status).to eql(401)
            expect(error.code).to eql(40101)
          end
        end

        it 'cannot be renewed automatically' do
          expect(token_auth_client.auth).to_not be_token_renewable
        end
      end

      context 'when implicit as a result of using :client id' do
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

          it 'with capability and TTL defaults' do
            client.channel('foo').publish('event', 'data')

            expect(token).to be_a(Ably::Models::TokenDetails)
            capability_with_str_key = Ably::Auth::TOKEN_DEFAULTS.fetch(:capability)
            capability = Hash[capability_with_str_key.keys.map(&:to_s).zip(capability_with_str_key.values)]
            expect(token.capability).to eq(capability)
            expect(token.expires.to_i).to be_within(2).of(Time.now.to_i + Ably::Auth::TOKEN_DEFAULTS.fetch(:ttl))
            expect(token.client_id).to eq(client_id)
          end
        end
      end
    end

    context 'when using an :key and basic auth' do
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
  end
end
