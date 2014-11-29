require 'spec_helper'

describe Ably::Models::Token do
  subject { Ably::Models::Token }

  it_behaves_like 'a model', with_simple_attributes: %w(id capability client_id nonce) do
    let(:model_args) { [] }
  end

  context 'defaults' do
    let(:one_hour)          { 60 * 60 }
    let(:all_capabilities)  { { "*" => ["*"] } }

    it 'should default TTL to 1 hour' do
      expect(Ably::Models::Token::DEFAULTS[:ttl]).to eql(one_hour)
    end

    it 'should default capability to all' do
      expect(Ably::Models::Token::DEFAULTS[:capability]).to eql(all_capabilities)
    end

    it 'should only have defaults for :ttl and :capability' do
      expect(Ably::Models::Token::DEFAULTS.keys).to contain_exactly(:ttl, :capability)
    end
  end

  context 'attributes' do
    let(:unique_value) { 'unique_value' }

    context '#key_id' do
      subject { Ably::Models::Token.new({ key: unique_value }) }
      it 'retrieves attribute :key' do
        expect(subject.key_id).to eql(unique_value)
      end
    end

    { :issued_at => :issued_at, :expires_at => :expires }.each do |method_name, attribute|
      let(:time) { Time.now }
      context "##{method_name}" do
        subject { Ably::Models::Token.new({ attribute.to_sym => time.to_i }) }

        it "retrieves attribute :#{attribute} as Time" do
          expect(subject.public_send(method_name)).to be_a(Time)
          expect(subject.public_send(method_name).to_i).to eql(time.to_i)
        end
      end
    end

    context '#expired?' do
      let(:expire_time) { Time.now + Ably::Models::Token::TOKEN_EXPIRY_BUFFER }

      context 'once grace period buffer has passed' do
        subject { Ably::Models::Token.new(expires: expire_time - 1) }

        it 'is true' do
          expect(subject.expired?).to eql(true)
        end
      end

      context 'within grace period buffer' do
        subject { Ably::Models::Token.new(expires: expire_time + 1) }

        it 'is false' do
          expect(subject.expired?).to eql(false)
        end
      end
    end
  end

  context '==' do
    let(:token_attributes) { { id: 'unique' } }

    it 'is true when attributes are the same' do
      new_token = -> { Ably::Models::Token.new(token_attributes) }
      expect(new_token[]).to eq(new_token[])
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Models::Token.new(id: 1)).to_not eq(Ably::Models::Token.new(id: 2))
    end

    it 'is false when class type differs' do
      expect(Ably::Models::Token.new(id: 1)).to_not eq(nil)
    end
  end
end
