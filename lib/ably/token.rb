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
      attributes == other.attributes
    end

    protected
    attr_reader :attributes
  end
end
