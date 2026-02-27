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
  end

  context '#ack_messages' do
    let(:dispatcher) { subject }
    let(:logger) { instance_double('Logger') }

    before do
      allow(dispatcher).to receive(:logger).and_return(logger)
      allow(logger).to receive(:debug)
    end

    context 'with a regular message (no action)' do
      let(:message) do
        msg = Ably::Models::Message.new(name: 'test', data: 'hello')
        # SafeDeferrable is included when Realtime is loaded
        msg
      end

      it 'succeeds the message with itself' do
        succeeded = false
        message.callback do |result|
          expect(result).to be(message)
          succeeded = true
        end

        dispatcher.send(:ack_messages, [message])
        expect(succeeded).to be(true)
      end
    end

    context 'with a MESSAGE_UPDATE action and publish_result' do
      let(:message) do
        Ably::Models::Message.new(
          name: 'test',
          data: 'updated',
          serial: 'msg-serial-001',
          action: Ably::Models::Message::ACTION.MessageUpdate.to_i
        )
      end
      let(:publish_result) { { 'serials' => ['version-serial-abc'] } }

      it 'succeeds with an UpdateDeleteResult' do
        succeeded = false
        message.callback do |result|
          expect(result).to be_a(Ably::Models::UpdateDeleteResult)
          expect(result.version_serial).to eql('version-serial-abc')
          succeeded = true
        end

        dispatcher.send(:ack_messages, [message], publish_result)
        expect(succeeded).to be(true)
      end
    end

    context 'with a MESSAGE_UPDATE action but no publish_result' do
      let(:message) do
        Ably::Models::Message.new(
          name: 'test',
          serial: 'msg-serial-001',
          action: Ably::Models::Message::ACTION.MessageUpdate.to_i
        )
      end

      it 'succeeds the message with itself (fallback)' do
        succeeded = false
        message.callback do |result|
          expect(result).to be(message)
          succeeded = true
        end

        dispatcher.send(:ack_messages, [message])
        expect(succeeded).to be(true)
      end
    end

    context 'with multiple update messages and a publish_result with multiple serials' do
      let(:message1) do
        Ably::Models::Message.new(
          name: 'test1',
          serial: 'serial-1',
          action: Ably::Models::Message::ACTION.MessageUpdate.to_i
        )
      end
      let(:message2) do
        Ably::Models::Message.new(
          name: 'test2',
          serial: 'serial-2',
          action: Ably::Models::Message::ACTION.MessageUpdate.to_i
        )
      end
      let(:publish_result) { { 'serials' => ['vs-aaa', 'vs-bbb'] } }

      it 'assigns the correct version serial to each message by index' do
        results = []
        message1.callback { |r| results << r }
        message2.callback { |r| results << r }

        dispatcher.send(:ack_messages, [message1, message2], publish_result)

        expect(results.length).to eql(2)
        expect(results[0]).to be_a(Ably::Models::UpdateDeleteResult)
        expect(results[0].version_serial).to eql('vs-aaa')
        expect(results[1]).to be_a(Ably::Models::UpdateDeleteResult)
        expect(results[1].version_serial).to eql('vs-bbb')
      end
    end

    context 'with symbol-keyed publish_result' do
      let(:message) do
        Ably::Models::Message.new(
          name: 'test',
          serial: 'msg-serial-001',
          action: Ably::Models::Message::ACTION.MessageUpdate.to_i
        )
      end
      let(:publish_result) { { serials: ['vs-sym'] } }

      it 'handles symbol keys for serials' do
        succeeded = false
        message.callback do |result|
          expect(result).to be_a(Ably::Models::UpdateDeleteResult)
          expect(result.version_serial).to eql('vs-sym')
          succeeded = true
        end

        dispatcher.send(:ack_messages, [message], publish_result)
        expect(succeeded).to be(true)
      end
    end

    context 'with a regular message and publish_result (PublishResult)' do
      let(:message) do
        Ably::Models::Message.new(name: 'test', data: 'hello')
      end
      let(:publish_result) { { 'serials' => ['pub-serial-001'] } }

      it 'succeeds with a PublishResult' do
        succeeded = false
        message.callback do |result|
          expect(result).to be_a(Ably::Models::PublishResult)
          expect(result.serials).to eql(['pub-serial-001'])
          succeeded = true
        end

        dispatcher.send(:ack_messages, [message], publish_result)
        expect(succeeded).to be(true)
      end
    end

    context 'with multiple regular messages and publish_result' do
      let(:message1) { Ably::Models::Message.new(name: 'test1', data: 'hello') }
      let(:message2) { Ably::Models::Message.new(name: 'test2', data: 'world') }
      let(:publish_result) { { 'serials' => ['ser-aaa', 'ser-bbb'] } }

      it 'assigns the correct serial to each message by index' do
        results = []
        message1.callback { |r| results << r }
        message2.callback { |r| results << r }

        dispatcher.send(:ack_messages, [message1, message2], publish_result)

        expect(results.length).to eql(2)
        expect(results[0]).to be_a(Ably::Models::PublishResult)
        expect(results[0].serials).to eql(['ser-aaa'])
        expect(results[1]).to be_a(Ably::Models::PublishResult)
        expect(results[1].serials).to eql(['ser-bbb'])
      end
    end

    context 'with a regular message and symbol-keyed publish_result' do
      let(:message) { Ably::Models::Message.new(name: 'test', data: 'hello') }
      let(:publish_result) { { serials: ['sym-serial'] } }

      it 'handles symbol keys for serials' do
        succeeded = false
        message.callback do |result|
          expect(result).to be_a(Ably::Models::PublishResult)
          expect(result.serials).to eql(['sym-serial'])
          succeeded = true
        end

        dispatcher.send(:ack_messages, [message], publish_result)
        expect(succeeded).to be(true)
      end
    end

    context 'with presence messages' do
      let(:presence_message) do
        Ably::Models::PresenceMessage.new(action: :enter, client_id: 'user1')
      end

      it 'succeeds with the message itself (no publish_result handling)' do
        succeeded = false
        presence_message.callback do |result|
          expect(result).to be(presence_message)
          succeeded = true
        end

        dispatcher.send(:ack_messages, [presence_message])
        expect(succeeded).to be(true)
      end
    end
  end
end
