require "spec_helper"

describe Ably::Message do
  context 'attributes' do
    let(:unique_value) { 'unique_value' }

    %w(name data client_id timestamp channel_serial).each do |attribute|
      context "##{attribute}" do
        subject { Ably::Message.new({ attribute.to_sym => unique_value }) }

        it "retrieves attribute :#{attribute}" do
          expect(subject.public_send(attribute)).to eql(unique_value)
        end
      end
    end

    context '#timestamp_at' do
      subject { Ably::Message.new(timestamp: Time.now.to_i * 1000) }
      it 'retrieves attribute :key' do
        expect(subject.timestamp_at.to_i).to be_within(1).of(Time.now.to_i)
      end
    end

    context '#raw_message' do
      let(:attributes) { { timestamp: Time.now.to_i * 1000 } }
      subject { Ably::Message.new(attributes) }

      it 'provides access to #raw_message' do
        expect(subject.raw_message).to eql(attributes)
      end
    end

    context '#[]' do
      subject { Ably::Message.new(unusual: 'attribute') }

      it 'provides accessor method to #raw_message' do
        expect(subject[:unusual]).to eql('attribute')
      end
    end
  end

  context '==' do
    let(:attributes) { { client_id: 'unique' } }

    it 'is true when attributes are the same' do
      new_message = -> { Ably::Message.new(attributes) }
      expect(new_message[]).to eq(new_message[])
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Message.new(client_id: 1)).to_not eq(Ably::Message.new(client_id: 2))
    end

    it 'is false when class type differs' do
      expect(Ably::Message.new(client_id: 1)).to_not eq(nil)
    end
  end

  context 'is immutable' do
    let(:options) { { client_id: 'John' } }
    subject { Ably::Message.new(options) }

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
