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

    # Configured options for this Crypto object, see {#initialize} for a list of configured options
    #
    # @return [Hash]
    attr_reader :options

    # Creates a {Ably::Util::Crypto} object
    #
    # @param [Hash] options an options Hash used to configure the Crypto library
    # @option options [String]  :key                 Required secret key used for encrypting and decrypting
    # @option options [String]  :algorithm           optional (default AES), specify the encryption algorithm supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option options [String]  :mode                optional (default CBC), specify the cipher mode supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option options [Integer] :key_length          optional (default 128), specify the key length of the cipher supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option options [String]  :combined            optional (default AES-128-CBC), specify in one option the algorithm, key length and cipher of the cipher supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    #
    # @return [Ably::Util::Crypto]
    #
    # @example
    #    crypto = Ably::Util::Crypto.new(key: 'mysecret')
    #    encrypted = crypto.encrypt('secret text')
    #    crypto.decrypt(decrypted) # => 'secret text'
    #
    def initialize(options)
      raise ArgumentError, ':key is required' unless options.has_key?(:key)
      @options = DEFAULTS.merge(options).freeze
    end

    # Obtain a default CipherParams. This uses default algorithm, mode and
    # padding and key length. A key and IV are generated using the default
    # system SecureRandom; the key may be obtained from the returned CipherParams
    # for out-of-band distribution to other clients.
    #
    # @return [Hash]   CipherParam options Hash with attributes :key, :algorithn, :mode, :key_length
    #
    def self.get_default_params(key = nil)
      params = DEFAULTS.merge(key: key)
      params[:key_length] = key.unpack('b*').first.length if params[:key]
      cipher_type = "#{params[:algorithm]}-#{params[:key_length]}-#{params[:mode]}"
      params[:key] = OpenSSL::Cipher.new(cipher_type.upcase).random_key unless params[:key]
      params
    end

    # Encrypt payload using configured Cipher
    #
    # @param [String] payload           the payload to be encrypted
    # @param [Hash]   encrypt_options   an options Hash to configure the encrypt action
    # @option encrypt_options [String]  :iv optionally use the provided Initialization Vector instead of a randomly generated IV
    #
    # @return [String] binary string with {Encoding::ASCII_8BIT} encoding
    #
    def encrypt(payload, encrypt_options = {})
      cipher = openssl_cipher
      cipher.encrypt
      cipher.key = key
      iv = encrypt_options[:iv] || options[:iv] || cipher.random_iv
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

    # Generate a random key
    # @return [String]
    def random_key
      openssl_cipher.random_key
    end

    # Generate a random IV
    # @return [String]
    def random_iv
      openssl_cipher.random_iv
    end

    # The Cipher algorithm string such as AES-128-CBC
    # @return [String]
    def cipher_type
      (options[:combined] || "#{options[:algorithm]}-#{options[:key_length]}-#{options[:mode]}").to_s.upcase
    end

    private
    def key
      options[:key]
    end

    def openssl_cipher
      OpenSSL::Cipher.new(cipher_type)
    end
  end
end
