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

    it "should return the requested token" do
      actual_token = auth.request_token(
        ttl:        ttl,
        capability: capability
      )

      expect(actual_token.id).to match(/^#{app_id}\.[\w-]+$/)
      expect(actual_token.key_id).to match(/^#{key_id}$/)
      expect(actual_token.issued_at).to be_within(2).of(Time.now)
      expect(actual_token.expires_at).to be_within(2).of(Time.now + ttl)
    end
  end


  describe "#create_token_request" do
    let(:ttl)           { 60 * 60 }
    let(:capability)    { { :foo => ["publish"] } }
    let(:options)       { Hash.new }
    subject { auth.create_token_request(options) }

    it "should use the key ID from the client" do
      expect(subject[:id]).to eql(key_id)
    end

    it "should use the default TTL" do
      expect(subject[:ttl]).to eql(Ably::Token::DEFAULTS[:ttl])
    end

    it "should use the default capability" do
      expect(subject[:capability]).to eql(Ably::Token::DEFAULTS[:capability].to_json)
    end

    it "should have a unique nonce" do
      unique_nonces = 100.times.map { auth.create_token_request[:nonce] }
      expect(unique_nonces.uniq.length).to eql(100)
    end

    it "should have a nonce of at least 16 characters" do
      expect(subject[:nonce].length).to be >= 16
    end

    %w(ttl capability nonce timestamp client_id).each do |attribute|
      context "with option :#{attribute}" do
        let(:option_value) { SecureRandom.hex }
        before do
          options[attribute.to_sym] = option_value
        end
        it "should override default" do
          expect(subject[attribute.to_sym]).to eql(option_value)
        end
      end
    end

    context "with :query_time option" do
      let(:time)    { Time.now - 30 }
      let(:options) { { query_time: true } }

      it 'should query the server for the time' do
        expect(client).to receive(:time).and_return(time)
        expect(subject[:timestamp]).to eql(time.to_i)
      end
    end

    context "signing" do
      let(:options) do
        {
          id: SecureRandom.hex,
          ttl: SecureRandom.hex,
          capability: SecureRandom.hex,
          client_id: SecureRandom.hex,
          timestamp: SecureRandom.hex,
          nonce: SecureRandom.hex
        }
      end

      it 'should generate a valid HMAC' do
        text = options.values.map { |t| "#{t}\n" }.join("")
        hmac = encode64(
          Digest::HMAC.digest(text, key_secret, Digest::SHA256)
        )
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
        Ably::Rest::Client.new(token: token_id, environment: environment)
      end

      it "should authenticate successfully" do
        expect(token_auth_client.channel("foo").publish("event", "data")).to be_truthy
      end

      it "should disallow publishing on unspecified capability channels" do
        expect { token_auth_client.channel("bar").publish("event", "data") }.to raise_error do |error|
          expect(error).to be_a(Ably::InvalidRequest)
          expect(error.status).to eql(401)
          expect(error.code).to eql(40160)
        end
      end

      it "should fail if timestamp is invalid" do
        expect { auth.request_token(timestamp: Time.now.to_i - 180) }.to raise_error do |error|
          expect(error).to be_a(Ably::InvalidRequest)
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
          stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
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
        it "after request is made only" do
          expect(client.token).to be_nil
        end

        it "when a message is published" do
          expect(client.channel("foo").publish("event", "data")).to be_truthy
        end

        it "with capability and TTL defaults" do
          client.channel("foo").publish("event", "data")

          expect(client.token).to be_a(Ably::Token)
          capability_with_str_key = Ably::Token::DEFAULTS[:capability]
          capability = Hash[capability_with_str_key.keys.map(&:to_sym).zip(capability_with_str_key.values)]
          expect(client.token.capability).to eql(capability)
          expect(client.token.expires_at).to be_within(2).of(Time.now + Ably::Token::DEFAULTS[:ttl])
          expect(client.token.client_id).to eql(client_id)
        end
      end
    end
  end
end
