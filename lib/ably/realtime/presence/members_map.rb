module Ably::Realtime
  class Presence
    # A class encapsulating a map of the members of this presence channel,
    # indexed by the unique {Ably::Models::PresenceMessage#member_key}
    #
    # This map synchronises the membership of the presence set by handling
    # SYNC messages from the service. Since sync messages can be out-of-order -
    # e.g. a PRESENT sync event being received after that member has in fact left -
    # this map keeps "witness" entries, with ABSENT Action, to remember the
    # fact that a LEAVE event has been seen for a member. These entries are
    # cleared once the last set of updates of a sync sequence have been received.
    #
    # @api private
    #
    class MembersMap
      include Ably::Modules::EventEmitter
      include Ably::Modules::SafeYield
      include Enumerable
      extend Ably::Modules::Enum

      STATE = ruby_enum('STATE',
        :initialized,
        :sync_starting,
        :in_sync,
        :failed
      )
      include Ably::Modules::StateEmitter

      # Number of absent members to cache internally whilst channel is in sync.
      # Cache is unlimited until initial sync is complete ensuring users who have left are never reported as present.
      MAX_ABSENT_MEMBER_CACHE = 100

      def initialize(presence)
        @presence = presence

        @state    = STATE(:initialized)
        @members  = Hash.new
        @absent_member_cleanup_queue = []

        setup_event_handlers
      end

      # When attaching to a channel that has members present, the server
      # initiates a sync automatically so that the client has a complete list of members.
      #
      # Until this sync is complete, this method returns false
      #
      # @return [Boolean]
      def sync_complete?
        in_sync?
      end

      # Update the SYNC serial from the ProtocolMessage so that SYNC can be resumed.
      # If the serial is nil, or the part after the first : is empty, then the SYNC is complete
      #
      # @return [void]
      #
      # @api private
      def update_sync_serial(serial)
        @sync_serial = serial
        change_state :in_sync if sync_serial_cursor_at_end?
      end

      # Get the list of presence members
      #
      # @param [Hash,String] options an options Hash to filter members
      # @option options [String] :client_id      optional client_id for the member
      # @option options [String] :connection_id  optional connection_id for the member
      # @option options [String] :wait_for_sync  defaults to true, if false the get method returns the current list of members and does not wait for the presence sync to complete
      #
      # @yield [Array<Ably::Models::PresenceMessage>] array of present members
      #
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
      #
      def get(options = {}, &block)
        wait_for_sync = options.fetch(:wait_for_sync, true)
        deferrable    = Ably::Util::SafeDeferrable.new(logger)

        result_block = proc do
          present_members.tap do |members|
            members.keep_if { |member| member.connection_id == options[:connection_id] } if options[:connection_id]
            members.keep_if { |member| member.client_id == options[:client_id] } if options[:client_id]
          end.tap do |members|
            safe_yield block, members if block_given?
            deferrable.succeed members
          end
        end

        if !wait_for_sync || sync_complete?
          result_block.call
        else
          # Must be defined before subsequent procs reference this callback
          reset_callbacks = nil

          in_sync_callback = proc do
            reset_callbacks
            result_block.call
          end

          failed_callback = proc do |error|
            reset_callbacks
            deferrable.fail error
          end

          reset_callbacks = proc do
            off &in_sync_callback
            off &failed_callback
            channel.off &failed_callback
          end

          once :in_sync, &in_sync_callback

          once(:failed, &failed_callback)
          channel.unsafe_once(:detaching, :detached, :failed) do |error_reason|
            failed_callback.call error_reason
          end
        end

        deferrable
      end

      # @!attribute [r] length
      # @return [Integer] number of present members known at this point in time, will not wait for sync operation to complete
      def length
        present_members.length
      end
      alias_method :count, :length
      alias_method :size,  :length

      # Method to allow {MembersMap} to be {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
      # @note this method will not wait for the sync operation to complete so may return an incomplete set of members.  Use {MembersMap#get} instead.
      def each(&block)
        return to_enum(:each) unless block_given?
        present_members.each(&block)
      end

      private
      attr_reader :members, :sync_serial, :presence, :absent_member_cleanup_queue

      def channel
        presence.channel
      end

      def client
        channel.client
      end

      def logger
        client.logger
      end

      def connection
        client.connection
      end

      def setup_event_handlers
        presence.__incoming_msgbus__.subscribe(:presence, :sync) do |presence_message|
          presence_message.decode channel
          update_members_and_emit_events presence_message
        end

        resume_sync_proc = method(:resume_sync).to_proc
        connection.on_resume &resume_sync_proc
        once(:in_sync, :failed) do
          connection.off_resume &resume_sync_proc
        end
      end

      # Trigger a manual SYNC operation to resume member synchronisation from last known cursor position
      def resume_sync
        connection.send_protocol_message(
          action:         Ably::Models::ProtocolMessage::ACTION.Sync.to_i,
          channel:        channel.name,
          channel_serial: sync_serial
        )
      end

      # When channel serial in ProtocolMessage SYNC is nil or
      # an empty cursor appears after the ':' such as 'cf30e75054887:psl_7g:client:189'.
      # That is an indication that there are no more SYNC messages.
      def sync_serial_cursor_at_end?
        sync_serial.nil? || sync_serial.to_s.match(/^[\w-]+:?$/)
      end

      def update_members_and_emit_events(presence_message)
        return unless ensure_presence_message_is_valid(presence_message)

        unless should_update_member?(presence_message)
          logger.debug "#{self.class.name}: Skipped presence member #{presence_message.action} on channel #{presence.channel.name}.\n#{presence_message.to_json}"
          return
        end

        case presence_message.action
        when Ably::Models::PresenceMessage::ACTION.Enter, Ably::Models::PresenceMessage::ACTION.Update, Ably::Models::PresenceMessage::ACTION.Present
          add_presence_member presence_message
        when Ably::Models::PresenceMessage::ACTION.Leave
          remove_presence_member presence_message
        else
          Ably::Exceptions::ProtocolError.new("Protocol error, unknown presence action #{presence_message.action}", 400, 80013)
        end

        clean_up_absent_members
      end

      def ensure_presence_message_is_valid(presence_message)
        return true if presence_message.connection_id

        error = Ably::Exceptions::ProtocolError.new("Protocol error, presence message is missing connectionId", 400, 80013)
        logger.error "PresenceMap: On channel '#{channel.name}' error: #{error}"
        channel.trigger :error, error
      end

      # If the message received is older than the last known event for presence
      # then skip.  This can occur during a SYNC operation.  For example:
      #   - SYNC starts
      #   - LEAVE event received for clientId 5
      #   - SYNC present even received for clientId 5 with a timestamp before LEAVE event because the LEAVE occured before the SYNC operation completed
      #
      # @return [Boolean]
      #
      def should_update_member?(presence_message)
        if members[presence_message.member_key]
          members[presence_message.member_key].fetch(:message).timestamp < presence_message.timestamp
        else
          true
        end
      end

      def add_presence_member(presence_message)
        logger.debug "#{self.class.name}: Member '#{presence_message.member_key}' for event '#{presence_message.action}' #{members.has_key?(presence_message.member_key) ? 'updated' : 'added'}.\n#{presence_message.to_json}"
        members[presence_message.member_key] = { present: true, message: presence_message }
        presence.emit_message presence_message.action, presence_message
      end

      def remove_presence_member(presence_message)
        logger.debug "#{self.class.name}: Member '#{presence_message.member_key}' removed.\n#{presence_message.to_json}"
        members[presence_message.member_key] = { present: false, message: presence_message }
        absent_member_cleanup_queue << presence_message.member_key
        presence.emit_message presence_message.action, presence_message
      end

      def present_members
        members.select do |key, presence|
          presence.fetch(:present)
        end.map do |key, presence|
          presence.fetch(:message)
        end
      end

      def absent_members
        members.reject do |key, presence|
          presence.fetch(:present)
        end.map do |key, presence|
          presence.fetch(:message)
        end
      end

      def clean_up_absent_members
        return unless sync_complete?
        members.delete absent_member_cleanup_queue.shift until absent_member_cleanup_queue.count <= MAX_ABSENT_MEMBER_CACHE
      end
    end
  end
end
