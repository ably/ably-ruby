# encoding: utf-8
require 'spec_helper'
require 'shared/protocol_msgbus_behaviour'

describe Ably::Realtime::Channel do
  let(:client)       { double('client').as_null_object }
  let(:channel_name) { 'test' }

  subject do
    Ably::Realtime::Channel.new(client, channel_name)
  end

  describe '#initializer' do
    let(:channel_name) { random_str.encode(encoding) }

    context 'as UTF_8 string' do
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.name).to eql(channel_name)
      end

      it 'remains as UTF-8' do
        expect(subject.name.encoding).to eql(encoding)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoding) { Encoding::SHIFT_JIS }

      it 'gets converted to UTF-8' do
        expect(subject.name.encoding).to eql(Encoding::UTF_8)
      end

      it 'is compatible with original encoding' do
        expect(subject.name.encode(encoding)).to eql(channel_name)
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoding) { Encoding::ASCII_8BIT }

      it 'gets converted to UTF-8' do
        expect(subject.name.encoding).to eql(Encoding::UTF_8)
      end

      it 'is compatible with original encoding' do
        expect(subject.name.encode(encoding)).to eql(channel_name)
      end
    end

    context 'as Integer' do
      let(:channel_name) { 1 }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError, /must be a String/
      end
    end

    context 'as Nil' do
      let(:channel_name) { nil }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError, /must be a String/
      end
    end
  end

  describe '#publish name argument' do
    let(:encoded_value) { random_str.encode(encoding) }
    let(:message) { instance_double('Ably::Models::Message', client_id: nil) }

    before do
      allow(subject).to receive(:create_message).and_return(message)
      allow(subject).to receive(:attach).and_return(:true)
    end

    context 'as UTF_8 string' do
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to eql(message)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoding) { Encoding::SHIFT_JIS }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to eql(message)
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoding) { Encoding::ASCII_8BIT }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to eql(message)
      end
    end

    context 'as Integer' do
      let(:encoded_value) { 1 }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError, /must be a String/
      end
    end

    context 'as Nil' do
      let(:encoded_value) { nil }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to eql(message)
      end
    end
  end

  describe 'callbacks' do
    specify 'are supported for valid STATE events' do
      state = nil
      subject.on(:initialized) { state = :ready }
      expect { subject.emit(:initialized) }.to change { state }.to(:ready)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { subject.on(:invalid) }.to raise_error KeyError
      expect { subject.emit(:invalid) }.to raise_error KeyError
      expect { subject.off(:invalid) }.to raise_error KeyError
    end
  end

  context 'msgbus', :api_private do
    let(:message) do
      Ably::Models::Message.new({
        'name' => 'test',
        'data' => 'payload'
      }, protocol_message: instance_double('Ably::Models::ProtocolMessage'))
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
    let(:click_event) { 'click' }
    let(:click_message) { instance_double('Ably::Models::Message', name: click_event, encode: nil, decode: nil) }
    let(:focus_event) { 'focus' }
    let(:focus_message) { instance_double('Ably::Models::Message', name: focus_event, encode: nil, decode: nil) }
    let(:blur_message) { instance_double('Ably::Models::Message', name: 'blur', encode: nil, decode: nil) }

    context '#subscribe' do
      before do
        allow(subject).to receive(:attach).and_return(:true)
      end

      specify 'without a block raises an invalid ArgumentError' do
        expect { subject.subscribe }.to raise_error ArgumentError
      end

      specify 'with no event name specified subscribes the provided block to all events' do
        subject.subscribe { |message| message_history[:received] += 1}
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'with a single event name subscribes that block to matching events' do
        subject.subscribe(click_event) { |message| message_history[:received] += 1 }
        subject.subscribe('non_match_move')  { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'with a multiple event name arguments subscribes that block to all of those event names' do
        subject.subscribe(focus_event, click_event) { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(1)
        subject.__incoming_msgbus__.publish(:message, focus_message)
        expect(message_history[:received]).to eql(2)

        # Blur does not match subscribed focus & click events
        subject.__incoming_msgbus__.publish(:message, blur_message)
        expect(message_history[:received]).to eql(2)
      end

      specify 'with a multiple duplicate event name arguments subscribes that block to all of those unique event names once' do
        subject.subscribe(click_event, click_event) { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(1)
      end
    end

    context '#unsubscribe' do
      let(:callback) do
        lambda { |message| message_history[:received] += 1 }
      end

      before do
        allow(subject).to receive(:attach).and_return(:true)
        subject.subscribe click_event, &callback
      end

      specify 'with no event name specified unsubscribes that block from all events' do
        subject.unsubscribe(&callback)
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'with a single event name argument unsubscribes the provided block with the matching event name' do
        subject.unsubscribe(click_event, &callback)
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'with multiple event name arguments unsubscribes each of those matching event names with the provided block' do
        subject.unsubscribe(focus_event, click_event, &callback)
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'with a non-matching event name argument has no effect' do
        subject.unsubscribe('move', &callback)
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'with no block argument unsubscribes all blocks for the event name argument' do
        subject.unsubscribe click_event
        subject.__incoming_msgbus__.publish(:message, click_message)
        expect(message_history[:received]).to eql(0)
      end
    end
  end
end
