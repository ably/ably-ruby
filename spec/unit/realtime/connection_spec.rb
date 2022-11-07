require 'spec_helper'
require 'shared/protocol_msgbus_behaviour'

describe Ably::Realtime::Connection do
  let(:client) { instance_double('Ably::Realtime::Client', logger: double('logger').as_null_object, recover: nil, endpoint: double('endpoint', host: 'realtime.ably.io'), client_id: '123') }

  subject do
    Ably::Realtime::Connection.new(client, {}).tap do |connection|
      connection.__incoming_protocol_msgbus__.unsubscribe
      connection.__outgoing_protocol_msgbus__.unsubscribe
    end
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
      expect { subject.emit(:initialized) }.to change { state }.to(:ready)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { subject.on(:invalid) }.to raise_error KeyError
      expect { subject.emit(:invalid) }.to raise_error KeyError
      expect { subject.off(:invalid) }.to raise_error KeyError
    end
  end

  it_behaves_like 'an incoming protocol message bus'
  it_behaves_like 'an outgoing protocol message bus'

  describe '#recovery_key' do
    context 'when key is empty' do
      before { allow(subject).to receive(:key).and_return nil }

      it 'should return nil' do
        expect(subject.recovery_key).to be_nil
      end
    end

    context 'when connection is closing' do
      it 'should return nil' do
        allow(subject).to receive(:key).and_return nil
        allow(subject).to receive(:closing?).and_return(true)
        expect(subject.recovery_key).to be_nil
      end
    end

    context 'when connection is closed' do
      it 'should return nil' do
        allow(subject).to receive(:key).and_return 'present'
        allow(subject).to receive(:closing?).and_return(false)
        allow(subject).to receive(:closed?).and_return(true)
        expect(subject.recovery_key).to be_nil
      end
    end

    context 'when connection is failed' do
      it 'should return nil' do
        allow(subject).to receive(:key).and_return 'present'
        allow(subject).to receive(:closing?).and_return(false)
        allow(subject).to receive(:closed?).and_return(false)
        allow(subject).to receive(:failed?).and_return(true)
        expect(subject.recovery_key).to be_nil
      end
    end

    context 'when connection is suspended' do
      it 'should return nil' do
        allow(subject).to receive(:key).and_return 'present'
        allow(subject).to receive(:closing?).and_return(false)
        allow(subject).to receive(:closed?).and_return(false)
        allow(subject).to receive(:failed?).and_return(false)
        allow(subject).to receive(:suspended?).and_return(true)
        expect(subject.recovery_key).to be_nil
      end
    end

    context 'when key is present and connection is not closing/closed/failed/suspended' do
      it 'should return JSON with connectionKey, msgSerial and channelSerials' do
        allow(subject).to receive(:key).and_return 'present'
        allow(subject).to receive(:closing?).and_return(false)
        allow(subject).to receive(:closed?).and_return(false)
        allow(subject).to receive(:failed?).and_return(false)
        allow(subject).to receive(:suspended?).and_return(false)
        allow(subject.client).to receive(:connection).and_return(subject)
        channels = [['channel1', '1234'], ['channel2', '1235'], ['channel3', '1236']]
        allow(subject.client).to receive(:serials).and_return(Hash[channels])
        expect(subject.recovery_key).to eq("{\"connectionKey\":\"present\",\"msgSerial\":0,\"channelSerials\":{\"channel1\":\"1234\",\"channel2\":\"1235\",\"channel3\":\"1236\"}}")
      end
    end
  end

  describe 'connection resume callbacks', api_private: true do
    let(:callbacks) { [] }

    describe '#trigger_resumed' do
      it 'executes the callbacks' do
        subject.on_resume { callbacks << true }
        subject.trigger_resumed
        expect(callbacks.count).to eql(1)
      end
    end

    describe '#on_resume' do
      it 'registers a callback' do
        subject.on_resume { callbacks << true }
        subject.trigger_resumed
        expect(callbacks.count).to eql(1)
      end
    end

    describe '#off_resume' do
      it 'registers a callback' do
        subject.on_resume { callbacks << true }
        additional_proc = lambda { raise 'This should not be called' }
        subject.off_resume(&additional_proc)
        subject.trigger_resumed
        expect(callbacks.count).to eql(1)
      end
    end
  end

  after(:all) do
    sleep 1 # let realtime library shut down any open clients
  end
end
