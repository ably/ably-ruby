require 'spec_helper'

describe Ably::Realtime::Client, '#time', :event_machine do
  vary_by_protocol do
    let(:client) do
      auto_close Ably::Realtime::Client.new(key: api_key, environment: environment, protocol: protocol)
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

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        run_reactor do
          expect(client.time).to be_a(Ably::Util::SafeDeferrable)
          stop_reactor
        end
      end

      context 'with reconfigured HTTP timeout' do
        let(:client) do
          auto_close Ably::Realtime::Client.new(http_request_timeout: 0.0001, key: api_key, environment: environment, protocol: protocol, log_level: :fatal)
        end

        it 'should raise a timeout exception' do
          client.time.errback do |error|
            expect(error).to be_a Ably::Exceptions::ConnectionTimeout
            stop_reactor
          end
        end
      end
    end
  end
end
