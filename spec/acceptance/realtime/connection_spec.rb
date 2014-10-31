require 'spec_helper'

describe Ably::Realtime::Connection do
  include RSpec::EventMachine

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:client) do
        Ably::Realtime::Client.new(api_key: api_key, environment: environment, protocol: protocol)
      end

      subject { client.connection }

      it 'connects automatically' do
        run_reactor do
          subject.on(:connected) do
            expect(subject.state).to eq(:connected)
            stop_reactor
          end
        end
      end

      context 'initialization phases' do
        let(:phases) { [:initialized, :connecting, :connected] }
        let(:events_triggered) { [] }

        it 'are triggered in order' do
          test_expectation = Proc.new do
            expect(events_triggered).to eq(phases)
            stop_reactor
          end

          run_reactor do
            phases.each do |phase|
              subject.on(phase) do
                events_triggered << phase
                test_expectation.call if events_triggered.length == phases.length
              end
            end
          end
        end
      end

      skip '#closed disconnects and closes the connection once timeout is reached'

      specify '#closed disconnects and closes the connection gracefully' do
        run_reactor(8) do
          subject.close
          subject.on(:closed) do
            expect(subject.state).to eq(:closed)
            stop_reactor
          end
        end
      end

      it 'receives a heart beat' do
        run_reactor(20) do
          subject.on(:connected) do
            subject.__incoming_protocol_msgbus__.subscribe(:message) do |protocol_message|
              if protocol_message.action == :heartbeat
                expect(protocol_message.action).to eq(:heartbeat)
                stop_reactor
              end
            end
          end
        end
      end

      skip 'connects, closes gracefully and reconnects on #connect'

      it 'connects, closes then connection when timeout is reaached and reconnects on #connect' do
        run_reactor(15) do
          subject.connect do
            connection_id = subject.id
            subject.close do
              subject.connect do
                expect(subject.id).to_not eql(connection_id)
                stop_reactor
              end
            end
          end
        end
      end
    end
  end
end
