module Ably::Models
  # Common model functionality across many {Ably::Models}
  module Common
    include Ably::Modules::Conversions
    include Ably::Modules::MessagePack

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

    # Return a JSON ready object from the underlying #hash using Ably naming conventions for keys
    def as_json
      hash.as_json.dup
    end

    # Stringify the JSON representation of this object from the underlying #hash
    def to_json(*args)
      as_json.to_json(*args)
    end
  end
end
