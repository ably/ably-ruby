module Ably::Modules
  # SafeYield provides the method safe_yield that will yield to the consumer
  # who provided a block, however any exceptions will be caught, logged, and
  # operation of the client library will continue.
  #
  # An exception in a callback provided by a developer should not break this client library
  # and stop further execution of code.
  #
  # @note this Module requires that the method #logger is available
  #
  # @api private
  module SafeYield
    private

    def safe_yield(block, *args)
      block.call(*args)
    rescue StandardError => e
      message = "An exception in an external block was caught. #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      safe_yield_log_error message
    end

    def safe_yield_log_error(message)
      if defined?(:logger) && logger.respond_to?(:error)
        return logger.error message
      end
    rescue StandardError
      fallback_logger.error message
    end

    def fallback_logger
      @fallback_logger ||= ::Logger.new(STDOUT).tap do |logger|
        logger.formatter = lambda do |severity, datetime, progname, msg|
          [
            "#{datetime.strftime("%Y-%m-%d %H:%M:%S.%L")} #{::Logger::SEV_LABEL[severity]} #{msg}",
            "Warning: SafeYield expects the method #logger to be defined in the class it is included in, the method was not found in #{self.class}"
          ].join("\n")
        end
      end
    end
  end
end
