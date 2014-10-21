module Ably::Realtime::Models
  # Nil object for Channels, this object is only used within the internal API of this client library
  class NilChannel
    include Ably::Modules::EventEmitter

    def name
      'Nil channel'
    end

    def __protocol_msgbus__
      @__protocol_msgbus__ ||= Ably::Util::PubSub.new
    end
  end
end
