require 'spec_helper'

describe Ably::Realtime::Client, '#stats', :event_machine do
  vary_by_protocol do
    let(:client) do
      Ably::Realtime::Client.new(key: api_key, environment: environment, protocol: protocol)
    end

    describe 'fetching stats' do
      it 'should return a PaginatedResource' do
        client.stats do |stats|
          expect(stats).to be_a(Ably::Models::PaginatedResource)
          stop_reactor
        end
      end

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        expect(client.stats).to be_a(Ably::Util::SafeDeferrable)
        stop_reactor
      end
    end
  end
end
