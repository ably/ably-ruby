require "json"
require "faraday"
require "securerandom"

require "ably/rest/middleware/external_exceptions"
require "ably/rest/middleware/parse_json"

module Ably
  # Auth is responsible for authentication with {https://ably.io Ably} using token authentication
  #
  # Find out more about Ably authentication at: http://docs.ably.io/other/authentication/
  class Auth
    include Ably::Support

    # The current token generated from an explicit/implicit authorise request
    attr_reader :current_token

    def initialize(client)
      @client = client
    end

    # Ensures valid auth credentials are present for the library instance. This may rely on an already-known and valid token, and will obtain a new token if necessary.
    #
    # In the event that a new token request is made, the specified options are used.
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key_id       key ID for the designated application (defaults to client key_id)
    # @option options [String]  :key_secret   key secret for the designated application used to sign token requests (defaults to client key_secret)
    # @option options [String]  :client_id    client ID identifying this connection to other clients (defaults to client client_id if configured)
    # @option options [String]  :auth_url     a URL to be used to GET or POST a set of token request params, to obtain a signed token request.
    # @option options [Hash]    :auth_headers a set of application-specific headers to be added to any request made to the authUrl
    # @option options [Hash]    :auth_params  a set of application-specific query params to be added to any request made to the authUrl
    # @option options [Symbol]  :auth_method  HTTP method to use with auth_url, must be either `:get` or `:post` (defaults to :get)
    # @option options [Integer] :ttl          validity time in seconds for the requested {Ably::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability   canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time   when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Integer] :timestamp    the time of the of the request in seconds since the epoch
    # @option options [String]  :nonce        an unquoted, unescaped random string of at least 16 characters
    # @option options [Boolean] :force        obtains a new token even if the current token is valid
    #
    # @yield [options] (optional) if an auth block is passed to this method, then this block will be called to create a new token request object
    # @yieldparam [Hash] options options passed to request_token will be in turn sent to the block in this argument
    # @yieldreturn [Hash] valid token request object, see {#create_token_request}
    #
    # @return [Ably::Token]
    #
    # @example
    #    # will issue a simple token request using basic auth
    #    client = Ably::Rest::Client.new(api_key: 'key.id:secret')
    #    token = client.auth.authorise
    #
    #    # will use token request from block to authorise if not already authorised
    #    token = client.auth.authorise do |options|
    #      # create token_request object
    #      token_request
    #    end
    #
    def authorise(options = {}, &block)
      if !options[:force] && current_token
        return current_token unless current_token.expired?
      end

      @current_token = request_token(options, &block)
    end

    # Request a {Ably::Token} which can be used to make authenticated token based requests
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key_id       key ID for the designated application (defaults to client key_id)
    # @option options [String]  :key_secret   key secret for the designated application used to sign token requests (defaults to client key_secret)
    # @option options [String]  :client_id    client ID identifying this connection to other clients (defaults to client client_id if configured)
    # @option options [String]  :auth_url     a URL to be used to GET or POST a set of token request params, to obtain a signed token request.
    # @option options [Hash]    :auth_headers a set of application-specific headers to be added to any request made to the authUrl
    # @option options [Hash]    :auth_params  a set of application-specific query params to be added to any request made to the authUrl
    # @option options [Symbol]  :auth_method  HTTP method to use with auth_url, must be either `:get` or `:post` (defaults to :get)
    # @option options [Integer] :ttl          validity time in seconds for the requested {Ably::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability   canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time   when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Integer] :timestamp    the time of the of the request in seconds since the epoch
    # @option options [String]  :nonce        an unquoted, unescaped random string of at least 16 characters
    #
    # @yield [options] (optional) if an auth block is passed to this method, then this block will be called to create a new token request object
    # @yieldparam [Hash] options options passed to request_token will be in turn sent to the block in this argument
    # @yieldreturn [Hash] valid token request object, see {#create_token_request}
    #
    # @return [Ably::Token]
    #
    # @example
    #    # simple token request using basic auth
    #    client = Ably::Rest::Client.new(api_key: 'key.id:secret')
    #    token = client.auth.request_token
    #
    #    # token request using auth block
    #    token = client.auth.request_token do |options|
    #      # create token_request object
    #      token_request
    #    end
    #
    def request_token(options = {}, &block)
      token_options = options.dup

      auth_url = options.delete(:auth_url)
      token_request = if block_given?
        yield(token_options)
      elsif auth_url
        token_request_from_auth_url(auth_url, token_options)
      else
        create_token_request(token_options)
      end

      key_id = token_options[:key_id] || client.key_id

      response = client.post("/keys/#{key_id}/requestToken", token_request, send_auth_header: false)

      Ably::Token.new(response.body[:access_token])
    end

    # Creates and signs a token request that can then subsequently be used by any client to request a token
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key_id     key ID for the designated application
    # @option options [String]  :key_secret key secret for the designated application used to sign token requests (defaults to client key_secret)
    # @option options [String]  :client_id  client ID identifying this connection to other clients
    # @option options [Integer] :ttl        validity time in seconds for the requested {Ably::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Integer] :timestamp  the time of the of the request in seconds since the epoch
    # @option options [String]  :nonce      an unquoted, unescaped random string of at least 16 characters
    # @return [Hash]
    #
    # @example
    #    client.auth.create_request_token(id: 'asd.asd', ttl: 3600)
    #    # => {
    #    #   :id=>"asds.adsa",
    #    #   :client_id=>nil,
    #    #   :ttl=>3600,
    #    #   :timestamp=>1410718527,
    #    #   :capability=>"{\"*\":[\"*\"]}",
    #    #   :nonce=>"95e543b88299f6bae83df9b12fbd1ecd",
    #    #   :mac=>"881oZHeFo6oMim7N64y2vFHtSlpQ2gn/uE56a8gUxHw="
    #    # }
    def create_token_request(options = {})
      token_attributes = %w(id client_id ttl timestamp capability nonce)

      token_options = options.dup
      token_options[:id] = token_options.delete(:key_id) if token_options.has_key?(:key_id)

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
      }.merge(options.select { |key, val| token_attributes.include?(key.to_s) })

      if token_request[:capability].is_a?(Hash)
        token_request[:capability] = token_request[:capability].to_json
      end

      token_request[:mac] = sign_params(token_request, options[:key_secret] || client.key_secret)

      token_request
    end

    private
    # Sign the request params using the secret
    #
    # @return [Hash]
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

    # Retrieve a token request from a specified URL, expects a JSON response
    #
    # @return [Hash]
    def token_request_from_auth_url(auth_url, options = {})
      uri = URI.parse(auth_url)
      connection = Faraday.new("#{uri.scheme}://#{uri.host}", connection_options)
      method = options[:auth_method] || :get

      connection.send(method) do |request|
        request.url uri.path
        request.params = options[:auth_params] || {}
        request.headers = options[:auth_headers] || {}
      end.body
    end

    # Return a Hash of connection options to initiate the Faraday::Connection with
    #
    # @return [Hash]
    def connection_options
      @connection_options ||= {
        builder: middleware,
        headers: {
          accept:     "application/json",
          user_agent: user_agent
        },
        request: {
          open_timeout: 5,
          timeout:      10
        }
      }
    end

    # Return a Faraday middleware stack to initiate the Faraday::Connection with
    #
    # @see http://mislav.uniqpath.com/2011/07/faraday-advanced-http/
    def middleware
      @middleware ||= Faraday::RackBuilder.new do |builder|
        # Convert request params to "www-form-urlencoded"
        builder.use Faraday::Request::UrlEncoded

        # Parse JSON response bodies
        builder.use Ably::Rest::Middleware::ParseJson

        # Log HTTP requests if debug_http option set
        builder.response :logger if @debug_http

        # Raise exceptions if response code is invalid
        builder.use Ably::Rest::Middleware::ExternalExceptions

        # Set Faraday's HTTP adapter
        builder.adapter Faraday.default_adapter
      end
    end

    private
    attr_reader :client
  end
end
