require 'msgpack'
require 'openssl'

module Ably::Util
  # Contains the properties required to configure the encryption of {Ably::Models::Message} payloads.
  #
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
    #
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
      @fixed_iv = params[:fixed_iv]
      @cipher_params = Ably::Models::CipherParams(params)
    end

    # Returns a {Ably::Models::CipherParams} object, using the default values for any fields not supplied by the `Hash` object.
    #
    # @spec RSE1, RSE1b, RSE1b
    #
    # @param [Hash]  params  a Hash used to configure the Crypto library's {Ably::Models::CipherParams}
    # @option params  (see {Ably::Models::CipherParams#initialize})
    #
    # @return [Ably::Models::CipherParams]   Configured cipher params with :key, :algorithm, :mode, :key_length attributes
    #
    def self.get_default_params(params = {})
      Ably::Models::CipherParams(params)
    end

    # Generates a random key to be used in the encryption of the channel. If the language cryptographic randomness
    # primitives are blocking or async, a callback is used. The callback returns a generated binary key.
    #
    # @spec RSE2, RSE2a, RSE2b
    #
    # @param  [Integer]  key_length  The length of the key, in bits, to be generated. If not specified, this is equal to the default keyLength of the default algorithm: for AES this is 256 bits.
    # @return   Binary   The key as a binary, for example, a byte array.
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
