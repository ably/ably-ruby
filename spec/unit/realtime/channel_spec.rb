# encoding: utf-8
require 'spec_helper'
require 'support/protocol_msgbus_helper'

describe Ably::Realtime::Channel do
  let(:client)       { double('client').as_null_object }
  let(:channel_name) { 'test' }

  subject do
    Ably::Realtime::Channel.new(client, channel_name)
  end

  describe '#initializer' do
    context 'as UTF_8 string' do
      let(:channel_name) { random_str.force_encoding(Encoding::UTF_8) }

      it 'is permitted' do
        expect(subject.name).to eql(channel_name)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:channel_name) { random_str.force_encoding(Encoding::SHIFT_JIS) }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as ASCII_8BIT string' do
      let(:channel_name) { random_str.force_encoding(Encoding::ASCII_8BIT) }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:channel_name) { 1 }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:channel_name) { nil }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end

  describe '#publish name argument' do
    let(:value) { random_str }

    before do
      allow(subject).to receive(:create_message).and_return('message_stubbed')
    end

    context 'as UTF_8 string' do
      let(:encoded_value) { value.force_encoding(Encoding::UTF_8) }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to eql('message_stubbed')
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoded_value) { value.force_encoding(Encoding::SHIFT_JIS) }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoded_value) { value.force_encoding(Encoding::ASCII_8BIT) }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:encoded_value) { 1 }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError
      end
    end
  end

  describe 'callbacks' do
    specify 'are supported for valid STATE events' do
      state = nil
      subject.on(:initialized) { state = :ready }
      expect { subject.trigger(:initialized) }.to change { state }.to(:ready)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { subject.on(:invalid) }.to raise_error KeyError
      expect { subject.trigger(:invalid) }.to raise_error KeyError
      expect { subject.off(:invalid) }.to raise_error KeyError
    end
  end

  context 'msgbus' do
    let(:message) do
      Ably::Models::Message.new({
        'name' => 'test',
        'data' => 'payload'
      }, instance_double('Ably::Models::ProtocolMessage'))
    end
    let(:msgbus) { subject.__incoming_msgbus__ }

    specify 'supports messages' do
      received = 0
      msgbus.subscribe(:message) { received += 1 }
      expect { msgbus.publish(:message, message) }.to change { received }.to(1)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { msgbus.subscribe(:invalid) }.to raise_error KeyError
      expect { msgbus.publish(:invalid) }.to raise_error KeyError
      expect { msgbus.unsubscribe(:invalid) }.to raise_error KeyError
    end
  end

  context 'subscriptions' do
    let(:message_history) { Hash.new { |hash, key| hash[key] = 0 } }
    let(:event_name) { 'click' }
    let(:message) { instance_double('Ably::Models::Message', name: event_name, encode: nil, decode: nil) }

    context '#subscribe' do
      specify 'to all events' do
        subject.subscribe { |message| message_history[:received] += 1}
        subject.__incoming_msgbus__.publish(:message, message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'to specific events' do
        subject.subscribe(event_name) { |message| message_history[:received] += 1 }
        subject.subscribe('move')  { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:message, message)
        expect(message_history[:received]).to eql(1)
      end
    end

    context '#unsubscribe' do
      let(:callback) do
        Proc.new { |message| message_history[:received] += 1 }
      end
      before do
        subject.subscribe(event_name, &callback)
      end

      specify 'to all events' do
        subject.unsubscribe &callback
        subject.__incoming_msgbus__.publish(:message, message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'to specific events' do
        subject.unsubscribe event_name, &callback
        subject.__incoming_msgbus__.publish(:message, message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'to specific non-matching events' do
        subject.unsubscribe 'move', &callback
        subject.__incoming_msgbus__.publish(:message, message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'all callbacks by not providing a callback' do
        subject.unsubscribe event_name
        subject.__incoming_msgbus__.publish(:message, message)
        expect(message_history[:received]).to eql(0)
      end
    end
  end
end
