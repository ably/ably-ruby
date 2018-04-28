require 'spec_helper'

describe Ably::Modules::AsyncWrapper, :api_private do
  include RSpec::EventMachine

  let(:class_with_module) do
    Class.new do
      include Ably::Modules::AsyncWrapper

      def operation(&success_callback)
        async_wrap success_callback, &@block
      end

      def block=(block)
        @block = block
      end

      def logger
        @logger ||= Ably::Models::NilLogger.new
      end
    end
  end
  let(:subject)    { class_with_module.new }
  let(:result)     { random_str }
  let(:sleep_time) { 0.1 }

  before do
    subject.block = block
  end

  context '#async_wrap blocking block' do
    context 'returns result' do
      let(:block) do
        lambda do
          sleep sleep_time
          result
        end
      end

      it 'returns a SafeDeferrable that catches and logs exceptions in the provided callbacks' do
        run_reactor do
          deferrable = subject.operation
          expect(deferrable).to be_a(Ably::Util::SafeDeferrable)
          stop_reactor
        end
      end

      it 'calls the provided block with result when provided' do
        run_reactor do
          subject.operation do |result|
            expect(result).to eql(result)
            stop_reactor
          end
        end
      end

      it 'catches exceptions in the provided block and logs them to logger' do
        run_reactor do
          subject.operation do |result|
            raise 'Intentional exception'
          end
          expect(subject.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/Intentional exception/)
            stop_reactor
          end
        end
      end

      it 'returns a SafeDeferrable that calls the callback block' do
        run_reactor do
          deferrable = subject.operation
          deferrable.callback do |result|
            expect(result).to eql(result)
            stop_reactor
          end
        end
      end

      it 'does not call the errback' do
        run_reactor do
          deferrable = subject.operation
          deferrable.callback do |result|
            expect(result).to eql(result)
            EventMachine.add_timer(sleep_time * 2) { stop_reactor }
          end
          deferrable.errback do |error|
            raise 'Errback should not have been called'
          end
        end
      end

      it 'does not block EventMachine' do
        run_reactor do
          timers_called = 0
          EventMachine.add_periodic_timer(sleep_time / 5) { timers_called += 1 }

          subject.operation do |result|
            expect(timers_called).to be >= 4
            stop_reactor
          end
        end
      end
    end

    context 'raises an Exception' do
      let(:block) do
        lambda do
          sleep sleep_time
          raise RuntimeError, 'Intentional'
        end
      end

      it 'calls the errback block of the SafeDeferrable' do
        run_reactor do
          deferrable = subject.operation
          deferrable.errback do |error|
            expect(error).to be_a(RuntimeError)
            expect(error.message).to match(/Intentional/)
            stop_reactor
          end
        end
      end

      it 'does not call the provided block' do
        run_reactor do
          subject.operation do |result|
            raise 'Callback should not have been called'
          end
          EventMachine.add_timer(sleep_time * 2) { stop_reactor }
        end
      end

      it 'does not call the callback block of the SafeDeferrable' do
        run_reactor do
          deferrable = subject.operation
          deferrable.callback do |result|
            raise 'Callback should not have been called'
          end
          EventMachine.add_timer(sleep_time * 2) { stop_reactor }
        end
      end
    end
  end
end
