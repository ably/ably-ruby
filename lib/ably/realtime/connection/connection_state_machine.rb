# frozen_string_literal: true

require 'ably/modules/state_machine'

module Ably
  module Realtime
    class Connection
      # Internal class to manage connection state, recovery and state transitions for {Ably::Realtime::Connection}
      class ConnectionStateMachine
        include ::Ably::Modules::StateMachine

        # States supported by this StateMachine match #{Connection::STATE}s
        #   :initialized
        #   :connecting
        #   :connected
        #   :disconnected
        #   :suspended
        #   :closing
        #   :closed
        #   :failed
        Connection::STATE.each_with_index do |state_enum, index|
          state state_enum.to_sym, initial: index.zero?
        end

        transition from: :initialized,  to: %I[connecting closing]
        transition from: :connecting,   to: %I[connected failed closing disconnected suspended]
        transition from: :connected,    to: %I[disconnected suspended closing failed]
        transition from: :disconnected, to: %I[connecting closing suspended failed]
        transition from: :suspended,    to: %I[connecting closing failed]
        transition from: :closing,      to: %I[closed]
        transition from: :closed,       to: %I[connecting]
        transition from: :failed,       to: %I[connecting]

        after_transition do |connection, _|
          connection.synchronize_state_with_statemachine
        end

        after_transition(to: %I[connecting], from: %I[initialized closed failed]) do |connection|
          connection.manager.setup_transport
        end

        after_transition(to: %I[connecting], from: %I[failed]) do |connection|
          connection.manager.reintialize_failed_chanels
        end

        after_transition(to: %I[connecting], from: %I[disconnected suspended]) do |connection|
          connection.manager.reconnect_transport
        end

        before_transition(to: %I[connected]) do |connection, current_transition|
          connection.manager.connected current_transition.metadata.protocol_message
        end

        after_transition(to: %I[connected]) do |connection, current_transition|
          error = current_transition.metadata.reason
          connection.logger.warn { "ConnectionManager: Connected with error - #{error.message}" } if is_error_type?(error)
        end

        after_transition(to: %I[disconnected suspended], from: %I[connecting]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.manager.respond_to_transport_disconnected_when_connecting err
        end

        after_transition(to: %I[disconnected suspended], from: %I[connected]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.manager.respond_to_transport_disconnected_whilst_connected err
        end

        after_transition(to: %I[suspended]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.manager.suspend_active_channels err
        end

        after_transition(to: %I[disconnected suspended]) do |connection|
          connection.manager.destroy_transport # never reuse a transport if the connection has failed
        end

        before_transition(to: %I[failed]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.manager.fail err
        end

        after_transition(to: %I[failed]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.manager.fail_active_channels err
        end

        # RTN7C - If a connection enters the SUSPENDED, CLOSED or FAILED state...
        #   the client should consider the delivery of those messages as failed
        after_transition(to: %I[suspended closed failed]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.manager.nack_messages_on_all_channels err
        end

        after_transition(to: %I[closing], from: %I[initialized disconnected suspended]) do |connection|
          connection.manager.force_close_connection
        end

        after_transition(to: %I[closing], from: %I[connecting connected]) do |connection|
          connection.manager.close_connection
        end

        before_transition(to: %I[closed], from: %I[closing]) do |connection|
          connection.manager.destroy_transport
        end

        after_transition(to: %I[closed]) do |connection|
          connection.manager.detach_active_channels
        end

        # Transitions responsible for updating connection#error_reason
        before_transition(to: %I[disconnected suspended failed]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          connection.set_failed_connection_error_reason err
        end

        before_transition(to: %I[connected closed]) do |connection, current_transition|
          err = error_from_state_change(current_transition)
          if err
            connection.set_failed_connection_error_reason err
          else
            # Connected & Closed are "healthy" final states so reset the error reason
            connection.clear_error_reason
          end
        end

        def self.error_from_state_change(current_transition)
          # ConnectionStateChange object is always passed in current_transition metadata object
          connection_state_change = current_transition.metadata
          # Reason attribute contains errors
          err = connection_state_change&.reason
          err if is_error_type?(err)
        end

        private

        def connection
          object
        end

        def logger
          connection.logger
        end
      end
    end
  end
end
