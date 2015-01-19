require 'ably/modules/state_machine'

module Ably::Realtime
  class Presence
    # Internal class to manage presence state for {Ably::Realtime::Presence}
    #
    # @api private
    #
    class PresenceStateMachine
      include Ably::Modules::StateMachine

      # States supported by this StateMachine match #{Presence::STATE}s
      #   :initialized
      #   :entering
      #   :entered
      #   :leaving
      #   :left
      #   :failed
      Presence::STATE.each_with_index do |state_enum, index|
        state state_enum.to_sym, initial: index == 0
      end

      # Entering or entered states can skip leaving and go straight to left if a channel is detached
      # A channel that detaches very quickly will also go straight to :left from :initialized
      # Failed states only occur when present and the channel fails or presence fails
      transition :from => :initialized,  :to => [:entering, :left]
      transition :from => :entering,     :to => [:entered, :leaving, :left, :failed]
      transition :from => :entered,      :to => [:leaving, :left, :failed]
      transition :from => :leaving,      :to => [:left, :entering, :failed]
      transition :from => :failed,       :to => [:entering]

      after_transition do |presence, transition|
        presence.synchronize_state_with_statemachine
      end

      after_transition(to: [:entering]) do |presence, current_transition|
        presence.manager.enter current_transition.metadata
      end

      after_transition(to: [:leaving]) do |presence, current_transition|
        presence.manager.leave current_transition.metadata
      end

      after_transition(to: [:failed]) do |presence, current_transition|
        presence.manager.emit_error current_transition.metadata
      end

      # Transitions responsible for updating channel#error_reason
      before_transition(to: [:left, :failed]) do |presence, current_transition|
        presence.channel.set_failed_channel_error_reason current_transition.metadata if is_error_type?(current_transition.metadata)
      end

      private
      def channel
        object.channel
      end

      # Logged needs to be defined as it is used by {Ably::Modules::StateMachine}
      def logger
        channel.logger
      end
    end
  end
end
