module Ably::Realtime
  class Push
    # Manage push notification channel subscriptions for devices or clients
    class ChannelSubscriptions
      include Ably::Modules::Conversions

      attr_reader :client
      attr_reader :admin

      def initialize(admin)
        @admin = admin
        @client = admin.client
      end
    end
  end
end
