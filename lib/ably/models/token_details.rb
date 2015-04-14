module Ably::Models
  # Convert token details argument to a {TokenDetails} object
  #
  # @param token_details [TokenDetails,Hash] A {TokenDetails} object or Hash of token details
  #
  # @return [TokenDetails]
  def self.TokenDetails(token_details)
    case token_details
    when TokenDetails
      return token_details
    else
      TokenDetails.new(token_details)
    end
  end

  # TokenDetails is a class providing details of a token and its associated metadata,
  # provided when the system successfully requests a token from the system.
  #
  class TokenDetails
    include Ably::Modules::ModelCommon

    # Buffer in seconds given to the use of a token prior to it being considered unusable
    # For example, if buffer is 10s, the token can no longer be used for new requests 9s before it expires
    TOKEN_EXPIRY_BUFFER = 5

    def initialize(attributes)
      @hash_object = IdiomaticRubyWrapper(attributes.clone.freeze)
    end

    # @!attribute [r] token
    # @return [String] Token used to authenticate requests
    def token
      # TODO: Change to :token
      # hash.fetch(:token)
      hash.fetch(:id)
    end

    # @!attribute [r] key_name
    # @return [String] API key name used to create this token.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      # TODO: Change to :key_name
      # hash.fetch(:key_name)
      hash.fetch(:key)
    end

    # @!attribute [r] issued_at
    # @return [Time] Time the token was issued
    def issued_at
      # TODO: Review whether this underlying data should be in ms
      as_time_from_epoch(hash.fetch(:issued_at), granularity: :s)
    end

    # @!attribute [r] expires
    # @return [Time] Time the token expires
    def expires
      # TODO: Review whether this underlying data should be in ms
      as_time_from_epoch(hash.fetch(:expires), granularity: :s)
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

    # @!attribute [r] nonce
    # @return [String] unique nonce used to generate Token and ensure token generation cannot be replayed
    def nonce
      hash.fetch(:nonce)
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
