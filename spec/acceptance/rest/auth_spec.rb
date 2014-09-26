require "spec_helper"
require "securerandom"

describe "REST" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end
  let(:auth) { client.auth }

  describe "#request_token" do
    let(:ttl)        { 30 * 60 }
    let(:capability) { { :foo => ["publish"] } }

    it "returns the requested token" do
      actual_token = auth.request_token(
        ttl:        ttl,
        capability: capability
      )

      expect(actual_token.id).to match(/^#{app_id}\.[\w-]+$/)
      expect(actual_token.key_id).to match(/^#{key_id}$/)
      expect(actual_token.issued_at).to be_within(2).of(Time.now)
      expect(actual_token.expires_at).to be_within(2).of(Time.now + ttl)
    end

    %w(client_id ttl timestamp capability nonce).each do |option|
      context "option :#{option}", webmock: true do
        let(:random)         { SecureRandom.random_number(1_000_000_000).to_s }
        let(:options)        { { option.to_sym => random } }

        let(:token_response) { { access_token: {} }.to_json }
        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
            with(:body => hash_including({ option => random })).
            to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
        end

        before { auth.request_token options }

        it 'overrides default' do
          expect(request_token_stub).to have_been_requested
        end
      end
    end

    context 'with :key_id & :key_secret options', webmock: true do
      let(:key_id)        { SecureRandom.hex }
      let(:key_secret)    { SecureRandom.hex }
      let(:nonce)         { SecureRandom.hex }
      let(:token_options) { { key_id: key_id, key_secret: key_secret, nonce: nonce, timestamp: Time.now } }
      let(:token_request) { auth.create_token_request(token_options) }
      let(:mac) do
        hmac_for(token_request, key_secret)
      end

      let(:token_response) { { access_token: {} }.to_json }
      let!(:request_token_stub) do
        stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
          with(:body => hash_including({ 'mac' => mac })).
          to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
      end

      let!(:token) { auth.request_token(token_options) }

      specify 'key_id is used in request and signing uses key_secret' do
        expect(request_token_stub).to have_been_requested
      end
    end

    context "with :query_time option" do
      let(:options) { { query_time: true } }

      it 'queries the server for the time' do
        expect(client).to receive(:time).and_call_original
        auth.request_token(options)
      end
    end

    context "without :query_time option" do
      let(:options) { { query_time: false } }

      it 'queries the server for the time' do
        expect(client).to_not receive(:time)
        auth.request_token(options)
      end
    end

    context 'with :auth_url option', webmock: true do
      let(:auth_url)          { 'https://www.fictitious.com/get_token' }
      let(:token_request)     { { id: key_id }.to_json }
      let(:token_response)    { { access_token: { } }.to_json }
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
        stub.with(:query => hash_including(query_params)) unless query_params.nil?
        stub.with(:header => hash_including(headers)) unless headers.nil?
        stub.to_return(:status => 201, :body => token_request, :headers => { 'Content-Type' => 'application/json' })
      end

      let!(:request_token_stub) do
        stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
          with(:body => hash_including({ 'id' => key_id })).
          to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
      end

      context 'valid' do
        before { auth.request_token options }

        context 'and default options' do
          it 'requests a token from :auth_url' do
            expect(request_token_stub).to have_been_requested
            expect(auth_url_request_stub).to have_been_requested
          end
        end

        context 'with params' do
          let(:query_params) { { 'key' => SecureRandom.hex } }
          it 'requests a token from :auth_url' do
            expect(request_token_stub).to have_been_requested
            expect(auth_url_request_stub).to have_been_requested
          end
        end

        context 'with headers' do
          let(:headers) { { 'key' => SecureRandom.hex } }
          it 'requests a token from :auth_url' do
            expect(request_token_stub).to have_been_requested
            expect(auth_url_request_stub).to have_been_requested
          end
        end

        context 'with POST' do
          let(:auth_method) { :post }
          it 'requests a token from :auth_url' do
            expect(request_token_stub).to have_been_requested
            expect(auth_url_request_stub).to have_been_requested
          end
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

    context 'with auth_block' do
      let(:client_id) { SecureRandom.hex }
      let(:options) { { client_id: client_id } }
      let!(:token) do
        auth.request_token(options) do |block_options|
          @block_called = true
          @block_options = block_options
          auth.create_token_request(client_id: client_id)
        end
      end

      it 'calls the block' do
        expect(@block_called).to eql(true)
        expect(@block_options).to include(options)
      end

      it 'uses the token request when requesting a new token' do
        expect(token.client_id).to eql(client_id)
      end
    end
  end

  describe '#authorise' do
    context 'with no previous authorisation' do
      let(:request_options) do
        { auth_url: 'http://somewhere.com/' }
      end

      it 'has no current_token' do
        expect(auth.current_token).to be_nil
      end

      it 'passes all options to request_token' do
        expect(auth).to receive(:request_token).with(request_options)
        auth.authorise request_options
      end

      it 'returns a valid token' do
        expect(auth.authorise).to be_a(Ably::Token)
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

      it 'does not request a token if token is not expired' do
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
  end

  describe "#create_token_request" do
    let(:ttl)           { 60 * 60 }
    let(:capability)    { { :foo => ["publish"] } }
    let(:options)       { Hash.new }
    subject { auth.create_token_request(options) }

    it "uses the key ID from the client" do
      expect(subject[:id]).to eql(key_id)
    end

    it "uses the default TTL" do
      expect(subject[:ttl]).to eql(Ably::Token::DEFAULTS[:ttl])
    end

    it "uses the default capability" do
      expect(subject[:capability]).to eql(Ably::Token::DEFAULTS[:capability].to_json)
    end

    it "has a unique nonce" do
      unique_nonces = 100.times.map { auth.create_token_request[:nonce] }
      expect(unique_nonces.uniq.length).to eql(100)
    end

    it "has a nonce of at least 16 characters" do
      expect(subject[:nonce].length).to be >= 16
    end

    %w(ttl capability nonce timestamp client_id).each do |attribute|
      context "with option :#{attribute}" do
        let(:option_value) { SecureRandom.random_number(1_000_000_000) }
        before do
          options[attribute.to_sym] = option_value
        end
        it "overrides default" do
          expect(subject[attribute.to_sym]).to eql(option_value)
        end
      end
    end

    context "invalid attributes" do
      let(:options) { { nonce: 'valid', is_not_used_by_token_request: 'invalid' } }
      specify 'are ignored' do
        expect(subject.keys).to_not include(:is_not_used_by_token_request)
        expect(subject.keys).to include(:nonce)
        expect(subject[:nonce]).to eql('valid')
      end
    end

    context "missing key ID and/or secret" do
      let(:client) { Ably::Rest::Client.new(auth_url: 'http://example.com') }

      it "should raise an exception if key secret is missing" do
        expect { auth.create_token_request(key_id: 'id') }.to raise_error Ably::Exceptions::TokenRequestError
      end

      it "should raise an exception if key id is missing" do
        expect { auth.create_token_request(key_secret: 'secret') }.to raise_error Ably::Exceptions::TokenRequestError
      end
    end

    context "with :query_time option" do
      let(:time)    { Time.now - 30 }
      let(:options) { { query_time: true } }

      it 'queries the server for the time' do
        expect(client).to receive(:time).and_return(time)
        expect(subject[:timestamp]).to eql(time.to_i)
      end
    end

    context "with :timestamp option" do
      let(:token_request_time) { Time.now + 5 }
      let(:options) { { timestamp: token_request_time } }

      it 'uses the provided timestamp' do
        expect(subject[:timestamp]).to eql(token_request_time.to_i)
      end
    end

    context "signing" do
      let(:options) do
        {
          id: SecureRandom.hex,
          ttl: SecureRandom.hex,
          capability: SecureRandom.hex,
          client_id: SecureRandom.hex,
          timestamp: SecureRandom.random_number(1_000_000_000),
          nonce: SecureRandom.hex
        }
      end

      it 'generates a valid HMAC' do
        hmac = hmac_for(options, key_secret)
        expect(subject[:mac]).to eql(hmac)
      end
    end
  end

  context "client with token authentication" do
    let(:capability) { { :foo => ["publish"] } }

    describe "with token_id argument" do
      let(:ttl) { 60 * 60 }
      let(:token) do
        auth.request_token(
          ttl:        ttl,
          capability: capability
        )
      end
      let(:token_id) { token.id }
      let(:token_auth_client) do
        Ably::Rest::Client.new(token_id: token_id, environment: environment)
      end

      it "authenticates successfully" do
        expect(token_auth_client.channel("foo").publish("event", "data")).to be_truthy
      end

      it "disallows publishing on unspecified capability channels" do
        expect { token_auth_client.channel("bar").publish("event", "data") }.to raise_error do |error|
          expect(error).to be_a(Ably::Exceptions::InvalidRequest)
          expect(error.status).to eql(401)
          expect(error.code).to eql(40160)
        end
      end

      it "fails if timestamp is invalid" do
        expect { auth.request_token(timestamp: Time.now - 180) }.to raise_error do |error|
          expect(error).to be_a(Ably::Exceptions::InvalidRequest)
          expect(error.status).to eql(401)
          expect(error.code).to eql(40101)
        end
      end
    end

    describe "implicit through client id" do
      let(:client_id) { '999' }
      let(:client) do
        Ably::Rest::Client.new(api_key: api_key, client_id: client_id, environment: environment)
      end
      let(:token_id) { 'unique-token-id' }
      let(:token_response) do
        {
          access_token: {
            id: token_id
          }
        }.to_json
      end

      context 'stubbed', webmock: true do
        let!(:request_token_stub) do
          stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").
            to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
        end
        let!(:publish_message_stub) do
          stub_request(:post, "#{client.endpoint}/channels/foo/publish").
            with(headers: { 'Authorization' => "Bearer #{encode64(token_id)}" }).
            to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })
        end

        it "will create a token request" do
          client.channel("foo").publish("event", "data")
          expect(request_token_stub).to have_been_requested
        end
      end

      context "will create a token" do
        let(:token) { client.auth.current_token }

        it "before a request is made" do
          expect(token).to be_nil
        end

        it "when a message is published" do
          expect(client.channel("foo").publish("event", "data")).to be_truthy
        end

        it "with capability and TTL defaults" do
          client.channel("foo").publish("event", "data")

          expect(token).to be_a(Ably::Token)
          capability_with_str_key = Ably::Token::DEFAULTS[:capability]
          capability = Hash[capability_with_str_key.keys.map(&:to_sym).zip(capability_with_str_key.values)]
          expect(token.capability).to eq(capability)
          expect(token.expires_at.to_i).to be_within(2).of(Time.now.to_i + Ably::Token::DEFAULTS[:ttl])
          expect(token.client_id).to eq(client_id)
        end
      end
    end
  end

  def hmac_for(token_request, secret)
    text = token_request.values_at(
      :id,
      :ttl,
      :capability,
      :client_id,
      :timestamp,
      :nonce
    ).map { |t| "#{t}\n" }.join("")

    encode64(
      Digest::HMAC.digest(text, key_secret, Digest::SHA256)
    )
  end
end
