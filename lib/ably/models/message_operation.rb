module Ably::Models
  # Represents the operation metadata for update, delete, or append message operations.
  #
  # @spec MOP
  #
  class MessageOperation
    include Ably::Modules::ModelCommon

    # @param attributes [Hash]
    # @option attributes [String] :client_id The client ID of the user performing the operation (MOP2a)
    # @option attributes [String] :description An optional human-readable description of the operation (MOP2b)
    # @option attributes [Hash]   :metadata Arbitrary key-value metadata for the operation (MOP2c)
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes || {}, stop_at: [:metadata])
      @hash_object.freeze
    end

    # The client ID of the user performing the operation.
    #
    # @spec MOP2a
    #
    # @return [String, nil]
    #
    def client_id
      attributes[:client_id]
    end

    # An optional human-readable description of the operation.
    #
    # @spec MOP2b
    #
    # @return [String, nil]
    #
    def description
      attributes[:description]
    end

    # Arbitrary key-value metadata for the operation.
    #
    # @spec MOP2c
    #
    # @return [Hash, nil]
    #
    def metadata
      attributes[:metadata]
    end

    def attributes
      @hash_object
    end
  end
end
