module Ably
  module Modules
    module EventEmitter
      # Unplugs currently registered listener callbacks
      # Ensures multiple calls to unplug is not destructive
      def unplug_listeners
        unplugged_callbacks[:callbacks] = unplugged_callbacks.fetch(:callbacks).merge(callbacks)
        unplugged_callbacks[:callbacks_any] = unplugged_callbacks.fetch(:callbacks_any) + callbacks_any
        callbacks.clear
        callbacks_any.clear
      end

      # Plug in previously unplugged listener callbacks
      # But merge them together in case other listners have been added in the mean time
      def plugin_listeners
        @callbacks = callbacks.merge(unplugged_callbacks.fetch(:callbacks))
        @callbacks_any = callbacks_any + unplugged_callbacks.fetch(:callbacks_any)
        unplugged_callbacks.fetch(:callbacks).clear
        unplugged_callbacks.fetch(:callbacks_any).clear
      end

      private
      def unplugged_callbacks
        @unplugged_callbacks ||= {
          callbacks: Hash.new { |hash, key| hash[key] = [] },
          callbacks_any: []
        }
      end
    end
  end
end
