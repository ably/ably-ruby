module Ably::Models
  # Contains {Ably::Models::ConnectionState} change information emitted by the {Ably::Realtime::Connection} object.
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

    # The new {Ably::Realtime::Connection::STATE}.
    #
    # @spec TA2
    #
    # @return [Ably::Realtime::Connection::STATE]
    #
    def current
      @hash_object[:current]
    end

    # The event that triggered this {Ably::Realtime::Connection::EVENT} change.
    #
    # @spec TA5
    #
    # @return [Ably::Realtime::Connection::STATE]
    #
    def event
      @hash_object[:event]
    end

    # The previous {Ably::Models::Connection::STATE}. For the {Ably::Models::Connection::EVENT} UPDATE event,
    # this is equal to the current {Ably::Models::Connection::STATE}.
    #
    # @spec TA2
    #
    # @return [Ably::Realtime::Connection::STATE]
    #
    def previous
      @hash_object[:previous]
    end

    # An {Ably::Models::ErrorInfo} object containing any information relating to the transition.
    #
    # @spec RTN4f, TA3
    #
    # @return [Ably::Models::ErrorInfo, nil]
    #
    def reason
      @hash_object[:reason]
    end

    # Duration in milliseconds, after which the client retries a connection where applicable.
    #
    # @spec RTN14d, TA2
    #
    # @return [Integer]
    #
    def retry_in
      @hash_object[:retry_in]
    end

    def protocol_message
      @hash_object[:protocol_message]
    end

    def to_s
      "<ConnectionStateChange: current state #{current}, previous state #{previous}>"
    end
  end
end
