require 'msgpack'

module Ably::Modules
  # MessagePack module adds #to_msgpack to the class on the assumption that the class
  # supports the method #as_json
  #
  module MessagePack
    # Generate a packed MsgPack version of this object based on the JSON representation.
    # Keys thus use mixedCase syntax as expected by the Realtime API
    def to_msgpack(*args)
      as_json(*args).to_msgpack
    end
  end
end
