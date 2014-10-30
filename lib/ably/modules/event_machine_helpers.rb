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
    def non_blocking_loop_while(lambda, &execution_block)
      if lambda.call
        yield
        EventMachine.next_tick do
          non_blocking_loop_while(lambda, &execution_block)
        end
      end
    end
  end
end
