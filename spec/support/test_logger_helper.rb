# Class with standard Ruby Logger interface
#   but it keeps a record of the lof entries for later inspection
class TestLogger
  def initialize
    @messages = []
  end

  SEVERITIES = [:fatal, :error, :warn, :info, :debug]
  SEVERITIES.each do |severity|
    define_method severity do |message|
      @messages << [severity, message]
    end
  end

  def logs(min_severity: nil)
    if min_severity
      severity_level = SEVERITIES.index(min_severity)
      raise "Unknown severity: #{min_severity}" if severity_level.nil?

      @messages.select do |severity, message|
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
