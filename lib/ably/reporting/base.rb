module Ably::Reporting
  class Base
    def initialize(options = {})
      @options = options
    end

    def capture_exception(exception)
      raise NotImplementedError
    end
  end
end
