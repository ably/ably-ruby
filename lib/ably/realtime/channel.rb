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
    # Channels emit errors - use `on(:error)` to subscribe to errors
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

      # Initialize a new Channel object
      #
      # @param  client [Ably::Rest::Client]
      # @param  name [String] The name of the channel
      # @param  channel_options [Hash]     Channel options, currently reserved for Encryption options
      # @option channel_options [Boolean]  :encrypted       setting this to true for this channel will encrypt & decrypt all messages automatically
      # @option channel_options [Hash]     :cipher_params   A hash of options to configure the encryption. *:key* is required, all other options are optional.  See {Ably::Util::Crypto#initialize} for a list of `cipher_params` options
      #
      def initialize(client, name, channel_options = {})
        ensure_utf_8 :name, name

        @client        = client
        @name          = name
        @options       = channel_options.clone.freeze
        @queue         = []

        @state_machine = ChannelStateMachine.new(self)
        @state         = STATE(state_machine.current_state)
        @manager       = ChannelManager.new(self, client.connection)

        setup_event_handlers
        setup_presence
      end

      # Publish a message on the channel
      #
      # @param name [String] The event name of the message
      # @param data [String,ByteArray] payload for the message
      # @yield [Ably::Models::Message] On success, will call the block with the {Ably::Models::Message}
      # @return [Ably::Models::Message] Deferrable {Ably::Models::Message} that supports both success (callback) and failure (errback) callbacks
      #
      # @example
      #   channel.publish('click', 'body')
      #
      #   channel.publish('click', 'body') do |message|
      #     puts "#{message.name} event received with #{message.data}"
      #   end
      #
      #   channel.publish('click', 'body').errback do |message, error|
      #     puts "#{message.name} was not received, error #{error.message}"
      #   end
      #
      def publish(name, data, &success_block)
        ensure_utf_8 :name, name

        create_message(name, data).tap do |message|
          message.callback(&success_block) if block_given?
          queue_message message
        end
      end

      # Subscribe to messages matching providing event name, or all messages if event name not provided
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
        transition_state_machine :attaching if can_transition_to?(:attaching)
        deferrable_for_state_change_to(STATE.Attached, &success_block)
      end

      # Detach this channel, and call the block if provided when in a Detached or Failed state
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Detached or Failed state
      # @return [void]
      #
      def detach(&success_block)
        raise exception_for_state_change_to(:detaching) if failed? || initialized?
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
        attach if initialized?
        @presence
      end

      # Return the message history of the channel
      #
      # @param (see Ably::Rest::Channel#history)
      # @option options (see Ably::Rest::Channel#history)
      #
      # @yield [Ably::Models::PaginatedResource<Ably::Models::Message>] An Array of {Ably::Models::Message} objects that supports paging (#next_page, #first_page)
      #
      # @return [Ably::Util::SafeDeferrable]
      def history(options = {}, &callback)
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

      # Queue message and process queue if channel is attached.
      # If channel is not yet attached, attempt to attach it before the message queue is processed.
      def queue_message(message)
        queue << message

        if attached?
          process_queue
        else
          attach
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
        client.connection.send_protocol_message(
          action:   Ably::Models::ProtocolMessage::ACTION.Message.to_i,
          channel:  name,
          messages: messages
        )
      end

      def create_message(name, data)
        message = { name: name }
        message.merge!(data: data) unless data.nil?
        message.merge!(clientId: client.client_id) if client.client_id

        Ably::Models::Message.new(message, logger: logger).tap do |message|
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
