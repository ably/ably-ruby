require 'eventmachine'

module Ably::Modules
  # Provides methods to convert synchronous operations into async operations through the use of
  # {http://www.rubydoc.info/github/eventmachine/eventmachine/EventMachine#defer-class_method EventMachine#defer}.
  # The async_wrap method can only be called from within an EventMachine reactor, and must be thread safe.
  #
  # @note using this AsyncWrapper should only be used for methods that are used less frequently and typically
  #       not run with levels of concurrency due to the limited number of threads available to EventMachine by default.
  #       This module requires that the method #logger is defined.
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

    # Will yield the provided block in a new thread and return an {Ably::Util::SafeDeferrable}
    #
    # @yield [Object] operation block that is run in a thread
    # @return [Ably::Util::SafeDeferrable]
    #
    def async_wrap(success_callback = nil, custom_error_handling = nil)
      raise ArgumentError, 'Block required' unless block_given?

      Ably::Util::SafeDeferrable.new(logger).tap do |deferrable|
        deferrable.callback(&success_callback) if success_callback

        operation_with_exception_handling = lambda do
          begin
            yield
          rescue StandardError => err
            if custom_error_handling
              custom_error_handling.call err, deferrable
            else
              logger.error { "An exception in an AsyncWrapper block was caught. #{err.class}: #{err.message}\n#{err.backtrace.join("\n")}" }
              deferrable.fail err
            end
          end
        end

        complete_callback = lambda do |result|
          deferrable.succeed result
        end

        EventMachine.defer operation_with_exception_handling, complete_callback
      end
    end
  end
end
