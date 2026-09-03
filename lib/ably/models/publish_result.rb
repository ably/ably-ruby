module Ably::Models
  # Contains the result of a publish operation.
  #
  # @spec RSL1n
  #
  class PublishResult
    include Ably::Modules::ModelCommon

    # @param attributes [Hash]
    # @option attributes [Array<String, nil>] :serials An array of nullable strings corresponding 1:1
    #   to the published messages. Each serial identifies the message on the channel.
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes || {}, stop_at: [:serials])
      @hash_object.freeze
    end

    # An array of serial strings (or nil entries), corresponding 1:1 to the published messages.
    #
    # @spec RSL1n
    #
    # @return [Array<String, nil>]
    #
    def serials
      attributes[:serials] || []
    end

    def attributes
      @hash_object
    end
  end
end
