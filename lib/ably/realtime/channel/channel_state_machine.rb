require 'ably/modules/state_machine'

module Ably::Realtime
  class Channel
    # Internal class to manage channel state for {Ably::Realtime::Channel}
    #
    # @api private
    #
    class ChannelStateMachine
      include Ably::Modules::StateMachine

      # States supported by this StateMachine match #{Channel::STATE}s
      #   :initialized
      #   :attaching
      #   :attached
      #   :detaching
      #   :detached
      #   :failed
      Channel::STATE.each_with_index do |state_enum, index|
        state state_enum.to_sym, initial: index == 0
      end

      transition :from => :initialized,  :to => [:attaching]
      transition :from => :attaching,    :to => [:attached, :detaching, :failed]
      transition :from => :attached,     :to => [:detaching, :failed]
      transition :from => :detaching,    :to => [:detached, :attaching, :failed]
      transition :from => :failed,       :to => [:attaching]

      after_transition do |channel, transition|
        channel.synchronize_state_with_statemachine
      end

      after_transition(to: [:attaching]) do |channel|
        channel.manager.attach
      end

      before_transition(to: [:attached]) do |channel, current_transition|
        channel.manager.attached current_transition.metadata.reason
      end

      after_transition(to: [:detaching]) do |channel, current_transition|
        err = error_from_state_change(current_transition)
        channel.manager.detach err
      end

      after_transition(to: [:detached]) do |channel, current_transition|
        err = error_from_state_change(current_transition)
        channel.manager.fail_messages_awaiting_ack err
        channel.manager.emit_error err if err
      end

      after_transition(to: [:failed]) do |channel, current_transition|
        err = error_from_state_change(current_transition)
        channel.manager.fail_messages_awaiting_ack err
        channel.manager.emit_error err if err
      end

      # Transitions responsible for updating channel#error_reason
      before_transition(to: [:failed]) do |channel, current_transition|
        err = error_from_state_change(current_transition)
        channel.set_failed_channel_error_reason err if err
      end

      before_transition(to: [:attached, :detached]) do |channel, current_transition|
        err = error_from_state_change(current_transition)
        if err
          channel.set_failed_channel_error_reason err
        else
          # Attached & Detached are "healthy" final states so reset the error reason
          channel.clear_error_reason
        end
      end

      def self.error_from_state_change(current_transition)
        # ChannelStateChange object is always passed in current_transition metadata object
        connection_state_change = current_transition.metadata
        # Reason attribute contains errors
        err = connection_state_change && connection_state_change.reason
        err if is_error_type?(err)
      end

      private
      def channel
        object
      end

      # Logged needs to be defined as it is used by {Ably::Modules::StateMachine}
      def logger
        channel.logger
      end
    end
  end
end
