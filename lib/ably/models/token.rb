module Ably::Models
  # Authentication token issued by Ably in response to an token request
  class Token
    include Common

    DEFAULTS = {
      capability: { "*" => ["*"] },
      ttl:        60 * 60 # 1 hour
    }

    # Buffer in seconds given to the use of a token prior to it being considered unusable
    # For example, if buffer is 10s, the token can no longer be used for new requests 9s before it expires
    TOKEN_EXPIRY_BUFFER = 5

    def initialize(attributes)
      @hash_object = IdiomaticRubyWrapper(attributes.clone.freeze)
    end

    # @!attribute [r] id
    # @return [String] Unique token ID used to authenticate requests
    def id
      hash.fetch(:id)
    end

    # @!attribute [r] key_id
    # @return [String] Key ID used to create this token
    def key_id
      hash.fetch(:key)
    end

    # @!attribute [r] issued_at
    # @return [Time] Time the token was issued
    def issued_at
      as_time_from_epoch(hash.fetch(:issued_at), granularity: :s)
    end

    # @!attribute [r] expires_at
    # @return [Time] Time the token expires
    def expires_at
      as_time_from_epoch(hash.fetch(:expires), granularity: :s)
    end

    # @!attribute [r] capability
    # @return [Hash] Capabilities assigned to this token
    def capability
      hash.fetch(:capability)
    end

    # @!attribute [r] client_id
    # @return [String] Optional client ID assigned to this token
    def client_id
      hash.fetch(:client_id)
    end

    # @!attribute [r] nonce
    # @return [String] unique nonce used to generate Token and ensure token generation cannot be replayed
    def nonce
      hash.fetch(:nonce)
    end

    # Returns true if token is expired or about to expire
    #
    # @return [Boolean]
    def expired?
      expires_at < Time.now + TOKEN_EXPIRY_BUFFER
    end

    # @!attribute [r] hash
    # @return [Hash] Access the token Hash object ruby'fied to use symbolized keys
    def hash
      @hash_object
    end
  end
end
