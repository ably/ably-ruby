require 'ably/util/pub_sub'

module Ably::Modules
  # Message emitter, subscriber and unsubscriber (Pub/Sub) functionality common to Channels and Presence
  # In addition to standard Pub/Sub functionality, it allows subscribers to subscribe to :all.
  module MessageEmitter
    # Subscribe to events on this object
    #
    # @param name [String,Symbol] Optional, the event name to subscribe to. Defaults to `:all` events
    # @yield [Object] For each event, the provided block is called with the event payload object
    #
    # @return [void]
    #
    def subscribe(*names, &callback)
      raise ArgumentError, 'Block required to subscribe to events' unless block_given?
      names = :all unless names && !names.empty?
      Array(names).uniq.each do |name|
        message_emitter_subscriptions[message_emitter_subscriptions_message_name_key(name)] << callback
      end
    end

    # Unsubscribe the matching block for events on the this object.
    # If a block is not provided, all subscriptions will be unsubscribed
    #
    # @param name [String,Symbol] Optional, the event name to unsubscribe from. Defaults to `:all` events
    #
    # @return [void]
    #
    def unsubscribe(*names, &callback)
      names = :all unless names && !names.empty?
      Array(names).each do |name|
        if name == :all
          message_emitter_subscriptions.keys
        else
          Array(message_emitter_subscriptions_message_name_key(name))
        end.each do |key|
          message_emitter_subscriptions[key].delete_if do |block|
            !block_given? || callback == block
          end
        end
      end
    end

    # Emit a message to message subscribers
    #
    # param name [String,Symbol] the event name
    # param payload [Object] the event object to emit
    #
    # @return [void]
    #
    # @api private
    def emit_message(name, payload)
      raise 'Event name is required' unless name

      message_emitter_subscriptions[:all].each { |cb| cb.call(payload) }
      message_emitter_subscriptions[name].each { |cb| cb.call(payload) }
    end

    private
    def message_emitter_subscriptions
      @message_emitter_subscriptions ||= Hash.new { |hash, key| hash[key] = [] }
    end

    def message_emitter_subscriptions_message_name_key(name)
      if name == :all
        :all
      else
        message_emitter_subscriptions_coerce_message_key(name)
      end
    end

    # this method can be overwritten easily to enforce use of set key types§
    def message_emitter_subscriptions_coerce_message_key(name)
      name.to_s
    end
  end
end
