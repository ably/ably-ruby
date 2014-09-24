require "spec_helper"

describe Ably::Rest::Message do
  context 'attributes' do
    let(:unique_value) { 'unique_value' }

    %w(name data client_id message_id).each do |attribute|
      context "##{attribute}" do
        subject { Ably::Rest::Message.new({ attribute.to_sym => unique_value }) }

        it "retrieves attribute :#{attribute}" do
          expect(subject.public_send(attribute)).to eql(unique_value)
        end
      end
    end

    context '#sender_timestamp_at' do
      subject { Ably::Rest::Message.new(timestamp: Time.now.to_i * 1000) }
      it 'retrieves attribute :timestamp' do
        expect(subject.sender_timestamp_at.to_i).to be_within(1).of(Time.now.to_i)
      end
    end

    context '#sender_timestamp' do
      let(:timestamp) { Time.now.to_i * 1000 }
      subject { Ably::Rest::Message.new(timestamp: timestamp) }
      it 'retrieves attribute :timestamp' do
        expect(subject.sender_timestamp).to eql(timestamp)
      end
    end

    context '#raw_message' do
      let(:attributes) { { timestamp: Time.now.to_i * 1000 } }
      subject { Ably::Rest::Message.new(attributes) }

      it 'provides access to #raw_message' do
        expect(subject.raw_message).to eql(attributes)
      end
    end

    context '#[]' do
      subject { Ably::Rest::Message.new(unusual: 'attribute') }

      it 'provides accessor method to #raw_message' do
        expect(subject[:unusual]).to eql('attribute')
      end
    end
  end

  context '==' do
    let(:attributes) { { client_id: 'unique' } }

    it 'is true when attributes are the same' do
      new_message = -> { Ably::Rest::Message.new(attributes) }
      expect(new_message[]).to eq(new_message[])
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Rest::Message.new(client_id: 1)).to_not eq(Ably::Rest::Message.new(client_id: 2))
    end

    it 'is false when class type differs' do
      expect(Ably::Rest::Message.new(client_id: 1)).to_not eq(nil)
    end
  end

  context 'is immutable' do
    let(:options) { { client_id: 'John' } }
    subject { Ably::Rest::Message.new(options) }

    it 'prevents changes' do
      expect { subject.raw_message[:client_id] = 'Joe' }.to raise_error RuntimeError, /can't modify frozen Hash/
    end

    it 'dups options' do
      expect(subject.raw_message[:client_id]).to eql('John')
      options[:client_id] = 'Joe'
      expect(subject.raw_message[:client_id]).to eql('John')
    end
  end
end
