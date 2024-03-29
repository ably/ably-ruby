require 'base64'
require 'ably/util/crypto'

module Ably::Models
  # Convert cipher param attributes to a {CipherParams} object
  #
  # @param attributes (see #initialize)
  #
  # @return [CipherParams]
  #
  def self.CipherParams(attributes)
    case attributes
    when CipherParams
      return attributes
    else
      CipherParams.new(attributes || {})
    end
  end

  # Sets the properties to configure encryption for a {Ably::Models::Rest::Channel} or {Ably::Models::Realtime::Channel} object.
  #
  class CipherParams
    include Ably::Modules::ModelCommon

    # @param params [Hash]
    # @option params [String,Binary]  :key         Required private key must be either a binary (e.g. a ASCII_8BIT encoded string), or a base64-encoded string. If the key is a base64-encoded string, the it will be automatically converted into a binary
    # @option params [String]         :algorithm   optional (default AES), specify the encryption algorithm supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option params [String]         :mode        optional (default CBC), specify the cipher mode supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option params [Integer]        :key_length  optional (default 128), specify the key length of the cipher supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    # @option params [String]         :combined    optional (default AES-128-CBC), specify in one option the algorithm, key length and cipher of the cipher supported by {http://ruby-doc.org/stdlib-2.0/libdoc/openssl/rdoc/OpenSSL/Cipher.html OpenSSL::Cipher}
    #
    def initialize(params = {})
      @attributes = IdiomaticRubyWrapper(params.clone)

      raise Ably::Exceptions::CipherError, ':key param is required' unless attributes[:key]
      raise Ably::Exceptions::CipherError, ':key param must be a base64-encoded string or byte array (ASCII_8BIT enocdede string)' unless key.kind_of?(String)
      attributes[:key] = decode_key(key) if key.kind_of?(String) && key.encoding != Encoding::ASCII_8BIT

      if attributes[:combined]
        match = /(?<algorithm>\w+)-(?<key_length>\d+)-(?<mode>\w+)/.match(attributes[:combined])
        raise Ably::Exceptions::CipherError, "Invalid :combined param, expecting format such as AES-256-CBC" unless match
        attributes[:algorithm] = match[:algorithm]
        attributes[:key_length] = match[:key_length].to_i
        attributes[:mode] = match[:mode]
      end

      if attributes[:key_length] && (key_length != attributes[:key_length])
        raise Ably::Exceptions::CipherError, "Incompatible :key length of #{key_length} and provided :key_length of #{attributes[:key_length]}"
      end

      if algorithm == 'aes' && mode == 'cbc'
        unless [128, 256].include?(key_length)
          raise Ably::Exceptions::CipherError, "Unsupported key length #{key_length} for aes-cbc encryption. Encryption key must be 128 or 256 bits (16 or 32 ASCII characters)"
        end
      end

      attributes.freeze
    end

    # The Cipher algorithm string such as AES-128-CBC
    #
    # @param [Hash]  params  Hash containing :algorithm, :key_length and :mode key values
    #
    # @return [String]
    #
    def self.cipher_type(params)
      "#{params[:algorithm]}-#{params[:key_length]}-#{params[:mode]}".to_s.upcase
    end

    # The algorithm to use for encryption. Only AES is supported and is the default value.
    #
    # @spec TZ2a
    #
    # @return [String]
    #
    def algorithm
      attributes.fetch(:algorithm) do
        Ably::Util::Crypto::DEFAULTS.fetch(:algorithm)
      end.downcase
    end

    # The private key used to encrypt and decrypt payloads.
    #
    # @spec TZ2d
    #
    # @return [Binary]
    #
    def key
      attributes[:key]
    end

    # The length of the key in bits; for example 128 or 256.
    #
    # @spec TZ2b
    #
    # @return [Integer]
    #
    def key_length
      key.unpack('b*').first.length
    end

    # The cipher mode. Only CBC is supported and is the default value.
    #
    # @spec TZ2c
    #
    # @return [String]
    #
    def mode
      attributes.fetch(:mode) do
        Ably::Util::Crypto::DEFAULTS.fetch(:mode)
      end.downcase
    end

    # The complete Cipher algorithm string such as AES-128-CBC
    #
    # @return [String]
    #
    def cipher_type
      self.class.cipher_type(algorithm: algorithm, key_length: key_length, mode: mode)
    end

    # Access the token details Hash object ruby'fied to use symbolized keys
    #
    # @return [Hash]
    #
    def attributes
      @attributes
    end

    private

    def decode_key(encoded_key)
      normalised_key = encoded_key.gsub('_', '/').gsub('-', '+')
      Base64.decode64(normalised_key)
    end
  end
end
