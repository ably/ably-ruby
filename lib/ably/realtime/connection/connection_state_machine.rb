require 'statesman'

module Ably::Realtime
  class Connection
    module StatesmanMonkeyPatch
      # Override Statesman's #before_transition to support :from arrays
      # This can be removed once https://github.com/gocardless/statesman/issues/95 is solved
      def before_transition(options = nil, &block)
        arrayify_transition(options) do |options_without_from_array|
          super *options_without_from_array, &block
        end
      end

      def after_transition(options = nil, &block)
        arrayify_transition(options) do |options_without_from_array|
          super *options_without_from_array, &block
        end
      end

      private
      def arrayify_transition(options, &block)
        if options.nil?
          yield []
        elsif options.fetch(:from, nil).kind_of?(Array)
          options[:from].each do |from_state|
            yield [options.merge(from: from_state)]
          end
        else
          yield [options]
        end
      end
    end

    # Internal class to manage connection state, recovery and state transitions for an {Ably::Realtime::Connection}
    class ConnectionStateMachine
      include Statesman::Machine
      extend StatesmanMonkeyPatch

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
      transition :from => :connecting,   :to => [:connected, :failed, :closing, :disconnected]
      transition :from => :connected,    :to => [:disconnected, :suspended, :closing, :failed]
      transition :from => :disconnected, :to => [:connecting, :closing, :failed]
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

      after_transition(to: [:disconnected], from: [:connecting]) do |connection, current_transition|
        connection.manager.respond_to_transport_disconnected current_transition
      end

      after_transition(to: [:failed]) do |connection|
        connection.manager.destroy_transport
      end

      after_transition(to: [:closing], from: [:initialized]) do |connection|
        connection.manager.cancel_initialized_timers
        connection.manager.force_close_connection
      end

      after_transition(to: [:closing], from: [:connecting, :connected, :disconnected, :suspended]) do |connection|
        connection.manager.close_connection
      end

      before_transition(to: [:closed], from: [:closing]) do |connection|
        connection.manager.destroy_transport
      end

      # Override Statesman's #transition_to so that:
      # * log state change failures to {Logger}
      # * raise an exception on the {Ably::Realtime::Connection}
      def transition_to(state, *args)
        unless result = super(state, *args)
          error_message = "ConnectionStateMachine: Unable to transition from #{current_state} => #{state}"
          connection.trigger :error, Ably::Exceptions::ConnectionError.new(error_message, nil, 80020)
          logger.fatal error_message
        end
        result
      end

      def previous_transition
        history[-2]
      end

      def previous_state
        previous_transition.to_state if previous_transition
      end

      private
      # TODO: Implement once CLOSED ProtocolMessage is sent back from Ably in response to a CLOSE message
      #
      # FORCE_CONNECTION_CLOSED_TIMEOUT = 5
      #
      # def force_closed_unless_server_acknowledge_closed
      #   timeouts[:close_connection] << EventMachine::Timer.new(FORCE_CONNECTION_CLOSED_TIMEOUT) do
      #     transition_to :closed
      #   end
      # end
      #
      # def clear_force_closed_timeouts
      #   timeouts[:close_connection].each do |timeout|
      #     timeout.cancel
      #   end.clear
      # end

      def connection
        object
      end

      def logger
        connection.logger
      end
    end
  end
end
