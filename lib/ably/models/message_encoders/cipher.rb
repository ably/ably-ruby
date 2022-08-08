# frozen_string_literal: true

require "ably/exceptions"
require "ably/models/message_encoders/base"
require "ably/util/crypto"

module Ably
  module Models
    module MessageEncoders
      # Cipher Encoder & Decoder that automatically encrypts & decrypts messages using Ably::Util::Crypto
      # when a channel has the +:cipher+ channel option configured
      #
      class Cipher < Base
        ENCODING_ID = "cipher"

        def initialize(*args)
          super
          @cryptos = {}
        end

        def encode(message, channel_options)
          return if is_empty?(message)
          return if already_encrypted?(message)
          return unless channel_configured_for_encryption?(channel_options)

          add_encoding_to_message "utf-8", message unless is_binary?(message) || is_utf8_encoded?(message)
          crypto = crypto_for(channel_options)
          message[:data] = crypto.encrypt(message[:data])
          add_encoding_to_message "#{ENCODING_ID}+#{crypto.cipher_params.cipher_type.downcase}", message
        rescue ArgumentError => e
          raise Ably::Exceptions::CipherError.new(e.message, nil, 92_005)
        rescue RuntimeError => e
          raise e unless /unsupported cipher algorithm/i.match?(e.message)

          raise Ably::Exceptions::CipherError.new(e.message, nil, 92_004)
        end

        def decode(message, channel_options)
          if is_cipher_encoded?(message)
            raise Ably::Exceptions::CipherError.new("Message cannot be decrypted as the channel is not set up for encryption & decryption", nil, 92_001) unless channel_configured_for_encryption?(channel_options)

            crypto = crypto_for(channel_options)
            raise Ably::Exceptions::CipherError.new("Cipher algorithm #{crypto.cipher_params.cipher_type} does not match message cipher algorithm of #{cipher_algorithm(message).upcase}", nil, 92_002) unless crypto.cipher_params.cipher_type == cipher_algorithm(message).upcase

            message[:data] = crypto.decrypt(message[:data])
            strip_current_encoding_part message
          end
        rescue OpenSSL::Cipher::CipherError
          raise Ably::Exceptions::CipherError.new("CipherError decrypting data, the private key may not be correct", nil, 92_003)
        end

        private

        def is_binary?(message)
          message.fetch(:data, "").encoding == Encoding::ASCII_8BIT
        end

        def is_utf8_encoded?(message)
          current_encoding_part(message).to_s.match(/^utf-8$/i)
        end

        def crypto_for(channel_options)
          @cryptos[channel_options.to_s] ||= Ably::Util::Crypto.new(channel_options.fetch(:cipher, {}))
        end

        def channel_configured_for_encryption?(channel_options)
          channel_options[:cipher]
        end

        def is_cipher_encoded?(message)
          !cipher_algorithm(message).nil?
        end

        def cipher_algorithm(message)
          current_encoding_part(message).to_s[/^#{ENCODING_ID}\+([\w-]+)$/o, 1]
        end

        def already_encrypted?(message)
          message.fetch(:encoding, "").to_s.match(%r{(^|/)#{ENCODING_ID}\+([\w-]+)($|/)}o)
        end
      end
    end
  end
end
