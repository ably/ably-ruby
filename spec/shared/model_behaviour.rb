# encoding: utf-8

shared_examples 'a model' do |shared_options = {}|
  let(:base_model_options) { shared_options.fetch(:base_model_options, {}) }
  let(:args) { ([base_model_options.merge(model_options)] + model_args) }
  let(:model) { subject.new(*args) }

  context 'attributes' do
    let(:unique_value) { random_str }

    Array(shared_options[:with_simple_attributes]).each do |attribute|
      context "##{attribute}" do
        let(:model_options) { { attribute.to_sym => unique_value } }

        it "retrieves attribute :#{attribute}" do
          expect(model.public_send(attribute)).to eql(unique_value)
        end
      end
    end

    context '#attributes', :api_private do
      let(:model_options) { { action: 5 } }

      it 'provides access to #attributes' do
        expect(model.attributes).to eq(model_options)
      end
    end

    context '#[]', :api_private do
      let(:model_options) { { unusual: 'attribute' } }

      it 'provides accessor method to #attributes' do
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

  context '#to_msgpack', :api_private do
    let(:model_options) { { name: 'test', action: 0, channel_snake_case: 'unique' } }
    let(:serialized)    { model.to_msgpack }

    it 'returns a msgpack object with Ably payload naming' do
      expect(MessagePack.unpack(serialized)).to include('channelSnakeCase' => 'unique')
    end
  end

  context '#to_json', :api_private do
    let(:model_options) { { name: 'test', action: 0, channel_snake_case: 'unique' } }
    let(:serialized)    { model.to_json }

    it 'returns a JSON string with Ably payload naming' do
      expect(JSON.parse(serialized)).to include('channelSnakeCase' => 'unique')
    end
  end

  context 'is immutable' do
    let(:model_options) { { channel: 'name' } }

    it 'prevents changes' do
      expect { model.attributes[:channel] = 'new' }.to raise_error RuntimeError, /can't modify frozen.*Hash/
    end

    it 'dups options' do
      expect(model.attributes[:channel]).to eql('name')
      model_options[:channel] = 'new'
      expect(model.attributes[:channel]).to eql('name')
    end
  end
end
