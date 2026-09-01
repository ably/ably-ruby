module Ably::Modules
  # Mixing module that assists with {https://github.com/gocardless/statesman Statemans State Machine} state transitions
  # and maintaining state of this object's #state.
  #
  # Expects:
  #   - @state_machine is set to the StateMachine
  #   - StateEmitter is included in the object
  #
  module UsesStateMachine
    extend Forwardable

    # Call #transition_to on the StateMachine
    #
    # @return [Boolean] true if new_state can be transitioned to by state machine
    # @api private
    def transition_state_machine(new_state, emit_params = {})
      state_machine.transition_state(new_state, emit_object(new_state, emit_params))
    end

    # Call #transition_to! on the StateMachine
    # An exception wil be raised if new_state cannot be transitioned to by state machine
    #
    # @return [void]
    # @api private
    def transition_state_machine!(new_state, emit_params = {})
      state_machine.transition_to!(new_state, emit_object(new_state, emit_params))
    end

    # Provides an internal method for this object's state to match the StateMachine's current state.
    # The current object's state will be changed to the StateMachine state and will emit an event
    # @api private
    def synchronize_state_with_statemachine(*args)
      log_state_machine_state_change
      change_state state_machine.current_state, state_machine.last_transition.metadata
    end

    # @!attribute [r] previous_state
    # @return [STATE,nil] The previous state for this connection
    # @api private
    def previous_state
      if state_machine.previous_state
        STATE(state_machine.previous_state)
      end
    end

    # @!attribute [r] state_history
    # @return [Array<Hash>] All previous states including the current state in date ascending order with Hash properties :state, :metadata, :transitioned_at
    # @api private
    def state_history
      state_machine.history.map do |transition|
        {
          state:           STATE(transition.to_state),
          metadata:        transition.metadata,
          transitioned_at: transition.created_at
        }
      end
    end

    def_delegators :state_machine, :can_transition_to?

    private
    def state_machine
      @state_machine
    end

    def_delegators :state_machine, :exception_for_state_change_to

    def log_state_machine_state_change
      if state_machine.previous_state
        logger.debug { "#{self.class.name}: Transitioned from #{state_machine.previous_state} => #{state_machine.current_state}" }
      else
        logger.debug { "#{self.class.name}: Transitioned to #{state_machine.current_state}" }
      end
    end

    def emit_object(new_state, emit_params)
      if self.class.emits_klass
        self.class.emits_klass.new((emit_params || {}).merge(
          current: STATE(new_state),
          previous: STATE(state_machine.current_state),
          event: EVENT(new_state)
        ))
      else
        emit_params
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      def emits_klass
        @emits_klass ||= if defined?(@emits_klass_name) && @emits_klass_name
          get_const(@emits_klass_name)
        end
      end

      def ensure_state_machine_emits(klass)
        @emits_klass_name = klass
      end

      def get_const(klass_name)
        klass_names = klass_name.split('::')
        klass_names.inject(Kernel) do |klass, name|
          klass.const_get(name)
        end
      end
    end
  end
end
