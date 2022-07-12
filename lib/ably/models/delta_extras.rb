# frozen_string_literal: true

module Ably
  module Models
    #
    # @!attribute [r] from
    #   @return [String] The id of the message the delta was generated from
    # @!attribute [r] format
    #   @return [String] The delta format. Only vcdiff is supported as at API version 1.2
    #
    class DeltaExtras
      include ::Ably::Modules::ModelCommon

      # The id of the message the delta was generated from.
      # @return [String, nil]
      #
      attr_reader :from

      # The delta format.
      # @return [String, nil]
      #
      attr_reader :format

      def initialize(attributes = {})
        @from, @format = IdiomaticRubyWrapper((attributes || {}), stop_at: %I[from format]).attributes.values_at(:from, :format)
      end

      def to_json(*args)
        as_json(args).to_json
      end
    end
  end
end
