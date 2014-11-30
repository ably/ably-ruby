require 'spec_helper'
require 'support/protocol_msgbus_helper'

describe Ably::Realtime::Connection::WebsocketTransport do
  let(:client_ignored) { double('Ably::Realtime::Client').as_null_object }
  let(:connection) { instance_double('Ably::Realtime::Connection', client: client_ignored, id: nil) }

  let(:websocket_transport_without_eventmachine) do
    Ably::Realtime::Connection::WebsocketTransport.send(:allocate).tap do |websocket_transport|
      websocket_transport.send(:initialize, connection)
    end
  end

  before do
    allow(Ably::Realtime::Connection::WebsocketTransport).to receive(:new).with(connection).and_return(websocket_transport_without_eventmachine)
  end

  subject do
    Ably::Realtime::Connection::WebsocketTransport.new(connection)
  end

  it_behaves_like 'an incoming protocol message bus'
  it_behaves_like 'an outgoing protocol message bus'
end
