require 'spec_helper'

describe Ably::Realtime::Client, '#stats', :event_machine do
  vary_by_protocol do
    let(:client) do
      Ably::Realtime::Client.new(api_key: api_key, environment: environment, protocol: protocol)
    end

    describe 'fetching stats' do
      it 'should return a Hash' do
        client.stats do |stats|
          expect(stats).to be_a(Array)
          stop_reactor
        end
      end

      it 'should return a Deferrable object' do
        expect(client.stats).to be_a(EventMachine::Deferrable)
        stop_reactor
      end
    end
  end
end
