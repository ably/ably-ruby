module Ably::Realtime
  class Presence
    # PresenceManager is responsible for all actions relating to presence state
    #
    # This is a private class and should never be used directly by developers as the API is likely to change in future.
    #
    # @api private
    #
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

      # Process presence messages from SYNC messages. Sync can be server-initiated or triggered following ATTACH
      #
      # @return [void]
      #
      # @api private
      def sync_process_messages(serial, presence_messages)
        unless presence.members.sync_starting?
          presence.members.change_state :sync_starting
        end

        presence.members.update_sync_serial serial

        presence_messages.each do |presence_message|
          presence.__incoming_msgbus__.publish :sync, presence_message
        end

        presence.members.change_state :finalizing_sync if presence.members.sync_serial_cursor_at_end?
      end

      # There server has indicated that there are no SYNC ProtocolMessages to come because
      # there are no members on this channel
      #
      # @return [void]
      #
      # @api private
      def sync_not_expected
        logger.debug { "#{self.class.name}: Emitting leave events for all members as a SYNC is not expected and thus there are no members on the channel" }
        presence.members.change_state :sync_none
      end

      private
      def_delegators :presence, :members, :channel

      def setup_channel_event_handlers
        channel.unsafe_on(:detached) do
          if !presence.initialized?
            presence.transition_state_machine :left if presence.can_transition_to?(:left)
          end
        end

        channel.unsafe_on(:failed) do |metadata|
          if !presence.initialized?
            presence.transition_state_machine :left, metadata if presence.can_transition_to?(:left)
          end
        end
      end

      def logger
        presence.channel.client.logger
      end
    end
  end
end
