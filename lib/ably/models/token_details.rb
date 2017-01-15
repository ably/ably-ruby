module Ably::Models
  # Convert token details argument to a {TokenDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [TokenDetails]
  def self.TokenDetails(attributes)
    case attributes
    when TokenDetails
      return attributes
    else
      TokenDetails.new(attributes)
    end
  end

  # TokenDetails is a class providing details of the token string and the token's associated metadata,
  # constructed from the response from Ably when request in a token via the REST API.
  #
  # Ruby {http://ruby-doc.org/core/Time.html Time} objects are supported in place of Ably ms since epoch time fields.  However, if a numeric is provided
  # it must always be expressed in milliseconds as the Ably API always uses milliseconds for time fields.
  #
  class TokenDetails
    include Ably::Modules::ModelCommon

    # Buffer in seconds before a token is considered unusable
    # For example, if buffer is 10s, the token can no longer be used for new requests 9s before it expires
    TOKEN_EXPIRY_BUFFER = 15

    # @param attributes
    # @option attributes [String]       :token      token used to authenticate requests
    # @option attributes [String]       :key_name   API key name used to create this token
    # @option attributes [Time,Integer] :issued     Time the token was issued as Time or Integer in milliseconds
    # @option attributes [Time,Integer] :expires    Time the token expires as Time or Integer in milliseconds
    # @option attributes [String]       :capability JSON stringified capabilities assigned to this token
    # @option attributes [String]       :client_id  client ID assigned to this token
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes.clone)

      %w(issued expires).map(&:to_sym).each do |time_attribute|
        if self.attributes[time_attribute].kind_of?(Time)
          self.attributes[time_attribute] = (self.attributes[time_attribute].to_f * 1000).round
        end
      end

      self.attributes.freeze
    end

    # @!attribute [r] token
    # @return [String] Token used to authenticate requests
    def token
      attributes[:token]
    end

    # @!attribute [r] key_name
    # @return [String] API key name used to create this token.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      attributes[:key_name]
    end

    # @!attribute [r] issued
    # @return [Time] Time the token was issued
    def issued
      as_time_from_epoch(attributes[:issued], granularity: :ms, allow_nil: :true)
    end

    # @!attribute [r] expires
    # @return [Time] Time the token expires
    def expires
      as_time_from_epoch(attributes[:expires], granularity: :ms, allow_nil: :true)
    end

    # @!attribute [r] capability
    # @return [Hash] Capabilities assigned to this token
    def capability
      if attributes.has_key?(:capability)
        capability_val = attributes.fetch(:capability)
        case capability_val
        when Hash
          capability_val
        when Ably::Models::IdiomaticRubyWrapper
          capability_val.as_json
        else
          JSON.parse(attributes.fetch(:capability))
        end
      end
    end

    # @!attribute [r] client_id
    # @return [String] Optional client ID assigned to this token
    def client_id
      attributes[:client_id]
    end

    # Returns true if token is expired or about to expire
    # For tokens that have not got an explicit expires attribute expired? will always return true
    #
    # @return [Boolean]
    def expired?
      return false if !expires
      expires < Time.now + TOKEN_EXPIRY_BUFFER
    end

    # True if the TokenDetails was created from an opaque string i.e. no metadata exists for this token
    # @return [Boolean]
    # @api private
    def from_token_string?
      attributes.keys == [:token]
    end

    # @!attribute [r] attributes
    # @return [Hash] Access the token details Hash object ruby'fied to use symbolized keys
    def attributes
      @hash_object
    end

    def to_s
      "<TokenDetails token=#{token} client_id=#{client_id} key_name=#{key_name} issued=#{issued} expires=#{expires} capability=#{capability} expired?=#{expired?}>"
    end
  end
end
