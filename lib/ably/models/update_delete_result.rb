module Ably::Models
  # Contains the result of an update or delete message operation.
  #
  # @spec UDR
  #
  class UpdateDeleteResult
    include Ably::Modules::ModelCommon

    # @param attributes [Hash]
    # @option attributes [String, nil] :version_serial The new version serial string of the updated or deleted message.
    #   Will be nil if the message was superseded by a subsequent update before it could be published.
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes || {})
      @hash_object.freeze
    end

    # The version serial of the updated or deleted message, or nil if superseded.
    #
    # @spec UDR2a
    #
    # @return [String, nil]
    #
    def version_serial
      attributes[:version_serial]
    end

    def attributes
      @hash_object
    end
  end
end
