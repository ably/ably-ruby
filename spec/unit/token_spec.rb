require "spec_helper"

describe Ably::Token do
  context 'defaults' do
    let(:one_hour)          { 60 * 60 }
    let(:all_capabilities)  { { "*" => ["*"] } }

    it 'should default TTL to 1 hour' do
      expect(Ably::Token::DEFAULTS[:ttl]).to eql(one_hour)
    end

    it 'should default capability to all' do
      expect(Ably::Token::DEFAULTS[:capability]).to eql(all_capabilities)
    end

    it 'should only have defaults for :ttl and :capability' do
      expect(Ably::Token::DEFAULTS.keys).to contain_exactly(:ttl, :capability)
    end
  end

  context 'attributes' do
    let(:unique_value) { 'unique_value' }

    %w(id capability client_id nonce).each do |attribute|
      context "##{attribute}" do
        subject { Ably::Token.new({ attribute.to_sym => unique_value }) }

        it "retrieves attribute :#{attribute}" do
          expect(subject.public_send(attribute)).to eql(unique_value)
        end
      end
    end

    context '#key_id' do
      subject { Ably::Token.new({ key: unique_value }) }
      it 'retrieves attribute :key' do
        expect(subject.key_id).to eql(unique_value)
      end
    end

    { :issued_at => :issued_at, :expires_at => :expires }.each do |method_name, attribute|
      let(:time) { Time.now }
      context "##{method_name}" do
        subject { Ably::Token.new({ attribute.to_sym => time.to_i }) }

        it "retrieves attribute :#{attribute} as Time" do
          expect(subject.public_send(method_name)).to be_a(Time)
          expect(subject.public_send(method_name).to_i).to eql(time.to_i)
        end
      end
    end
  end
end
