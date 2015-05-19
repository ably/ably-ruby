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
  end
end
