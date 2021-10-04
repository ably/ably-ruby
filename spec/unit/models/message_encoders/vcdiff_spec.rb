require 'spec_helper'

require 'ably/models/message_encoders/vcdiff'

describe Ably::Models::MessageEncoders::Vcdiff do
  let(:string_ascii)        { 'string'.encode(Encoding::ASCII_8BIT) }
  let(:string_utf8)         { 'string'.encode(Encoding::UTF_8) }

  let(:client)              { instance_double('Ably::Realtime::Client') }

  subject { Ably::Models::MessageEncoders::Vcdiff.new(client) }

  describe '#decode' do
    context 'vcdiff encoding' do
      let(:message) { { data: string_ascii, encoding: 'vcdiff' } }

      context 'no vcdiff plugin was set' do
        it 'should raise an exception' do
          expect { subject.decode(message, {}) }.to raise_error(Ably::Exceptions::VcdiffError)
          expect { subject.decode(message, { plugins: nil }) }.to raise_error(Ably::Exceptions::VcdiffError)
        end
      end

      context 'vcdiff plugin was set' do
        let(:channel_options) { { plugins: { vcdiff: Plugin } } }

        class Plugin
          def self.decode(message, base)
            'vcdiff'
          end
        end

        it 'should run vcdiff.decode function' do
          expect do
            data = subject.decode(message, channel_options)
            expect(message[:data]).to eq(data)
            expect(channel_options[:base_encoded_previous_payload]).to eq(data)
          end.to change { message[:data] }.to('vcdiff')
        end
      end
    end
  end
end
