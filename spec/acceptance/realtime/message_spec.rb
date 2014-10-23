require 'spec_helper'
require 'securerandom'

describe 'Ably::Realtime::Channel Messages' do
  include RSpec::EventMachine

  let(:client) do
    Ably::Realtime::Client.new(options.merge(api_key: api_key, environment: environment))
  end
  let(:options) { {} }

  skip 'sends a string messaging using a binary protocol'

  context 'using text protocol' do
    let(:channel_name) { 'subscribe_send_text' }
    let(:options) { { :protocol => :json } }
    let(:payload) { 'Test message (subscribe_send_text)' }

    it 'send a string message' do
      run_reactor do
        channel = client.channel(channel_name)
        channel.attach
        channel.on(:attached) do
          channel.publish('test_event', payload) do |message|
            expect(message.data).to eql(payload)
            stop_reactor
          end
        end
      end
    end
  end
end
