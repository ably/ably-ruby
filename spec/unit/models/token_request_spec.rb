require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::TokenRequest do
  subject { Ably::Models::TokenRequest }

  it_behaves_like 'a model', with_simple_attributes: %w(key_name client_id nonce mac) do
    let(:model_args) { [] }
  end

  context 'attributes' do
    context '#capability' do
      let(:capability) { { "value" => random_str } }
      let(:capability_str) { JSON.dump(capability) }

      subject { Ably::Models::TokenRequest.new({ capability: capability_str }) }

      it 'retrieves attribute :capability as parsed JSON' do
        expect(subject.capability).to eql(capability)
      end
    end

    context "#timestamp" do
      let(:time) { Time.now }

      context 'with :timestamp option as milliseconds in constructor' do
        subject { Ably::Models::TokenRequest.new(timestamp: time.to_i * 1000) }

        it "retrieves attribute :timestamp as Time" do
          expect(subject.timestamp).to be_a(Time)
          expect(subject.timestamp.to_i).to eql(time.to_i)
        end
      end

      context 'with :timestamp option as Time in constructor' do
        subject { Ably::Models::TokenRequest.new(timestamp: time) }

        it "retrieves attribute :timestamp as Time" do
          expect(subject.timestamp).to be_a(Time)
          expect(subject.timestamp.to_i).to eql(time.to_i)
        end
      end

      context 'when converted to JSON' do
        subject { Ably::Models::TokenRequest.new(timestamp: time) }

        it "is in milliseconds since epoch" do
          expect(JSON.parse(JSON.dump(subject))['timestamp']).to eql((time.to_f * 1000).round)
        end
      end
    end

    context "#ttl" do
      let(:ttl) { 500 }

      context 'with :ttl option as milliseconds in constructor' do
        subject { Ably::Models::TokenRequest.new(ttl: ttl * 1000) }

        it "retrieves attribute :ttl as seconds" do
          expect(subject.ttl).to be_a(Integer)
          expect(subject.ttl).to eql(ttl)
        end
      end

      context 'when converted to JSON' do
        subject { Ably::Models::TokenRequest.new(ttl: ttl * 1000) }

        it "is in milliseconds since epoch" do
          expect(JSON.parse(JSON.dump(subject))['ttl']).to eql(ttl * 1000)
        end
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
