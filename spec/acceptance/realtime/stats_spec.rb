require 'spec_helper'

describe 'Ably::Realtime::Client stats' do
  include RSpec::EventMachine

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:client) do
        Ably::Realtime::Client.new(api_key: api_key, environment: environment, protocol: protocol)
      end

      describe 'fetching stats' do
        it 'should return a Hash' do
          run_reactor do
            client.stats do |stats|
              expect(stats).to be_a(Array)
              stop_reactor
            end
          end
        end

        it 'should return a deferrable object' do
          run_reactor do
            expect(client.stats).to be_a(EventMachine::Deferrable)
            stop_reactor
          end
        end
      end
    end
  end
end
