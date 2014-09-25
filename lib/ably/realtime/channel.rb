module Ably
  module Realtime
    class Channel
      include Callbacks

      STATES = {
        initialised: 1,
        attaching:   2,
        attached:    3,
        detaching:   4,
        detached:    5,
        failed:      6
      }.freeze

      attr_reader :client, :name

      # Retrieve a state symbol by the integer value
      def self.state_sym_for(state_int)
        @states_index_by_int ||= STATES.invert.freeze
        @states_index_by_int[state_int]
      end

      def initialize(client, name)
        @client          = client
        @name            = name
        @subscriptions   = Hash.new { |hash, key| hash[key] = [] }
        @queue           = []

        set_state :initialised

        on(:message) do |message|
          @subscriptions[:all].each { |cb| cb.call(message) }
          @subscriptions[message.name].each { |cb| cb.call(message) }
        end

        on(:attached) do
          set_state :attached
          process_queue
        end
      end

      # Current Channel state, will always be one of {STATES}
      #
      # @return [Symbol] state
      def state
        self.class.state_sym_for(@state)
      end

      def state?(check_state)
        check_state = STATES.fetch(check_state) if check_state.kind_of?(Symbol)
        @state == check_state
      end

      def publish(event, data)
        queue << { name: event, data: data, timestamp: Time.now.to_i * 1000 }

        if attached?
          process_queue
        else
          attach
        end
      end

      def subscribe(event = :all, &blk)
        event = event.to_s unless event == :all
        attach unless attached?
        @subscriptions[event] << blk
      end

      def attach
        unless state?(:attaching)
          set_state :attaching
          client.attach_to_channel(name)
        end
      end

      def attached?
        state?(:attached)
      end

      private
      attr_reader :queue

      def set_state(new_state)
        new_state = STATES.fetch(new_state) if new_state.kind_of?(Symbol)
        raise ArgumentError, "#{new_state} is not a valid state" unless STATES.values.include?(new_state)
        @state = new_state
      end

      def process_queue
        client.send_messages(name, queue.shift(100)) until queue.empty?
      end
    end
  end
end
