require 'spec_helper'

describe Ably::Modules::EventEmitter do
  let(:options) { {} }
  let(:klass) do
    callback_opts = options
    Class.new do
      include Ably::Modules::EventEmitter
      configure_event_emitter callback_opts
    end
  end
  let(:obj) { double('example') }
  let(:msg) { double('message') }

  subject { klass.new }

  context 'event fan out' do
    specify do
      2.times do
        subject.on(:message) { |msg| obj.received_message msg }
      end

      expect(obj).to receive(:received_message).with(msg).twice
      subject.trigger :message, msg
    end

    it 'sends only messages to matching event names' do
      subject.on(:valid) { |msg| obj.received_message msg }

      expect(obj).to receive(:received_message).with(msg).once
      subject.trigger :valid, msg
      subject.trigger :ignored, msg
      subject.trigger 'valid', msg
    end

    context 'with coercion' do
      let(:options) do
        { coerce_into: Proc.new { |event| String(event) } }
      end

      it 'calls the provided proc to coerce the event name' do
        subject.on('valid') { |msg| obj.received_message msg }

        expect(obj).to receive(:received_message).with(msg).once
        subject.trigger :valid, msg
      end
    end

    context 'without coercion' do
      it 'only matches event names on type matches' do
        subject.on('valid') { |msg| obj.received_message msg }

        expect(obj).to_not receive(:received_message).with(msg)
        subject.trigger :valid, msg
      end
    end

    context 'subscribe to multiple events' do
      it 'with the same block' do
        subject.on(:click, :hover) { |msg| obj.received_message msg }

        expect(obj).to receive(:received_message).with(msg).twice

        subject.trigger :click, msg
        subject.trigger :hover, msg
      end
    end
  end

  context '#once' do
    it 'calls the block the first time an event is emitted only' do
      block_called = 0
      subject.once('event') { block_called += 1 }
      3.times { subject.trigger 'event', 'data' }
      expect(block_called).to eql(1)
    end

    it 'does not remove other blocks after it is called' do
      block_called = 0
      subject.once('event') { block_called += 1 }
      subject.on('event')   { block_called += 1 }
      3.times { subject.trigger 'event', 'data' }
      expect(block_called).to eql(4)
    end
  end

  context '#off' do
    let(:callback) { Proc.new { |msg| obj.received_message msg } }

    before do
      subject.on(:message, &callback)
    end

    after do
      subject.trigger :message, msg
    end

    context 'with event names as arguments' do
      it 'deletes matching callbacks' do
        expect(obj).to_not receive(:received_message).with(msg)
        subject.off(:message, &callback)
      end

      it 'deletes all callbacks if not block given' do
        expect(obj).to_not receive(:received_message).with(msg)
        subject.off(:message)
      end

      it 'continues if the block does not exist' do
        expect(obj).to receive(:received_message).with(msg)
        subject.off(:message) { true }
      end
    end

    context 'without any event names' do
      it 'deletes all matching callbacks' do
        expect(obj).to_not receive(:received_message).with(msg)
        subject.off(&callback)
      end

      it 'deletes all callbacks if not block given' do
        expect(obj).to_not receive(:received_message).with(msg)
        subject.off
      end
    end
  end
end
