require 'statesman'

module Ably::Realtime
  class Connection
    # Internal class to manage connection state, recovery and state transitions for an {Ably::Realtime::Connection}
    class ConnectionStateMachine
      include Statesman::Machine
      extend Ably::Modules::StatesmanMonkeyPatch

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
      transition :from => :disconnected, :to => [:connecting, :closing, :suspended]
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

      before_transition(to: [:connected]) do |connection|
        connection.manager.cancel_connection_retry_timers
      end

      after_transition(to: [:disconnected, :suspended], from: [:connecting]) do |connection, current_transition|
        connection.manager.respond_to_transport_disconnected current_transition
      end

      after_transition(to: [:failed]) do |connection|
        connection.manager.destroy_transport
      end

      after_transition(to: [:closing], from: [:initialized, :disconnected, :suspended]) do |connection|
        connection.manager.cancel_initialized_timers
        connection.manager.force_close_connection
      end

      after_transition(to: [:closing], from: [:connecting, :connected]) do |connection|
        connection.manager.close_connection
      end

      before_transition(to: [:closed], from: [:closing]) do |connection|
        connection.manager.destroy_transport
      end

      # Override Statesman's #transition_to so that:
      # * log state change failures to {Logger}
      # * raise an exception on the {Ably::Realtime::Connection}
      #
      # @return [void]
      def transition_to(state, *args)
        unless result = super(state, *args)
          exception = exception_for_state_change_to(state)
          connection.trigger :error, exception
          logger.fatal exception.message
        end
        result
      end

      # @return [Statesman History Object]
      def previous_transition
        history[-2]
      end

      # @return [Symbol]
      def previous_state
        previous_transition.to_state if previous_transition
      end

      # @return [Ably::Exceptions::ConnectionStateChangeError]
      def exception_for_state_change_to(state)
        error_message = "ConnectionStateMachine: Unable to transition from #{current_state} => #{state}"
        Ably::Exceptions::ConnectionStateChangeError.new(error_message, nil, 80020)
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
