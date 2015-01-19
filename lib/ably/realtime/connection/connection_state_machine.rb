require 'ably/modules/state_machine'

module Ably::Realtime
  class Connection
    # Internal class to manage connection state, recovery and state transitions for {Ably::Realtime::Connection}
    class ConnectionStateMachine
      include Ably::Modules::StateMachine

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
        state state_enum.to_sym, initial: index == 0
      end

      transition :from => :initialized,  :to => [:connecting, :closing]
      transition :from => :connecting,   :to => [:connected, :failed, :closing, :disconnected, :suspended]
      transition :from => :connected,    :to => [:disconnected, :suspended, :closing, :failed]
      transition :from => :disconnected, :to => [:connecting, :closing, :suspended, :failed]
      transition :from => :suspended,    :to => [:connecting, :closing, :failed]
      transition :from => :closing,      :to => [:closed]
      transition :from => :closed,       :to => [:connecting]
      transition :from => :failed,       :to => [:connecting]

      after_transition do |connection, transition|
        connection.synchronize_state_with_statemachine
      end

      after_transition(to: [:connecting], from: [:initialized, :closed, :failed]) do |connection|
        connection.manager.setup_transport
      end

      after_transition(to: [:connecting], from: [:disconnected, :suspended]) do |connection|
        connection.manager.reconnect_transport
      end

      after_transition(to: [:connected]) do |connection, current_transition|
        connection.manager.connected_with_error current_transition.metadata if is_error_type?(current_transition.metadata)
      end

      after_transition(to: [:disconnected, :suspended], from: [:connecting]) do |connection, current_transition|
        connection.manager.respond_to_transport_disconnected_when_connecting current_transition
      end

      after_transition(to: [:disconnected], from: [:connected]) do |connection, current_transition|
        connection.manager.respond_to_transport_disconnected_whilst_connected current_transition
      end

      after_transition(to: [:disconnected, :suspended]) do |connection|
        connection.manager.destroy_transport # never reuse a transport if the connection has failed
      end

      before_transition(to: [:failed]) do |connection, current_transition|
        connection.manager.fail current_transition.metadata
      end

      after_transition(to: [:closing], from: [:initialized, :disconnected, :suspended]) do |connection|
        connection.manager.force_close_connection
      end

      after_transition(to: [:closing], from: [:connecting, :connected]) do |connection|
        connection.manager.close_connection
      end

      before_transition(to: [:closed], from: [:closing]) do |connection|
        connection.manager.destroy_transport
      end

      # Transitions responsible for updating connection#error_reason
      before_transition(to: [:disconnected, :suspended, :failed]) do |connection, current_transition|
        connection.set_failed_connection_error_reason current_transition.metadata
      end

      before_transition(to: [:connected, :closed]) do |connection, current_transition|
        if is_error_type?(current_transition.metadata)
          connection.set_failed_connection_error_reason current_transition.metadata
        else
          # Connected & Closed are "healthy" final states so reset the error reason
          connection.clear_error_reason
        end
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
