module Ably::Realtime
  class Push
    # Manage device registrations for push notifications
    class DeviceRegistrations
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
