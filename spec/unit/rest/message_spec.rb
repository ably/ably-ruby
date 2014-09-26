require "spec_helper"

describe Ably::Rest::Models::Message do
  include Ably::Modules::Conversions
  context 'attributes' do
    let(:unique_value) { 'unique_value' }

    %w(name data client_id message_id).each do |attribute|
      context "##{attribute}" do
        subject { Ably::Rest::Models::Message.new({ attribute.to_sym => unique_value }) }

        it "retrieves attribute :#{attribute}" do
          expect(subject.public_send(attribute)).to eql(unique_value)
        end
      end
    end

    context '#sender_timestamp' do
      subject { Ably::Rest::Models::Message.new(timestamp: as_since_epoch(Time.now)) }
      it 'retrieves attribute :timestamp' do
        expect(subject.sender_timestamp).to be_a(Time)
        expect(subject.sender_timestamp.to_i).to be_within(1).of(Time.now.to_i)
      end
    end

    context '#json' do
      let(:attributes) { { timestamp: as_since_epoch(Time.now) } }
      subject { Ably::Rest::Models::Message.new(attributes) }

      it 'provides access to #json' do
        expect(subject.json).to eql(attributes)
      end
    end

    context '#[]' do
      subject { Ably::Rest::Models::Message.new(unusual: 'attribute') }

      it 'provides accessor method to #json' do
        expect(subject[:unusual]).to eql('attribute')
      end
    end
  end

  context '==' do
    let(:attributes) { { client_id: 'unique' } }

    it 'is true when attributes are the same' do
      new_message = -> { Ably::Rest::Models::Message.new(attributes) }
      expect(new_message[]).to eq(new_message[])
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Rest::Models::Message.new(client_id: 1)).to_not eq(Ably::Rest::Models::Message.new(client_id: 2))
    end

    it 'is false when class type differs' do
      expect(Ably::Rest::Models::Message.new(client_id: 1)).to_not eq(nil)
    end
  end

  context 'is immutable' do
    let(:options) { { client_id: 'John' } }
    subject { Ably::Rest::Models::Message.new(options) }

    it 'prevents changes' do
      expect { subject.json[:client_id] = 'Joe' }.to raise_error RuntimeError, /can't modify frozen Hash/
    end

    it 'clones options' do
      expect(subject.json[:client_id]).to eql('John')
      options[:client_id] = 'Joe'
      expect(subject.json[:client_id]).to eql('John')
    end
  end
end
