require 'ably/modules/event_emitter.rb'

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

    # Ensure new PubSub object does not share class instance variables
    def self.new(options = {})
      Class.new(PubSub).allocate.tap do |pub_sub_object|
        pub_sub_object.send(:initialize, options)
      end
    end

    def inspect
      "<#PubSub: @event_emitter_coerce_proc: #{self.class.event_emitter_coerce_proc.inspect}\n @callbacks: #{callbacks}>"
    end

    def initialize(options = {})
      self.class.instance_eval do
        configure_event_emitter options

        alias_method :subscribe, :unsafe_on
        alias_method :publish, :emit
        alias_method :unsubscribe, :unsafe_off
      end
    end
  end
end
