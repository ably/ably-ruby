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
        @subscriptions = Hash.new { |hash, key| hash[key] = [] }
        @queue         = []
        @state         = STATE.Initialized

        setup_event_handlers
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
      def publish(name, data, &callback)
        ensure_utf_8 :name, name

        create_message(name, data).tap do |message|
          message.callback(&callback) if block_given?
          queue_message message
        end
      end

      # Subscribe to messages matching providing event name, or all messages if event name not provided
      #
      # @param name [String] The event name of the message to subscribe to if provided.  Defaults to all events.
      # @yield [Ably::Models::Message] For each message received, the block is called
      #
      # @return [void]
      #
      def subscribe(name = :all, &blk)
        attach unless attached? || attaching?
        subscriptions[message_name_key(name)] << blk
      end

      # Unsubscribe the matching block for messages matching providing event name, or all messages if event name not provided.
      # If a block is not provided, all subscriptions will be unsubscribed
      #
      # @param name [String] The event name of the message to subscribe to if provided.  Defaults to all events.
      #
      # @return [void]
      #
      def unsubscribe(name = :all, &blk)
        if message_name_key(name) == :all
          subscriptions.keys
        else
          Array(message_name_key(name))
        end.each do |key|
          subscriptions[key].delete_if do |block|
            !block_given? || blk == block
          end
        end
      end

      # Attach to this channel, and call the block if provided when attached.
      # Attaching to a channel is implicit in when a message is published or #subscribe is called, so it is uncommon
      # to need to call attach explicitly.
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Attached state
      # @return [void]
      #
      def attach(&block)
        connect_if_connection_initialized
        once_or_if(STATE.Attached) { block.call self } if block_given?
        if !attaching?
          change_state STATE.Attaching
          send_attach_protocol_message
        end
      end

      # Detach this channel, and call the block if provided when in a Detached or Failed state
      #
      # @yield [Ably::Realtime::Channel] Block is called as soon as this channel is in the Detached or Failed state
      # @return [void]
      #
      def detach(&block)
        detached_block = proc do
          off(&detached_block)
          block.call self
        end
        [STATE.Detached, STATE.Failed].each { |state| once_or_if(state, &detached_block) } if block_given?

        if attaching? || attached?
          change_state STATE.Detaching
          send_detach_protocol_message
        end
      end

      # Presence object for this Channel.  This controls this client's
      # presence on the channel and may also be used to obtain presence information
      # and change events for other members of the channel.
      #
      # @return {Ably::Realtime::Presence}
      #
      def presence
        attach if initialized?
        @presence ||= Presence.new(self)
      end

      # Return the message history of the channel
      #
      # @param (see Ably::Rest::Channel#history)
      # @option options (see Ably::Rest::Channel#history)
      #
      # @yield [Ably::Models::PaginatedResource<Ably::Models::Message>] An Array of {Ably::Models::Message} objects that supports paging (#next_page, #first_page)
      #
      # @return [EventMachine::Deferrable]
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

      # Set connection state to Failed
      # @api private
      def fail(error)
        logger.error "Channel #{name} error: #{error}"
        set_failed_channel_error_reason error
        change_state STATE.Failed, error
        trigger :error, error
      end

      private
      attr_reader :queue, :subscriptions

      def setup_event_handlers
        __incoming_msgbus__.subscribe(:message) do |message|
          message.decode self

          subscriptions[:all].each         { |cb| cb.call(message) }
          subscriptions[message.name].each { |cb| cb.call(message) }
        end

        on(STATE.Attached) do
          process_queue
        end

        connection.on(Connection::STATE.Closed) do
          change_state STATE.Detached if attached? || attaching?
        end

        connection.on(Connection::STATE.Failed) do |error|
          fail error unless detached? || initialized?
        end

        on(:attached, :detached) do
          set_failed_channel_error_reason nil
        end
      end

      def set_failed_channel_error_reason(error)
        @error_reason = error
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

      def send_attach_protocol_message
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Attach
      end

      def send_detach_protocol_message
        send_state_change_protocol_message Ably::Models::ProtocolMessage::ACTION.Detach
      end

      def send_state_change_protocol_message(state)
        client.connection.send_protocol_message(
          action:  state.to_i,
          channel: name
        )
      end

      def create_message(name, data)
        message = { name: name }
        message.merge!(data: data) unless data.nil?
        message.merge!(clientId: client.client_id) if client.client_id

        Ably::Models::Message.new(message, nil).tap do |message|
          message.encode self
        end
      end

      def rest_channel
        client.rest_client.channel(name)
      end

      # Used by {Ably::Modules::StateEmitter} to debug state changes
      def logger
        client.logger
      end

      def connection
        client.connection
      end

      # If the connection has not previously connected, connect now
      def connect_if_connection_initialized
        connection.connect if connection.initialized?
      end

      def message_name_key(name)
        if name == :all
          :all
        else
          name.to_s
        end
      end
    end
  end
end
