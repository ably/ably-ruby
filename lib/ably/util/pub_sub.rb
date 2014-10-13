module Ably::Util
  # PubSub provides methods to publish & subscribe to events
  #
  # @example
  #
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
    extend Ably::Modules::Callbacks

    def initialize(options = {})
      self.class.instance_eval do
        add_callbacks options

        alias_method :subscribe, :on
        alias_method :publish, :trigger
        alias_method :unsubscribe, :off
      end
    end
  end
end
