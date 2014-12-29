require 'eventmachine'
require 'timeout'

module RSpec
  module EventMachine
    def run_reactor(timeout = 5)
      Timeout::timeout(timeout + 0.5) do
        ::EventMachine.run do
          yield
        end
      end
    end

    def stop_reactor
      ::EventMachine.next_tick do
        ::EventMachine.stop
      end
    end
  end
end
