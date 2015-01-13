require 'statesman'
require 'ably/modules/statesman_monkey_patch'

module Ably::Modules
  # Module providing Statesman StateMachine functionality
  #
  # Expects method #logger to be defined
  #
  # @api private
  module StateMachine
    def self.included(klass)
      klass.class_eval do
        include Statesman::Machine
      end
      klass.extend Ably::Modules::StatesmanMonkeyPatch
      klass.extend ClassMethods
    end

    # Alternative to Statesman's #transition_to that:
    # * log state change failures to {Logger}
    # * raise an exception on the {Ably::Realtime::Channel}
    #
    # @return [void]
    def transition_state(state, *args)
      unless result = transition_to(state, *args)
        exception = exception_for_state_change_to(state)
        object.trigger :error, exception
        logger.fatal "#{self.class}: #{exception.message}"
      end
      result
    end

    # @return [Statesman History Object]
    def previous_transition
      history[-2]
    end

    # @return [Symbol]
    def previous_state
      previous_transition.to_state if previous_transition
    end

    # @return [Ably::Exceptions::StateChangeError]
    def exception_for_state_change_to(state)
      error_message = "#{self.class}: Unable to transition from #{current_state} => #{state}"
      Ably::Exceptions::StateChangeError.new(error_message, nil, 80020)
    end

    module ClassMethods
      private

      def is_error_type?(error)
        error.kind_of?(Ably::Models::ErrorInfo) || error.kind_of?(StandardError)
      end
    end
  end
end
