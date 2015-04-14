module Ably::Models
  # Convert token request argument to a {TokenRequest} object
  #
  # @param token_request [TokenRequest,Hash] A {TokenRequest} object or Hash of token request
  #
  # @return [TokenRequest]
  def self.TokenRequest(token_request)
    case token_request
    when TokenRequest
      return token_request
    else
      TokenRequest.new(token_request)
    end
  end


  # TokenRequest is a class that stores the attributes of a token request
  #
  class TokenRequest
    include Ably::Modules::ModelCommon

    def initialize(attributes)
      @hash_object = IdiomaticRubyWrapper(attributes.clone.freeze)
    end

    # @!attribute [r] key_name
    # @return [String] API key name of the key against which this request is made.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      # TODO: Change to :key_name
      # hash.fetch(:key_name)
      hash.fetch(:id)
    end

    # @!attribute [r] ttl
    # @return [Integer] requested time to live for the token in seconds. If the token request is successful,
    #                  the TTL of the returned token will be less than or equal to this value depending on application
    #                  settings and the attributes of the issuing key.
    def ttl
      # TODO: This field will be in milliseconds
      hash.fetch(:ttl)
    end

    # @!attribute [r] capability
    # @return [Hash] capability of the token. If the token request is successful,
    #                the capability of the returned token will be the intersection of
    #                this capability with the capability of the issuing key.
    def capability
      JSON.parse(hash.fetch(:capability))
    end

    # @!attribute [r] client_id
    # @return [String] the clientId to associate with this token. The generated token
    #                  may be used to authenticate as this clientId.
    def client_id
      hash[:client_id]
    end

    # @!attribute [r] timestamp
    # @return [Time] the timestamp of this request.
    #                  Timestamps, in conjunction with the nonce, are used to prevent
    #                  token requests from being replayed.
    def timestamp
      # TODO: Review whether this underlying data should be in ms
      as_time_from_epoch(hash.fetch(:timestamp), granularity: :s)
    end

    # @!attribute [r] nonce
    # @return [String]  an opaque nonce string of at least 16 characters to ensure
    #                   uniqueness of this request. Any subsequent request using the
    #                   same nonce will be rejected.
    def nonce
      hash.fetch(:nonce)
    end

    # @!attribute [r] mac
    # @return [String]  the Message Authentication Code for this request. See the
    #                   {https://www.ably.io/documentation Ably Authentication documentation} for more details.
    def mac
      hash.fetch(:mac)
    end

    # @!attribute [r] hash
    # @return [Hash] the token request Hash object ruby'fied to use symbolized keys
    def hash
      @hash_object
    end
  end
end
