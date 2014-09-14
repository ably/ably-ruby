module Ably
  class Token
    DEFAULTS = {
      capability: { "*" => ["*"] },
      ttl:        60 * 60 # 1 hour
    }

    def initialize(attributes)
      @attributes = attributes
    end

    def id
      attributes[:id]
    end

    def key_id
      attributes[:key]
    end

    def issued_at
      Time.at(attributes[:issued_at])
    end

    def expires_at
      Time.at(attributes[:expires])
    end

    def capability
      attributes[:capability]
    end

    def client_id
      attributes[:client_id]
    end

    def nonce
      attributes[:nonce]
    end

    def ==(other)
      attributes == other.attributes
    end

    protected
    attr_reader :attributes
  end
end
