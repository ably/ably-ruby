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
        :sync_starting, # Indicates the client is waiting for SYNC ProtocolMessages from Ably
        :sync_none, # Indicates the ATTACHED ProtocolMessage had no presence flag and thus no members on the channel
        :finalizing_sync,
        :in_sync,
        :failed
      )
      include Ably::Modules::StateEmitter

      def initialize(presence)
        @presence = presence

        @state = STATE(:initialized)

        # Two sets of members maintained
        # @members contains all members present on the channel
        # @local_members contains only this connection's members for the purpose of re-entering the member if channel continuity is lost
        reset_members
        reset_local_members

        @absent_member_cleanup_queue = []

        # Each SYNC session has a unique ID so that following SYNC
        # any members present in the map without this session ID are
        # not present according to Ably, see #RTP19
        @sync_session_id = -1

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
      end

      # When channel serial in ProtocolMessage SYNC is nil or
      # an empty cursor appears after the ':' such as 'cf30e75054887:psl_7g:client:189'.
      # That is an indication that there are no more SYNC messages.
      #
      # @api private
      #
      def sync_serial_cursor_at_end?
        sync_serial.nil? || sync_serial.to_s.match(/^[\w-]+:?$/)
      end

      # Get the list of presence members
      #
      # @param [Hash,String] options an options Hash to filter members
      # @option options [String] :client_id      optional client_id filter for the member
      # @option options [String] :connection_id  optional connection_id filter for the member
      # @option options [String] :wait_for_sync  defaults to true, if true the get method waits for the initial presence sync following channel attachment to complete before returning the members present, else it immediately returns the members present currently
      #
      # @yield [Array<Ably::Models::PresenceMessage>] array of present members
      #
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
      #
      def get(options = {}, &block)
        wait_for_sync = options.fetch(:wait_for_sync, true)
        deferrable    = Ably::Util::SafeDeferrable.new(logger)

        result_block = lambda do
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

          in_sync_callback = lambda do
            reset_callbacks.call if reset_callbacks
            result_block.call
          end

          failed_callback = lambda do |error|
            reset_callbacks.call if reset_callbacks
            deferrable.fail error
          end

          reset_callbacks = lambda do
            off(&in_sync_callback)
            off(&failed_callback)
            channel.off(&failed_callback)
          end

          unsafe_once(:in_sync, &in_sync_callback)
          unsafe_once(:failed, &failed_callback)

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

      # A copy of the local members present i.e. members entered from this connection
      # and thus the responsibility of this library to re-enter on the channel automatically if the
      # channel loses continuity
      #
      # @return [Array<PresenceMessage>]
      # @api private
      def local_members
        @local_members
      end

      private
      attr_reader :sync_session_id

      def members
        @members
      end

      def sync_serial
        @sync_serial
      end

      def presence
        @presence
      end

      def absent_member_cleanup_queue
        @absent_member_cleanup_queue
      end

      def reset_members
        @members = Hash.new
      end

      def reset_local_members
        @local_members = Hash.new
      end

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
          presence_message.decode(client.encoders, channel.options) do |encode_error, error_message|
            client.logger.error error_message
          end
          update_members_and_emit_events presence_message
        end

        channel.unsafe_on(:failed, :detached) do
          reset_members
          reset_local_members
        end

        resume_sync_proc = method(:resume_sync).to_proc

        unsafe_on(:sync_starting) do
          @sync_session_id += 1

          channel.unsafe_once(:attached) do
            connection.on_resume(&resume_sync_proc)
          end

          unsafe_once(:in_sync, :failed) do
            connection.off_resume(&resume_sync_proc)
          end
        end

        unsafe_on(:sync_none) do
          @sync_session_id += 1
          # Immediately change to finalizing which will result in all members being cleaned up
          change_state :finalizing_sync
        end

        unsafe_on(:finalizing_sync) do
          clean_up_absent_members
          clean_up_members_not_present_in_sync
          change_state :in_sync
        end

        unsafe_on(:in_sync) do
          update_local_member_state
        end
      end

      # Listen for events that change the PresenceMap state and thus
      # need to be replicated to the local member set
      def update_local_member_state
        new_local_members = members.select do |member_key, member|
          member.fetch(:message).connection_id == connection.id
        end.each_with_object({}) do |(member_key, member), hash_object|
          hash_object[member_key] = member.fetch(:message)
        end

        @local_members.reject do |member_key, message|
          new_local_members.keys.include?(member_key)
        end.each do |member_key, message|
          re_enter_local_member_missing_from_presence_map message
        end

        @local_members = new_local_members
      end

      def re_enter_local_member_missing_from_presence_map(presence_message)
        local_client_id = presence_message.client_id || client.auth.client_id
        logger.debug { "#{self.class.name}: Manually re-entering local presence member, client ID: #{local_client_id} with data: #{presence_message.data}" }
        presence.enter_client(local_client_id, presence_message.data).tap do |deferrable|
          deferrable.errback do |error|
            presence_message_client_id = presence_message.client_id || client.auth.client_id
            re_enter_error = Ably::Models::ErrorInfo.new(
              message: "unable to automatically re-enter presence channel for client_id '#{presence_message_client_id}'. Source error code #{error.code} and message '#{error.message}'",
              code: Ably::Exceptions::Codes::UNABLE_TO_AUTOMATICALLY_REENTER_PRESENCE_CHANNEL
            )
            channel.emit :update, Ably::Models::ChannelStateChange.new(
              current: channel.state,
              previous: channel.state,
              event: Ably::Realtime::Channel::EVENT(:update),
              reason: re_enter_error,
              resumed: true
            )
          end
        end
      end

      # Trigger a manual SYNC operation to resume member synchronisation from last known cursor position
      def resume_sync
        connection.send_protocol_message(
          action:         Ably::Models::ProtocolMessage::ACTION.Sync.to_i,
          channel:        channel.name,
          channel_serial: sync_serial
        ) if channel.attached?
      end

      def update_members_and_emit_events(presence_message)
        return unless ensure_presence_message_is_valid(presence_message)

        unless should_update_member?(presence_message)
          logger.debug { "#{self.class.name}: Skipped presence member #{presence_message.action} on channel #{presence.channel.name}.\n#{presence_message.to_json}" }
          touch_presence_member presence_message
          return
        end

        case presence_message.action
        when Ably::Models::PresenceMessage::ACTION.Enter, Ably::Models::PresenceMessage::ACTION.Update, Ably::Models::PresenceMessage::ACTION.Present
          add_presence_member presence_message
        when Ably::Models::PresenceMessage::ACTION.Leave
          remove_presence_member presence_message
        else
          Ably::Exceptions::ProtocolError.new("Protocol error, unknown presence action #{presence_message.action}", 400, Ably::Exceptions::Codes::PROTOCOL_ERROR)
        end
      end

      def ensure_presence_message_is_valid(presence_message)
        return true if presence_message.connection_id

        error = Ably::Exceptions::ProtocolError.new("Protocol error, presence message is missing connectionId", 400, Ably::Exceptions::Codes::PROTOCOL_ERROR)
        logger.error { "PresenceMap: On channel '#{channel.name}' error: #{error}" }
      end

      # If the message received is older than the last known event for presence
      # then skip (return false). This can occur during a SYNC operation.  For example:
      #   - SYNC starts
      #   - LEAVE event received for clientId 5
      #   - SYNC present even received for clientId 5 with a timestamp before LEAVE event because the LEAVE occured before the SYNC operation completed
      #
      # @return [Boolean] true when +new_message+ is newer than the existing member in the PresenceMap
      #
      def should_update_member?(new_message)
        if members[new_message.member_key]
          existing_message = members[new_message.member_key].fetch(:message)

          # If both are messages published by clients (not fabricated), use the ID to determine newness, see #RTP2b2
          if new_message.id.start_with?(new_message.connection_id) && existing_message.id.start_with?(existing_message.connection_id)
            new_message_parts = new_message.id.match(/(\d+):(\d+)$/)
            existing_message_parts = existing_message.id.match(/(\d+):(\d+)$/)

            if !new_message_parts || !existing_message_parts
              logger.fatal { "#{self.class.name}: Message IDs for new message #{new_message.id} or old message #{existing_message.id} are invalid. \nNew message: #{new_message.to_json}" }
              return existing_message.timestamp < new_message.timestamp
            end

            # ID is in the format "connid:msgSerial:index" such as "aaaaaa:0:0"
            # if msgSerial is greater then the new_message should update the member
            # if msgSerial is equal and index is greater, then update the member
            if new_message_parts[1].to_i > existing_message_parts[1].to_i # msgSerial
              true
            elsif new_message_parts[1].to_i == existing_message_parts[1].to_i # msgSerial equal
              new_message_parts[2].to_i > existing_message_parts[2].to_i # compare index
            else
              false
            end
          else
            # This message is fabricated or could not be validated so rely on timestamps, see #RTP2b1
            new_message.timestamp > existing_message.timestamp
          end
        else
          true
        end
      end

      def add_presence_member(presence_message)
        logger.debug { "#{self.class.name}: Member '#{presence_message.member_key}' for event '#{presence_message.action}' #{members.has_key?(presence_message.member_key) ? 'updated' : 'added'}.\n#{presence_message.to_json}" }
        # Mutate the PresenceMessage so that the action is :present, see #RTP2d
        present_presence_message = presence_message.shallow_clone(action: Ably::Models::PresenceMessage::ACTION.Present)
        member_set_upsert present_presence_message, true
        presence.emit_message presence_message.action, presence_message
      end

      def remove_presence_member(presence_message)
        logger.debug { "#{self.class.name}: Member '#{presence_message.member_key}' removed.\n#{presence_message.to_json}" }

        if in_sync?
          member_set_delete presence_message
        else
          member_set_upsert presence_message, false
          absent_member_cleanup_queue << presence_message
        end

        presence.emit_message presence_message.action, presence_message
      end

      # No update is necessary for this member as older / no change during update
      # however we need to update the sync_session_id so that this member is not removed following SYNC
      def touch_presence_member(presence_message)
        members.fetch(presence_message.member_key)[:sync_session_id] = sync_session_id
      end

      def member_set_upsert(presence_message, present)
        members[presence_message.member_key] = { present: present, message: presence_message, sync_session_id: sync_session_id }
        if presence_message.connection_id == connection.id
          local_members[presence_message.member_key] = presence_message
          logger.debug { "#{self.class.name}: Local member '#{presence_message.member_key}' added" }
        end
      end

      def member_set_delete(presence_message)
        members.delete presence_message.member_key
        if in_sync?
          # If not in SYNC, then local members missing may need to be re-entered
          # Let #update_local_member_state handle missing members
          local_members.delete presence_message.member_key
        end
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
        while member_to_remove = absent_member_cleanup_queue.shift
          logger.debug { "#{self.class.name}: Cleaning up absent member '#{member_to_remove.member_key}' after SYNC.\n#{member_to_remove.to_json}" }
          member_set_delete member_to_remove
        end
      end

      def clean_up_members_not_present_in_sync
        members.select do |member_key, member|
          member.fetch(:sync_session_id) != sync_session_id
        end.each do |member_key, member|
          presence_message = member.fetch(:message).shallow_clone(action: Ably::Models::PresenceMessage::ACTION.Leave, id: nil)
          logger.debug { "#{self.class.name}: Fabricating a LEAVE event for member '#{presence_message.member_key}' was not present in recently completed SYNC session ID '#{sync_session_id}'.\n#{presence_message.to_json}" }
          member_set_delete member.fetch(:message)
          presence.emit_message Ably::Models::PresenceMessage::ACTION.Leave, presence_message
        end
      end
    end
  end
end
