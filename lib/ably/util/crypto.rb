require 'msgpack'
require 'openssl'

module Ably::Util
  class Crypto
    DEFAULTS = {
      algorithm: 'AES',
      mode: 'CBC',
      key_length: 128,
      block_length: 16
    }

    attr_reader :options

    def initialize(options = {})
      raise ArgumentError, ":secret is required" unless options.has_key?(:secret)
      @options = DEFAULTS.merge(options).freeze
    end

    def encrypt(payload)
      cipher = openssl_cipher

      cipher.encrypt
      cipher.key = secret
      iv = cipher.random_iv
      cipher.iv = iv

      iv + cipher.update(payload) + cipher.final
    end

    def decrypt(encrypted_payload_with_iv)
      raise Ably::Exceptions::EncryptionError, "iv is missing" unless encrypted_payload_with_iv.length >= block_length*2

      decipher = openssl_cipher

      decipher.decrypt
      decipher.key = secret
      decipher.iv = encrypted_payload_with_iv.slice(0..15)

      decipher.update(encrypted_payload_with_iv.slice(16..-1)) + decipher.final
    end

    def random_key
      openssl_cipher.random_key
    end

    def random_iv
      openssl_cipher.random_iv
    end

    private
    def secret
      options[:secret]
    end

    def block_length
      options[:block_length]
    end

    def cipher_type
      "#{options[:algorithm]}-#{options[:key_length]}-#{options[:mode]}"
    end

    def openssl_cipher
      OpenSSL::Cipher.new(cipher_type)
    end
  end
end
