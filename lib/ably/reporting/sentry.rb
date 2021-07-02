require 'sentry-ruby'

module Ably::Reporting
  class Sentry < Base
    LOG_EXCEPTION_REPORTING_URL = "https://765e1fcaba404d7598d2fd5a2a43c4f0:8d469b2b0fb34c01a12ae217931c4aed@errors.ably.io/3"

    def initialize(options = {})
      ::Sentry.init { |config| config.dsn = options.delete(:dsn) || LOG_EXCEPTION_REPORTING_URL }
    end

    def capture_exception(exception)
      ::Sentry.capture_exception(exception)
    end
  end
end
