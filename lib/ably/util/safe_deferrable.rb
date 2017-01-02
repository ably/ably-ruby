module Ably::Util
  # SafeDeferrable class provides a Deferrable that is safe to use for for public interfaces
  # of this client library.  Any exceptions raised in the success or failure callbacks are
  # caught and logged to the provided logger.
  #
  # An exception in a callback provided by a developer should not break this client library
  # and stop further execution of code.
  #
  class SafeDeferrable
    include Ably::Modules::SafeDeferrable

    attr_reader :logger

    def initialize(logger)
      @logger = logger
    end

    # Create a new {SafeDeferrable} and fail immediately with the provided error in the next eventloop cycle
    #
    # @param error [Ably::Exceptions::BaseAblyException, Ably::Models::ErrorInfo]   The error used to fail the newly created {SafeDeferrable}
    #
    # @return [SafeDeferrable]
    #
    def self.new_and_fail_immediately(logger, error)
      new(logger).tap do |deferrable|
        EventMachine.next_tick do
          deferrable.fail error
        end
      end
    end

    # Create a new {SafeDeferrable} and succeed immediately with the provided arguments in the next eventloop cycle
    #
    # @return [SafeDeferrable]
    #
    def self.new_and_succeed_immediately(logger, *args)
      new(logger).tap do |deferrable|
        EventMachine.next_tick do
          deferrable.succeed *args
        end
      end
    end
  end
end
