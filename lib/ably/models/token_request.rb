module Ably::Models
  # Convert token request argument to a {TokenRequest} object
  #
  # @param attributes [TokenRequest,Hash] A {TokenRequest} object or Hash of attributes to create a new token request
  # @option attributes (see TokenRequest#initialize)
  #
  # @return [TokenRequest]
  def self.TokenRequest(attributes)
    case attributes
    when TokenRequest
      return attributes
    else
      TokenRequest.new(attributes)
    end
  end


  # TokenRequest is a class that stores the attributes of a token request
  #
  # Ruby {Time} objects are supported in place of Ably ms since epoch time fields.  However, if a numeric is provided
  # it must always be expressed in milliseconds as the Ably API always uses milliseconds for time fields.
  #
  class TokenRequest
    include Ably::Modules::ModelCommon

    # @param attributes
    # @option attributes [Integer]      :ttl        requested time to live for the token in milliseconds
    # @option attributes [Time,Integer] :timestamp  the timestamp of this request in milliseconds or as a {Time}
    # @option attributes [String]       :key_name   API key name of the key against which this request is made
    # @option attributes [String]       :capability JSON stringified capability of the token
    # @option attributes [String]       :client_id  client ID to associate with this token
    # @option attributes [String]       :nonce      an opaque nonce string of at least 16 characters
    # @option attributes [String]       :mac        the Message Authentication Code for this request
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes.clone)
      hash[:timestamp] = (hash[:timestamp].to_f * 1000).round if hash[:timestamp].kind_of?(Time)
      hash.freeze
    end

    # @!attribute [r] key_name
    # @return [String] API key name of the key against which this request is made.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      hash.fetch(:key_name)
    end

    # @!attribute [r] ttl
    # @return [Integer] requested time to live for the token in seconds. If the token request is successful,
    #                   the TTL of the returned token will be less than or equal to this value depending on application
    #                   settings and the attributes of the issuing key.
    #                   TTL when sent to Ably is in milliseconds.
    def ttl
      hash.fetch(:ttl) / 1000
    end

    # @!attribute [r] capability
    # @return [Hash] capability of the token. If the token request is successful,
    #                the capability of the returned token will be the intersection of
    #                this capability with the capability of the issuing key.
    def capability
      JSON.parse(hash.fetch(:capability))
    end

    # @!attribute [r] client_id
    # @return [String] the client ID to associate with this token. The generated token
    #                  may be used to authenticate as this clientId.
    def client_id
      hash[:client_id]
    end

    # @!attribute [r] timestamp
    # @return [Time] the timestamp of this request.
    #                Timestamps, in conjunction with the nonce, are used to prevent
    #                token requests from being replayed.
    #                Timestamp when sent to Ably is in milliseconds.
    def timestamp
      as_time_from_epoch(hash.fetch(:timestamp), granularity: :ms)
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

    # Requests that the token is always persisted
    # @api private
    #
    def persisted
      hash.fetch(:persisted)
    end

    # @!attribute [r] hash
    # @return [Hash] the token request Hash object ruby'fied to use symbolized keys
    def hash
      @hash_object
    end
  end
end
