require 'securerandom'

shared_examples 'a realtime model' do |shared_options = {}|
  let(:args) { ([model_options] + model_args) }
  let(:model) { subject.new(*args) }

  context 'attributes' do
    let(:unique_value) { SecureRandom.hex }

    Array(shared_options[:with_simple_attributes]).each do |attribute|
      context "##{attribute}" do
        let(:model_options) { { attribute.to_sym => unique_value } }

        it "retrieves attribute :#{attribute}" do
          expect(model.public_send(attribute)).to eql(unique_value)
        end
      end
    end

    context '#json' do
      let(:model_options) { { action: 5 } }

      it 'provides access to #json' do
        expect(model.json).to eq(model_options)
      end
    end

    context '#[]' do
      let(:model_options) { { unusual: 'attribute' } }

      it 'provides accessor method to #json' do
        expect(model[:unusual]).to eql('attribute')
      end
    end
  end

  context '#==' do
    let(:model_options) { { channel: 'unique' } }

    it 'is true when attributes are the same' do
      new_message = -> { subject.new(*args) }
      expect(new_message[]).to eq(new_message[])
    end

    it 'is false when attributes are not the same' do
      expect(subject.new(*[action: 1] + model_args)).to_not eq(subject.new(*[action: 2] + model_args))
    end

    it 'is false when class type differs' do
      expect(subject.new(*[action: 1] + model_args)).to_not eq(nil)
    end
  end

  context 'is immutable' do
    let(:model_options) { { channel: 'name' } }

    it 'prevents changes' do
      expect { model.json[:channel] = 'new' }.to raise_error RuntimeError, /can't modify frozen Hash/
    end

    it 'dups options' do
      expect(model.json[:channel]).to eql('name')
      model_options[:channel] = 'new'
      expect(model.json[:channel]).to eql('name')
    end
  end
end
