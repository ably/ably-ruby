require 'json'
require 'faraday'
require 'securerandom'

require "ably/rest/middleware/external_exceptions"

module Ably
  # Auth is responsible for authentication with {https://ably.io Ably} using basic or token authentication
  #
  # Find out more about Ably authentication at: http://docs.ably.io/other/authentication/
  #
  # @!attribute [r] client_id
  #   @return [String] The provided client ID, used for identifying this client for presence purposes
  # @!attribute [r] current_token
  #   @return [Ably::Models::Token] Current {Ably::Models::Token} issued by this library or one of the provided callbacks used to authenticate requests
  # @!attribute [r] token_id
  #   @return [String] Token ID provided to the {Ably::Client} constructor that is used to authenticate all requests
  # @!attribute [r] api_key
  #   @return [String] Complete API key containing both the key ID and key secret, if present
  # @!attribute [r] key_id
  #   @return [String] Key ID (public part of the API key), if present
  # @!attribute [r] key_secret
  #   @return [String] Key secret (private secure part of the API key), if present
  # @!attribute [r] options
  #   @return [Hash] {Ably::Auth} options configured for this client

  class Auth
    include Ably::Modules::Conversions
    include Ably::Modules::HttpHelpers

    attr_reader :options, :current_token
    alias_method :auth_options, :options

    # Creates an Auth object
    #
    # @param [Ably::Rest::Client] client  {Ably::Rest::Client} this Auth object uses
    # @param [Hash] auth_options          see {Ably::Rest::Client#initialize}
    # @yield [auth_options]               see {Ably::Rest::Client#initialize}
    def initialize(client, auth_options, &auth_block)
      auth_options = auth_options.dup

      @client        = client
      @options       = auth_options
      @auth_callback = auth_block if block_given?

      unless auth_options.kind_of?(Hash)
        raise ArgumentError, "Expected auth_options to be a Hash"
      end

      if auth_options[:api_key] && (auth_options[:key_secret] || auth_options[:key_id])
        raise ArgumentError, "api_key and key_id or key_secret are mutually exclusive. Provider either an api_key or key_id & key_secret"
      end

      if auth_options[:api_key]
        api_key_parts = auth_options[:api_key].to_s.match(/(?<id>[\w_-]+\.[\w_-]+):(?<secret>[\w_-]+)/)
        raise ArgumentError, "api_key is invalid" unless api_key_parts
        auth_options[:key_id] = api_key_parts[:id]
        auth_options[:key_secret] = api_key_parts[:secret]
      end

      if using_basic_auth? && !api_key_present?
        raise ArgumentError, "api_key is missing. Either an API key, token, or token auth method must be provided"
      end

      if has_client_id? && !api_key_present?
        raise ArgumentError, "client_id cannot be provided without a complete API key. Key ID & Secret is needed to authenticate with Ably and obtain a token"
      end

      @options.freeze
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
    # @option options [Integer] :ttl          validity time in seconds for the requested {Ably::Models::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability   canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time   when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Time]    :timestamp    the time of the of the request
    # @option options [String]  :nonce        an unquoted, unescaped random string of at least 16 characters
    # @option options [Boolean] :force        obtains a new token even if the current token is valid
    #
    # @yield [options] (optional) if an auth block is passed to this method, then this block will be called to create a new token request object
    # @yieldparam [Hash] options options passed to request_token will be in turn sent to the block in this argument
    # @yieldreturn [Hash] valid token request object, see {Auth#create_token_request}
    #
    # @return [Ably::Models::Token]
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

    # Request a {Ably::Models::Token} which can be used to make authenticated token based requests
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key_id       key ID for the designated application (defaults to client key_id)
    # @option options [String]  :key_secret   key secret for the designated application used to sign token requests (defaults to client key_secret)
    # @option options [String]  :client_id    client ID identifying this connection to other clients (defaults to client client_id if configured)
    # @option options [String]  :auth_url     a URL to be used to GET or POST a set of token request params, to obtain a signed token request.
    # @option options [Hash]    :auth_headers a set of application-specific headers to be added to any request made to the authUrl
    # @option options [Hash]    :auth_params  a set of application-specific query params to be added to any request made to the authUrl
    # @option options [Symbol]  :auth_method  HTTP method to use with auth_url, must be either `:get` or `:post` (defaults to :get)
    # @option options [Integer] :ttl          validity time in seconds for the requested {Ably::Models::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability   canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time   when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Time]    :timestamp    the time of the of the request
    # @option options [String]  :nonce        an unquoted, unescaped random string of at least 16 characters
    #
    # @yield [options] (optional) if an auth block is passed to this method, then this block will be called to create a new token request object
    # @yieldparam [Hash] options options passed to request_token will be in turn sent to the block in this argument
    # @yieldreturn [Hash] valid token request object, see {Auth#create_token_request}
    #
    # @return [Ably::Models::Token]
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
      token_options = self.auth_options.merge(options)

      auth_url = token_options.delete(:auth_url)
      token_request = if block_given?
        yield(token_options)
      elsif auth_callback
        auth_callback.call(token_options)
      elsif auth_url
        token_request_from_auth_url(auth_url, token_options)
      else
        create_token_request(token_options)
      end

      token_request = IdiomaticRubyWrapper(token_request)

      response = client.post("/keys/#{token_request.fetch(:id)}/requestToken", token_request, send_auth_header: false)
      body = IdiomaticRubyWrapper(response.body)

      Ably::Models::Token.new(body.fetch(:access_token))
    end

    # Creates and signs a token request that can then subsequently be used by any client to request a token
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key_id     key ID for the designated application
    # @option options [String]  :key_secret key secret for the designated application used to sign token requests (defaults to client key_secret)
    # @option options [String]  :client_id  client ID identifying this connection to other clients
    # @option options [Integer] :ttl        validity time in seconds for the requested {Ably::Models::Token}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Time]    :timestamp  the time of the of the request
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
      token_attributes   = %w(id client_id ttl timestamp capability nonce)

      token_options      = options.clone
      request_key_id     = token_options.delete(:key_id) || key_id
      request_key_secret = token_options.delete(:key_secret) || key_secret

      raise Ably::Exceptions::TokenRequestError, "Key ID and Key Secret are required to generate a new token request" unless request_key_id && request_key_secret

      timestamp = if token_options[:query_time]
        client.time
      else
        token_options.delete(:timestamp) || Time.now
      end.to_i

      token_request = {
        id:         request_key_id,
        client_id:  client_id,
        ttl:        Ably::Models::Token::DEFAULTS[:ttl],
        timestamp:  timestamp,
        capability: Ably::Models::Token::DEFAULTS[:capability],
        nonce:      SecureRandom.hex
      }.merge(token_options.select { |key, val| token_attributes.include?(key.to_s) })

      if token_request[:capability].is_a?(Hash)
        token_request[:capability] = token_request[:capability].to_json
      end

      token_request[:mac] = sign_params(token_request, request_key_secret)

      token_request
    end

    def api_key
      "#{key_id}:#{key_secret}" if api_key_present?
    end

    def key_id
      options[:key_id]
    end

    def key_secret
      options[:key_secret]
    end

    # True when Basic Auth is being used to authenticate with Ably
    def using_basic_auth?
      !using_token_auth?
    end

    # True when Token Auth is being used to authenticate with Ably
    def using_token_auth?
      token_id || current_token || has_client_id? || token_creatable_externally?
    end

    def client_id
      options[:client_id]
    end

    def token_id
      options[:token_id]
    end

    # Auth header string used in HTTP requests to Ably
    #
    # @return [String] HTTP authentication value used in HTTP_AUTHORIZATION header
    def auth_header
      if using_token_auth?
        token_auth_header
      else
        basic_auth_header
      end
    end

    # Auth params used in URI endpoint for Realtime connections
    #
    # @return [Hash] Auth params for a new Realtime connection
    def auth_params
      if using_token_auth?
        token_auth_params
      else
        basic_auth_params
      end
    end

    # True if prerequisites for creating a new token request are present
    #
    # One of the following criterion must be met:
    # * Valid key id and secret
    # * Authentication callback for new token requests
    # * Authentication URL for new token requests
    #
    # @return [Boolean]
    def token_renewable?
      token_creatable_externally? || api_key_present?
    end

    private
    attr_reader :auth_callback

    # Basic Auth HTTP Authorization header value
    def basic_auth_header
      raise Ably::Exceptions::InsecureRequestError, "Cannot use Basic Auth over non-TLS connections" unless client.use_tls?
      "Basic #{encode64("#{api_key}")}"
    end

    def token_auth_id
      current_token_id = if token_id
        token_id
      else
        authorise.id
      end
    end

    # Token Auth HTTP Authorization header value
    def token_auth_header
      "Bearer #{encode64(token_auth_id)}"
    end

    # Basic Auth params to authenticate the Realtime connection
    def basic_auth_params
      raise Ably::Exceptions::InsecureRequestError, "Cannot use Basic Auth over non-TLS connections" unless client.use_tls?
      # TODO: Change to key_secret when API is updated
      {
        key_id: key_id,
        key_value: key_secret
      }
    end

    # Token Auth params to authenticate the Realtime connection
    def token_auth_params
      {
        access_token: token_auth_id
      }
    end

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
          accept:     client.mime_type,
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
        setup_middleware builder

        # Raise exceptions if response code is invalid
        builder.use Ably::Rest::Middleware::ExternalExceptions


        # Log HTTP requests if log level is DEBUG option set
        builder.response :logger if client.log_level == Logger::DEBUG

        # Set Faraday's HTTP adapter
        builder.adapter Faraday.default_adapter
      end
    end

    def token_callback_present?
      !!auth_callback
    end

    def token_url_present?
      !!options[:auth_url]
    end

    def token_creatable_externally?
      token_callback_present? || token_url_present?
    end

    def has_client_id?
      !!client_id
    end

    def api_key_present?
      key_id && key_secret
    end

    private
    attr_reader :client
  end
end
