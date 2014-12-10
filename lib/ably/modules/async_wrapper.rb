require 'eventmachine'

module Ably::Modules
  # Provides methods to convert synchronous operations into async operations through the use of
  # {EventMachine#defer http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine#defer-class_method}.
  # The async_wrap method can only be called from within an EventMachine reactor, and must be thread safe.
  #
  # @note using this AsyncWrapper should only be used for methods that are used less frequently and typically
  #       not run with levels of concurrency due to the limited number of threads available to EventMachine by default.
  #
  # @example
  #   class BlockingOperation
  #     include Aby::Modules::AsyncWrapper
  #
  #     def operation(&success_callback)
  #       async_wrap(success_callback) do
  #         sleep 1
  #         'slept'
  #       end
  #     end
  #   end
  #
  #   blocking_object = BlockingOperation.new
  #   deferrable = blocking_object.operation do |result|
  #     puts "Done with result: #{result}"
  #   end
  #   puts "Starting"
  #
  #   # => 'Starting'
  #   # => 'Done with result: slept'
  #
  module AsyncWrapper
    private

    # Will yield the provided block in a new thread and return an {EventMachine::Deferrable http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine/Deferrable}
    #
    # @yield [Object] operation block that is run in a thread
    # @return [EventMachine::Deferrable]
    #
    def async_wrap(success_callback = nil, &operation)
      raise ArgumentError, "Operation block is missing" unless block_given?

      EventMachine::DefaultDeferrable.new.tap do |deferrable|
        deferrable.callback &success_callback if success_callback

        operation_with_exception_handling = proc do
          begin
            yield
          rescue StandardError => e
            deferrable.fail e
          end
        end

        complete_callback = proc do |result|
          deferrable.succeed result
        end

        EventMachine.defer operation_with_exception_handling, complete_callback
      end
    end
  end
end
