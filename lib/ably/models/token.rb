module Ably::Models
  # Authentication token issued by Ably in response to an token request
  class Token
    include Ably::Modules::Conversions

    DEFAULTS = {
      capability: { "*" => ["*"] },
      ttl:        60 * 60 # 1 hour
    }

    # Buffer in seconds given to the use of a token prior to it being considered unusable
    # For example, if buffer is 10s, the token can no longer be used for new requests 9s before it expires
    TOKEN_EXPIRY_BUFFER = 5

    def initialize(attributes)
      @attributes = IdiomaticRubyWrapper(attributes.clone.freeze)
    end

    # Unique token ID used to authenticate requests
    #
    # @return [String]
    def id
      attributes.fetch(:id)
    end

    # Key ID used to create this token
    #
    # @return [String]
    def key_id
      attributes.fetch(:key)
    end

    # Time the token was issued
    #
    # @return [Time]
    def issued_at
      as_time_from_epoch(attributes.fetch(:issued_at), granularity: :s)
    end

    # Time the token expires
    #
    # @return [Time]
    def expires_at
      as_time_from_epoch(attributes.fetch(:expires), granularity: :s)
    end

    # Capabilities assigned to this token
    #
    # @return [Hash]
    def capability
      attributes.fetch(:capability)
    end

    # Optioanl client ID assigned to this token
    #
    # @return [String]
    def client_id
      attributes.fetch(:client_id)
    end

    def nonce
      attributes.fetch(:nonce)
    end

    def ==(other)
      other.kind_of?(Token) &&
        attributes == other.attributes
    end

    # Returns true if token is expired or about to expire
    #
    # @return [Boolean]
    def expired?
      expires_at < Time.now + TOKEN_EXPIRY_BUFFER
    end

    protected
    attr_reader :attributes
  end
end
