module Ably
  module Realtime
    # The Channel class represents a Channel belonging to this application.
    # The Channel instance allows messages to be published and
    # received, and controls the lifecycle of this instance's
    # attachment to the channel.
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
    #   Channel::STATE.Initialized
    #   Channel::STATE.Attaching
    #   Channel::STATE.Attached
    #   Channel::STATE.Detaching
    #   Channel::STATE.Detached
    #   Channel::STATE.Failed
    #
    # Channels emit errors - use +on(:error)+ to subscribe to errors
    #
    # @!attribute [r] state
    #   @return {Ably::Realtime::Connection::STATE} channel state
    #
    class Channel
      include Ably::Modules::Conversions
      include Ably::Modules::EventEmitter
      include Ably::Modules::EventMachineHelpers
      include Ably::Modules::AsyncWrapper
      include Ably::Modules::MessageEmitter
      extend Ably::Modules::Enum

      STATE = ruby_enum('STATE',
        :initialized,
        :attaching,
        :attached,
        :detaching,
        :detached,
        :failed
      )
      include Ably::Modules::StateEmitter
      include Ably::Modules::UsesStateMachine

      # Max number of messages to bundle in a single ProtocolMessage
      MAX_PROTOCOL_MESSAGE_BATCH_SIZE = 50

      # {Ably::Realtime::Client} associated with this channel
      # @return [Ably::Realtime::Client]
      attr_reader :client

      # Channel name
      # @return [String]
      attr_reader :name

      # Channel options configured for this channel, see {#initialize} for channel_options
      # @return [Hash]
      attr_reader :options

      # When a channel failure occurs this attribute contains the Ably Exception
      # @return [Ably::Models::ErrorInfo,Ably::Exceptions::BaseAblyException]
      attr_reader :error_reason

      # The Channel manager responsible for attaching, detaching and handling failures for this channel
      # @return [Ably::Realtime::Channel::ChannelManager]
      # @api private
      attr_reader :manager

      # Serial number assigned to this channel when it was attached
      # @return [Integer]
      # @api private
      attr_reader :attached_serial

      # Initialize a new Channel object
      #
      # @param  client [Ably::Rest::Client]
      # @param  name [String] The name of the channel
      # @param  channel_options [Hash]     Channel options, currently reserved for Encryption options
      # @option channel_options [Boolean]  :encrypted       setting this to true for this channel will encrypt & decrypt all messages automatically
      # @option channel_options [Hash]     :cipher_params   A hash of options to configure the encryption. *:key* is required, all other options are optional.  See {Ably::Util::Crypto#initialize} for a list of +cipher_params+ options
      #
      def initialize(client, name, channel_options = {})
        ensure_utf_8 :name, name

        update_options channel_options
        @client        = client
        @name          = name
        @queue         = []

        @state_machine = ChannelStateMachine.new(self)
        @state         = STATE(state_machine.current_state)
        @manager       = ChannelManager.new(self, client.connection)

        setup_event_handlers
        setup_presence
      end

      # Publish one or more messages to the channel.
      #
      # When publishing a message, if the channel is not attached, the channel is implicitly attached
      #
      # @param name [String, Array<Ably::Models::Message|Hash>, nil]   The event name of the message to publish, or an Array of [Ably::Model::Message] objects or [Hash] objects with +:name+ and +:data+ pairs
      # @param data [String, ByteArray, nil]   The message payload unless an Array of [Ably::Model::Message] objects passed in the first argument
      #
      # @yield [Ably::Models::Message,Array<Ably::Models::Message>] On success, will call the block with the {Ably::Models::Message} if a single message is publishde, or an Array of {Ably::Models::Message} when multiple messages are published
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callbacks
      #
      # @example
      #   # Publish a single message
      #   channel.publish 'click', { x: 1, y: 2 }
      #
      #   # Publish an array of message Hashes
      #   messages = [
      #     { name: 'click', { x: 1, y: 2 } },
      #     { name: 'click', { x: 2, y: 3 } }
      #   ]
      #   channel.publish messages
      #
      #   # Publish an array of Ably::Models::Message objects
      #   messages = [
      #     Ably::Models::Message(name: 'click', { x: 1, y: 2 })
      #     Ably::Models::Message(name: 'click', { x: 2, y: 3 })
      #   ]
      #   channel.publish messages
      #
      #   channel.publish('click', 'body') do |message|
      #     puts "#{message.name} event received with #{message.data}"
      #   end
      #
      #   channel.publish('click', 'body').errback do |message, error|
      #     puts "#{message.name} was not received, error #{error.message}"
      #   end
      #
      def publish(name, data = nil, &success_block)
        raise Ably::Exceptions::ChannelInactive.new('Cannot publish messages on a detached channel') if detached? || detaching?
        raise Ably::Exceptions::ChannelInactive.new('Cannot publish messages on a failed channel') if failed?

        if !client.connection.can_publish_messages?
          raise Ably::Exceptions::MessageQueueingDisabled.new("Message cannot be published. Client is configured to disallow queueing of messages and connection is currently #{client.connection.state}")
        end

        messages = if name.kind_of?(Enumerable)
          name
        else
          ensure_utf_8 :name, name, allow_nil: true
          ensure_supported_payload data
          [{ name: name, data: data }]
        end

        queue_messages(messages).tap do |deferrable|
          deferrable.callback &success_block if block_given?
        end
      end

      # Subscribe to messages matching providing event name, or all messages if event name not provided.
      #
      # When subscribing to messages, if the channel is not attached, the channel is implicitly attached
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

      # Unsubscribe the matching block for messages matching providing event name, or all messages if event name not provided.
      # If a block is not provided, all subscriptions will be unsubscribed
      #
      # @param names [String] The event name of the message to subscribe to if provided.  Defaults to all events.
      #
      # @return [void]
      #
      def unsubscribe(*names, &callback)
        super
      end

      # Attach to this channel, and call the block if provided when attached.
      # Attaching to a channel is implicit in when a message is published or #subscribe is called, so it is uncommon
      # to need to call attach explicitly.
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Attached state
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callback
      #
      def attach(&success_block)
        raise Ably::Exceptions::InvalidStateChange.new("Cannot ATTACH channel when the connection is in a closed, suspended or failed state. Connection state: #{connection.state}") if connection.closing? || connection.closed? || connection.suspended? || connection.failed?

        transition_state_machine :attaching if can_transition_to?(:attaching)
        deferrable_for_state_change_to(STATE.Attached, &success_block)
      end

      # Detach this channel, and call the block if provided when in a Detached or Failed state
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Detached or Failed state
      # @return [Ably::Util::SafeDeferrable] Deferrable that supports both success (callback) and failure (errback) callback
      #
      def detach(&success_block)
        if initialized?
          success_block.call if block_given?
          return Ably::Util::SafeDeferrable.new(logger).tap do |deferrable|
            EventMachine.next_tick { deferrable.succeed }
          end
        end

        raise exception_for_state_change_to(:detaching) if failed?

        transition_state_machine :detaching if can_transition_to?(:detaching)
        deferrable_for_state_change_to(STATE.Detached, &success_block)
      end

      # Presence object for this Channel.  This controls this client's
      # presence on the channel and may also be used to obtain presence information
      # and change events for other members of the channel.
      #
      # @return {Ably::Realtime::Presence}
      #
      def presence
        @presence
      end

      # Return the message history of the channel
      #
      # If the channel is attached, you can retrieve messages published on the channel before the
      # channel was attached with the option <tt>until_attach: true</tt>.  This is useful when a developer
      # wishes to display historical messages with the guarantee that no messages have been missed since attach.
      #
      # @param (see Ably::Rest::Channel#history)
      # @option options (see Ably::Rest::Channel#history)
      # @option options [Boolean]  :until_attach  When true, the history request will be limited only to messages published before this channel was attached. Channel must be attached
      #
      # @yield [Ably::Models::PaginatedResult<Ably::Models::Message>] First {Ably::Models::PaginatedResult page} of {Ably::Models::Message} objects accessible with {Ably::Models::PaginatedResult#items #items}.
      #
      # @return [Ably::Util::SafeDeferrable]
      #
      def history(options = {}, &callback)
        if options.delete(:until_attach)
          raise ArgumentError, 'option :until_attach is invalid as the channel is not attached' unless attached?
          options[:from_serial] = attached_serial
        end

        async_wrap(callback) do
          rest_channel.history(options.merge(async_blocking_operations: true))
        end
      end

      # @!attribute [r] __incoming_msgbus__
      # @return [Ably::Util::PubSub] Client library internal channel incoming message bus
      # @api private
      def __incoming_msgbus__
        @__incoming_msgbus__ ||= Ably::Util::PubSub.new(
          coerce_into: Proc.new { |event| Ably::Models::ProtocolMessage::ACTION(event) }
        )
      end

      # @api private
      def set_failed_channel_error_reason(error)
        @error_reason = error
      end

      # @api private
      def clear_error_reason
        @error_reason = nil
      end

      # @api private
      def set_attached_serial(serial)
        @attached_serial = serial
      end

      # @api private
      def update_options(channel_options)
        @options = channel_options.clone.freeze
      end

      # Used by {Ably::Modules::StateEmitter} to debug state changes
      # @api private
      def logger
        client.logger
      end

      private
      attr_reader :queue

      def setup_event_handlers
        __incoming_msgbus__.subscribe(:message) do |message|
          message.decode self
          emit_message message.name, message
        end

        on(STATE.Attached) do
          process_queue
        end
      end

      # Queue messages and process queue if channel is attached.
      # If channel is not yet attached, attempt to attach it before the message queue is processed.
      # @returns [Ably::Util::SafeDeferrable]
      def queue_messages(raw_messages)
        messages = Array(raw_messages).map { |msg| create_message(msg) }
        queue.push *messages

        if attached?
          process_queue
        else
          attach
        end

        if messages.count == 1
          # A message is a Deferrable so, if publishing only one message, simply return that Deferrable
          messages.first
        else
          deferrable_for_multiple_messages(messages)
        end
      end

      # A deferrable object that calls the success callback once all messages are delivered
      # If any message fails, the errback is called immediately
      # Only one callback or errback is ever called i.e. if a group of messages all fail, only once
      # errback will be invoked
      def deferrable_for_multiple_messages(messages)
        expected_deliveries = messages.count
        actual_deliveries = 0
        failed = false

        Ably::Util::SafeDeferrable.new(logger).tap do |deferrable|
          messages.each do |message|
            message.callback do
              return if failed
              actual_deliveries += 1
              deferrable.succeed messages if actual_deliveries == expected_deliveries
            end
            message.errback do |error|
              return if failed
              failed = true
              deferrable.fail error, message
            end
          end
        end
      end

      def messages_in_queue?
        !queue.empty?
      end

      # Move messages from Channel Queue into Outgoing Connection Queue
      def process_queue
        condition = -> { attached? && messages_in_queue? }
        non_blocking_loop_while(condition) do
          send_messages_within_protocol_message queue.shift(MAX_PROTOCOL_MESSAGE_BATCH_SIZE)
        end
      end

      def send_messages_within_protocol_message(messages)
        connection.send_protocol_message(
          action:   Ably::Models::ProtocolMessage::ACTION.Message.to_i,
          channel:  name,
          messages: messages
        )
      end

      def create_message(message)
        Ably::Models::Message(message.dup).tap do |message|
          message.encode self
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
    end
  end
end

require 'ably/realtime/channel/channel_manager'
require 'ably/realtime/channel/channel_state_machine'
