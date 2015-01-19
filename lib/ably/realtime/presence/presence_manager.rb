module Ably::Realtime
  class Presence
    # PresenceManager is responsible for all actions relating to presence state
    #
    # This is a private class and should never be used directly by developers as the API is likely to change in future.
    #
    # @api private
    class PresenceManager
      extend Forwardable

      # {Ably::Realtime::Presence} this Manager is associated with
      # @return [Ably::Realtime::Presence]
      attr_reader :presence

      def initialize(presence)
        @presence = presence

        setup_channel_event_handlers
      end

      # Expect SYNC ProtocolMessages from the server with a list of current members on this channel
      #
      # @return [void]
      #
      # @api private
      def sync_expected
        presence.members.change_state :sync_starting
      end

      # There server has indicated that there are no SYNC ProtocolMessages to come because
      # there are no members on this channel
      #
      # @return [void]
      #
      # @api private
      def sync_not_expected
        presence.members.change_state :in_sync
      end

      private
      def_delegators :presence, :members, :channel

      def setup_channel_event_handlers
        channel.on(:detached) do
          presence.transition_state_machine :left if presence.can_transition_to?(:left)
        end

        channel.on(:failed) do |metadata|
          presence.transition_state_machine :failed, metadata if presence.can_transition_to?(:failed)
        end

        presence.on(:entered) do |message|
          presence.set_connection_id message.connection_id
        end
      end
    end
  end
end
