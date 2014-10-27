require 'spec_helper'
require 'support/protocol_msgbus_helper'
require 'support/event_machine_helper'

describe Ably::Realtime::Connection do
  let(:client) { instance_double('Ably::Realtime::Client', logger: double('logger').as_null_object) }

  subject do
    Ably::Realtime::Connection.new(client)
  end

  before do
    expect(EventMachine::Timer).to receive(:new)
    expect(EventMachine).to receive(:next_tick)
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

  it_behaves_like 'an incoming protocol message bus'
  it_behaves_like 'an outgoing protocol message bus'
end
