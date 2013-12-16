module Ably
  module Realtime
    class Channel
      include Callbacks

      attr_reader :client, :name

      def initialize(client, name)
        @state         = :initialised
        @client        = client
        @name          = name
        @subscriptions = Hash.new { |hash, key| hash[key] = [] }

        on(:message) do |message|
          event = message[:name]

          @subscriptions[:all].each { |cb| cb.call(message) }
          @subscriptions[event].each { |cb| cb.call(message) }
        end
      end

      def publish(event, data)
        message = { name: event, data: data }

        if attached?
          client.send_message(name, message)
        else
          on(:attached) { client.send_message(name, message) }
          attach
        end
      end

      def subscribe(event = :all, &blk)
        @subscriptions[event] << blk
      end

      private
      def attached?
        @state == :attached
      end

      def attach
        unless @state == :attaching
          @state = :attaching
          client.attach_to_channel(name)
          on(:attached) { @state = :attached }
        end
      end
    end
  end
end
