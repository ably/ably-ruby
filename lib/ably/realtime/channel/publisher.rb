module Ably::Realtime
  class Channel
    # Publisher module adds publishing capabilities to the current object
    module Publisher
      private

      # Prepare and queue messages on the connection queue immediately
      # @return [Ably::Util::SafeDeferrable]
      def enqueue_messages_on_connection(client, raw_messages, channel_name, channel_options = {})
        messages = Array(raw_messages).map do |raw_msg|
          create_message(client, raw_msg, channel_options).tap do |message|
            next if message.client_id.nil?
            if message.client_id == '*'
              raise Ably::Exceptions::IncompatibleClientId.new('Wildcard client_id is reserved and cannot be used when publishing messages')
            end
            if message.client_id && !message.client_id.kind_of?(String)
              raise Ably::Exceptions::IncompatibleClientId.new('client_id must be a String when publishing messages')
            end
            unless client.auth.can_assume_client_id?(message.client_id)
              raise Ably::Exceptions::IncompatibleClientId.new("Cannot publish with client_id '#{message.client_id}' as it is incompatible with the current configured client_id '#{client.client_id}'")
            end
          end
        end

        connection.send_protocol_message(
          action:   Ably::Models::ProtocolMessage::ACTION.Message.to_i,
          channel:  channel_name,
          messages: messages
        )

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
              next if failed
              actual_deliveries += 1
              deferrable.succeed messages if actual_deliveries == expected_deliveries
            end
            message.errback do |error|
              next if failed
              failed = true
              deferrable.fail error, message
            end
          end
        end
      end

      def create_message(client, message, channel_options)
        Ably::Models::Message(message.dup).tap do |msg|
          msg.encode(client.encoders, channel_options) do |encode_error, error_message|
            client.logger.error error_message
          end
        end
      end
    end
  end
end

