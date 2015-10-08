require 'spec_helper'

describe Ably::Realtime::Client, '#stats', :event_machine do
  vary_by_protocol do
    let(:client) do
      auto_close Ably::Realtime::Client.new(key: api_key, environment: environment, protocol: protocol)
    end

    describe 'fetching stats' do
      it 'returns a PaginatedResult' do
        client.stats do |stats|
          expect(stats).to be_a(Ably::Models::PaginatedResult)
          stop_reactor
        end
      end

      context 'with options' do
        let(:options) { { arbitrary: random_str } }

        it 'passes the option arguments to the REST stat method' do
          expect(client.rest_client).to receive(:stats).with(options)

          client.stats(options) do |stats|
            stop_reactor
          end
        end
      end

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        expect(client.stats).to be_a(Ably::Util::SafeDeferrable)
        stop_reactor
      end
    end
  end
end
