require 'ably/realtime/push/admin'

module Ably
  module Realtime
    # Class providing push notification functionality
    class Push
      # @private
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # A {Ably::Realtime::Push::Admin} object.
      #
      # @spec RSH1
      #
      # @return [Ably::Realtime::Push::Admin]
      #
      def admin
        @admin ||= Admin.new(self)
      end
    end
  end
end
