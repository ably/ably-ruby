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
        class Plugin
          def self.decode(message, base)
            'vcdiffdata'
          end
        end

        let(:channel_options) { { plugins: { vcdiff: Plugin } } }

        it 'should run vcdiff.decode function' do
          expect do
            subject.decode(message, channel_options)
          end.to change { message[:data] }.to('vcdiffdata')
        end

        context 'last message id is different than message.extras.delta.from' do
          let(:channel_options) { { plugins: { vcdiff: Plugin } } }

          before { message[:extras] = { delta: { from: 'CurrentId' } } }

          it 'should raise the VcdiffError exception' do
            expect do
              subject.decode(message, channel_options.merge(previous_message_id: 'AnotherId'))
            end.to raise_error(Ably::Exceptions::VcdiffError)
          end
        end
      end

      context 'vcdiff plugin does not support decode method' do
        class InvalidPlugin
          # without decode(data, base) method
        end

        let(:channel_options) { { plugins: { vcdiff: InvalidPlugin } } }

        it 'should raise the VcdiffError exception' do
          expect do
            subject.decode(message, channel_options)
          end.to raise_error(Ably::Exceptions::VcdiffError)
        end
      end
    end
  end
end
