shared_examples 'a protocol message bus' do
  describe '__protocol_msgbus__ PubSub', :api_private do
    let(:protocol_message) do
      Ably::Models::ProtocolMessage.new(
        action: 15,
        channel: 'channel',
        msg_serial: 0,
        messages: []
      )
    end

    specify 'supports valid ProtocolMessage messages' do
      received = 0
      msgbus.subscribe(:protocol_message) { received += 1 }
      expect { msgbus.publish(:protocol_message, protocol_message) }.to change { received }.to(1)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { msgbus.subscribe(:invalid) }.to raise_error KeyError
      expect { msgbus.publish(:invalid) }.to raise_error KeyError
      expect { msgbus.unsubscribe(:invalid) }.to raise_error KeyError
    end
  end
end

shared_examples 'an incoming protocol message bus' do
  it_behaves_like 'a protocol message bus' do
    let(:msgbus) { subject.__incoming_protocol_msgbus__ }
  end
end

shared_examples 'an outgoing protocol message bus' do
  it_behaves_like 'a protocol message bus' do
    let(:msgbus) { subject.__outgoing_protocol_msgbus__ }
  end
end
