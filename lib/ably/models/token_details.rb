module Ably::Models
  # Convert token details argument to a {TokenDetails} object
  #
  # @param attributes [TokenDetails,Hash] A {TokenDetails} object or Hash of token and meta data attributes
  # @option attributes (see TokenDetails#initialize)
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
  # Ruby {Time} objects are supported in place of Ably ms since epoch time fields.  However, if a numeric is provided
  # it must always be expressed in milliseconds as the Ably API always uses milliseconds for time fields.
  #
  class TokenDetails
    include Ably::Modules::ModelCommon

    # Buffer in seconds before a token is considered unusable
    # For example, if buffer is 10s, the token can no longer be used for new requests 9s before it expires
    TOKEN_EXPIRY_BUFFER = 5

    def initialize(attributes)
      @hash_object = IdiomaticRubyWrapper(attributes.clone.freeze)
    end

    # @param attributes
    # @option attributes [String]       :token      token used to authenticate requests
    # @option attributes [String]       :key_name   API key name used to create this token
    # @option attributes [Time,Integer] :issued  Time the token was issued as Time or Integer in milliseconds
    # @option attributes [Time,Integer] :expires    Time the token expires as Time or Integer in milliseconds
    # @option attributes [String]       :capability JSON stringified capabilities assigned to this token
    # @option attributes [String]       :client_id  client ID assigned to this token
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes.clone)

      %w(issued expires).map(&:to_sym).each do |time_attribute|
        hash[time_attribute] = (hash[time_attribute].to_f * 1000).round if hash[time_attribute].kind_of?(Time)
      end

      hash.freeze
    end

    # @!attribute [r] token
    # @return [String] Token used to authenticate requests
    def token
      hash.fetch(:token)
    end

    # @!attribute [r] key_name
    # @return [String] API key name used to create this token.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      hash.fetch(:key_name)
    end

    # @!attribute [r] issued
    # @return [Time] Time the token was issued
    def issued
      as_time_from_epoch(hash.fetch(:issued), granularity: :ms)
    end

    # @!attribute [r] expires
    # @return [Time] Time the token expires
    def expires
      as_time_from_epoch(hash.fetch(:expires), granularity: :ms)
    end

    # @!attribute [r] capability
    # @return [Hash] Capabilities assigned to this token
    def capability
      JSON.parse(hash.fetch(:capability))
    end

    # @!attribute [r] client_id
    # @return [String] Optional client ID assigned to this token
    def client_id
      hash[:client_id]
    end

    # Returns true if token is expired or about to expire
    #
    # @return [Boolean]
    def expired?
      expires < Time.now + TOKEN_EXPIRY_BUFFER
    end

    # @!attribute [r] hash
    # @return [Hash] Access the token details Hash object ruby'fied to use symbolized keys
    def hash
      @hash_object
    end
  end
end