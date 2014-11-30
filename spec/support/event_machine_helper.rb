require 'timeout'

module RSpec
  module EventMachine
    def run_reactor(timeout = 3)
      Timeout::timeout(timeout + 0.5) do
        EM.run do
          yield
        end
      end
    end

    def stop_reactor
      EM.stop
    end
  end
end
