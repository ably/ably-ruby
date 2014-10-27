require 'spec_helper'
require "support/protocol_msgbus_helper"

describe Ably::Realtime::Channel do
  let(:client) { instance_double('Ably::Realtime::Client') }
  let(:channel_name) { 'test' }

  subject do
    Ably::Realtime::Channel.new(client, channel_name)
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
      Ably::Realtime::Models::Message.new({
        'name' => 'test',
        'data' => 'payload'
      }, instance_double('Ably::Realtime::Models::ProtocolMessage'))
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
end
