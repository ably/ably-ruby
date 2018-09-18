module Ably::Models
  # ConnectionStateChange is a class that is emitted by the {Ably::Realtime::Connection} object
  # when a state change occurs
  #
  # @!attribute [r] current
  #   @return [Connection::STATE] Current connection state
  # @!attribute [r] previous
  #   @return [Connection::STATE] Previous connection state
  # @!attribute [r] retry_in
  #   @return [Integer] Time in seconds until the connection will reattempt to connect when in the +:disconnected+ or +:suspended+ state
  # @!attribute [r] reason
  #   @return [Ably::Models::ErrorInfo] Object describing the reason for a state change when not initiated by the consumer of the client library
  #
  class ConnectionStateChange
    include Ably::Modules::ModelCommon

    def initialize(hash_object)
      unless (hash_object.keys - [:current, :previous, :event, :retry_in, :reason, :protocol_message]).empty?
        raise ArgumentError, 'Invalid attributes, expecting :current, :previous, :event, :retry_in, :reason'
      end

      @hash_object = {
        current: hash_object.fetch(:current),
        previous: hash_object.fetch(:previous),
        event: hash_object[:event],
        retry_in: hash_object[:retry_in],
        reason: hash_object[:reason],
        protocol_message: hash_object[:protocol_message]
      }
    rescue KeyError => e
      raise ArgumentError, e
    end

    %w(current previous event retry_in reason protocol_message).each do |attribute|
      define_method attribute do
        @hash_object[attribute.to_sym]
      end
    end

    def to_s
      "<ConnectionStateChange: current state #{current}, previous state #{previous}>"
    end
  end
end
