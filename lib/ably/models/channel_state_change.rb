module Ably::Models
  # ChannelStateChange is a class that is emitted by the {Ably::Realtime::Channel} object
  # when a state change occurs
  #
  # @!attribute [r] current
  #   @return [Connection::STATE] Current channel state
  # @!attribute [r] previous
  #   @return [Connection::STATE] Previous channel state
  # @!attribute [r] reason
  #   @return [Ably::Models::ErrorInfo] Object describing the reason for a state change when not initiated by the consumer of the client library
  # @!attribute [r] resumed
  #   @return [Boolean] True when a channel is resumed, false when continuity on the channel is no longer provided indicating that the developer is now responsible for recovering lost messages on this channel through other means, such as using the hisory API
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

    %w(current previous event reason).each do |attribute|
      define_method attribute do
        @hash_object[attribute.to_sym]
      end
    end

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
