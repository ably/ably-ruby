module Ably
  class Token
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
      Time.at(attributes.fetch(:issued_at))
    end

    def expires_at
      Time.at(attributes.fetch(:expires))
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
      other.class == self.class &&
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
