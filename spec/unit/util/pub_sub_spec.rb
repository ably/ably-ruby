require 'spec_helper'

describe Ably::Util::PubSub do
  let(:options) { {} }
  let(:obj) { double('example') }
  let(:msg) { double('message') }

  subject { Ably::Util::PubSub.new(options) }

  context 'event fan out' do
    specify '#publish allows publishing to more than on subscriber' do
      expect(obj).to receive(:received_message).with(msg).twice
      2.times do
        subject.subscribe(:message) { |msg| obj.received_message msg }
      end
      subject.publish :message, msg
    end

    it '#publish sends only messages to #subscribe callbacks matching event names' do
      expect(obj).to receive(:received_message).with(msg).once
      subject.subscribe(:valid) { |msg| obj.received_message msg }
      subject.publish :valid, msg
      subject.publish :ignored, msg
      subject.publish 'valid', msg
    end

    context 'with coercion', api_private: true do
      let(:options) do
        { coerce_into: lambda { |event| String(event) } }
      end

      it 'calls the provided proc to coerce the event name' do
        expect(obj).to receive(:received_message).with(msg).once
        subject.subscribe('valid') { |msg| obj.received_message msg }
        subject.publish :valid, msg
      end

      context 'and two different configurations but sharing the same class' do
        let!(:exception_pubsub) { Ably::Util::PubSub.new(coerce_into: lambda { |event| raise KeyError }) }

        it 'does not share state' do
          expect(obj).to receive(:received_message).with(msg).once
          subject.subscribe('valid') { |msg| obj.received_message msg }
          subject.publish :valid, msg

          expect { exception_pubsub.publish :fail }.to raise_error KeyError
        end
      end
    end

    context 'without coercion', api_private: true do
      it 'only matches event names on type matches' do
        expect(obj).to_not receive(:received_message).with(msg)
        subject.subscribe('valid') { |msg| obj.received_message msg }
        subject.publish :valid, msg
      end
    end
  end

  context '#unsubscribe' do
    let(:callback) { lambda { |msg| obj.received_message msg } }

    before do
      subject.subscribe(:message, &callback)
    end

    after do
      subject.publish :message, msg
    end

    it 'deletes matching callbacks' do
      expect(obj).to_not receive(:received_message).with(msg)
      subject.unsubscribe(:message, &callback)
    end

    it 'deletes all callbacks if not block given' do
      expect(obj).to_not receive(:received_message).with(msg)
      subject.unsubscribe(:message)
    end

    it 'continues if the block does not exist' do
      expect(obj).to receive(:received_message).with(msg)
      subject.unsubscribe(:message) { true }
    end
  end
end
