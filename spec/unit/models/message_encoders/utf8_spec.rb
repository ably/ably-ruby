require 'spec_helper'

require 'ably/models/message_encoders/utf8'

describe Ably::Models::MessageEncoders::Utf8 do
  let(:string_ascii)        { 'string'.encode(Encoding::ASCII_8BIT) }
  let(:string_utf8)         { 'string'.encode(Encoding::UTF_8) }

  let(:client)              { instance_double('Ably::Realtime::Client') }

  subject { Ably::Models::MessageEncoders::Utf8.new(client) }

  context '#decode' do
    before do
      subject.decode message, {}
    end

    context 'message with utf8 payload' do
      let(:message) { { data: string_ascii, encoding: 'utf-8' } }

      it 'sets the encoding' do
        expect(message[:data]).to eq(string_utf8)
        expect(message[:data].encoding).to eql(Encoding::UTF_8)
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to be_nil
      end
    end

    context 'message with utf8 payload before other payloads' do
      let(:message) { { data: string_utf8, encoding: 'json/utf-8' } }

      it 'sets the encoding' do
        expect(message[:data]).to eql(string_utf8)
        expect(message[:data].encoding).to eql(Encoding::UTF_8)
      end

      it 'strips the encoding' do
        expect(message[:encoding]).to eql('json')
      end
    end

    context 'message with another payload' do
      let(:message) { { data: string_ascii, encoding: 'json' } }

      it 'leaves the message data intact' do
        expect(message[:data]).to eql(string_ascii)
      end

      it 'leaves the encoding intact' do
        expect(message[:encoding]).to eql('json')
      end
    end
  end
end
