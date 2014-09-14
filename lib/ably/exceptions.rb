module Ably
  class InvalidRequest < StandardError
    attr_reader :status, :code
    def initialize(message, status: nil, code: nil)
      super message
      @status = status
      @code = code
    end
  end

  class ServerError < StandardError; end
  class InvalidPageError < StandardError; end
  class InvalidResponseBody < StandardError; end
end
