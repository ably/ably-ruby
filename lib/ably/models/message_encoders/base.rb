require 'ably/modules/conversions'

# MessageEncoders are registered with the Ably client library and are responsible
# for encoding & decoding messages.
#
# For example, if a message body is detected as JSON, it is encoded as a String and the encoding attribute
# of the message is defined as 'json'.
# Encrypted messages are encoded & decoded by the Cipher encoder.
#
module Ably
  module Models
    module MessageEncoders
      extend Ably::Modules::Conversions

      # Base interface for an Ably Encoder
      #
      class Base
        attr_reader :client, :options

        def initialize(client, options = {})
          @client = client
          @options = options
        end

        # #encode is called once before a message is sent to Ably
        #
        # It is the responsibility of the #encode method to detect the intended encoding and modify the :data & :encoding properties of the message object.
        #
        # @param [Hash] message          the message as a Hash object received directly from Ably.
        #                                The message contains properties :name, :data, :encoding, :timestamp, and optionally :id and :client_id.
        #                                This #encode method should modify the message Hash if any encoding action is to be taken
        # @param [Hash] channel_options  the options used to initialize the channel that this message was received on
        #
        # @return [void]
        def encode(message, channel_options)
          raise "Not yet implemented"
        end

        # #decode is called once for every encoding step
        # i.e. if message encoding arrives with 'utf-8/cipher+aes-128-cbc/base64'
        #      the decoder will call #decode once for each encoding part such as 'base64', then 'cipher+aes-128-cbc', and finally 'utf-8'
        #
        # It is the responsibility of the #decode method to detect the current encoding part and modify the :data & :encoding properties of the message object.
        #
        # @param [Hash] message          the message as a Hash object received directly from Ably.
        #                                The message contains properties :name, :data, :encoding, :timestamp, and optionally :id and :client_id.
        #                                This #encode method should modify the message Hash if any decoding action is to be taken
        # @param [Hash] channel_options  the options used to initialize the channel that this message was received on
        #
        # @return [void]
        def decode(message, channel_options)
          raise "Not yet implemented"
        end

        # Add encoding to the message Hash.
        # Ensures that encoding delimeter is used where required i.e utf-8/cipher+aes-128-cbc/base64
        #
        # @param [Hash]   message   the message as a Hash object received directly from Ably.
        # @param [String] encoding  encoding to add to the current encoding
        #
        # @return [void]
        def add_encoding_to_message(encoding, message)
          message[:encoding] = [message[:encoding], encoding].compact.join('/')
        end

        # Returns the right most encoding form a meessage encoding, and nil if none exists
        # i.e. current_encoding_part('utf-8/cipher+aes-128-cbc/base64') => 'base64'
        #
        # @return [String,nil]
        def current_encoding_part(message)
          if message[:encoding]
            message[:encoding].split('/')[-1]
          end
        end

        # Strip the current encoding part within the message Hash.
        #
        # For example, calling this method on an :encoding value of 'utf-8/cipher+aes-128-cbc/base64' would update the attribute
        # :encoding to 'utf-8/cipher+aes-128-cbc'
        #
        # @param [Hash]   message   the message as a Hash object received directly from Ably.
        #
        # @return [void]
        def strip_current_encoding_part(message)
          raise "Cannot strip encoding when there is no encoding for this message" unless message[:encoding]
          message[:encoding] = message[:encoding].split('/')[0...-1].join('/')
          message[:encoding] = nil if message[:encoding].empty?
        end

        # True of the message data payload is empty
        #
        # @param [Hash]   message   the message as a Hash object received directly from Ably.
        #
        # @return [Boolean]
        def is_empty?(message)
          message[:data].nil? || message[:data] == ''
        end
      end

      # @api private
      def self.register_default_encoders(client, options = {})
        binary_protocol = !!options[:binary_protocol]
        client.register_encoder Ably::Models::MessageEncoders::Utf8
        client.register_encoder Ably::Models::MessageEncoders::Json
        client.register_encoder Ably::Models::MessageEncoders::Cipher
        client.register_encoder Ably::Models::MessageEncoders::Base64, binary_protocol: binary_protocol
      end

      # @api private
      def self.encoder_from(encoder, options)
        encoder_klass = if encoder.kind_of?(String)
          encoder.split('::').inject(Kernel) do |base, klass_name|
            base.public_send(:const_get, klass_name)
          end
        else
          encoder
        end

        raise "Encoder must inherit from `Ably::Models::MessageEncoders::Base`" unless encoder_klass.ancestors.include?(Ably::Models::MessageEncoders::Base)
        encoder_klass.new(self, options)
      end
    end
  end
end

require 'ably/models/message_encoders/base64'
require 'ably/models/message_encoders/cipher'
require 'ably/models/message_encoders/json'
require 'ably/models/message_encoders/utf8'
