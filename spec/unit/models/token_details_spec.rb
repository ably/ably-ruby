require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::TokenDetails do
  subject { Ably::Models::TokenDetails }

  it_behaves_like 'a model', with_simple_attributes: %w(client_id nonce) do
    # TODO: Include :token and :key_name
    let(:model_args) { [] }
  end

  context 'interim tests' do
    subject { Ably::Models::TokenDetails.new(id: 'token', key: 'key_name') }

    it 'retrieves the interim attributes' do
      expect(subject.token).to eql('token')
      expect(subject.key_name).to eql('key_name')
    end
  end

  context 'attributes' do
    let(:capability) { { "value" => random_str } }
    let(:capability_str) { JSON.dump(capability) }

    context '#capability' do
      subject { Ably::Models::TokenDetails.new({ capability: capability_str }) }

      it 'retrieves attribute :capability as parsed JSON' do
        expect(subject.capability).to eql(capability)
      end
    end

    { :issued_at => :issued_at, :expires => :expires }.each do |method_name, attribute|
      let(:time) { Time.now }
      context "##{method_name}" do
        subject { Ably::Models::TokenDetails.new({ attribute.to_sym => time.to_i }) }

        it "retrieves attribute :#{attribute} as Time" do
          expect(subject.public_send(method_name)).to be_a(Time)
          expect(subject.public_send(method_name).to_i).to eql(time.to_i)
        end
      end
    end

    context '#expired?' do
      let(:expire_time) { Time.now + Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER }

      context 'once grace period buffer has passed' do
        subject { Ably::Models::TokenDetails.new(expires: expire_time - 1) }

        it 'is true' do
          expect(subject.expired?).to eql(true)
        end
      end

      context 'within grace period buffer' do
        subject { Ably::Models::TokenDetails.new(expires: expire_time + 1) }

        it 'is false' do
          expect(subject.expired?).to eql(false)
        end
      end
    end
  end

  context '==' do
    let(:token_attributes) { { token: 'unique' } }

    it 'is true when attributes are the same' do
      new_token = -> { Ably::Models::TokenDetails.new(token_attributes) }
      expect(new_token[]).to eq(new_token[])
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Models::TokenDetails.new(token: 1)).to_not eq(Ably::Models::TokenDetails.new(token: 2))
    end

    it 'is false when class type differs' do
      expect(Ably::Models::TokenDetails.new(token: 1)).to_not eq(nil)
    end
  end

  context 'TokenDetails conversion methods', :api_private do
    context 'with a TokenDetails object' do
      let(:token_details) { Ably::Models::TokenDetails.new(client_id: random_str) }

      it 'returns the TokenDetails object' do
        expect(Ably::Models::TokenDetails(token_details)).to eql(token_details)
      end
    end

    context 'with a JSON object' do
      let(:client_id) { random_str }
      let(:token_details_json) { { client_id: client_id } }

      it 'returns a new TokenDetails object from the JSON' do
        expect(Ably::Models::TokenDetails(token_details_json).client_id).to eql(client_id)
      end
    end
  end
end
