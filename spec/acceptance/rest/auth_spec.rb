# encoding: utf-8
require 'spec_helper'

describe Ably::Auth do
  include Ably::Modules::Conversions

  def hmac_for(token_request, secret)
    ruby_named_token_request = Ably::Models::IdiomaticRubyWrapper.new(token_request)

    text = [
      :id,
      :ttl,
      :capability,
      :client_id,
      :timestamp,
      :nonce
    ].map { |key| "#{ruby_named_token_request[key]}\n" }.join("")

    encode64(
      OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, secret, text)
    )
  end

  vary_by_protocol do
    let(:client) do
      Ably::Rest::Client.new(api_key: api_key, environment: environment, protocol: protocol)
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
      expect { auth.options['key_id'] = 'new_id' }.to raise_error RuntimeError, /can't modify frozen.*Hash/
    end

    describe '#request_token' do
      let(:ttl)        { 30 * 60 }
      let(:capability) { { :foo => ['publish'] } }

      let(:token) do
        auth.request_token(
          ttl:        ttl,
          capability: capability
        )
      end

      it 'returns a valid requested token in the expected format with valid issued_at and expires_at attributes' do
        expect(token.id).to match(/^#{app_id}\.[\w-]+$/)
        expect(token.key_id).to match(/^#{key_id}$/)
        expect(token.issued_at).to be_within(2).of(Time.now)
        expect(token.expires_at).to be_within(2).of(Time.now + ttl)
      end

      %w(client_id capability nonce timestamp ttl).each do |option|
        context "with option :#{option}", :webmock do
          let(:random)         { random_int_str }
          let(:options)        { { option.to_sym => random } }

          let(:token_response) { { access_token: {} } }
          let!(:request_token_stub) do
            stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
              with do |request|
                request_body_includes(request, protocol, option, random)
              end.to_return(
                :status => 201,
                :body => serialize(token_response, protocol),
                :headers => { 'Content-Type' => content_type }
              )
          end

          before { auth.request_token options }

          it 'overrides default and uses camelCase notation for all attributes' do
            expect(request_token_stub).to have_been_requested
          end
        end
      end

      context 'with :key_id & :key_secret options', :webmock do
        let(:key_id)        { random_str }
        let(:key_secret)    { random_str }
        let(:nonce)         { random_str }
        let(:token_options) { { key_id: key_id, key_secret: key_secret, nonce: nonce, timestamp: Time.now } }
        let(:token_request) { auth.create_token_request(token_options) }
        let(:mac) do
          hmac_for(token_request, key_secret)
        end

        let(:token_response) { { access_token: {} } }
        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
            with do |request|
              request_body_includes(request, protocol, 'mac', mac)
            end.to_return(
              :status => 201,
              :body => serialize(token_response, protocol),
              :headers => { 'Content-Type' => content_type })
        end

        let!(:token) { auth.request_token(token_options) }

        specify 'key_id is used in request and signing uses key_secret' do
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
        let(:auth_url_response) { { id: key_id } }
        let(:token_response)    { { access_token: { } } }
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
            :body => auth_url_response.to_json,
            :headers => { 'Content-Type' => 'application/json' }
          )
        end

        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
            with do |request|
              request_body_includes(request, protocol, 'id', key_id)
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
            expect(token).to be_a(Ably::Models::Token)
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

        context 'when response from :auth_url is a token' do
          let(:token_id) { 'J_0Tlg.D7AVZkdOZW-PqNNGvCSp38' }
          let(:issued_at) { Time.now }
          let(:expires) { Time.now + 60}
          let(:capability) { {'foo'=>['publish']} }
          let(:auth_url_response) do
            {
              'id' => token_id,
              'key' => 'J_0Tlg.NxCRig',
              'issued_at' => issued_at.to_i,
              'expires' => expires.to_i,
              'capability'=> capability
            }
          end

          let!(:token) { auth.request_token(options) }

          it 'returns a Token created from the token JSON' do
            expect(request_token_stub).to_not have_been_requested
            expect(token.id).to eql(token_id)
            expect(token.expires_at).to be_within(1).of(expires)
            expect(token.issued_at).to be_within(1).of(issued_at)
            expect(token.capability.to_json).to eql(capability.to_json)
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

      context 'with token_request_block that returns a token request' do
        let(:client_id) { random_str }
        let(:options) { { client_id: client_id } }
        let!(:request_token) do
          auth.request_token(options) do |block_options|
            @block_called = true
            @block_options = block_options
            auth.create_token_request(client_id: client_id)
          end
        end

        it 'calls the block when authenticating to obtain the request token' do
          expect(@block_called).to eql(true)
          expect(@block_options).to include(options)
        end

        it 'uses the token request from the block when requesting a new token' do
          expect(request_token.client_id).to eql(client_id)
        end
      end

      context 'with token_request_block that returns a token' do
        let(:client_id)   { random_str }
        let(:options)     { { client_id: client_id } }
        let(:token_id)    { 'J_0Tlg.D7AVZkdOZW-PqNNGvCSp38' }
        let(:issued_at)   { Time.now }
        let(:expires)     { Time.now + 60}
        let(:capability)  { {'foo'=>['publish']} }

        let!(:request_token) do
          auth.request_token(options) do |block_options|
            @block_called = true
            @block_options = block_options
            {
              'id' => token_id,
              'key' => 'J_0Tlg.NxCRig',
              'client_id' => client_id,
              'issued_at' => issued_at.to_i,
              'expires' => expires.to_i,
              'capability'=> capability
            }
          end
        end

        it 'calls the block when authenticating to obtain the request token' do
          expect(@block_called).to eql(true)
          expect(@block_options).to include(options)
        end

        it 'uses the token request from the block when requesting a new token' do
          expect(request_token).to be_a(Ably::Models::Token)
          expect(request_token.id).to eql(token_id)
          expect(request_token.client_id).to eql(client_id)
          expect(request_token.expires_at).to be_within(1).of(expires)
          expect(request_token.issued_at).to be_within(1).of(issued_at)
          expect(request_token.capability.to_json).to eql(capability.to_json)
        end
      end

      context 'persisted option', api_private: true do
        context 'when set to true', api_private: true do
          let(:options) { { persisted: true } }
          let(:token) { auth.request_token(options) }

          it 'returns a token with a short token ID that is used to look up the token details' do
            expect(token.id.length).to be < 64
            expect(token.id).to match(/^#{app_id}\.A/)
          end
        end

        context 'when omitted', api_private: true do
          let(:options) { { } }
          let(:token) { auth.request_token(options) }

          it 'returns a literal token' do
            expect(token.id.length).to be > 64
          end
        end
      end

      context 'with client_id' do
        let(:client_id) { random_str }
        let(:token) { auth.request_token(client_id: client_id) }

        it 'returns a token with the client_id' do
          expect(token.client_id).to eql(client_id)
        end
      end
    end

    context 'before #authorise has been called' do
      it 'has no current_token' do
        expect(auth.current_token).to be_nil
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
          expect(auth.authorise).to be_a(Ably::Models::Token)
        end

        it 'issues a new token if option :force => true' do
          expect { auth.authorise(force: true) }.to change { auth.current_token }
        end
      end

      context 'with previous authorisation' do
        before do
          auth.authorise
          expect(auth.current_token).to_not be_expired
        end

        it 'does not request a token if current_token has not expired' do
          expect(auth).to_not receive(:request_token)
          auth.authorise
        end

        it 'requests a new token if token is expired' do
          allow(auth.current_token).to receive(:expired?).and_return(true)
          expect(auth).to receive(:request_token)
          expect { auth.authorise }.to change { auth.current_token }
        end

        it 'issues a new token if option :force => true' do
          expect { auth.authorise(force: true) }.to change { auth.current_token }
        end
      end

      it 'updates the persisted auth options thare are then used for subsequent authorise requests' do
        expect(auth.options[:ttl]).to_not eql(26)
        auth.authorise(ttl: 26)
        expect(auth.options[:ttl]).to eql(26)
      end

      context 'with token_request_block' do
        let(:client_id) { random_str }
        let!(:token) do
          auth.authorise do
            @block_called ||= 0
            @block_called += 1
            auth.create_token_request(client_id: client_id)
          end
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
              auth.request_token { @request_block_called = true; auth.create_token_request }
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
      let(:options)       { Hash.new }
      subject { auth.create_token_request(options) }

      it 'uses the key ID from the client' do
        expect(subject['id']).to eql(key_id)
      end

      it 'uses the default TTL' do
        expect(subject['ttl']).to eql(Ably::Models::Token::DEFAULTS[:ttl])
      end

      it 'uses the default capability' do
        expect(subject['capability']).to eql(Ably::Models::Token::DEFAULTS[:capability].to_json)
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

      %w(ttl capability nonce timestamp client_id).each do |attribute|
        context "with option :#{attribute}" do
          let(:option_value) { random_int_str(1_000_000_000) }
          before do
            options[attribute.to_sym] = option_value
          end
          it "overrides default" do
            expect(subject[convert_to_mixed_case(attribute)].to_s).to eql(option_value.to_s)
          end
        end
      end

      context 'with additional invalid attributes' do
        let(:options) { { nonce: 'valid', is_not_used_by_token_request: 'invalid' } }
        specify 'are ignored' do
          expect(subject.keys).to_not include(:is_not_used_by_token_request)
          expect(subject.keys).to_not include(convert_to_mixed_case(:is_not_used_by_token_request))
          expect(subject.keys).to include('nonce')
          expect(subject['nonce']).to eql('valid')
        end
      end

      context 'when required fields are missing' do
        let(:client) { Ably::Rest::Client.new(auth_url: 'http://example.com', protocol: protocol) }

        it 'should raise an exception if key secret is missing' do
          expect { auth.create_token_request(key_id: 'id') }.to raise_error Ably::Exceptions::TokenRequestError
        end

        it 'should raise an exception if key id is missing' do
          expect { auth.create_token_request(key_secret: 'secret') }.to raise_error Ably::Exceptions::TokenRequestError
        end
      end

      context 'with :query_time option' do
        let(:time)    { Time.now - 30 }
        let(:options) { { query_time: true } }

        it 'queries the server for the timestamp' do
          expect(client).to receive(:time).and_return(time)
          expect(subject['timestamp']).to eql(time.to_i)
        end
      end

      context 'with :timestamp option' do
        let(:token_request_time) { Time.now + 5 }
        let(:options) { { timestamp: token_request_time } }

        it 'uses the provided timestamp in the token request' do
          expect(subject['timestamp']).to eql(token_request_time.to_i)
        end
      end

      context 'signing' do
        let(:options) do
          {
            id:         random_str,
            ttl:        random_str,
            capability: random_str,
            client_id:  random_str,
            timestamp:  random_int_str,
            nonce:      random_str
          }
        end

        it 'generates a valid HMAC' do
          hmac = hmac_for(options, key_secret)
          expect(subject['mac']).to eql(hmac)
        end
      end
    end

    context 'using token authentication' do
      let(:capability) { { :foo => ["publish"] } }

      describe 'with :token_id option' do
        let(:ttl) { 60 * 60 }
        let(:token) do
          auth.request_token(
            ttl:        ttl,
            capability: capability
          )
        end
        let(:token_id) { token.id }
        let(:token_auth_client) do
          Ably::Rest::Client.new(token_id: token_id, environment: environment, protocol: protocol)
        end

        it 'authenticates successfully using the provided :token_id' do
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
          Ably::Rest::Client.new(api_key: api_key, client_id: client_id, environment: environment, protocol: protocol)
        end
        let(:token_id) { 'unique-token-id' }
        let(:token_response) do
          {
            access_token: {
              id: token_id
            }
          }.to_json
        end

        context 'and requests to the Ably server are mocked', :webmock do
          let!(:request_token_stub) do
            stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
              to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
          end
          let!(:publish_message_stub) do
            stub_request(:post, "#{client.endpoint}/channels/foo/publish").
              with(headers: { 'Authorization' => "Bearer #{encode64(token_id)}" }).
              to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })
          end

          it 'will send a token request to the server' do
            client.channel('foo').publish('event', 'data')
            expect(request_token_stub).to have_been_requested
          end
        end

        describe 'a token is created' do
          let(:token) { client.auth.current_token }

          it 'before a request is made' do
            expect(token).to be_nil
          end

          it 'when a message is published' do
            expect(client.channel('foo').publish('event', 'data')).to be_truthy
          end

          it 'with capability and TTL defaults' do
            client.channel('foo').publish('event', 'data')

            expect(token).to be_a(Ably::Models::Token)
            capability_with_str_key = Ably::Models::Token::DEFAULTS[:capability]
            capability = Hash[capability_with_str_key.keys.map(&:to_sym).zip(capability_with_str_key.values)]
            expect(token.capability).to eq(capability)
            expect(token.expires_at.to_i).to be_within(2).of(Time.now.to_i + Ably::Models::Token::DEFAULTS[:ttl])
            expect(token.client_id).to eq(client_id)
          end
        end
      end
    end

    context 'when using an :api_key and basic auth' do
      specify '#using_token_auth? is false' do
        expect(auth).to_not be_using_token_auth
      end

      specify '#using_basic_auth? is true' do
        expect(auth).to be_using_basic_auth
      end
    end
  end
end
