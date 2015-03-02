require 'spec_helper'
require 'shared/protocol_msgbus_behaviour'

describe Ably::Realtime::Connection do
  let(:client) { instance_double('Ably::Realtime::Client', logger: double('logger').as_null_object) }

  subject do
    Ably::Realtime::Connection.new(client)
  end

  before do
    expect(EventMachine).to receive(:next_tick)  # non_blocking_loop_while for delivery of messages async
    subject.__incoming_protocol_msgbus__.off
    subject.__outgoing_protocol_msgbus__.off
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

  describe 'connection resume callbacks', api_private: true do
    let(:callbacks) { [] }

    describe '#resumed' do
      it 'triggers callbacks' do
        subject.on_resume { callbacks << true }
        subject.resumed
        expect(callbacks.count).to eql(1)
      end
    end

    describe '#on_resume' do
      it 'registers a callback' do
        subject.on_resume { callbacks << true }
        subject.resumed
        expect(callbacks.count).to eql(1)
      end
    end

    describe '#off_resume' do
      it 'registers a callback' do
        subject.on_resume { callbacks << true }
        additional_proc = proc { raise 'This should not be called' }
        subject.off_resume &additional_proc
        subject.resumed
        expect(callbacks.count).to eql(1)
      end
    end
  end
end
