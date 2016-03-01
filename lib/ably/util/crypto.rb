require 'msgpack'
require 'openssl'

module Ably::Util
  class Crypto
    DEFAULTS = {
      algorithm: 'aes',
      mode: 'cbc',
      key_length: 256,
    }

    BLOCK_LENGTH = 16

    # Configured {Ably::Models::CipherParams} for this Crypto object, see {#initialize} for a list of configureable options
    #
    # @return [Ably::Models::CipherParams]
    attr_reader :cipher_params

    # Creates a {Ably::Util::Crypto} object
    #
    # @param [Hash] params a Hash used to configure the Crypto library's {Ably::Models::CipherParams}
    # @option params (see Ably::Models::CipherParams#initialize)
    #
    # @return [Ably::Util::Crypto]
    #
    # @example
    #    key = Ably::Util::Crypto.generate_random_key
    #    crypto = Ably::Util::Crypto.new(key: key)
    #    encrypted = crypto.encrypt('secret text')
    #    crypto.decrypt(decrypted) # => 'secret text'
    #
    def initialize(params)
      @fixed_iv = params.delete(:fixed_iv) if params.kind_of?(Hash)
      @cipher_params = Ably::Models::CipherParams(params)
    end

    # Obtain a default {Ably::Models::CipherParams}. This uses default algorithm, mode and
    # padding and key length. An IV is generated using the default
    # system SecureRandom; the key may be obtained from the returned {Ably::Models::CipherParams}
    # for out-of-band distribution to other clients.

    # @param [Hash]  params  a Hash used to configure the Crypto library's {Ably::Models::CipherParams}
    # @option params  (see Ably::Models::CipherParams#initialize)
    #
    # @return [Ably::Models::CipherParams]   Configured cipher params with :key, :algorithm, :mode, :key_length attributes
    #
    def self.get_default_params(params = {})
      Ably::Models::CipherParams(params)
    end

    # Generate a random encryption key from the supplied keylength (or the
    # default key_length of 256 if none supplied)
    #
    # @param  [Integer]  key_length  Optional (default 256) key length for the generated random key. 128 and 256 bit key lengths are supported
    # @return   Binary   String (byte array) with ASCII_8BIT encoding
    #
    def self.generate_random_key(key_length = DEFAULTS.fetch(:key_length))
      params = DEFAULTS.merge(key_length: key_length)
      OpenSSL::Cipher.new(cipher_type(params)).random_key
    end

    # The Cipher algorithm string such as AES-128-CBC
    # @api private
    def self.cipher_type(options)
      Ably::Models::CipherParams.cipher_type(options)
    end

    # Encrypt payload using configured Cipher
    #
    # @param [String] payload           the payload to be encrypted
    # @param [Hash]   encrypt_options   an options Hash to configure the encrypt action
    # @option encrypt_options [String]  :iv optionally use the provided Initialization Vector instead of a randomly generated IV
    #
    # @return [String] binary string with +Encoding::ASCII_8BIT+ encoding
    #
    def encrypt(payload, encrypt_options = {})
      cipher = openssl_cipher
      cipher.encrypt
      cipher.key = key
      iv = encrypt_options[:iv] || fixed_iv || cipher.random_iv
      cipher.iv = iv

      iv << cipher.update(payload) << cipher.final
    end

    # Decrypt payload using configured Cipher
    #
    # @param [String] encrypted_payload_with_iv  the encrypted payload to be decrypted
    #
    # @return [String]
    #
    def decrypt(encrypted_payload_with_iv)
      raise Ably::Exceptions::CipherError, 'iv is missing or not long enough' unless encrypted_payload_with_iv.length >= BLOCK_LENGTH*2

      iv = encrypted_payload_with_iv.slice(0...BLOCK_LENGTH)
      encrypted_payload = encrypted_payload_with_iv.slice(BLOCK_LENGTH..-1)

      decipher = openssl_cipher
      decipher.decrypt
      decipher.key = key
      decipher.iv = iv

      decipher.update(encrypted_payload) << decipher.final
    end

    # Generate a random IV
    # @return [String]
    def random_iv
      openssl_cipher.random_iv
    end

    private
    # Used solely for tests to fix the IV instead of randomly generate one
    attr_reader :fixed_iv

    # Generate a random key
    # @return [String]
    def random_key
      openssl_cipher.random_key
    end

    def key
      cipher_params.key
    end

    def openssl_cipher
      @openssl_cipher ||= OpenSSL::Cipher.new(cipher_params.cipher_type)
    end
  end
end
