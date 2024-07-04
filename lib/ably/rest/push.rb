require 'ably/rest/push/admin'

module Ably
  module Rest
    # Class providing push notification functionality
    class Push
      include Ably::Modules::Conversions

      # @private
      attr_reader :client

      def initialize(client)
        @client = client
      end

      # Admin features for push notifications like managing devices and channel subscriptions
      #
      # @return [Ably::Rest::Push::Admin]
      #
      def admin
        @admin ||= Admin.new(self)
      end
    end
  end
end
