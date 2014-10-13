require 'spec_helper'

describe Ably::Realtime::Client::MessageDispatcher do
  let(:msgbus) do
    Ably::Util::PubSub.new
  end
  let(:client) do
    double(:client,
      connection: double('connection', __protocol_msgbus__: msgbus),
      channels: {}
    )
  end

  subject { Ably::Realtime::Client::MessageDispatcher.new(client) }

  context '#initialize' do
    it 'should subscribe to protocol messages from the connection' do
      expect(msgbus).to receive(:subscribe).with(:message).and_call_original
      subject
    end
  end

  context '#dispatch_protocol_message' do
    before { subject }

    it 'should raise an exception if a message is sent that is not a ProtocolMessage' do
      expect { msgbus.publish :message, nil }.to raise_error ArgumentError
    end

    it 'should warn if a message is received for a non-existent channel' do
      allow(subject).to receive_message_chain(:logger, :debug)
      expect(subject).to receive_message_chain(:logger, :warn)
      msgbus.publish :message, Ably::Realtime::Models::ProtocolMessage.new(:action => :attached, channel: 'unknown')
    end
  end
end
