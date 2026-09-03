module Ably::Models
  # Convert auth details attributes to a {AuthDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [AuthDetails]
  #
  def self.AuthDetails(attributes)
    case attributes
    when AuthDetails
      return attributes
    else
      AuthDetails.new(attributes || {})
    end
  end

  # AuthDetails are included in an +AUTH+ {Ably::Models::ProtocolMessage#auth} attribute
  # to provide the realtime service with new token authentication details following a re-auth workflow
  #
  class AuthDetails
    include Ably::Modules::ModelCommon

    # @param attributes [Hash]
    # @option attributes [String]    :access_token     token string
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes.clone)
      self.attributes.freeze
    end

    # The authentication token string.
    #
    # @spec AD2
    #
    # @return [String]
    #
    def access_token
      attributes[:access_token]
    end

    def attributes
      @hash_object
    end
  end
end
