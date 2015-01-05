require 'spec_helper'
require 'shared/protocol_msgbus_behaviour'

describe Ably::Realtime::Connection::WebsocketTransport, :api_private do
  let(:client_ignored) { double('Ably::Realtime::Client').as_null_object }
  let(:connection)     { instance_double('Ably::Realtime::Connection', client: client_ignored, id: nil) }
  let(:url)            { 'http://ably.io/' }

  let(:websocket_transport_without_eventmachine) do
    Ably::Realtime::Connection::WebsocketTransport.send(:allocate).tap do |websocket_transport|
      websocket_transport.send(:initialize, connection, url)
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
