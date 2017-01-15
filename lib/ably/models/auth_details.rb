module Ably::Models
  # Convert auth details attributes to a {AuthDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [AuthDetails]
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

    %w(access_token).each do |attribute|
      define_method attribute do
        attributes[attribute.to_sym]
      end
    end

    # @!attribute [r] attributes
    # @return [Hash] Access the token details Hash object ruby'fied to use symbolized keys
    def attributes
      @hash_object
    end
  end
end
