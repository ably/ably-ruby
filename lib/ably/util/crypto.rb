require 'msgpack'
require 'openssl'

module Ably::Util
  class Crypto
    DEFAULTS = {
      algorithm: 'AES',
      mode: 'CBC',
      key_length: 128,
    }

    BLOCK_LENGTH = 16

    attr_reader :options

    # Creates a {Ably::Util::Crypto} object
    #
    # @param [Hash] options an options Hash used to configure the Crypto library
    # @option options [String]  :secret              Required secret used for encrypting and decrypting
    # @option options [String]  :algorithm           optional (default AES), specify the encryption algorithm supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option options [String]  :mode                optional (default CBC), specify the cipher mode supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option options [Integer] :key_length          optional (default 128), specify the key length of the cipher supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    #
    # @return [Ably::Util::Crypto]
    #
    # @example
    #    crypto = Ably::Util::Crypto.new(secret: 'mysecret')
    #    encrypted = crypto.encrypt('secret text')
    #    crypto.decrypt(decrypted) # => 'secret text'
    #
    def initialize(options)
      raise ArgumentError, ':secret is required' unless options.has_key?(:secret)
      @options = DEFAULTS.merge(options).freeze
    end

    # Encrypt payload using configured Cipher
    #
    # @param [String] payload           the payload to be encrypted
    # @param [Hash]   encrypt_options   an options Hash to configure the encrypt action
    # @option encrypt_options [String]  :iv optionally use the provided Initialization Vector instead of a randomly generated IV
    #
    def encrypt(payload, encrypt_options = {})
      cipher = openssl_cipher
      cipher.encrypt
      cipher.key = secret
      iv = encrypt_options[:iv] || cipher.random_iv
      cipher.iv = iv

      iv << cipher.update(payload) << cipher.final
    end

    def decrypt(encrypted_payload_with_iv)
      raise Ably::Exceptions::EncryptionError, 'iv is missing or not long enough' unless encrypted_payload_with_iv.length >= BLOCK_LENGTH*2

      iv = encrypted_payload_with_iv.slice(0...BLOCK_LENGTH)
      encrypted_payload = encrypted_payload_with_iv.slice(BLOCK_LENGTH..-1)

      decipher = openssl_cipher
      decipher.decrypt
      decipher.key = secret
      decipher.iv = iv

      decipher.update(encrypted_payload) << decipher.final
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

    def cipher_type
      "#{options[:algorithm]}-#{options[:key_length]}-#{options[:mode]}"
    end

    def openssl_cipher
      OpenSSL::Cipher.new(cipher_type)
    end
  end
end
