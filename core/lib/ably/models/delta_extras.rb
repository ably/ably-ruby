module Ably::Models
  # Contains any arbitrary key-value pairs, which may also contain other primitive JSON types, JSON-encodable objects,
  # or JSON-encodable arrays from delta compression.
  #
  class DeltaExtras
    include Ably::Modules::ModelCommon

    # The ID of the message the delta was generated from.
    #
    # @return [String, nil]
    #
    attr_reader :from

    # The delta compression format. Only vcdiff is supported.
    #
    # @return [String, nil]
    #
    attr_reader :format

    def initialize(attributes = {})
      @from, @format = IdiomaticRubyWrapper((attributes || {}), stop_at: [:from, :format]).attributes.values_at(:from, :format)
    end

    def to_json(*args)
      as_json(args).to_json
    end
  end
end
