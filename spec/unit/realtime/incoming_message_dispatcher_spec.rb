require 'spec_helper'

describe Ably::Realtime::Client::IncomingMessageDispatcher, :api_private do
  let(:msgbus) do
    Ably::Util::PubSub.new
  end
  let(:connection) do
    instance_double('Ably::Realtime::Connection', __incoming_protocol_msgbus__: msgbus, configure_new: true, id: nil, set_connection_confirmed_alive: nil)
  end
  let(:client) do
    instance_double('Ably::Realtime::Client', channels: {})
  end

  subject { Ably::Realtime::Client::IncomingMessageDispatcher.new(client, connection) }

  context '#initialize' do
    it 'should subscribe to protocol messages from the connection' do
      expect(msgbus).to receive(:subscribe).with(:protocol_message).and_call_original
      subject
    end
  end

  context '#dispatch_protocol_message' do
    before { subject }

    it 'should raise an exception if a message is sent that is not a ProtocolMessage' do
      expect { msgbus.publish :protocol_message, nil }.to raise_error ArgumentError
    end

    it 'should warn if a message is received for a non-existent channel' do
      allow(subject).to receive_message_chain(:logger, :debug)
      expect(subject).to receive_message_chain(:logger, :warn)
      msgbus.publish :protocol_message, Ably::Models::ProtocolMessage.new(:action => :attached, channel: 'unknown')
    end

    context 'TO3l8' do
      context 'on action presence' do
        let(:presence) { 101.times.map { { data: 'x' * 655 } } }

        let(:protocol_message) do
          Ably::Models::ProtocolMessage.new(action: :presence, channel: 'default', presence: presence, connection_serial: 123123123)
        end

        it 'should raise a protocol error when message size exceeded 65536 bytes' do
          allow(connection).to receive(:serial).and_return(12312312)
          allow(subject).to receive(:update_connection_recovery_info)
          allow(subject).to receive_message_chain(:logger, :debug)
          allow(subject).to receive_message_chain(:logger, :warn)
          expect(subject).to receive_message_chain(:logger, :fatal)

          msgbus.publish :protocol_message, protocol_message
        end
      end

      context 'on action message' do
        let(:messages) { 101.times.map { { data: 'x' * 655 } } }

        let(:protocol_message) do
          Ably::Models::ProtocolMessage.new(action: :message, channel: 'default', messages: messages, connection_serial: 123123123)
        end

        it 'should raise a protocol error when message size exceeded 65536 bytes' do
          allow(connection).to receive(:serial).and_return(12312312)
          allow(subject).to receive(:update_connection_recovery_info)
          allow(subject).to receive_message_chain(:logger, :debug)
          allow(subject).to receive_message_chain(:logger, :warn)
          expect(subject).to receive_message_chain(:logger, :fatal)

          msgbus.publish :protocol_message, protocol_message
        end
      end
    end
  end
end
