require 'eventmachine'
require 'rspec'
require 'timeout'

module RSpec
  module EventMachine
    extend self

    DEFAULT_TIMEOUT = 15

    def run_reactor(timeout = DEFAULT_TIMEOUT)
      Timeout::timeout(timeout + 0.5) do
        ::EventMachine.run do
          yield
        end
      end
    end

    def stop_reactor
      unless realtime_clients.empty?
        realtime_clients.shift.tap do |client|
          # Ensure close appens outside of the caller as this can cause errbacks on Deferrables
          # e.g. connection.connect { connection.close } => # Error as calling close within the connected callback
          ::EventMachine.add_timer(0.05) do
            client.close if client.connection.can_transition_to?(:closing)
            ::EventMachine.add_timer(0.1) { stop_reactor }
          end
        end
        return
      end

      ::EventMachine.next_tick do
        ::EventMachine.stop
      end
    end

    # Ensures that any clients used in tests will have their connections
    # explicitly closed when stop_reactor is called
    def auto_close(realtime_client)
      realtime_clients << realtime_client
      realtime_client
    end

    def realtime_clients
      @realtime_clients ||= []
    end

    # Allows multiple Deferrables to be passed in and calls the provided block when
    # all success callbacks have completed
    def when_all(*deferrables)
      raise ArgumentError, 'Block required' unless block_given?

      options = if deferrables.last.kind_of?(Hash)
        deferrables.pop
      else
        {}
      end

      successful_deferrables = {}

      deferrables.each do |deferrable|
        deferrable.callback do
          successful_deferrables[deferrable.object_id] = true
          if successful_deferrables.keys.sort == deferrables.map(&:object_id).sort
            if options[:and_wait]
              ::EventMachine.add_timer(options[:and_wait]) { yield }
            else
              yield
            end
          end
        end

        deferrable.errback do |error|
          raise RuntimeError, "Error: Deferrable failed: #{error}"
        end
      end
    end

    def wait_until(condition_block, &block)
      raise ArgumentError, 'Block required' unless block_given?

      if condition_block.call
        yield
      else
        ::EventMachine.add_timer(0.1) do
          wait_until condition_block, &block
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

  # Run the test block wrapped in an EventMachine reactor that has a configured timeout.
  # As RSpec does not provide an API to wrap blocks, accessing the instance variables is required.
  # Note, if you start a reactor and simply run the example with example#run then the example
  # will run and not wait for the reactor to stop thus triggering after callbacks prematurely.
  #
  config.around(:example, :event_machine) do |example|
    timeout = if example.metadata[:em_timeout].is_a?(Numeric)
      example.metadata[:em_timeout]
    else
      RSpec::EventMachine::DEFAULT_TIMEOUT
    end

    example_block          = example.example.instance_variable_get('@example_block')
    example_group_instance = example.example.instance_variable_get('@example_group_instance')

    event_machine_block = Proc.new do
      RSpec::EventMachine.run_reactor(timeout) do
        example_group_instance.instance_exec(example, &example_block)
      end
    end

    example.example.instance_variable_set('@example_block', event_machine_block)

    example.run
  end

  config.before(:example, :event_machine) do
    # Ensure EventMachine shutdown hooks are deregistered for every test
    EventMachine.instance_variable_set '@tails', []
  end
end
