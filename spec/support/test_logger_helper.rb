# Class with standard Ruby Logger interface
#   but it keeps a record of the lof entries for later inspection
class TestLogger
  def initialize
    @messages = []
  end

  [:fatal, :error, :warn, :info, :debug].each do |severity|
    define_method severity do |message|
      @messages << [severity, message]
    end
  end

  def logs
    @messages
  end

  def level
    1
  end

  def level=(new_level)
  end
end
