require 'base64'
require 'ably/exceptions'

module Ably::Modules
  # Provides methods to allow this model's `data` property to be encoded and decoded based on the `encoding` property.
  #
  # This module expects the following:
  # - A #attributes method that returns the underlying hash object
  # - A #set_attributes_object(attributes) method that updates the underlying hash object
  # - A #raw_hash_object attribute that returns the original hash object used to create this object
  #
  module Encodeable
    def self.included(base)
      base.extend(ClassMethods)
    end

    module ClassMethods
      # Return a Message or Presence object from the encoded JSON-like object, using the optional channel options
      # @param message_object [Hash] JSON-like object representation of an encoded message
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      # @yield [Ably::Exceptions::BaseAblyException] yields an Ably exception if decoding fails
      # @return [Message,Presence]
      def from_encoded(message_object, channel_options = {}, &error_block)
        new(message_object).tap do |message|
          message.decode(encoders, channel_options, &error_block)
        end
      end

      # Return an Array of Message or Presence objects from the encoded Array of JSON-like objects, using the optional channel options
      # @param message_object_array [Array<Hash>] Array of JSON-like objects with encoded messages
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      # @return [Array<Message,Presence>]
      def from_encoded_array(message_object_array, channel_options = {})
        Array(message_object_array).map do |message_object|
          from_encoded(message_object, channel_options)
        end
      end

      # Register an encoder for this object
      # @api private
      def register_encoder(encoder, options = {})
        encoders << Ably::Models::MessageEncoders.encoder_from(encoder, options)
      end

      private
      def encoders
        @encoders ||= []
      end
    end

    # Encode a message using the channel options and register encoders for the client
    # @param encoders [Array<Ably::Models::MessageEncoders::Base>] List of encoders to apply to the message
    # @param channel_options [Hash] Channel options, currently reserved for Encryption options
    # @return [void]
    # @api private
    def encode(encoders, channel_options, &error_block)
      apply_encoders :encode, encoders, channel_options, &error_block
    end

    # Decode a message using the channel options and registered encoders for the client
    # @param encoders [Array<Ably::Models::MessageEncoders::Base>] List of encoders to apply to the message
    # @param channel_options [Hash] Channel options, currently reserved for Encryption options
    # @return [void]
    # @api private
    def decode(encoders, channel_options, &error_block)
      apply_encoders :decode, encoders, channel_options, &error_block
    end

    # The original encoding of this message when it was received as a raw message from the Ably service
    # @return [String,nil]
    # @api private
    def original_encoding
      raw_hash_object['encoding']
    end

    private
    def decode_binary_data_before_to_json(message)
      data_key = message[:data] ? :data : 'data'
      encoding_key = message[:encoding] ? :encoding : 'encoding'

      if message[data_key].kind_of?(String) && message[data_key].encoding == ::Encoding::ASCII_8BIT
        message[data_key] = ::Base64.encode64(message[data_key])
        message[encoding_key] = [message[encoding_key], 'base64'].compact.join('/')
      end
    end

    def apply_encoders(method, encoders, channel_options, &error_callback)
      max_encoding_length = 512
      message_attributes = attributes.dup

      begin
        if message_attributes[:encoding].to_s.length > max_encoding_length
          raise Ably::Exceptions::EncoderError("Encoding error, encoding value is too long: '#{message_attributes[:encoding]}'", nil, 92100)
        end

        previous_encoding = message_attributes[:encoding]
        encoders.each do |encoder|
          encoder.public_send method, message_attributes, channel_options
        end
      end until previous_encoding == message_attributes[:encoding]

      set_attributes_object message_attributes
    rescue Ably::Exceptions::CipherError => cipher_error
      if block_given?
        yield cipher_error, "Encoder error #{cipher_error.code} trying to #{method} message: #{cipher_error.message}"
      else
        raise cipher_error
      end
    end
  end
end
