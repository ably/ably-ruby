module Ably
  module Modules
    # EventEmitter provides methods to attach to public events and trigger events on any class instance
    #
    # EventEmitter are typically used for public interfaces, and as such, may be overriden in
    # the classes to enforce `event` names match expected values.
    #
    # @example
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
      #
      # @param [Array<String>] event_names event name
      #
      # @return [void]
      def on(*event_names, &block)
        event_names.each do |event_name|
          callbacks[callbacks_event_coerced(event_name)] << proc_for_block(block)
        end
      end

      # On receiving an event maching the event_name, call the provided block only once and remove the registered callback
      #
      # @param [Array<String>] event_names event name
      #
      # @return [void]
      def once(*event_names, &block)
        event_names.each do |event_name|
          callbacks[callbacks_event_coerced(event_name)] << proc_for_block(block, delete_once_run: true)
        end
      end

      # Trigger an event with event_name that will in turn call all matching callbacks setup with `on`
      def trigger(event_name, *args)
        callbacks[callbacks_event_coerced(event_name)].delete_if { |proc_hash| proc_hash[:trigger_proc].call(*args) }
      end

      # Remove all callbacks for event_name.
      #
      # If a block is provided, only callbacks matching that block signature will be removed.
      # If block is not provided, all callbacks matching the event_name will be removed.
      #
      # @param [Array<String>] event_names event name
      #
      # @return [void]
      def off(*event_names, &block)
        keys = if event_names.empty?
          callbacks.keys
        else
          event_names
        end

        keys.each do |event_name|
          if block_given?
            callbacks[callbacks_event_coerced(event_name)].delete_if { |proc_hash| proc_hash[:block] == block }
          else
            callbacks[callbacks_event_coerced(event_name)].clear
          end
        end
      end

      private
      def self.included(klass)
        klass.extend ClassMethods
      end

      # Create a Hash with a proc that calls the provided block and returns true if option :delete_once_run is set to true.
      # #trigger automatically deletes any blocks that return true thus allowing a block to be run once
      def proc_for_block(block, options = {})
        {
          trigger_proc: Proc.new do |*args|
            block.call *args
            true if options[:delete_once_run]
          end,
          block: block
        }
      end

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
