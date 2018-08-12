# encoding: utf-8
require 'spec_helper'

describe Ably::Rest do
  describe 'transport protocol' do
    include Ably::Modules::Conversions

    let(:client_options) { {} }
    let(:client) do
      Ably::Rest::Client.new(client_options.merge(key: 'appid.keyuid:keysecret', log_retries_as_info: true))
    end

    let(:now) { Time.now - 1000 }
    let(:body_value) { [as_since_epoch(now)] }

    before do
      stub_request(:get, "#{client.endpoint}/time").
        with(:headers => { 'Accept' => mime }).
        to_return(:status => 200, :body => request_body, :headers => { 'Content-Type' => mime })
    end

    context 'when protocol is not defined it defaults to :msgpack' do
      let(:client_options) { { } }
      let(:mime) { 'application/x-msgpack' }
      let(:request_body) { body_value.to_msgpack }

      it 'uses MsgPack', :webmock do
        expect(client.protocol).to eql(:msgpack)
        expect(client.time).to be_within(1).of(now)
      end
    end

    options = [
        { protocol: :json },
        { use_binary_protocol: false }
      ].each do |client_option|

      context "when option #{client_option} is used" do
        let(:client_options) { client_option }
        let(:mime) { 'application/json' }
        let(:request_body) { body_value.to_json }

        it 'uses JSON', :webmock do
          expect(client.protocol).to eql(:json)
          expect(client.time).to be_within(1).of(now)
        end
      end
    end

    options = [
        { protocol: :msgpack },
        { use_binary_protocol: true }
      ].each do |client_option|

      context "when option #{client_option} is used" do
        let(:client_options) { client_option }
        let(:mime) { 'application/x-msgpack' }
        let(:request_body) { body_value.to_msgpack }

        it 'uses MsgPack', :webmock do
          expect(client.protocol).to eql(:msgpack)
          expect(client.time).to be_within(1).of(now)
        end
      end
    end
  end

  vary_by_protocol do
    let(:client) do
      Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol, log_retries_as_info: true)
    end

    describe 'failed requests' do
      context 'due to invalid Auth' do
        it 'should raise an InvalidRequest exception with a valid error message and code' do
          invalid_client = Ably::Rest::Client.new(key: 'appid.keyuid:keysecret', environment: environment)
          expect { invalid_client.channel('test').publish('foo', 'choo') }.to raise_error do |error|
            expect(error).to be_a(Ably::Exceptions::ResourceMissing)
            expect(error.message).to match(/No application found/)
            expect(error.code).to eql(40400)
            expect(error.status).to eql(404)
          end
        end
      end

      describe 'server error with JSON error response body', :webmock do
        let(:error_response) { '{ "error": { "statusCode": 500, "code": 50000, "message": "Internal error" } }' }

        before do
          stub_request(:get, "#{client.endpoint}/time").
            to_return(:status => 500, :body => error_response, :headers => { 'Content-Type' => 'application/json' })
        end

        it 'should raise a ServerError exception' do
          expect { client.time }.to raise_error(Ably::Exceptions::ServerError, /Internal error/)
        end
      end

      describe '500 server error without a valid JSON response body', :webmock do
        before do
          stub_request(:get, "#{client.endpoint}/time").
          to_return(:status => 500, :headers => { 'Content-Type' => 'application/json' })
        end

        it 'should raise a ServerError exception' do
          expect { client.time }.to raise_error(Ably::Exceptions::ServerError, /Unknown/)
        end
      end
    end

    describe 'token authentication failures', :webmock do
      let(:token_1) { { token: random_str } }
      let(:token_2) { { token: random_str } }
      let(:channel) { random_str }

      before do
        @token_requests = 0
        @publish_attempts = 0

        stub_request(:post, "#{client.endpoint}/keys/#{key_name}/requestToken").to_return do
          @token_requests += 1
          {
            :body => public_send("token_#{@token_requests}").merge(expires: (Time.now.to_i + 60) * 1000).to_json,
            :headers => { 'Content-Type' => 'application/json' }
          }
        end

        stub_request(:post, "#{client.endpoint}/channels/#{channel}/publish").to_return do
          @publish_attempts += 1
          if [1, 3].include?(@publish_attempts)
            { status: 201, :body => '[]', :headers => { 'Content-Type' => 'application/json' } }
          else
            raise Ably::Exceptions::TokenExpired.new('Authentication failure', 401, 40142)
          end
        end
      end

      context 'when auth#token_renewable?' do
        before do
          client.auth.authorize
        end

        it 'should automatically reissue a token' do
          client.channel(channel).publish('evt', 'msg')
          expect(@publish_attempts).to eql(1)
          expect(@token_requests).to eql(1)

          # Triggers an authentication 401 failure which should automatically request a new token
          client.channel(channel).publish('evt', 'msg')
          expect(@publish_attempts).to eql(3)
          expect(@token_requests).to eql(2)
        end
      end

      context 'when NOT auth#token_renewable?' do
        let(:client) { Ably::Rest::Client.new(token: 'token ID cannot be used to create a new token', environment: environment, protocol: protocol) }

        it 'should raise an TokenExpired exception' do
          client.channel(channel).publish('evt', 'msg')
          expect(@publish_attempts).to eql(1)
          expect { client.channel(channel).publish('evt', 'msg') }.to raise_error Ably::Exceptions::TokenExpired
          expect(@token_requests).to eql(0)
        end
      end
    end
  end
end
