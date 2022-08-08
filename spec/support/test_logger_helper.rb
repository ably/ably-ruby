# frozen_string_literal: true

# Class with standard Ruby Logger interface
#   but it keeps a record of the lof entries for later inspection
#
# Recommendation: Use :prevent_log_stubbing attibute on tests that use this logger
#
class TestLogger
  def initialize
    @messages = []
  end

  SEVERITIES = %i[fatal error warn info debug].freeze
  SEVERITIES.each do |severity_sym|
    define_method(severity_sym) do |*args, &block|
      @messages << if block
        [severity_sym, block.call]
      else
        [severity_sym, args.join(", ")]
      end
    end
  end

  def logs(options = {})
    min_severity = options[:min_severity]
    if min_severity
      severity_level = SEVERITIES.index(min_severity)
      raise "Unknown severity: #{min_severity}" if severity_level.nil?

      @messages.select do |severity, _message|
        SEVERITIES.index(severity) <= severity_level
      end
    else
      @messages
    end
  end

  def level
    1
  end

  def level=(new_level)
  end
end
