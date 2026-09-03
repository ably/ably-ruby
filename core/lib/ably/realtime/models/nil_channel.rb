module Ably::Realtime::Models
  # Nil object for Channels, this object is only used within the internal API of this client library
  # @api private
  class NilChannel
    include Ably::Modules::EventEmitter
    extend Ably::Modules::Enum
    STATE = ruby_enum('STATE', Ably::Realtime::Channel::STATE)
    include Ably::Modules::StateEmitter
    include Ably::Modules::UsesStateMachine

    attr_reader :state_machine

    def initialize
      @state_machine = Ably::Realtime::Channel::ChannelStateMachine.new(self)
      @state         = STATE(state_machine.current_state)
    end

    def name
      'Nil channel'
    end

    def __incoming_msgbus__
      @__incoming_msgbus__ ||= Ably::Util::PubSub.new
    end

    def logger
      @logger ||= Ably::Models::NilLogger.new
    end
  end
end
