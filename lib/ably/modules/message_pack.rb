require 'msgpack'

module Ably::Modules
  # MessagePack module adds #to_msgpack to the class on the assumption that the class
  # supports the method #as_json
  #
  module MessagePack
    # Generate a packed MsgPack version of this object based on the JSON representation.
    # Keys thus use mixedCase syntax as expected by the Realtime API
    def to_msgpack(pk = nil)
      as_json.to_msgpack(pk)
    end
  end
end
