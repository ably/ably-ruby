module Ably::Realtime::Models
  # Nil object for Channels, this object is only used within the internal API of this client library
  class NilChannel
    include Ably::Modules::EventEmitter
    extend Ably::Modules::Enum
    STATE = ruby_enum('STATE', Ably::Realtime::Channel::STATE)
    include Ably::Modules::State

    def initialize
      @state = STATE.Initialized
    end

    def name
      'Nil channel'
    end

    def __incoming_msgbus__
      @__incoming_msgbus__ ||= Ably::Util::PubSub.new
    end
  end
end
