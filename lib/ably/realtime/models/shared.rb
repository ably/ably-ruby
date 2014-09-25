module Ably::Realtime::Models
  module Shared
    include Ably::Modules::Conversions

    # Provide a normal Hash accessor to the underlying raw message object
    #
    # @return [Object]
    def [](key)
      json[key]
    end

    def ==(other)
      other.kind_of?(self.class) &&
        json == other.json
    end
  end
end
