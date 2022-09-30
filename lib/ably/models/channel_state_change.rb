module Ably::Models
  # Contains state change information emitted by {Ably::Rest::Channel} and {Ably::Realtime::Channel} objects.
  #
  class ChannelStateChange
    include Ably::Modules::ModelCommon

    def initialize(hash_object)
      unless (hash_object.keys - [:current, :previous, :event, :reason, :resumed, :protocol_message]).empty?
        raise ArgumentError, 'Invalid attributes, expecting :current, :previous, :event, :reason, :resumed'
      end

      @hash_object = {
        current: hash_object.fetch(:current),
        previous: hash_object.fetch(:previous),
        event: hash_object[:event],
        reason: hash_object[:reason],
        protocol_message: hash_object[:protocol_message],
        resumed: hash_object[:resumed]
      }
    rescue KeyError => e
      raise ArgumentError, e
    end

    # The new current {Ably::Realtime::Channel::STATE}.
    #
    # @spec RTL2a, RTL2b
    #
    # @return [Ably::Realtime::Channel::STATE]
    #
    def current
      @hash_object[:current]
    end

    # The previous state. For the {Ably::Realtime::Channel::EVENT}(:update) event, this is equal to the current {Ably::Realtime::Channel::STATE}.
    #
    # @spec RTL2a, RTL2b
    #
    # @return [Ably::Realtime::Channel::EVENT]
    #
    def previous
      @hash_object[:previous]
    end

    # The event that triggered this {Ably::Realtime::Channel::STATE} change.
    #
    # @spec TH5
    #
    # @return [Ably::Realtime::Channel::STATE]
    #
    def event
      @hash_object[:event]
    end

    # An {Ably::Models::ErrorInfo} object containing any information relating to the transition.
    #
    # @spec RTL2e, TH3
    #
    # @return [Ably::Models::ErrorInfo, nil]
    #
    def reason
      @hash_object[:reason]
    end

    # Indicates whether message continuity on this channel is preserved, see Nonfatal channel errors for more info.
    #
    # @spec RTL2f, TH4
    #
    # @return [Boolean]
    #
    def resumed
      !!@hash_object[:resumed]
    end
    alias_method :resumed?, :resumed

    # @api private
    def protocol_message
      @hash_object[:protocol_message]
    end

    def to_s
      "<ChannelStateChange: current state #{current}, previous state #{previous}>"
    end
  end
end
