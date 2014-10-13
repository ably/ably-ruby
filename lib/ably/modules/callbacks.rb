module Ably
  module Modules
    # Callbacks provides methods to attach to public events and trigger events on any class instance
    #
    # Callbacks are typically used for public interfaces, and as such, may be overriden in
    # the classes to enforce `event` names match expected values.
    #
    # @example
    #
    #   class EventEmitter
    #     extend Modules::Callbacks
    #     add_callbacks
    #   end
    #
    #   event_emitter = EventEmitter.new
    #   event_emitter.on(:signal) { |name| puts "Signal #{name} received" }
    #   event_emitter.trigger :signal, "Test"
    #   #=> "Signal Test received"
    #
    module Callbacks
      attr_reader :callbacks_coerce_proc

      # Add callback functionality to the current class
      #
      # @param [Hash] options the options for the callbacks
      # @option options [Proc] :coerce_into A lambda/Proc that is used to coerce the event names for all events. This is useful to ensure the event names conform to a naming or type convention.
      #
      # @example
      #   add_callbacks coerce_into: Proc.new { |event| event.to_sym }
      #
      def add_callbacks(options = {})
        @callbacks_coerce_proc = options[:coerce_into]

        class_eval do
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
            if self.class.callbacks_coerce_proc
              self.class.callbacks_coerce_proc.call(event_name)
            else
              event_name
            end
          end
        end
      end

      # Ensure @callbacks_coerce_proc option is passed down to any classes that inherit the class with callbacks
      def inherited(subclass)
        subclass.instance_variable_set('@callbacks_coerce_proc', @callbacks_coerce_proc)
        super
      end
    end
  end
end
