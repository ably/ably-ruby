module Ably
  module Modules
    # EventEmitter provides methods to attach to public events and trigger events on any class instance
    #
    # EventEmitter are typically used for public interfaces, and as such, may be overriden in
    # the classes to enforce `event` names match expected values.
    #
    # @example
    #
    #   class Example
    #     include Modules::EventEmitter
    #   end
    #
    #   event_emitter = Example.new
    #   event_emitter.on(:signal) { |name| puts "Signal #{name} received" }
    #   event_emitter.trigger :signal, "Test"
    #   #=> "Signal Test received"
    #
    module EventEmitter
      def self.included(klass)
        klass.extend ClassMethods
      end

      module ClassMethods
        attr_reader :event_emitter_coerce_proc

        # Configure included EventEmitter
        #
        # @param [Hash] options the options for the {EventEmitter}
        # @option options [Proc] :coerce_into A lambda/Proc that is used to coerce the event names for all events. This is useful to ensure the event names conform to a naming or type convention.
        #
        # @example
        #   configure_event_emitter coerce_into: Proc.new { |event| event.to_sym }
        #
        def configure_event_emitter(options = {})
          @event_emitter_coerce_proc = options[:coerce_into]
        end

        # Ensure @event_emitter_coerce_proc option is passed down to any classes that inherit the class with callbacks
        def inherited(subclass)
          subclass.instance_variable_set('@event_emitter_coerce_proc', @event_emitter_coerce_proc)
          super
        end
      end

      # On receiving an event matching the event_name, call the provided block
      def on(event_name, &block)
        callbacks[callbacks_event_coerced(event_name)] << block
      end

      # Trigger an event with event_name that will in turn call all matching callbacks setup with `on`
      def trigger(event_name, *args)
        callbacks[callbacks_event_coerced(event_name)].each { |cb| cb.call(*args) }
      end

      # Remove all callbacks for event_name.
      #
      # If a block is provided, only callbacks matching that block signature will be removed.
      # If block is not provided, all callbacks matching the event_name will be removed.
      def off(event_name, &block)
        if block_given?
          callbacks[callbacks_event_coerced(event_name)].delete(block)
        else
          callbacks[callbacks_event_coerced(event_name)].clear
        end
      end

      private
      def callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def callbacks_event_coerced(event_name)
        if self.class.event_emitter_coerce_proc
          self.class.event_emitter_coerce_proc.call(event_name)
        else
          event_name
        end
      end
    end
  end
end
