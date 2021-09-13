module Ably::Models
  #
  # @!attribute [r] from
  #   @return [String] The id of the message the delta was generated from
  # @!attribute [r] format
  #   @return [String] The delta format. Only vcdiff is supported as at API version 1.2
  #
  class DeltaExtras
    include Ably::Modules::ModelCommon

    # DeltaExtras attributes
    # @return [Hash]
    #
    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = IdiomaticRubyWrapper((attributes || {}), stop_at: [:from, :format])
    end

    # The id of the message the delta was generated from.
    # @return [String, nil]
    #
    def from
      attributes[:from]
    end

    # The delta format.
    # @return [String, nil]
    #
    def format
      attributes[:format]
    end

    def to_json(*args)
      as_json(args).to_json
    end
  end
end
