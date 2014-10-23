module Ably::Util
  # PubSub class provides methods to publish & subscribe to events, with methods and naming
  # intentionally different to EventEmitter as it is intended for private message handling
  # within the client library.
  #
  # @example
  #   class Channel
  #     def messages
  #       @messages ||= PubSub.new
  #     end
  #   end
  #
  #   channel = Channel.new
  #   channel.messages.subscribe(:event) { |name| puts "Event message #{name} received" }
  #   channel.messages.publish :event, "Test"
  #   #=> "Event message Test received"
  #   channel.messages.remove :event
  #
  class PubSub
    include Ably::Modules::EventEmitter

    def initialize(options = {})
      self.class.instance_eval do
        configure_event_emitter options

        alias_method :subscribe, :on
        alias_method :publish, :trigger
        alias_method :unsubscribe, :off
      end
    end
  end
end
