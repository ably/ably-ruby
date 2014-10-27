module Ably::Modules
  # State module adds a set of generic state related methods to a class on the assumption that
  # the instance variable @state is used exclusively, the {Enum} STATE is defined prior to inclusion of this
  # module, and the class is an {EventEmitter}
  #
  # @example
  #   class Connection
  #     include Ably::Modules::EventEmitter
  #     extend  Ably::Modules::Enum
  #     STATE = ruby_enum('STATE',
  #       :initialized,
  #       :connecting,
  #       :connected
  #     )
  #     include Ably::Modules::State
  #   end
  #
  #   connection = Connection.new
  #   connection.state = :connecting     # emits :connecting event via EventEmitter, returns STATE.Connecting
  #   connection.state?(:connected)      # => false
  #   connection.connecting?             # => true
  #   connection.state                   # => STATE.Connecting
  #   connection.state = :invalid        # raises an Exception as only a valid state can be defined
  #   connection.trigger :invalid        # raises an Exception as only a valid state can be used for EventEmitter
  #   connection.change_state :connected # emits :connected event via EventEmitter, returns STATE.Connected
  #
  module State
    # Current state {Ably::Modules::Enum}
    #
    # @return [Symbol] state
    def state
      STATE(@state)
    end

    # Evaluates if check_state matches current state
    #
    # @return [Boolean]
    def state?(check_state)
      state == check_state
    end

    # Set the current state {Ably::Modules::Enum}
    #
    # @return [Symbol] new state
    # @api private
    def state=(new_state, *args)
      if state != new_state
        logger.debug("#{self.class}: State changed from #{state} => #{new_state}") if respond_to?(:logger, true)
        @state = STATE(new_state)
        trigger @state, *args
      end
    end
    alias_method :change_state, :state=

    private
    def self.included(klass)
      klass.configure_event_emitter coerce_into: Proc.new { |event| klass::STATE(event) }

      klass::STATE.each do |state_predicate|
        klass.instance_eval do
          define_method("#{state_predicate.to_sym}?") do
            state?(state_predicate)
          end
        end
      end
    end
  end
end
