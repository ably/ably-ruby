# encoding: utf-8
require 'spec_helper'
require 'shared/protocol_msgbus_behaviour'

describe Ably::Realtime::Presence do
  let(:channel) { double('Ably::Realtime::Channel').as_null_object }

  subject do
    Ably::Realtime::Presence.new(channel)
  end

  describe 'callbacks' do
    specify 'are supported for valid STATE events' do
      state = nil
      subject.on(:initialized) { state = :entered }
      expect { subject.emit(:initialized) }.to change { state }.to(:entered)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { subject.on(:invalid) }.to raise_error KeyError
      expect { subject.emit(:invalid) }.to raise_error KeyError
      expect { subject.off(:invalid) }.to raise_error KeyError
    end
  end

  context 'msgbus', :api_private do
    let(:message) do
      Ably::Models::PresenceMessage.new({
        'action' => 0,
        'connection_id' => random_str,
      }, protocol_message: instance_double('Ably::Models::ProtocolMessage'))
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
    let(:enter_action) { Ably::Models::PresenceMessage::ACTION.Enter }
    let(:clone) { instance_double('Ably::Models::PresenceMessage', member_key: random_str, connection_id: random_str) }
    let(:enter_message) do
      instance_double('Ably::Models::PresenceMessage', action: enter_action, connection_id: random_str, decode: true, member_key: random_str, shallow_clone: clone)
    end
    let(:leave_message) do
      instance_double('Ably::Models::PresenceMessage', action: Ably::Models::PresenceMessage::ACTION.Leave, connection_id: random_str, decode: true, member_key: random_str, shallow_clone: clone)
    end
    let(:update_message) do
      instance_double('Ably::Models::PresenceMessage', action: Ably::Models::PresenceMessage::ACTION.Update, connection_id: random_str, decode: true, member_key: random_str, shallow_clone: clone)
    end

    context '#subscribe' do
      specify 'without a block raises an invalid ArgumentError' do
        expect { subject.subscribe }.to raise_error ArgumentError
      end

      specify 'with no action specified subscribes the provided block to all action' do
        subject.subscribe { |message| message_history[:received] += 1}
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'with a single action argument subscribes that block to matching actions' do
        subject.subscribe(enter_action) { |message| message_history[:received] += 1 }
        subject.subscribe(:leave)  { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'with a multiple action arguments subscribes that block to all of those actions' do
        subject.subscribe(:leave, enter_action) { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(1)
        subject.__incoming_msgbus__.publish(:presence, leave_message)
        expect(message_history[:received]).to eql(2)

        # This message should be ignored as subscribed to :leave and :enter
        subject.__incoming_msgbus__.publish(:presence, update_message)
        expect(message_history[:received]).to eql(2)
      end

      specify 'with a multiple duplicate action arguments subscribes that block to all of those unique actions once' do
        subject.subscribe(enter_action, enter_action) { |message| message_history[:received] += 1 }
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(1)
      end
    end

    context '#unsubscribe' do
      let(:callback) do
        lambda { |message| message_history[:received] += 1 }
      end
      before do
        subject.subscribe(enter_action, &callback)
      end

      specify 'with no action specified unsubscribes that block from all events' do
        subject.unsubscribe(&callback)
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'with a single action argument unsubscribes the provided block with the matching action' do
        subject.unsubscribe(enter_action, &callback)
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'with multiple action arguments unsubscribes each of those matching actions with the provided block' do
        subject.unsubscribe(:update, :leave, enter_action, &callback)
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(0)
      end

      specify 'with a non-matching action argument has no effect' do
        subject.unsubscribe(:leave, &callback)
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(1)
      end

      specify 'with no block argument unsubscribes all blocks for the action argument' do
        subject.unsubscribe(enter_action)
        subject.__incoming_msgbus__.publish(:presence, enter_message)
        expect(message_history[:received]).to eql(0)
      end
    end
  end
end
