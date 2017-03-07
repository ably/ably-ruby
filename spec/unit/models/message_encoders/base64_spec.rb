require 'spec_helper'
require 'base64'
require 'msgpack'

require 'ably/models/message_encoders/base64'

describe Ably::Models::MessageEncoders::Base64 do
  let(:decoded_data)        { random_str(32) }
  let(:base64_data)         { Base64.encode64(decoded_data) }
  let(:binary_data)         { MessagePack.pack(decoded_data) }
  let(:base64_binary_data)  { Base64.encode64(binary_data) }
  let(:client)              { instance_double('Ably::Realtime::Client') }

  subject { Ably::Models::MessageEncoders::Base64.new(client) }

  context '#decode' do
    before do
      subject.decode message, {}
    end

    context 'message with base64 payload' do
      let(:message) { { data: base64_data, encoding: 'base64' } }

      it 'decodes base64' do
        expect(message[:data]).to eql(decoded_data)
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to be_nil
      end
    end

    context 'message with base64 payload before other payloads' do
      let(:message) { { data: base64_data, encoding: 'utf-8/base64' } }

      it 'decodes base64' do
        expect(message[:data]).to eql(decoded_data)
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to eql('utf-8')
      end
    end

    context 'message with another payload' do
      let(:message) { { data: decoded_data, encoding: 'utf-8' } }

      it 'leaves the message data intact' do
        expect(message[:data]).to eql(decoded_data)
      end

      it 'leaves the encoding intact' do
        expect(message[:encoding]).to eql('utf-8')
      end
    end
  end

  context '#encode' do
    context 'over binary transport' do
      subject { Ably::Models::MessageEncoders::Base64.new(client, binary_protocol: true) }

      before do
        subject.encode message, {}
      end

      context 'message with binary payload' do
        let(:message) { { data: binary_data, encoding: nil } }

        it 'leaves the message data intact as Base64 encoding is not necessary' do
          expect(message[:data]).to eql(binary_data)
        end

        it 'leaves the encoding intact' do
          expect(message[:encoding]).to eql(nil)
        end
      end

      context 'already encoded message with binary payload' do
        let(:message) { { data: binary_data, encoding: 'cipher' } }

        it 'leaves the message data intact as Base64 encoding is not necessary' do
          expect(message[:data]).to eql(binary_data)
        end

        it 'leaves the encoding intact' do
          expect(message[:encoding]).to eql('cipher')
        end
      end

      context 'message with UTF-8 payload' do
        let(:message) { { data: decoded_data, encoding: nil } }

        it 'leaves the data intact' do
          expect(message[:data]).to eql(decoded_data)
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

      context 'message with empty binary string payload' do
        let(:message) { { data: ''.encode(Encoding::ASCII_8BIT), encoding: nil } }

        it 'leaves the message data intact' do
          expect(message[:data]).to eql('')
        end

        it 'leaves the encoding intact' do
          expect(message[:encoding]).to be_nil
        end
      end
    end

    context 'over text transport' do
      before do
        allow(client).to receive(:protocol_binary?).and_return(false)
        subject.encode message, {}
      end

      context 'message with binary payload' do
        let(:message) { { data: binary_data, encoding: nil } }

        it 'encodes binary data as base64' do
          expect(message[:data]).to eql(base64_binary_data)
        end

        it 'adds the encoding' do
          expect(message[:encoding]).to eql('base64')
        end
      end

      context 'already encoded message with binary payload' do
        let(:message) { { data: binary_data, encoding: 'cipher' } }

        it 'encodes binary data as base64' do
          expect(message[:data]).to eql(base64_binary_data)
        end

        it 'adds the encoding' do
          expect(message[:encoding]).to eql('cipher/base64')
        end
      end

      context 'message with UTF-8 payload' do
        let(:message) { { data: decoded_data, encoding: nil } }

        it 'leaves the data intact' do
          expect(message[:data]).to eql(decoded_data)
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
    end
  end
end
