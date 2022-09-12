module Ably::Models
  # Convert token request argument to a {TokenRequest} object
  #
  # @param attributes (see #initialize)
  #
  # @return [TokenRequest]
  #
  def self.TokenRequest(attributes)
    case attributes
    when TokenRequest
      return attributes
    else
      TokenRequest.new(attributes)
    end
  end


  # Contains the properties of a request for a token to Ably. Tokens are generated using {Ably::Auth#requestToken}.
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

    # The name of the key against which this request is made. The key name is public, whereas the key secret is private.
    # @spec TE2
    # @return [String] API key name of the key against which this request is made.  An API key is made up of an API key name and secret delimited by a +:+
    def key_name
      attributes.fetch(:key_name) { raise Ably::Exceptions::InvalidTokenRequest, 'Key name is missing' }
    end

    # Requested time to live for the Ably Token in milliseconds. If the Ably TokenRequest is successful, the TTL of the
    # returned Ably Token is less than or equal to this value, depending on application settings and the attributes of
    # the issuing key. The default is 60 minutes.
    # @spec TE4
    # @return [Integer] requested time to live for the token in seconds. If the token request is successful,
    #                   the TTL of the returned token will be less than or equal to this value depending on application
    #                   settings and the attributes of the issuing key.
    #                   TTL when sent to Ably is in milliseconds.
    def ttl
      attributes.fetch(:ttl) / 1000
    end

    # Capability of the requested Ably Token. If the Ably TokenRequest is successful, the capability of the returned
    # Ably Token will be the intersection of this capability with the capability of the issuing key. The capabilities
    # value is a JSON-encoded representation of the resource paths and associated operations. Read more about
    # capabilities in the capabilities docs.
    # @spec TE3
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

    # The client ID to associate with the requested Ably Token. When provided, the Ably Token may only be used to
    # perform operations on behalf of that client ID.
    # @spec TE2
    # @return [String] the client ID to associate with this token. The generated token
    #                  may be used to authenticate as this clientId.
    def client_id
      attributes[:client_id]
    end

    # The timestamp of this request as milliseconds since the Unix epoch.
    # @spec TE5
    # @return [Time] the timestamp of this request.
    #                Timestamps, in conjunction with the nonce, are used to prevent
    #                token requests from being replayed.
    #                Timestamp when sent to Ably is in milliseconds.
    def timestamp
      timestamp_val = attributes.fetch(:timestamp) { raise Ably::Exceptions::InvalidTokenRequest, 'Timestamp is missing' }
      as_time_from_epoch(timestamp_val, granularity: :ms)
    end

    # A cryptographically secure random string of at least 16 characters, used to ensure the TokenRequest cannot be reused.
    # @spec TE2
    # @return [String]  an opaque nonce string of at least 16 characters to ensure
    #                   uniqueness of this request. Any subsequent request using the
    #                   same nonce will be rejected.
    def nonce
      attributes.fetch(:nonce) { raise Ably::Exceptions::InvalidTokenRequest, 'Nonce is missing' }
    end

    # The Message Authentication Code for this request.
    # @spec TE2
    # @return [String]  the Message Authentication Code for this request. See the
    def mac
      attributes.fetch(:mac) { raise Ably::Exceptions::InvalidTokenRequest, 'MAC is missing' }
    end

    # Requests that the token is always persisted
    # @api private
    #
    def persisted
      attributes[:persisted]
    end

    # @return [Hash] the token request Hash object ruby'fied to use symbolized keys
    #
    def attributes
      @hash_object
    end

    # A static factory method to create a TokenRequest object from a deserialized TokenRequest-like object or a JSON
    # stringified TokenRequest object. This method is provided to minimize bugs as a result of differing types by platform
    # for fields such as timestamp or ttl. For example, in Ruby ttl in the TokenRequest object is exposed in seconds as
    # that is idiomatic for the language, yet when serialized to JSON using to_json it is automatically converted to
    # the Ably standard which is milliseconds. By using the fromJson() method when constructing a TokenRequest object,
    # Ably ensures that all fields are consistently serialized and deserialized across platforms.
    #
    # @overload from_json(json_like_object)
    # @spec TE6
    # @param json_like_object [Hash, String] A deserialized TokenRequest-like object or a JSON stringified TokenRequest object to create a TokenRequest.
    #
    # @return [Ably::Models::TokenRequest] An Ably token request object.
    #
  end
end
