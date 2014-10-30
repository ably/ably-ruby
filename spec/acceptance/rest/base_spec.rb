require "spec_helper"
require "securerandom"

describe "REST" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "protocol" do
    include Ably::Modules::Conversions

    let(:client_options) { {} }
    let(:client) do
      Ably::Rest::Client.new(client_options.merge(api_key: 'appid.keyuid:keysecret'))
    end

    skip '#protocol should default to :msgpack'

    context 'transport' do
      let(:now) { Time.now - 1000 }
      let(:body_value) { [as_since_epoch(now)] }

      before do
        stub_request(:get, "#{client.endpoint}/time").
          with(:headers => { 'Accept' => mime }).
          to_return(:status => 200, :body => request_body, :headers => { 'Content-Type' => mime })
      end

      context 'when protocol is set as :json' do
        let(:client_options) { { protocol: :json } }
        let(:mime) { 'application/json' }
        let(:request_body) { body_value.to_json }

        it 'uses JSON', webmock: true do
          expect(client.protocol).to eql(:json)
          expect(client.time).to be_within(1).of(now)
        end

        skip 'uses JSON against Ably service for Auth'
        skip 'uses JSON against Ably service for Messages'
      end

      context 'when protocol is set as :msgpack' do
        let(:client_options) { { protocol: :msgpack } }
        let(:mime) { 'application/x-msgpack' }
        let(:request_body) { body_value.to_msgpack }

        it 'uses MsgPack', webmock: true do
          expect(client.protocol).to eql(:msgpack)
          expect(client.time).to be_within(1).of(now)
        end

        skip 'uses MsgPack against Ably service for Auth'
        skip 'uses MsgPack against Ably service for Messages'
      end
    end
  end

  describe "invalid requests in middleware" do
    it "should raise an InvalidRequest exception with a valid message" do
      invalid_client = Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret', environment: environment)
      expect { invalid_client.channel('test').publish('foo', 'choo') }.to raise_error do |error|
        expect(error).to be_a(Ably::Exceptions::InvalidToken)
        expect(error.message).to match(/invalid credentials/)
        expect(error.code).to eql(40100)
        expect(error.status).to eql(401)
      end
    end

    describe "server error with JSON response", webmock: true do
      let(:error_response) { '{ "error": { "statusCode": 500, "code": 50000, "message": "Internal error" } }' }

      before do
        stub_request(:get, "#{client.endpoint}/time").to_return(:status => 500, :body => error_response, :headers => { 'Content-Type' => 'application/json' })
      end

      it "should raise a ServerError exception" do
        expect { client.time }.to raise_error(Ably::Exceptions::ServerError, /Internal error/)
      end
    end

    describe "server error", webmock: true do
      before do
        stub_request(:get, "#{client.endpoint}/time").to_return(:status => 500)
      end

      it "should raise a ServerError exception" do
        expect { client.time }.to raise_error(Ably::Exceptions::ServerError, /Unknown/)
      end
    end
  end

  describe 'authentication failure', webmock: true do
    let(:token_1) { { id: SecureRandom.hex } }
    let(:token_2) { { id: SecureRandom.hex } }
    let(:channel) { 'channelname' }

    before do
      @token_requests = 0
      @publish_attempts = 0

      stub_request(:post, "#{client.endpoint}/keys/#{key_id}/requestToken").to_return do
        @token_requests += 1
        {
          :body => { access_token: send("token_#{@token_requests}").merge(expires: Time.now.to_i + 3600) }.to_json,
          :headers => { 'Content-Type' => 'application/json' }
        }
      end

      stub_request(:post, "#{client.endpoint}/channels/#{channel}/publish").to_return do
        @publish_attempts += 1
        if [1, 3].include?(@publish_attempts)
          { status: 201, :body => '[]' }
        else
          raise Ably::Exceptions::InvalidRequest.new('Authentication failure', status: 401, code: 40140)
        end
      end
    end

    context 'when auth#token_renewable?' do
      before do
        client.auth.authorise
      end

      it 'should automatically reissue a token' do
        client.channel(channel).publish('evt', 'msg')
        expect(@publish_attempts).to eql(1)

        client.channel(channel).publish('evt', 'msg')
        expect(@publish_attempts).to eql(3)
        expect(@token_requests).to eql(2)
      end
    end

    context 'when NOT auth#token_renewable?' do
      let(:client) { Ably::Rest::Client.new(token_id: 'token ID cannot be used to create a new token', environment: environment) }
      it 'should raise the exception' do
        client.channel(channel).publish('evt', 'msg')
        expect(@publish_attempts).to eql(1)
        expect { client.channel(channel).publish('evt', 'msg') }.to raise_error Ably::Exceptions::InvalidToken
        expect(@token_requests).to eql(0)
      end
    end
  end

  describe Ably::Rest::Client do
    context '#initialize' do
      context 'with an auth block' do
        let(:client) { Ably::Rest::Client.new(environment: environment) { token_request } }
        let(:token_request) { client.auth.create_token_request(key_id: key_id, key_secret: key_secret, client_id: client_id) }
        let(:client_id) { 'unique_client_id' }

        it 'calls the block to get a new token' do
          expect { client.channel('channel_name').publish('event', 'message') }.to change { client.auth.current_token }
          expect(client.auth.current_token.client_id).to eql(client_id)
        end
      end

      context 'with an auth URL' do
        let(:client) { Ably::Rest::Client.new(environment: environment, auth_url: token_request_url, auth_method: :get) }
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
        Ably::Rest::Client.new(environment: environment) do
          @request_index ||= 0
          @request_index += 1
          send("token_request_#{@request_index}")
        end
      end
      let(:token_request_1) { client.auth.create_token_request(token_request_options.merge(client_id: SecureRandom.hex)) }
      let(:token_request_2) { client.auth.create_token_request(token_request_options.merge(client_id: SecureRandom.hex)) }

      context 'when expired' do
        let(:token_request_options) { { key_id: key_id, key_secret: key_secret, ttl: Ably::Token::TOKEN_EXPIRY_BUFFER } }

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
  end
end
