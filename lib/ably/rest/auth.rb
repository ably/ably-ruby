module Ably
  # Auth is responsible for authentication with {https://ably.io Ably} using token authentication
  #
  # Find out more about Ably authentication at: http://docs.ably.io/other/authentication/
  class Auth
    include Ably::Support

    def initialize(client)
      @client = client
    end

    # Request a {Ably::Token} which can be used to make authenticated token based requests
    #
    # @param [Hash] options the options for the token request
    # @return [Ably::Token]
    def request_token(options = {})
      response = client.post("/keys/#{client.key_id}/requestToken", create_token_request(options), send_auth_header: false)

      Ably::Token.new(response.body[:access_token])
    end

    # Creates and signs a token request that can then subsequently be used by any client to request a token
    #
    # @param [Hash] options the options for the token request
    # @option options [String] :id key ID for the designated application
    # @option options [String] :client_id client ID identifying this connection to other clients
    # @option options [Integer] :ttl validity time in seconds for the requested {Ably::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Integer] :timestamp the time of the of the request in seconds since the epoch
    # @option options [Hash] :capability canonicalised representation of the resource paths and associated operations
    # @option options [String] :nonce an unquoted, unescaped random string of at least 16 characters
    # @return [Hash]
    def create_token_request(options = {})
      timestamp = if options[:query_time]
        client.time
      else
        Time.now
      end.to_i

      token_request = {
        id:         client.key_id,
        client_id:  client.client_id,
        ttl:        Token::DEFAULTS[:ttl],
        timestamp:  timestamp,
        capability: Token::DEFAULTS[:capability],
        nonce:      SecureRandom.hex
      }.merge(options)

      if token_request[:capability].is_a?(Hash)
        token_request[:capability] = token_request[:capability].to_json
      end

      token_request[:mac] = sign_params(token_request, client.key_secret)

      token_request
    end

    private
    # Sign the request params using the secret
    def sign_params(params, secret)
      text = params.values_at(
        :id,
        :ttl,
        :capability,
        :client_id,
        :timestamp,
        :nonce
      ).map { |t| "#{t}\n" }.join("")

      encode64(
        Digest::HMAC.digest(text, secret, Digest::SHA256)
      )
    end

    private
    attr_reader :client
  end
end
