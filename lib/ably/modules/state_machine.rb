# frozen_string_literal: true

require 'statesman'
require 'ably/modules/statesman_monkey_patch'

module Ably
  module Modules
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
        klass.extend ::Ably::Modules::StatesmanMonkeyPatch
        klass.extend ClassMethods
      end

      # Alternative to Statesman's #transition_to that:
      # * log state change failures to {Logger}
      #
      # @return [void]
      def transition_state(state, *args)
        unless (result = transition_to(state.to_sym, *args))
          exception = exception_for_state_change_to(state)
          logger.fatal { "#{self.class}: #{exception.message}\n#{caller[0..20].join("\n")}" }
        end
        result
      end

      # @return [Statesman History Object]
      def previous_transition
        history[-2]
      end

      # @return [Symbol]
      def previous_state
        previous_transition&.to_state
      end

      # @return [Ably::Exceptions::InvalidStateChange]
      def exception_for_state_change_to(state)
        error_message = "#{self.class}: Unable to transition from #{current_state} => #{state}"
        Ably::Exceptions::InvalidStateChange.new(error_message, nil, Ably::Exceptions::Codes::CHANNEL_OPERATION_FAILED_INVALID_CHANNEL_STATE)
      end

      # ClassMethods provides the methods for the Ably library classes
      #
      module ClassMethods
        private

        def is_error_type?(error)
          error.is_a?(Ably::Models::ErrorInfo) || error.is_a?(StandardError)
        end
      end
    end
  end
end
