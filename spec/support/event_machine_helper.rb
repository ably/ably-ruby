require 'eventmachine'
require 'rspec'
require 'timeout'

# Prevent EM signal_loopbreak race condition from corrupting the entire
# process. When EM.defer is used and the reactor stops while a threadpool
# worker is mid-flight, the worker calls signal_loopbreak on a stopped
# reactor, raising RuntimeError. This poisons EM for the rest of the
# process, cascading failures to every subsequent test that touches EM.
# Swallowing the error is safe — signal_loopbreak is just a notification
# that there's work to process, and if EM isn't running there's nothing
# to notify.
module EventMachine
  class << self
    alias_method :original_signal_loopbreak, :signal_loopbreak

    def signal_loopbreak
      original_signal_loopbreak
    rescue RuntimeError
      # EM not initialized — reactor was stopped between the check and the call
    end
  end
end

module RSpec
  module EventMachine
    extend self

    DEFAULT_TIMEOUT = 15

    def run_reactor(timeout = DEFAULT_TIMEOUT)
      @reactor_stopping = false

      Timeout::timeout(timeout + 0.5) do
        ::EventMachine.run do
          yield
        end
      end
    end

    def reactor_stopping?
      @reactor_stopping
    end

    def stop_reactor
      mark_reactor_stopping

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

    def mark_reactor_stopping
      @reactor_stopping = true
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

    event_machine_block = lambda do |*args|
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

  # Catch-all cleanup for ANY test that used EventMachine, whether via
  # the :event_machine tag or by calling run_reactor directly. Without this,
  # a crashed/timed-out reactor and stale client references leak into
  # subsequent tests causing cascade failures.
  config.after(:example) do
    RSpec::EventMachine.realtime_clients.clear
    begin
      EventMachine.stop if EventMachine.reactor_running?
    rescue RuntimeError
      # EM can be in a corrupted state (e.g. signal_loopbreak failure)
      # where reactor_running? returns true but stop raises. Swallow
      # the error to prevent cascading failures across subsequent tests.
    end
  end
end

module RSpec
  module Expectations
    module ExpectationHelper
      class << self
        # This is very hacky and ties into the internals of RSpec which is likely to break in future versions
        # However, this is just a convenience to reduce log noise when the reactor is stopping
        # i.e. debug_failure_helper logs the verbose messages generated by the libraries, however it also often
        # catches all the shutdown messages which is unnecessary
        alias_method :orig_handle_failure, :handle_failure

        def handle_failure(*args, &block)
          RSpec::EventMachine.mark_reactor_stopping
          orig_handle_failure(*args, &block)
        end
      end
    end
  end
end
