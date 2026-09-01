module Ably::Models
  # Convert token details argument to a {TokenDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [TokenDetails]
  #
  def self.TokenDetails(attributes)
    case attributes
    when TokenDetails
      return attributes
    else
      TokenDetails.new(attributes)
    end
  end

  # Contains an Ably Token and its associated metadata.
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

    # The Ably Token itself. A typical Ably Token string appears with the form xVLyHw.A-pwh7wicf3afTfgiw4k2Ku33kcnSA7z6y8FjuYpe3QaNRTEo4.
    #
    # @spec TD2
    #
    # @return [String] Token used to authenticate requests
    #
    def token
      attributes[:token]
    end

    # @return [String] API key name used to create this token.  An API key is made up of an API key name and secret delimited by a +:+
    #
    def key_name
      attributes[:key_name]
    end

    # The timestamp at which this token was issued as milliseconds since the Unix epoch.
    # @spec TD4
    # @return [Time] Time the token was issued
    def issued
      as_time_from_epoch(attributes[:issued], granularity: :ms, allow_nil: :true)
    end

    # The timestamp at which this token expires as milliseconds since the Unix epoch.
    # @spec TD3
    # @return [Time] Time the token expires
    def expires
      as_time_from_epoch(attributes[:expires], granularity: :ms, allow_nil: :true)
    end

    # The capabilities associated with this Ably Token. The capabilities value is a JSON-encoded representation of the
    # resource paths and associated operations. Read more about capabilities in the capabilities docs.
    # @spec TD5
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

    # The client ID, if any, bound to this Ably Token. If a client ID is included, then the Ably Token authenticates its
    # bearer as that client ID, and the Ably Token may only be used to perform operations on behalf of that client ID.
    # The client is then considered to be an identified client.
    # @spec TD6
    # @return [String] Optional client ID assigned to this token
    def client_id
      attributes[:client_id]
    end

    # Returns true if token is expired or about to expire
    # For tokens that have not got an explicit expires attribute expired? will always return true
    #
    # @param attributes [Hash]
    # @option attributes [Time] :from   Sets a current time from which token expires
    #
    # @return [Boolean]
    def expired?(attributes = {})
      return false if !expires

      from = attributes[:from] || Time.now
      expires < from + TOKEN_EXPIRY_BUFFER
    end

    # True if the TokenDetails was created from an opaque string i.e. no metadata exists for this token
    # @return [Boolean]
    # @api private
    def from_token_string?
      attributes.keys == [:token]
    end

    # @return [Hash] Access the token details Hash object ruby'fied to use symbolized keys
    #
    def attributes
      @hash_object
    end

    def to_s
      "<TokenDetails token=#{token} client_id=#{client_id} key_name=#{key_name} issued=#{issued} expires=#{expires} capability=#{capability} expired?=#{expired?}>"
    end

    # A static factory method to create a {Ably::Models::TokenDetails} object from a deserialized {Ably::Models::TokenDetails}-like
    # object or a JSON stringified TokenDetails object. This method is provided to minimize bugs as a result of differing
    # types by platform for fields such as timestamp or ttl. For example, in Ruby ttl in the {Ably::Models::TokenDetails}
    # object is exposed in seconds as that is idiomatic for the language, yet when serialized to JSON using to_json it
    # is automatically converted to the Ably standard which is milliseconds. By using the fromJson() method when constructing
    # a {Ably::Models::TokenDetails} object, Ably ensures that all fields are consistently serialized and deserialized across platforms.
    #
    # @overload from_json(json_like_object)
    # @spec TD7
    # @param json_like_object [Hash, String] A deserialized TokenDetails-like object or a JSON stringified TokenDetails object.
    #
    # @return [Ably::Models::TokenDetails]  An Ably authentication token.
    #
  end
end
