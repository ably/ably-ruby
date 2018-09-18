require 'base64'
require 'ably/modules/conversions'
require 'ably/modules/message_pack'

module Ably::Modules
  # Common model functionality shared across many {Ably::Models}
  module ModelCommon
    include Conversions
    include MessagePack

    def self.included(base)
      base.extend(ClassMethods)
    end

    # Provide a normal Hash accessor to the underlying raw message object
    #
    # @return [Object]
    def [](key)
      attributes[key]
    end

    def ==(other)
      other.kind_of?(self.class) &&
        attributes == other.attributes
    end

    # Return a JSON ready object from the underlying #attributes using Ably naming conventions for keys
    # @return [Hash]
    def as_json(*args)
      attributes.as_json.reject { |key, val| val.nil? }
    end

    # Stringify the JSON representation of this object from the underlying #attributes
    # @return [String]
    def to_json(*args)
      as_json.to_json(*args)
    end

    # @!attribute [r] hash
    # @return [Integer] Compute a hash-code for this hash. Two hashes with the same content will have the same hash code
    def hash
      attributes.hash
    end

    def to_s
      representation = attributes.map do |key, val|
        if val.nil?
          nil
        else
          val_str = val.to_s
          val_str = "#{val_str[0...80]}..." if val_str.length > 80
          "#{key}=#{val_str}"
        end
      end
      "<#{self.class.name}: #{representation.compact.join(', ')}>"
    end

    module ClassMethods
      # Return a new instance of this object using the provided JSON-like object or JSON string
      # @param json_like_object  [Hash, String]  JSON-like object or JSON string
      # @return a new instance to this object
      def from_json(json_like_object)
        if json_like_object.kind_of?(String)
          new(JSON.parse(json_like_object))
        else
          new(json_like_object)
        end
      end
    end

    private
    def ensure_utf8_string_for(attribute, value)
      if value
        raise ArgumentError, "#{attribute} must be a String" unless value.kind_of?(String)
        raise ArgumentError, "#{attribute} cannot use ASCII_8BIT encoding, please use UTF_8 encoding" unless value.encoding == Encoding::UTF_8
      end
    end
  end
end
