require 'spec_helper'

describe Ably::Realtime::Client, '#time', :event_machine do
  vary_by_protocol do
    let(:client) do
      Ably::Realtime::Client.new(api_key: api_key, environment: environment, protocol: protocol)
    end

    describe 'fetching the service time' do
      it 'should return the service time as a Time object' do
        run_reactor do
          client.time do |time|
            expect(time).to be_within(2).of(Time.now)
            stop_reactor
          end
        end
      end

      it 'should return a deferrable object' do
        run_reactor do
          expect(client.time).to be_a(EventMachine::Deferrable)
          stop_reactor
        end
      end
    end
  end
end
