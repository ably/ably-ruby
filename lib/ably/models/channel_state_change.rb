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
  #
  class ChannelStateChange
    include Ably::Modules::ModelCommon

    def initialize(hash_object)
      unless (hash_object.keys - [:current, :previous, :reason, :protocol_message]).empty?
        raise ArgumentError, 'Invalid attributes, expecting :current, :previous, :reason'
      end

      @hash_object = {
        current: hash_object.fetch(:current),
        previous: hash_object.fetch(:previous),
        reason: hash_object[:reason],
        protocol_message: hash_object[:protocol_message]
      }
    rescue KeyError => e
      raise ArgumentError, e
    end

    %w(current previous reason protocol_message).each do |attribute|
      define_method attribute do
        @hash_object[attribute.to_sym]
      end
    end

    def to_s
      "ChannelStateChange: current state #{current}, previous state #{previous}"
    end
  end
end
