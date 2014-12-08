require 'base64'

module Ably::Modules
  # Common model functionality shared across many {Ably::Models}
  module ModelCommon
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

    def decode_binary_data_before_to_json(message)
      if message[:data].kind_of?(String) && message[:data].encoding == ::Encoding::ASCII_8BIT
        message[:data] = ::Base64.encode64(message[:data])
        message[:encoding] = [message[:encoding], 'base64'].compact.join('/')
      end
    end
  end
end
