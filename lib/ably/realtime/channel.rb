require 'ably/realtime/channel/publisher'

module Ably
  module Realtime
    # Enables messages to be published and subscribed to. Also enables historic messages to be retrieved and provides
    # access to the {Ably::Realtime::Channel} object of a channel.
    #
    # Channels will always be in one of the following states:
    #
    #   initialized: 0
    #   attaching:   1
    #   attached:    2
    #   detaching:   3
    #   detached:    4
    #   failed:      5
    #
    # Note that the states are available as Enum-like constants:
    #
    #   Channel::STATE.Initialized  The channel has been initialized but no attach has yet been attempted.
    #   Channel::STATE.Attaching    An attach has been initiated by sending a request to Ably.
    #                               This is a transient state, followed either by a transition to ATTACHED, SUSPENDED, or FAILED.
    #   Channel::STATE.Attached     The attach has succeeded. In the ATTACHED state a client may publish and subscribe to messages, or be present on the channel.
    #   Channel::STATE.Detaching    A detach has been initiated on an ATTACHED channel by sending a request to Ably.
    #                               This is a transient state, followed either by a transition to DETACHED or FAILED.
    #   Channel::STATE.Detached     The channel, having previously been ATTACHED, has been detached by the user.
    #   Channel::STATE.Suspended    The channel, having previously been ATTACHED, has lost continuity, usually due to
    #                               the client being disconnected from Ably for longer than two minutes. It will automatically attempt to reattach as soon as connectivity is restored.
    #   Channel::STATE.Failed       An indefinite failure condition. This state is entered if a channel error
    #                               has been received from the Ably service, such as an attempt to attach without the necessary access rights.
    #
    class Channel
      include Ably::Modules::Conversions
      include Ably::Modules::EventEmitter
      include Ably::Modules::EventMachineHelpers
      include Ably::Modules::AsyncWrapper
      include Ably::Modules::MessageEmitter
      include Ably::Realtime::Channel::Publisher
      extend Ably::Modules::Enum
      extend Forwardable

      # The current {Abbly::Realtime::Channel::STATE} of the channel.
      #
      # @spec RTL2b
      #
      # The permited states for this channel
      STATE = ruby_enum('STATE',
        :initialized,
        :attaching,
        :attached,
        :detaching,
        :detached,
        :suspended,
        :failed
      )

      # Describes the events emitted by a {Ably::Rest::Channel} or {Ably::Realtime::Channel} object.
      # An event is either an UPDATE or a {Ably::Rest::Channel::STATE}.
      #
      # The permitted channel events that are emitted for this channel
      #
      # @spec RTL2g
      #
      EVENT = ruby_enum('EVENT',
        STATE.to_sym_arr + [:update]
      )

      include Ably::Modules::StateEmitter
      include Ably::Modules::UsesStateMachine
      ensure_state_machine_emits 'Ably::Models::ChannelStateChange'

      # Max number of messages to bundle in a single ProtocolMessage
      MAX_PROTOCOL_MESSAGE_BATCH_SIZE = 50

      # {Ably::Realtime::Client} associated with this channel
      #
      # @return [Ably::Realtime::Client]
      #
      # @api private
      attr_reader :client

      # The channel name.
      # @return [String]
      attr_reader :name

      # A {Ably::Realtime::Channel::PushChannel} object.
      #
      # @return [Ably::Realtime::Channel::PushChannel]
      attr_reader :push

      # Channel options configured for this channel, see {#initialize} for channel_options
      # @return [Hash]
      attr_reader :options

      # A {Ably::Realtime::Channel::ChannelProperties} object.
      #
      # @spec CP1, RTL15
      #
      # @return [{Ably::Realtime::Channel::ChannelProperties}]
      attr_reader :properties

      # An {Ably::Models::ErrorInfo} object describing the last error which occurred on the channel, if any.
      # @spec RTL4e
      # @return [Ably::Models::ErrorInfo,Ably::Exceptions::BaseAblyException]
      attr_reader :error_reason

      # The Channel manager responsible for attaching, detaching and handling failures for this channel
      # @return [Ably::Realtime::Channel::ChannelManager]
      # @api private
      attr_reader :manager

      # Flag that specifies whether channel is resuming attachment(reattach) or is doing a 'clean attach' RTL4j1
      # @return [Boolean]
      # @api private
      attr_reader :attach_resume

      # Optional channel parameters that configure the behavior of the channel.
      # @spec RTL4k1
      # return [Hash]
      def_delegators :options, :params

      # Initialize a new Channel object
      #
      # @param  client [Ably::Rest::Client]
      # @param  name [String] The name of the channel
      # @param  channel_options [Hash, Ably::Models::ChannelOptions]     A hash of options or a {Ably::Models::ChannelOptions}
      #
      def initialize(client, name, channel_options = {})
        name = ensure_utf_8(:name, name)

        @options       = Ably::Models::ChannelOptions(channel_options)
        @client        = client
        @name          = name
        @queue         = []

        @state_machine = ChannelStateMachine.new(self)
        @state         = STATE(state_machine.current_state)
        @manager       = ChannelManager.new(self, client.connection)
        @push          = PushChannel.new(self)
        @properties    = ChannelProperties.new(self)
        @attach_resume = false

        setup_event_handlers
        setup_presence
      end

      # Publish a message to the channel. A callback may optionally be passed in to this call to be notified of success
      # or failure of the operation. When publish is called with this client library, it won't attempt to implicitly
      # attach to the channel.
      #
      # @spec RTL6i
      #
      # @param name [String, Array<Ably::Models::Message|Hash>, nil]   The event name of the message to publish, or an Array of [Ably::Model::Message] objects or [Hash] objects with +:name+ and +:data+ pairs
      # @param data [String, ByteArray, nil]   The message payload unless an Array of [Ably::Model::Message] objects passed in the first argument
      # @param attributes [Hash, nil]   Optional additional message attributes such as :client_id or :connection_id, applied when name attribute is nil or a string
      #
      # @yield [Ably::Models::Message,Array<Ably::Models::Message>] On success, will call the block with the {Ably::Models::Message} if a single message is published, or an Array of {Ably::Models::Message} when multiple messages are published
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
      #
      # @example
      #   # Publish a single message form
      #   channel.publish 'click', { x: 1, y: 2 }
      #
      #   # Publish a single message with single Hash form
      #   message = { name: 'click', data: { x: 1, y: 2 } }
      #   channel.publish message
      #
      #   # Publish an array of message Hashes form
      #   messages = [
      #     { name: 'click', data: { x: 1, y: 2 } },
      #     { name: 'click', data: { x: 2, y: 3 } }
      #   ]
      #   channel.publish messages
      #
      #   # Publish an array of Ably::Models::Message objects form
      #   messages = [
      #     Ably::Models::Message(name: 'click', data: { x: 1, y: 2 })
      #     Ably::Models::Message(name: 'click', data: { x: 2, y: 3 })
      #   ]
      #   channel.publish messages
      #
      #   # Publish an array of Ably::Models::Message objects form
      #   message = Ably::Models::Message(name: 'click', data: { x: 1, y: 2 })
      #   channel.publish message
      #
      #   channel.publish('click', 'body') do |message|
      #     puts "#{message.name} event received with #{message.data}"
      #   end
      #
      #   channel.publish('click', 'body').errback do |error, message|
      #     puts "#{message.name} was not received, error #{error.message}"
      #   end
      #
      def publish(name, data = nil, attributes = {}, &success_block)
        if suspended? || failed?
          error = Ably::Exceptions::ChannelInactive.new("Cannot publish messages on a channel in state #{state}")
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        if !connection.can_publish_messages?
          error = Ably::Exceptions::MessageQueueingDisabled.new("Message cannot be published. Client is not allowed to queue messages when connection is in state #{connection.state}")
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        messages = build_messages(name, data, attributes) # (RSL1a, RSL1b)

        if messages.length > Realtime::Connection::MAX_PROTOCOL_MESSAGE_BATCH_SIZE
          error = Ably::Exceptions::InvalidRequest.new("It is not possible to publish more than #{Realtime::Connection::MAX_PROTOCOL_MESSAGE_BATCH_SIZE} messages with a single publish request.")
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        enqueue_messages_on_connection(client, messages, channel_name, options).tap do |deferrable|
          deferrable.callback(&success_block) if block_given?
        end
      end

      # Registers a listener for messages on this channel. The caller supplies a listener function, which is called
      # each time one or more messages arrives on the channel. A callback may optionally be passed in to this call
      # to be notified of success or failure of the channel {Ably::Realtime::Channel#attach} operation.
      #
      # @spec RTL7a
      #
      # @param names [String] The event name of the message to subscribe to if provided.  Defaults to all events.
      # @yield [Ably::Models::Message] For each message received, the block is called
      #
      # @return [void]
      #
      def subscribe(*names, &callback)
        attach unless attached? || attaching?
        super
      end

      # Deregisters the given listener for the specified event name(s). This removes an earlier event-specific subscription.
      #
      # @spec RTL8a
      #
      # @param names [String] The event name of the message to subscribe to if provided.  Defaults to all events.
      #
      # @return [void]
      #
      def unsubscribe(*names, &callback)
        super
      end

      # Attach to this channel ensuring the channel is created in the Ably system and all messages published on
      # the channel are received by any channel listeners registered using {Ably::Realtime::Channel#subscribe}.
      # Any resulting channel state change will be emitted to any listeners registered using the {Ably::Modules::EventEmitter#on}
      # or {Ably::Modules::EventEmitter#once} methods. A callback may optionally be passed in to this call to be notified
      # of success or failure of the operation. As a convenience, attach() is called implicitly
      # if {Ably::Realtime::Channel#subscribe} for the channel is called, or {Ably::Realtime::Presence#enter}
      # or {Ably::Realtime::Presence#subscribe} are called on the {Ably::Realtime::Presence} object for this channel.
      #
      # @spec RTL4d
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Attached state
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callback
      #
      def attach(&success_block)
        if connection.closing? || connection.closed? || connection.suspended? || connection.failed?
          error = Ably::Exceptions::InvalidStateChange.new("Cannot ATTACH channel when the connection is in a closed, suspended or failed state. Connection state: #{connection.state}")
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
        end

        if !attached?
          if detaching?
            # Let the pending operation complete (#RTL4h)
            once_state_changed { transition_state_machine :attaching if can_transition_to?(:attaching) }
          else
            transition_state_machine :attaching if can_transition_to?(:attaching)
          end
        end

        deferrable_for_state_change_to(STATE.Attached, &success_block)
      end

      # Detach from this channel. Any resulting channel state change is emitted to any listeners registered using
      # the {Ably::Modules::EventEmitter#on} or {Ably::Modules::EventEmitter#once} methods. A callback may optionally
      # be passed in to this call to be notified of success or failure of the operation. Once all clients globally
      # have detached from the channel, the channel will be released in the Ably service within two minutes.
      #
      # @spec RTL5e
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Detached or Failed state
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callback
      #
      def detach(&success_block)
        if initialized?
          success_block.call if block_given?
          return Ably::Util::SafeDeferrable.new_and_succeed_immediately(logger)
        end

        if failed? || connection.closing? || connection.failed?
          return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, exception_for_state_change_to(:detaching))
        end

        if !detached?
          if attaching?
            # Let the pending operation complete (#RTL5i)
            once_state_changed { transition_state_machine :detaching if can_transition_to?(:detaching) }
          elsif can_transition_to?(:detaching)
            transition_state_machine :detaching
          else
            transition_state_machine! :detached
          end
        end

        deferrable_for_state_change_to(STATE.Detached, &success_block)
      end

      # A {Ably::Realtime::Presence} object.
      #
      # @spec RTL9
      #
      # @return {Ably::Realtime::Presence}
      #
      def presence
        @presence
      end

      # Retrieves a {Ably::Models::PaginatedResult} object, containing an array of historical
      # {Ably::Models::Message} objects for the channel. If the channel is configured to persist messages,
      # then messages can be retrieved from history for up to 72 hours in the past. If not, messages can only
      # be retrieved from history for up to two minutes in the past.
      #
      # @spec RSL2a
      #
      # @param (see {Ably::Rest::Channel#history})
      # @option options (see {Ably::Rest::Channel#history})
      # @option options [Boolean]  :until_attach  When true, the history request will be limited only to messages published before this channel was attached. Channel must be attached
      #
      # @yield [Ably::Models::PaginatedResult<Ably::Models::Message>] First {Ably::Models::PaginatedResult page} of {Ably::Models::Message} objects accessible with {Ably::Models::PaginatedResult#items #items}.
      #
      # @return [Ably::Util::SafeDeferrable]
      #
      def history(options = {}, &callback)
        # RTL10b
        if options.delete(:until_attach)
          unless attached?
            error = Ably::Exceptions::InvalidRequest.new('option :until_attach is invalid as the channel is not attached' )
            return Ably::Util::SafeDeferrable.new_and_fail_immediately(logger, error)
          end
          options[:from_serial] = properties.attach_serial
        end

        async_wrap(callback) do
          rest_channel.history(options.merge(async_blocking_operations: true))
        end
      end

      # @return [Ably::Util::PubSub] Client library internal channel incoming message bus
      #
      # @api private
      def __incoming_msgbus__
        @__incoming_msgbus__ ||= Ably::Util::PubSub.new(
          coerce_into: lambda { |event| Ably::Models::ProtocolMessage::ACTION(event) }
        )
      end

      # Sets the {Ably::Models::ChannelOptions} for the channel.
      # An optional callback may be provided to notify of the success or failure of the operation.
      #
      # @spec RTL16
      #
      # @param channel_options [Hash, Ably::Models::ChannelOptions]     A hash of options or a {Ably::Models::ChannelOptions}
      # @return [Ably::Models::ChannelOptions]
      def set_options(channel_options)
        @options = Ably::Models::ChannelOptions(channel_options)

        manager.request_reattach if need_reattach?
      end
      alias options= set_options

      # @api private
      def set_channel_error_reason(error)
        @error_reason = error
      end

      # @api private
      def clear_error_reason
        @error_reason = nil
      end

      # Used by {Ably::Modules::StateEmitter} to debug state changes
      # @api private
      def logger
        client.logger
      end

      # @api private
      def attach_resume!
        @attach_resume = true
      end

      # @api private
      def reset_attach_resume!
        @attach_resume = false
      end

      # As we are using a state machine, do not allow change_state to be used
      # #transition_state_machine must be used instead
      private :change_state

      def need_reattach?
        !!(attaching? || attached?) && !!(options.modes || options.params)
      end

      private

      def setup_event_handlers
        __incoming_msgbus__.subscribe(:message) do |message|
          message.decode(client.encoders, options) do |encode_error, error_message|
            client.logger.error error_message
          end
          emit_message message.name, message
        end
      end

      def rest_channel
        client.rest_client.channel(name)
      end

      def connection
        client.connection
      end

      def setup_presence
        @presence ||= Presence.new(self)
      end

      # Alias useful for methods with a name argument
      def channel_name
        name
      end
    end
  end
end

require 'ably/realtime/channel/channel_manager'
require 'ably/realtime/channel/channel_state_machine'
require 'ably/realtime/channel/push_channel'
require 'ably/realtime/channel/channel_properties'
