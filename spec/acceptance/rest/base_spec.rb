require "spec_helper"

describe "REST" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "initializing the client" do
    it "should disallow an invalid key" do
      expect { Ably::Rest::Client.new({}) }.to raise_error(ArgumentError, /api_key is missing/)
      expect { Ably::Rest::Client.new(api_key: 'invalid') }.to raise_error(ArgumentError, /api_key is invalid/)
      expect { Ably::Rest::Client.new(api_key: 'invalid:asdad') }.to raise_error(ArgumentError, /api_key is invalid/)
      expect { Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret') }.to_not raise_error
    end

    it "should default to the production REST end point" do
      expect(Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret').endpoint.to_s).to eql('https://rest.ably.io')
    end

    it "should allow an environment to be set" do
      expect(Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret', environment: 'sandbox').endpoint.to_s).to eql('https://sandbox-rest.ably.io')
    end
  end

  describe "invalid requests" do
    it "should raise a InvalidRequest exception with a valid message" do
      invalid_client = Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret')
      expect { invalid_client.channel('test').publish('foo', 'choo') }.to raise_error do |error|
        expect(error).to be_a(Ably::InvalidRequest)
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
        expect { client.time }.to raise_error(Ably::ServerError, /Internal error/)
      end
    end

    describe "server error", webmock: true do
      before do
        stub_request(:get, "#{client.endpoint}/time").to_return(:status => 500)
      end

      it "should raise a ServerError exception" do
        expect { client.time }.to raise_error(Ably::ServerError, /Unknown/)
      end
    end
  end
end
