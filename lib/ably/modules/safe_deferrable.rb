require 'eventmachine'

module Ably::Modules
  # SafeDeferrable module provides an EventMachine::Deferrable interface to the object it is included in
  # and is safe to use for for public interfaces of this client library.
  # Any exceptions raised in the success or failure callbacks are caught and logged to #logger
  #
  # An exception in a callback provided by a developer should not break this client library
  # and stop further execution of code.
  #
  # @note this Module requires that the method #logger is available
  #
  # See http://www.rubydoc.info/gems/eventmachine/1.0.7/EventMachine/Deferrable
  #
  module SafeDeferrable
    include EventMachine::Deferrable

    # Specify a block to be executed if and when the Deferrable object receives
    # a status of :succeeded.
    # See http://www.rubydoc.info/gems/eventmachine/1.0.7/EventMachine/Deferrable#callback-instance_method
    #
    # @return [void]
    #
    def callback(&block)
      super do |*args|
        safe_deferrable_block(*args, &block)
      end
    end

    # Specify a block to be executed if and when the Deferrable object receives
    # a status of :failed.
    # See http://www.rubydoc.info/gems/eventmachine/1.0.7/EventMachine/Deferrable#errback-instance_method
    #
    # @return [void]
    #
    def errback(&block)
      super do |*args|
        safe_deferrable_block(*args, &block)
      end
    end

    # Mark the Deferrable as succeeded and trigger all callbacks.
    # See http://www.rubydoc.info/gems/eventmachine/1.0.7/EventMachine/Deferrable#succeed-instance_method
    #
    # @return [void]
    #
    def succeed(*args)
      super(*args)
    end

    # Mark the Deferrable as failed and trigger all callbacks.
    # See http://www.rubydoc.info/gems/eventmachine/1.0.7/EventMachine/Deferrable#fail-instance_method
    #
    # @return [void]
    #
    def fail(*args)
      super(*args)
    end

    private
    def safe_deferrable_block(*args)
      yield(*args)
    rescue StandardError => e
      message = "An exception in a Deferrable callback was caught. #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
      if defined?(:logger) && logger.respond_to?(:error)
        logger.error message
      else
        fallback_logger.error message
      end
    end

    def fallback_logger
      @fallback_logger ||= ::Logger.new(STDOUT).tap do |logger|
        logger.formatter = lambda do |severity, datetime, progname, msg|
          [
            "#{datetime.strftime("%Y-%m-%d %H:%M:%S.%L")} #{::Logger::SEV_LABEL[severity]} #{msg}",
            "Warning: SafeDeferrable expects the method #logger to be defined in the class it is included in, the method was not found in #{self.class}"
          ].join("\n")
        end
      end
    end
  end
end
