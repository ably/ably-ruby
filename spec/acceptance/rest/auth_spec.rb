require "spec_helper"
require "securerandom"

describe "REST" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "fetching a token" do
    let(:ttl)        { 60 * 60 }
    let(:capability) { { :foo => ["publish"] } }

    it "should return the requested token" do
      actual_token = client.request_token(
        ttl:        ttl,
        capability: capability
      )

      expect(actual_token.id).to match(/^#{app_id}\.[\w-]+$/)
      expect(actual_token.app_key).to match(/^#{key_id}$/)
      expect(actual_token.issued_at).to be_within(2).of(Time.now)
      expect(actual_token.expires_at).to be_within(2).of(Time.now + ttl)
    end
  end

  context "token authentication" do
    let(:capability) { { :foo => ["publish"] } }

    describe "with token id" do
      let(:ttl) { 60 * 60 }
      let(:token) do
        client.request_token(
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
    end

    describe "implicit through client id" do
      let(:client) do
        Ably::Rest::Client.new(api_key: api_key, client_id: 1, environment: environment)
      end
      let(:token_id) { 'unique-token-id' }
      let(:token_response) do
        {
          access_token: {
            id: token_id
          }
        }.to_json
      end
      let!(:request_token_stub) do
        stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").to_return(:status => 201, :body => token_response, :headers => { 'Content-Type' => 'application/json' })
      end
      let!(:publish_message_stub) do
        stub_request(:post, "#{client.endpoint}/channels/foo/publish").
          with(headers: { 'Authorization' => "Bearer #{encode64(token_id)}" }).
          to_return(status: 201, body: '{}', headers: { 'Content-Type' => 'application/json' })
      end

      it "will create a token request", webmock: true do
        client.channel("foo").publish("event", "data")
        expect(request_token_stub).to have_been_requested
      end
    end
  end
end
