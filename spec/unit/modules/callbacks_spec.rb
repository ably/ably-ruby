require 'spec_helper'

describe Ably::Modules::Callbacks do
  let(:options) { {} }
  let(:klass) do
    callback_opts = options
    Class.new do
      extend Ably::Modules::Callbacks
      add_callbacks callback_opts
    end
  end
  let(:obj) { double('example') }
  let(:msg) { double('message') }

  subject { klass.new }

  context 'event fan out' do
    specify do
      expect(obj).to receive(:received_message).with(msg).twice
      2.times do
        subject.on(:message) { |msg| obj.received_message msg }
      end
      subject.trigger :message, msg
    end

    it 'sends only messages to matching event names' do
      expect(obj).to receive(:received_message).with(msg).once
      subject.on(:valid) { |msg| obj.received_message msg }
      subject.trigger :valid, msg
      subject.trigger :ignored, msg
      subject.trigger 'valid', msg
    end

    context 'with coercion' do
      let(:options) do
        { coerce_into: Proc.new { |event| String(event) } }
      end

      it 'calls the provided proc to coerce the event name' do
        expect(obj).to receive(:received_message).with(msg).once
        subject.on('valid') { |msg| obj.received_message msg }
        subject.trigger :valid, msg
      end
    end

    context 'without coercion' do
      it 'only matches event names on type matches' do
        expect(obj).to_not receive(:received_message).with(msg)
        subject.on('valid') { |msg| obj.received_message msg }
        subject.trigger :valid, msg
      end
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
end
