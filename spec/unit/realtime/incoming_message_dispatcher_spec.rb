require 'spec_helper'

describe Ably::Realtime::Client::IncomingMessageDispatcher do
  let(:msgbus) do
    Ably::Util::PubSub.new
  end
  let(:connection) do
    instance_double('Ably::Realtime::Connection', __incoming_protocol_msgbus__: msgbus, update_connection_id: true)
  end
  let(:client) do
    instance_double('Ably::Realtime::Client', channels: {})
  end

  subject { Ably::Realtime::Client::IncomingMessageDispatcher.new(client, connection) }

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
