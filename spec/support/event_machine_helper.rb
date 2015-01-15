require 'eventmachine'
require 'rspec'
require 'timeout'

module RSpec
  module EventMachine
    extend self

    DEFAULT_TIMEOUT = 10

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
          raise RuntimeError, "Deferrable failed: #{error.message}"
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

  # Running a reactor block and then calling the example block with #call
  # does not work as expected as the example completes immediately and the block
  # calls after hooks before it returns the EventMachine loop.
  #
  # As there is no public API to inject around blocks correctly without calling the after blocks,
  # we have to monkey patch the run_after_example method at https://github.com/rspec/rspec-core/blob/master/lib/rspec/core/example.rb#L376
  # so that it does not run until we explicitly call it once the EventMachine reactor loop is finished.
  #
  def patch_example_block_with_surrounding_eventmachine_reactor(example)
    example.example.class.class_eval do
      alias_method :run_after_example_original, :run_after_example
      public :run_after_example_original

      # prevent after hooks being run for example until EventMachine reactor has finished
      def run_after_example; end
    end
  end

  def remove_patch_example_block(example)
    example.example.class.class_eval do
      remove_method :run_after_example
      alias_method :run_after_example, :run_after_example_original
      remove_method :run_after_example_original
    end
  end

  config.around(:example, :event_machine) do |example|
    timeout = if example.metadata[:em_timeout].is_a?(Numeric)
      example.metadata[:em_timeout]
    else
      RSpec::EventMachine::DEFAULT_TIMEOUT
    end

    patch_example_block_with_surrounding_eventmachine_reactor example

    begin
      RSpec::EventMachine.run_reactor(timeout) do
        example.call
        raise example.exception if example.exception
      end
    ensure
      example.example.run_after_example_original
      remove_patch_example_block example
    end
  end

  config.before(:example) do
    # Ensure EventMachine shutdown hooks are deregistered for every test
    EventMachine.instance_variable_set '@tails', []
  end
end
