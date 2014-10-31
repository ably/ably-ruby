module Ably::Models
  module Shared
    include Ably::Modules::Conversions

    # Provide a normal Hash accessor to the underlying raw message object
    #
    # @return [Object]
    def [](key)
      hash[key]
    end

    def ==(other)
      other.kind_of?(self.class) &&
        hash == other.hash
    end
  end
end
