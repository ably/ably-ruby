module Ably
  module Modules
    module Callbacks
      def on(event, &block)
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
        @callbacks[event] << block
      end

      def trigger(event, *args)
        @callbacks ||= Hash.new { |hash, key| hash[key] = [] }
        @callbacks[event].each { |cb| cb.call(*args) }
      end
    end
  end
end
