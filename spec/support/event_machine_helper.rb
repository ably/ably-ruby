require 'eventmachine'
require 'rspec'
require 'timeout'

module RSpec
  module EventMachine
    extend self

    DEFAULT_TIMEOUT = 5

    # See https://github.com/igrigorik/em-http-request/blob/master/lib/em-http/multi.rb
    class MultiRequest
      include ::EventMachine::Deferrable

      attr_reader :requests, :responses

      def initialize
        @requests  = {}
        @responses = {:callback => {}, :errback => {}}
      end

      def add(name, conn)
        raise 'Duplicate Multi key' if @requests.key? name

        @requests[name] = conn

        conn.callback { @responses[:callback][name] = conn; check_progress }
        conn.errback  { @responses[:errback][name]  = conn; check_progress }
      end

      def finished?
        (@responses[:callback].size + @responses[:errback].size) == @requests.size
      end

      protected
      # invoke callback if all requests have completed
      def check_progress
        succeed(self) if finished?
      end
    end

    def run_reactor(timeout = DEFAULT_TIMEOUT)
      Timeout::timeout(timeout + 0.5) do
        ::EventMachine.run do
          yield
        end
      end
    end

    def stop_reactor
      ::EventMachine.next_tick do
        ::EventMachine.stop
      end
    end

    # Allows multiple Deferrables to be passed in and calls the provided block when
    # all success callbacks have completed
    def when_all(*callbacks, &block)
      raise "Block expected" unless block_given?

      options = if callbacks.last.kind_of?(Hash)
        callbacks.pop
      else
        {}
      end

      RSpec::EventMachine::MultiRequest.new.tap do |multi|
        callbacks.each_with_index do |callback, index|
          multi.add index, callback
        end

        multi.callback do
          if options[:and_wait]
            ::EventMachine.add_timer(options[:and_wait]) { block.call }
          else
            block.call
          end
        end

        multi.errback do |error|
          raise RuntimeError, "Callbacks failed: #{error.message}"
        end
      end
    end
  end
end

RSpec.configure do |config|
  config.before(:context, :event_machine) do |context|
    context.class.class_eval do
      include RSpec::EventMachine
    end
  end

  config.around(:example) do |example|
    next example.call unless example.metadata[:event_machine]

    timeout = if example.metadata[:em_timeout].is_a?(Numeric)
      example.metadata[:em_timeout]
    else
      RSpec::EventMachine::DEFAULT_TIMEOUT
    end

    RSpec::EventMachine.run_reactor(timeout) do
      example.call
      stop_reactor if example.exception
    end
  end

  config.before(:example) do
    # Ensure EventMachine shutdown hooks are deregistered for every test
    EventMachine.instance_variable_set '@tails', []
  end
end
