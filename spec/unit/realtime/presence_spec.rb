# encoding: utf-8
require 'spec_helper'
require 'support/protocol_msgbus_helper'

describe Ably::Realtime::Presence do
  let(:channel) { double('Ably::Realtime::Channel').as_null_object }

  subject do
    Ably::Realtime::Presence.new(channel)
  end

  describe 'callbacks' do
    specify 'are supported for valid STATE events' do
      state = nil
      subject.on(:initialized) { state = :entered }
      expect { subject.trigger(:initialized) }.to change { state }.to(:entered)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { subject.on(:invalid) }.to raise_error KeyError
      expect { subject.trigger(:invalid) }.to raise_error KeyError
      expect { subject.off(:invalid) }.to raise_error KeyError
    end
  end

  context 'msgbus' do
    let(:message) do
      Ably::Models::PresenceMessage.new({
        'action' => 0,
        'member_id' => SecureRandom.hex.force_encoding(Encoding::UTF_8),
      }, instance_double('Ably::Models::ProtocolMessage'))
    end
    let(:msgbus) { subject.__incoming_msgbus__ }

    specify 'supports messages' do
      received = 0
      msgbus.subscribe(:presence) { received += 1 }
      expect { msgbus.publish(:presence, message) }.to change { received }.to(1)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { msgbus.subscribe(:invalid) }.to raise_error KeyError
      expect { msgbus.publish(:invalid) }.to raise_error KeyError
      expect { msgbus.unsubscribe(:invalid) }.to raise_error KeyError
    end
  end

  context 'subscriptions' do
    let(:message_history) { Hash.new { |hash, key| hash[key] = 0 } }
    let(:presence_action) { Ably::Models::PresenceMessage::ACTION.Enter }
    let(:message) do
      instance_double('Ably::Models::PresenceMessage', action: presence_action, member_id: SecureRandom.hex, decode: true)
    end

    context '#subscribe' do
      specify 'to all presence state actions' do
        subject.subscribe { |message| message_history[:received] += 1}
        subject.__incoming_msgbus__.publish(:presence, message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'to specific presence state actions' do
        subject.subscribe(presence_action) { |message| message_history[:received] += 1 }
        subject.subscribe(:leave)  { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:presence, message)
        expect(message_history[:received]).to eql(1)
      end
    end

    context '#unsubscribe' do
      let(:callback) do
        Proc.new { |message| message_history[:received] += 1 }
      end
      before do
        subject.subscribe(presence_action, &callback)
      end

      specify 'to all presence state actions' do
        subject.unsubscribe &callback
        subject.__incoming_msgbus__.publish(:presence, message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'to specific presence state actions' do
        subject.unsubscribe presence_action, &callback
        subject.__incoming_msgbus__.publish(:presence, message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'to specific non-matching presence state actions' do
        subject.unsubscribe :leave, &callback
        subject.__incoming_msgbus__.publish(:presence, message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'all callbacks by not providing a callback' do
        subject.unsubscribe presence_action
        subject.__incoming_msgbus__.publish(:presence, message)
        expect(message_history[:received]).to eql(0)
      end
    end
  end
end
