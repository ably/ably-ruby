module Ably
  class Token
    include Ably::Modules::Conversions

    DEFAULTS = {
      capability: { "*" => ["*"] },
      ttl:        60 * 60 # 1 hour
    }

    TOKEN_EXPIRY_BUFFER = 5

    def initialize(attributes)
      @attributes = attributes.dup.freeze
    end

    def id
      attributes.fetch(:id)
    end

    def key_id
      attributes.fetch(:key)
    end

    def issued_at
      as_time_from_epoch(attributes.fetch(:issued_at), granularity: :s)
    end

    def expires_at
      as_time_from_epoch(attributes.fetch(:expires), granularity: :s)
    end

    def capability
      attributes.fetch(:capability)
    end

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
    def expired?
      expires_at < Time.now + TOKEN_EXPIRY_BUFFER
    end

    protected
    attr_reader :attributes
  end
end
