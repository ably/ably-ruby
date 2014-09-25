require 'timeout'

module RSpec
  module EventMachine
    def run_reactor(timeout = 3)
      Timeout::timeout(timeout + 0.5) do
        EM.run do
          yield

          EM.add_timer(timeout) do
            EM.stop
            raise RuntimeError, "EventMachine test did not complete in #{timeout} seconds"
          end
        end
      end
    end

    def stop_reactor
      EM.stop
    end
  end
end
