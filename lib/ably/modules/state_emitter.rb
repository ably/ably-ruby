module Ably::Modules
  # StateEmitter module adds a set of generic state related methods to a class on the assumption that
  # the instance variable @state is used exclusively, the {Enum} STATE is defined prior to inclusion of this
  # module, and the class is an {EventEmitter}.  It then emits state changes.
  #
  # It also ensures the EventEmitter is configured to retrict permitted events to the
  # the available STATEs or EVENTs if defined i.e. if EVENTs includes an additional type such as
  # :update, then it will support all EVENTs being emitted. EVENTs must be a superset of STATEs
  #
  # @note This module requires that the method #logger is defined.
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
  #     include Ably::Modules::StateEmitter
  #   end
  #
  #   connection = Connection.new
  #   connection.state = :connecting     # emits :connecting event via EventEmitter, returns STATE.Connecting
  #   connection.state?(:connected)      # => false
  #   connection.connecting?             # => true
  #   connection.state                   # => STATE.Connecting
  #   connection.state = :invalid        # raises an Exception as only a valid state can be defined
  #   connection.emit :invalid           # raises an Exception as only a valid state can be used for EventEmitter
  #   connection.change_state :connected # emits :connected event via EventEmitter, returns STATE.Connected
  #   connection.once_or_if(:connected) { puts 'block called once when state is connected or becomes connected' }
  #
  module StateEmitter
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
        logger.debug { "#{self.class}: StateEmitter changed from #{state} => #{new_state}" } if respond_to?(:logger, true)
        @state = STATE(new_state)
        emit @state, *args
      end
    end
    alias_method :change_state, :state=

    # If the current state matches the target_state argument the block is called immediately.
    # Else the block is called once when the target_state is reached.
    #
    # If the option block :else is provided then if any state other than target_state is reached, the :else block is called,
    # however only one of the blocks will ever be called
    #
    # @param [Symbol,Ably::Modules::Enum,Array] target_states a single state or array of states that once met, will fire the success block only once
    # @param [Hash] options
    # @option options [Proc] :else block called once the state has changed to anything but target_state
    #
    # @yield block is called if the state is matched immediately or once when the state is reached
    #
    # @return [void]
    def once_or_if(target_states, options = {}, &block)
      raise ArgumentError, 'Block required' unless block_given?

      if Array(target_states).any? { |target_state| state == target_state }
        safe_yield block
      else
        failure_block   = options.fetch(:else, nil)
        failure_wrapper = nil

        success_wrapper = lambda do |*args|
          yield
          off(&success_wrapper)
          off(&failure_wrapper) if failure_wrapper
        end

        failure_wrapper = lambda do |*args|
          failure_block.call(*args)
          off(&success_wrapper)
          off(&failure_wrapper)
        end if failure_block

        Array(target_states).each do |target_state|
          safe_unsafe_method options[:unsafe], :once, target_state, &success_wrapper

          safe_unsafe_method options[:unsafe], :once_state_changed do |*args|
            failure_wrapper.call(*args) unless state == target_state
          end if failure_block
        end
      end
    end

    # Equivalent of {#once_or_if} but any exception raised in a block will bubble up and cause this client library to fail.
    # This method should only be used internally by the client library.
    # @api private
    def unsafe_once_or_if(target_states, options = {}, &block)
      once_or_if(target_states, options.merge(unsafe: true), &block)
    end

    # Calls the block once when the state changes
    #
    # @yield block is called once the state changes
    # @return [void]
    #
    # @api private
    def once_state_changed(options = {}, &block)
      raise ArgumentError, 'Block required' unless block_given?

      once_block = lambda do |*args|
        off(*self.class::STATE.map, &once_block)
        yield(*args)
      end

      safe_unsafe_method options[:unsafe], :once, *self.class::STATE.map, &once_block
    end

    # Equivalent of {#once_state_changed} but any exception raised in a block will bubble up and cause this client library to fail.
    # This method should only be used internally by the client library.
    # @api private
    def unsafe_once_state_changed(&block)
      once_state_changed(unsafe: true, &block)
    end

    private

    # Returns an {Ably::Util::SafeDeferrable} and once the target state is reached, the
    # success block if provided and {Ably::Util::SafeDeferrable#callback} is called.
    # If the state changes to any other state, the {Ably::Util::SafeDeferrable#errback} is called.
    #
    def deferrable_for_state_change_to(target_state)
      Ably::Util::SafeDeferrable.new(logger).tap do |deferrable|
        fail_proc = lambda do |state_change|
          deferrable.fail state_change.reason
        end
        once_or_if(target_state, else: fail_proc) do
          yield self if block_given?
          deferrable.succeed self
        end
      end
    end

    def self.included(klass)
      klass.configure_event_emitter coerce_into: lambda { |event|
        # Special case allows EVENT instead of STATE to be emitted
        # Relies on the assumption that EVENT is a superset of STATE
        if klass.const_defined?(:EVENT)
          klass::EVENT(event)
        else
          klass::STATE(event)
        end
      }

      klass::STATE.each do |state_predicate|
        klass.instance_eval do
          define_method("#{state_predicate.to_sym}?") do
            state?(state_predicate)
          end
        end
      end
    end

    def safe_unsafe_method(unsafe, method_name, *args, &block)
      public_send("#{'unsafe_' if unsafe}#{method_name}", *args, &block)
    end
  end
end
