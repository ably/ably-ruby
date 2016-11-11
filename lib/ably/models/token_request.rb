module Ably::Models
  # Convert token request argument to a {TokenRequest} object
  #
  # @param attributes (see #initialize)
  #
  # @return [TokenRequest]
  def self.TokenRequest(attributes)
    case attributes
    when TokenRequest
      return attributes
    else
      TokenRequest.new(attributes)
    end
  end


  # TokenRequest is a class that stores the attributes of a token request
  #
  # Ruby {http://ruby-doc.org/core/Time.html Time} objects are supported in place of Ably ms since epoch time fields.  However, if a numeric is provided
  # it must always be expressed in milliseconds as the Ably API always uses milliseconds for time fields.
  #
  class TokenRequest
    include Ably::Modules::ModelCommon

    # @param attributes
    # @option attributes [Integer]      :ttl        requested time to live for the token in milliseconds
    # @option attributes [Time,Integer] :timestamp  the timestamp of this request in milliseconds or as a {http://ruby-doc.org/core/Time.html Time}
    # @option attributes [String]       :key_name   API key name of the key against which this request is made
    # @option attributes [String]       :capability JSON stringified capability of the token
    # @option attributes [String]       :client_id  client ID to associate with this token
    # @option attributes [String]       :nonce      an opaque nonce string of at least 16 characters
    # @option attributes [String]       :mac        the Message Authentication Code for this request
    #
    def initialize(attributes = {})
      @hash_object = IdiomaticRubyWrapper(attributes.clone)
      if self.attributes[:timestamp].kind_of?(Time)
        self.attributes[:timestamp] = (self.attributes[:timestamp].to_f * 1000).round
      end
      self.attributes.freeze
    end

    # @!attribute [r] key_name
    # @return [String] API key name of the key against which this request is made.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      attributes.fetch(:key_name) { raise Ably::Exceptions::InvalidTokenRequest, 'Key name is missing' }
    end

    # @!attribute [r] ttl
    # @return [Integer] requested time to live for the token in seconds. If the token request is successful,
    #                   the TTL of the returned token will be less than or equal to this value depending on application
    #                   settings and the attributes of the issuing key.
    #                   TTL when sent to Ably is in milliseconds.
    def ttl
      attributes.fetch(:ttl) / 1000
    end

    # @!attribute [r] capability
    # @return [Hash] capability of the token. If the token request is successful,
    #                the capability of the returned token will be the intersection of
    #                this capability with the capability of the issuing key.
    def capability
      capability_val = attributes.fetch(:capability) { raise Ably::Exceptions::InvalidTokenRequest, 'Capability is missing' }

      case capability_val
      when Hash
        capability_val
      when Ably::Models::IdiomaticRubyWrapper
        capability_val.as_json
      else
        JSON.parse(attributes.fetch(:capability))
      end
    end

    # @!attribute [r] client_id
    # @return [String] the client ID to associate with this token. The generated token
    #                  may be used to authenticate as this clientId.
    def client_id
      attributes[:client_id]
    end

    # @!attribute [r] timestamp
    # @return [Time] the timestamp of this request.
    #                Timestamps, in conjunction with the nonce, are used to prevent
    #                token requests from being replayed.
    #                Timestamp when sent to Ably is in milliseconds.
    def timestamp
      timestamp_val = attributes.fetch(:timestamp) { raise Ably::Exceptions::InvalidTokenRequest, 'Timestamp is missing' }
      as_time_from_epoch(timestamp_val, granularity: :ms)
    end

    # @!attribute [r] nonce
    # @return [String]  an opaque nonce string of at least 16 characters to ensure
    #                   uniqueness of this request. Any subsequent request using the
    #                   same nonce will be rejected.
    def nonce
      attributes.fetch(:nonce) { raise Ably::Exceptions::InvalidTokenRequest, 'Nonce is missing' }
    end

    # @!attribute [r] mac
    # @return [String]  the Message Authentication Code for this request. See the
    #                   {https://www.ably.io/documentation Ably Authentication documentation} for more details.
    def mac
      attributes.fetch(:mac) { raise Ably::Exceptions::InvalidTokenRequest, 'MAC is missing' }
    end

    # Requests that the token is always persisted
    # @api private
    #
    def persisted
      attributes[:persisted]
    end

    # @!attribute [r] attributes
    # @return [Hash] the token request Hash object ruby'fied to use symbolized keys
    def attributes
      @hash_object
    end
  end
end
