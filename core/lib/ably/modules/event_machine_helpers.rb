require 'eventmachine'

module Ably::Modules
  # EventMachineHelpers module provides common private methods to classes simplifying interaction with EventMachine
  module EventMachineHelpers
    private

    # This method allows looped blocks to be run at the next EventMachine tick
    # @example
    #   x = 0
    #   less_than_3 = -> { x < 3 }
    #   non_blocking_loop_while(less_than_3) do
    #     x += 1
    #   end
    def non_blocking_loop_while(lambda_condition, &execution_block)
      if lambda_condition.call
        EventMachine.next_tick do
          if lambda_condition.call # ensure condition is still met following #next_tick
            yield
            non_blocking_loop_while(lambda_condition, &execution_block)
          end
        end
      end
    end
  end
end
