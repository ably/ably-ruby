require 'ably/modules/safe_yield'

module Ably
  module Modules
    # EventEmitter provides methods to attach to public events and emit events on any class instance
    #
    # EventEmitter are typically used for public interfaces, and as such, may be overriden in
    # the classes to enforce `event` names match expected values.
    #
    # @note This module requires that the method #logger is defined.
    #
    # @example
    #   class Example
    #     include Modules::EventEmitter
    #   end
    #
    #   event_emitter = Example.new
    #   event_emitter.on(:signal) { |name| puts "Signal #{name} received" }
    #   event_emitter.emit :signal, "Test"
    #   #=> "Signal Test received"
    #
    module EventEmitter
      include Ably::Modules::SafeYield

      module ClassMethods
        attr_reader :event_emitter_coerce_proc

        # Configure included EventEmitter
        #
        # @param [Hash] options the options for the {EventEmitter}
        # @option options [Proc] :coerce_into A lambda/Proc that is used to coerce the event names for all events. This is useful to ensure the event names conform to a naming or type convention.
        #
        # @example
        #   configure_event_emitter coerce_into: lambda { |event| event.to_sym }
        #
        def configure_event_emitter(options = {})
          @event_emitter_coerce_proc = options[:coerce_into]
        end

        # Ensure @event_emitter_coerce_proc option is passed down to any classes that inherit the class with callbacks
        def inherited(subclass)
          subclass.instance_variable_set('@event_emitter_coerce_proc', @event_emitter_coerce_proc) if defined?(@event_emitter_coerce_proc)
          super
        end
      end

      # On receiving an event matching the event_name, call the provided block
      #
      # @param [Array<String>] event_names event name
      #
      # @return [void]
      def on(*event_names, &block)
        add_callback event_names, proc_for_block(block)
      end

      # Equivalent of {#on} but any exception raised in a block will bubble up and cause this client library to fail.
      # This method is designed to be used internally by the client library.
      # @api private
      def unsafe_on(*event_names, &block)
        add_callback event_names, proc_for_block(block, unsafe: true)
      end

      # On receiving an event maching the event_name, call the provided block only once and remove the registered callback
      #
      # @param [Array<String>] event_names event name
      #
      # @return [void]
      def once(*event_names, &block)
        add_callback event_names, proc_for_block(block, delete_once_run: true)
      end

      # Equivalent of {#once} but any exception raised in a block will bubble up and cause this client library to fail.
      # This method is designed to be used internally by the client library.
      # @api private
      def unsafe_once(*event_names, &block)
        add_callback event_names, proc_for_block(block, delete_once_run: true, unsafe: true)
      end

      # Emit an event with event_name that will in turn call all matching callbacks setup with `on`
      def emit(event_name, *args)
        [callbacks_any, callbacks[callbacks_event_coerced(event_name)]].each do |callback_arr|
          callback_arr.clone.
          select do |proc_hash|
            if proc_hash[:unsafe]
              proc_hash[:emit_proc].call(*args)
            else
              safe_yield proc_hash[:emit_proc], *args
            end
          end.each do |callback|
            callback_arr.delete callback
          end
        end
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
        off_internal(false, *event_names, &block)
      end

      # Equivalent of {#off} but only unsafe listeners are removed.
      # This method is designed to be used internally by the client library.
      # @api private
      def unsafe_off(*event_names, &block)
        off_internal(true, *event_names, &block)
      end

      private
      def off_internal(unsafe, *event_names, &block)
        keys = if event_names.empty?
          callbacks.keys
        else
          event_names
        end

        if event_names.empty?
          callbacks_any.delete_if do |proc_hash|
            if block_given?
              (proc_hash[:unsafe] == unsafe) && (proc_hash[:block] == block)
            else
              proc_hash[:unsafe] == unsafe
            end
          end
        end

        keys.each do |event_name|
          callbacks[callbacks_event_coerced(event_name)].delete_if do |proc_hash|
            if block_given?
              (proc_hash[:unsafe] == unsafe) && (proc_hash[:block] == block)
            else
              proc_hash[:unsafe] == unsafe
            end
          end
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
      end

      def add_callback(event_names, proc_block)
        if event_names.empty?
          callbacks_any << proc_block
        else
          event_names.each do |event_name|
            callbacks[callbacks_event_coerced(event_name)] << proc_block
          end
        end
      end

      # Create a Hash with a proc that calls the provided block and returns true if option :delete_once_run is set to true.
      # #emit automatically deletes any blocks that return true thus allowing a block to be run once
      def proc_for_block(block, options = {})
        {
          emit_proc: lambda do |*args|
            block.call(*args)
            true if options[:delete_once_run]
          end,
          block: block,
          unsafe: options[:unsafe] || false
        }
      end

      def callbacks
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
      end

      def callbacks_any
        @callbacks_any ||= []
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
