# frozen_string_literal: true

require "ably/modules/state_machine"

module Ably
  module Realtime
    class Channel
      # Internal class to manage channel state for {Ably::Realtime::Channel}
      #
      # @api private
      #
      class ChannelStateMachine
        include ::Ably::Modules::StateMachine

        # States supported by this StateMachine match #{Channel::STATE}s
        #   :initialized
        #   :attaching
        #   :attached
        #   :detaching
        #   :detached
        #   :failed
        Channel::STATE.each_with_index do |state_enum, index|
          state state_enum.to_sym, initial: index.zero?
        end

        transition from: :initialized, to: %I[attaching failed]
        transition from: :attaching, to: %I[attached detaching failed suspended]
        transition from: :attached, to: %I[attaching detaching detached failed suspended]
        transition from: :detaching, to: %I[detached attaching attached failed suspended]
        transition from: :detached, to: %I[attaching attached failed]
        transition from: :suspended, to: %I[attaching attached detached failed]
        transition from: :failed, to: %I[attaching initialized]

        after_transition do |channel, _|
          channel.synchronize_state_with_statemachine
        end

        after_transition(to: %I[initialized]) do |channel|
          channel.clear_error_reason
        end

        after_transition(to: %I[attaching]) do |channel|
          channel.manager.attach
        end

        before_transition(to: %I[attached]) do |channel, current_transition|
          channel.manager.attached current_transition.metadata.protocol_message
          channel.attach_resume!
        end

        before_transition(to: %I[detaching failed]) do |channel, _current_transition|
          channel.reset_attach_resume!
        end

        after_transition(to: %I[detaching]) do |channel, current_transition|
          err = error_from_state_change(current_transition)
          channel.manager.detach err, current_transition.metadata.previous
        end

        after_transition(to: %I[detached failed suspended]) do |channel, current_transition|
          err = error_from_state_change(current_transition)
          channel.manager.fail_queued_messages(err) if channel.failed? || channel.suspended? # RTL11
          channel.manager.log_channel_error err if err
        end

        after_transition(to: %I[suspended]) do |channel, _|
          channel.manager.start_attach_from_suspended_timer
        end

        # Transitions responsible for updating channel#error_reason
        before_transition(to: %I[failed suspended]) do |channel, current_transition|
          err = error_from_state_change(current_transition)
          channel.set_channel_error_reason err if err
        end

        before_transition(to: %I[attached detached]) do |channel, current_transition|
          err = error_from_state_change(current_transition)
          if err
            channel.set_channel_error_reason err
          else
            # Attached & Detached are "healthy" final states so reset the error reason
            channel.clear_error_reason
          end
        end

        def self.error_from_state_change(current_transition)
          # ChannelStateChange object is always passed in current_transition metadata object
          connection_state_change = current_transition.metadata
          # Reason attribute contains errors
          err = connection_state_change&.reason
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
end
