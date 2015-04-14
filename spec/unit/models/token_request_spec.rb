require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::TokenRequest do
  subject { Ably::Models::TokenRequest }

  it_behaves_like 'a model', with_simple_attributes: %w(ttl client_id nonce mac) do
    # TODO: Include :key_name
    # TODO: Change TTL to use ms internally
    let(:model_args) { [] }
  end

  context 'interim tests' do
    subject { Ably::Models::TokenRequest.new(id: 'key_name') }

    it 'retrieves the interim attributes' do
      expect(subject.key_name).to eql('key_name')
    end
  end

  context 'attributes' do
    let(:capability) { { "value" => random_str } }
    let(:capability_str) { JSON.dump(capability) }

    context '#capability' do
      subject { Ably::Models::TokenRequest.new({ capability: capability_str }) }

      it 'retrieves attribute :capability as parsed JSON' do
        expect(subject.capability).to eql(capability)
      end
    end

    let(:time) { Time.now }
    context "#timestamp" do
      subject { Ably::Models::TokenRequest.new(timestamp: time.to_i) }

      it "retrieves attribute :time as Time" do
        expect(subject.timestamp).to be_a(Time)
        expect(subject.timestamp.to_i).to eql(time.to_i)
      end
    end
  end

  context '==' do
    let(:token_attributes) { { client_id: random_str } }

    it 'is true when attributes are the same' do
      new_token = -> { Ably::Models::TokenRequest.new(token_attributes) }
      expect(new_token[]).to eq(new_token[])
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Models::TokenRequest.new(client_id: 1)).to_not eq(Ably::Models::TokenRequest.new(client_id: 2))
    end

    it 'is false when class type differs' do
      expect(Ably::Models::TokenRequest.new(client_id: 1)).to_not eq(nil)
    end
  end

  context 'TokenRequest conversion methods', :api_private do
    context 'with a TokenRequest object' do
      let(:token_request) { Ably::Models::TokenRequest.new(client_id: random_str) }

      it 'returns the TokenRequest object' do
        expect(Ably::Models::TokenRequest(token_request)).to eql(token_request)
      end
    end

    context 'with a JSON object' do
      let(:client_id) { random_str }
      let(:token_request_json) { { client_id: client_id } }

      it 'returns a new TokenRequest object from the JSON' do
        expect(Ably::Models::TokenRequest(token_request_json).client_id).to eql(client_id)
      end
    end
  end
end
