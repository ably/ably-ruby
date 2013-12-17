module Ably
  class Token
    def initialize(attributes)
      @attributes = attributes
    end

    def id
      attributes[:id]
    end

    def app_key
      attributes[:key]
    end

    def issued_at
      Time.at(attributes[:issued_at])
    end

    def expires_at
      Time.at(attributes[:expires])
    end

    def ==(other)
      attributes == other.attributes
    end

    protected
    attr_reader :attributes
  end
end
