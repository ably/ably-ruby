require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::TokenDetails do
  include Ably::Modules::Conversions

  subject { Ably::Models::TokenDetails }

  it_behaves_like 'a model', with_simple_attributes: %w(token key_name client_id) do
    let(:model_args) { [] }
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

    context do
      let(:time) { Time.now }
      { :issued => :issued, :expires => :expires }.each do |method_name, attribute|
        context "##{method_name} with :#{method_name} option as milliseconds in constructor" do
          subject { Ably::Models::TokenDetails.new({ attribute.to_sym => time.to_i * 1000 }) }

          it "retrieves attribute :#{attribute} as Time" do
            expect(subject.public_send(method_name)).to be_a(Time)
            expect(subject.public_send(method_name).to_i).to eql(time.to_i)
          end
        end

        context "##{method_name} with :#{method_name} option as a Time in constructor" do
          subject { Ably::Models::TokenDetails.new({ attribute.to_sym => time }) }

          it "retrieves attribute :#{attribute} as Time" do
            expect(subject.public_send(method_name)).to be_a(Time)
            expect(subject.public_send(method_name).to_i).to eql(time.to_i)
          end
        end

        context "##{method_name} when converted to JSON" do
          subject { Ably::Models::TokenDetails.new({ attribute.to_sym => time }) }

          it 'is in milliseconds' do
            expect(JSON.parse(JSON.dump(subject))[convert_to_mixed_case(attribute)]).to eql((time.to_f * 1000).round)
          end
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

      context 'when expires is not available (i.e. string tokens)' do
        subject { Ably::Models::TokenDetails.new() }

        it 'is always false' do
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

  context 'to_json' do
    let(:token_json_parsed) { JSON.parse(Ably::Models::TokenDetails(token_attributes).to_json) }

    context 'with all attributes and values' do
      let(:token_attributes) do
        { token: random_str, capability: random_str, keyName: random_str, issued: Time.now.to_i, expires: Time.now.to_i + 10, clientId: random_str }
      end

      it 'returns all attributes' do
        token_attributes.each do |key, val|
          expect(token_json_parsed[key.to_s]).to eql(val)
        end
        expect(token_attributes.keys.length).to eql(token_json_parsed.keys.length)
      end
    end

    context 'with only a token string' do
      let(:token_attributes) do
        { token: random_str }
      end

      it 'returns populated attributes' do
        expect(token_json_parsed['token']).to eql(token_attributes[:token])
        expect(token_json_parsed.keys.length).to eql(1)
      end
    end
  end

  context 'from_json (#TD7)' do
    let(:issued_time) { Time.now }
    let(:expires_time) { Time.now + 24*60*60 }
    let(:capabilities) { { '*' => ['publish'] } }

    context 'with Ruby idiomatic Hash object' do
      subject { Ably::Models::TokenDetails.from_json(token_details_object) }

      let(:token_details_object) do
        {
          token: 'val1',
          key_name: 'val2',
          issued: issued_time.to_i * 1000,
          expires: expires_time.to_i * 1000,
          capability: capabilities,
          client_id: 'val3'
        }
      end

      it 'returns a valid TokenDetails object' do
        expect(subject.token).to eql('val1')
        expect(subject.key_name).to eql('val2')
        expect(subject.issued.to_f).to be_within(1).of(issued_time.to_f)
        expect(subject.expires.to_f).to be_within(1).of(expires_time.to_f)
        expect(subject.capability).to eql(capabilities)
        expect(subject.client_id).to eql('val3')
      end
    end

    context 'with JSON-like object' do
      subject { Ably::Models::TokenDetails.from_json(token_details_object) }

      let(:token_details_object) do
        {
          'keyName' => 'val2',
          'issued' => issued_time.to_i * 1000,
          'expires' => expires_time.to_i * 1000,
          'capability' => JSON.dump(capabilities),
          'clientId' => 'val3'
        }
      end

      it 'returns a valid TokenDetails object' do
        expect(subject.token).to be_nil
        expect(subject.key_name).to eql('val2')
        expect(subject.issued.to_f).to be_within(1).of(issued_time.to_f)
        expect(subject.expires.to_f).to be_within(1).of(expires_time.to_f)
        expect(subject.capability).to eql(capabilities)
        expect(subject.client_id).to eql('val3')
      end
    end

    context 'with JSON string' do
      subject { Ably::Models::TokenDetails.from_json(JSON.dump(token_details_object)) }

      let(:token_details_object) do
        {
          'keyName' => 'val2',
          'issued' => issued_time.to_i * 1000,
          'expires' => expires_time.to_i * 1000,
          'clientId' => 'val3'
        }
      end

      it 'returns a valid TokenDetails object' do
        expect(subject.token).to be_nil
        expect(subject.key_name).to eql('val2')
        expect(subject.issued.to_f).to be_within(1).of(issued_time.to_f)
        expect(subject.expires.to_f).to be_within(1).of(expires_time.to_f)
        expect(subject.capability).to be_nil
        expect(subject.client_id).to eql('val3')
      end
    end
  end
end
