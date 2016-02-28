require 'spec_helper'
require 'json'

require 'ably/models/message_encoders/json'

describe Ably::Models::MessageEncoders::Json do
  let(:hash_data)           { { 'key' => 'value', 'key2' => 123 } }
  let(:hash_string_data)    { JSON.dump(hash_data) }
  let(:array_data)          { ['value', 123] }
  let(:array_string_data)   { JSON.dump(array_data) }

  let(:client)              { instance_double('Ably::Realtime::Client') }

  subject { Ably::Models::MessageEncoders::Json.new(client) }

  context '#decode' do
    before do
      subject.decode message, {}
    end

    context 'message with json payload' do
      let(:message) { { data: hash_string_data, encoding: 'json' } }

      it 'decodes json' do
        expect(message[:data]).to eq(hash_data)
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to be_nil
      end
    end

    context 'message with json payload in camelCase' do
      let(:message) { { data: '{"keyId":"test"}', encoding: 'json' } }

      it 'decodes json' do
        expect(message[:data]).to eq({ 'keyId' => 'test' })
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to be_nil
      end
    end

    context 'message with json payload before other payloads' do
      let(:message) { { data: hash_string_data, encoding: 'utf-8/json' } }

      it 'decodes json' do
        expect(message[:data]).to eql(hash_data)
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to eql('utf-8')
      end
    end

    context 'message with another payload' do
      let(:message) { { data: hash_string_data, encoding: 'utf-8' } }

      it 'leaves the message data intact' do
        expect(message[:data]).to eql(hash_string_data)
      end

      it 'leaves the encoding intact' do
        expect(message[:encoding]).to eql('utf-8')
      end
    end
  end

  context '#encode' do
    before do
      subject.encode message, {}
    end

    context 'message with hash payload' do
      let(:message) { { data: hash_data, encoding: nil } }

      it 'encodes hash payload data as json' do
        expect(message[:data]).to eql(hash_string_data)
      end

      it 'adds the encoding' do
        expect(message[:encoding]).to eql('json')
      end
    end

    context 'message with hash payload and underscore case keys' do
      let(:message) { { data: { key_id: 'test' }, encoding: nil } }

      it 'encodes hash payload data as json and leaves underscore case in tact' do
        expect(message[:data]).to eql('{"key_id":"test"}')
      end

      it 'adds the encoding' do
        expect(message[:encoding]).to eql('json')
      end
    end

    context 'already encoded message with hash payload' do
      let(:message) { { data: hash_data, encoding: 'utf-8' } }

      it 'encodes hash payload data as json' do
        expect(message[:data]).to eql(hash_string_data)
      end

      it 'adds the encoding' do
        expect(message[:encoding]).to eql('utf-8/json')
      end
    end

    context 'message with Array payload' do
      let(:message) { { data: array_data, encoding: nil } }

      it 'encodes Array payload data as json' do
        expect(message[:data]).to eql(array_string_data)
      end

      it 'adds the encoding' do
        expect(message[:encoding]).to eql('json')
      end
    end

    context 'message with UTF-8 payload' do
      let(:message) { { data: hash_string_data, encoding: nil } }

      it 'leaves the message data intact' do
        expect(message[:data]).to eql(hash_string_data)
      end

      it 'leaves the encoding intact' do
        expect(message[:encoding]).to be_nil
      end
    end

    context 'message with nil payload' do
      let(:message) { { data: nil, encoding: nil } }

      it 'leaves the message data intact' do
        expect(message[:data]).to be_nil
      end

      it 'leaves the encoding intact' do
        expect(message[:encoding]).to be_nil
      end
    end

    context 'message with no data payload' do
      let(:message) { { encoding: nil } }

      it 'leaves the message data intact' do
        expect(message[:data]).to be_nil
      end

      it 'leaves the encoding intact' do
        expect(message[:encoding]).to be_nil
      end
    end
  end
end
