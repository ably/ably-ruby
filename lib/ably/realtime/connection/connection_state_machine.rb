require 'statesman'

module Ably::Realtime
  class Connection
    module StatesmanMonkeyPatch
      # Override Statesman's #before_transition to support :from arrays
      # This can be removed once https://github.com/gocardless/statesman/issues/95 is solved
      def before_transition(options, &block)
        if options.fetch(:from, nil).kind_of?(Array)
          options[:from].each do |from_state|
            super(options.merge(from: from_state), &block)
          end
        else
          super
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
      #   :closed
      #   :failed
      Connection::STATE.each_with_index do |state_enum, index|
        state state_enum.to_sym, initial: index == 0
      end

      transition :from => :initialized,  :to => [:connecting, :closed]
      transition :from => :connecting,   :to => [:connected, :failed, :closed]
      transition :from => :connected,    :to => [:disconnected, :suspended, :closed, :failed]
      transition :from => :disconnected, :to => [:connecting, :closed]
      transition :from => :suspended,    :to => [:connecting, :closed]
      transition :from => :closed,       :to => [:connecting]
      transition :from => :failed,       :to => [:connecting]

      before_transition(to: [:connecting], from: [:initialized, :closed, :failed]) do |connection|
        connection.setup_transport do |transport|
          # Transition this StateMachine once the transport is connected or disconnected
          # Invalid state changes are simply ignored and logged
          transport.on(:disconnected) do
            connection.transition_state_machine :disconnected
          end
        end
      end

      before_transition(to: [:connecting], from: [:disconnected, :suspended]) do |connection|
        connection.reconnect_transport
      end

      after_transition(to: [:failed]) do |connection|
        connection.transport.disconnect
      end

      before_transition(to: [:closed], from: [:initialized]) do |connection|
        connection.timers.fetch(:initializer, []).each(&:cancel)
      end

      before_transition(to: [:closed], from: [:connecting, :connected, :disconnected, :suspended]) do |connection|
        connection.send_protocol_message action: Models::ProtocolMessage::ACTION.Close
        connection.transport.disconnect
      end

      after_transition do |connection, transition|
        connection.change_state transition.to_state
      end

      def initialize(connection)
        @connection = connection
        super(connection)
      end

      # Override Statesman's #transition_to to simply log state change failures
      def transition_to(*args)
        unless super(*args)
          logger.debug "Unable to transition to #{args[0]} from #{current_state}"
        end
      end

      private
      attr_reader :connection

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

      def logger
        connection.logger
      end
    end
  end
end
