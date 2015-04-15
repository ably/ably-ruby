require 'json'
require 'faraday'
require 'securerandom'

require 'ably/rest/middleware/external_exceptions'

module Ably
  # Auth is responsible for authentication with {https://ably.io Ably} using basic or token authentication
  #
  # Find out more about Ably authentication at: http://docs.ably.io/other/authentication/
  #
  # @!attribute [r] client_id
  #   @return [String] The provided client ID, used for identifying this client for presence purposes
  # @!attribute [r] current_token_details
  #   @return [Ably::Models::TokenDetails] Current {Ably::Models::TokenDetails} issued by this library or one of the provided callbacks used to authenticate requests
  # @!attribute [r] token
  #   @return [String] Token string provided to the {Ably::Client} constructor that is used to authenticate all requests
  # @!attribute [r] key
  #   @return [String] Complete API key containing both the key name and key secret, if present
  # @!attribute [r] key_name
  #   @return [String] Key name (public part of the API key), if present
  # @!attribute [r] key_secret
  #   @return [String] Key secret (private secure part of the API key), if present
  # @!attribute [r] options
  #   @return [Hash] {Ably::Auth} options configured for this client

  class Auth
    include Ably::Modules::Conversions
    include Ably::Modules::HttpHelpers

    # Default capability Hash object and TTL in seconds for issued tokens
    TOKEN_DEFAULTS = {
      capability: { '*' => ['*'] },
      ttl:        60 * 60 # 1 hour in seconds
    }

    attr_reader :options, :current_token_details
    alias_method :auth_options, :options

    # Creates an Auth object
    #
    # @param [Ably::Rest::Client] client  {Ably::Rest::Client} this Auth object uses
    # @param [Hash] options (see Ably::Rest::Client#initialize)
    # @option (see Ably::Rest::Client#initialize)
    # @yield  (see Ably::Rest::Client#initialize)
    #
    def initialize(client, options, &token_request_block)
      ensure_valid_auth_attributes options

      auth_options = options.dup

      @client              = client
      @options             = auth_options
      @default_token_block = token_request_block if block_given?

      unless auth_options.kind_of?(Hash)
        raise ArgumentError, 'Expected auth_options to be a Hash'
      end

      if auth_options[:key] && (auth_options[:key_secret] || auth_options[:key_name])
        raise ArgumentError, 'key and key_name or key_secret are mutually exclusive. Provider either a key or key_name & key_secret'
      end

      split_api_key_into_key_and_secret! auth_options if auth_options[:key]

      if using_basic_auth? && !api_key_present?
        raise ArgumentError, 'key is missing. Either an API key, token, or token auth method must be provided'
      end

      if has_client_id?
        raise ArgumentError, 'client_id cannot be provided without a complete API key. Key name & Secret is needed to authenticate with Ably and obtain a token' unless api_key_present?
        ensure_utf_8 :client_id, client_id
      end

      @options.freeze
    end

    # Ensures valid auth credentials are present for the library instance. This may rely on an already-known and valid token, and will obtain a new token if necessary.
    #
    # In the event that a new token request is made, the specified options are used.
    #
    # @param [Hash] options the options for the token request
    # @option options (see #request_token)
    # @option options [String]  :key            API key comprising the key name and key secret in a single string
    # @option options [Boolean] :force          obtains a new token even if the current token is valid
    #
    # @yield (see #request_token)
    # @yieldparam [Hash] options options passed to {#authorise} will be in turn sent to the block in this argument
    # @yieldreturn (see #request_token)
    #
    # @return (see #request_token)
    #
    # @example
    #    # will issue a simple token request using basic auth
    #    client = Ably::Rest::Client.new(key: 'key.id:secret')
    #    token = client.auth.authorise
    #
    #    # will use token request from block to authorise if not already authorised
    #    token = client.auth.authorise do |options|
    #      # create token_request object
    #      token_request
    #    end
    #
    def authorise(options = {}, &token_request_block)
      ensure_valid_auth_attributes options

      if current_token_details && !options[:force]
        return current_token_details unless current_token_details.expired?
      end

      options = options.clone

      split_api_key_into_key_and_secret! options if options[:key]

      @options             = @options.merge(options)
      @default_token_block = token_request_block if block_given?

      @current_token_details = request_token(options, &token_request_block)
    end

    # Request a {Ably::Models::TokenDetails} which can be used to make authenticated token based requests
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key          complete API key for the designated application
    # @option options [String]  :client_id    client ID identifying this connection to other clients (defaults to client client_id if configured)
    # @option options [String]  :auth_url     a URL to be used to GET or POST a set of token request params, to obtain a signed token request.
    # @option options [Hash]    :auth_headers a set of application-specific headers to be added to any request made to the authUrl
    # @option options [Hash]    :auth_params  a set of application-specific query params to be added to any request made to the authUrl
    # @option options [Symbol]  :auth_method  HTTP method to use with auth_url, must be either `:get` or `:post` (defaults to :get)
    # @option options [Integer] :ttl          validity time in seconds for the requested {Ably::Models::TokenDetails}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability   canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time   when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Time]    :timestamp    the time of the of the request
    # @option options [String]  :nonce        an unquoted, unescaped random string of at least 16 characters
    #
    # @yield [options] (optional) if a token request block is passed to this method, then this block will be called whenever a new token is required
    # @yieldparam [Hash] options options passed to {#request_token} will be in turn sent to the block in this argument
    # @yieldreturn [Hash] expects a valid token request object, see {#create_token_request}
    #
    # @return [Ably::Models::TokenDetails]
    #
    # @example
    #    # simple token request using basic auth
    #    client = Ably::Rest::Client.new(key: 'key.id:secret')
    #    token = client.auth.request_token
    #
    #    # token request using auth block
    #    token = client.auth.request_token do |options|
    #      # create token_request object
    #      token_request
    #    end
    #
    def request_token(options = {})
      ensure_valid_auth_attributes options

      token_options = auth_options.merge(options)

      auth_url = token_options.delete(:auth_url)
      token_request = if block_given?
        yield token_options
      elsif default_token_block
        default_token_block.call(token_options)
      elsif auth_url
        token_request_from_auth_url(auth_url, token_options)
      else
        create_token_request(token_options)
      end

      case token_request
        when Ably::Models::TokenDetails
          return token_request
        when Hash
          return Ably::Models::TokenDetails.new(token_request) if IdiomaticRubyWrapper(token_request).has_key?(:issued_at)
        when String
          return Ably::Models::TokenDetails.new(token: token_request)
      end

      token_request = Ably::Models::TokenRequest(token_request)

      response = client.post("/keys/#{token_request.key_name}/requestToken",
                             token_request.hash, send_auth_header: false,
                             disable_automatic_reauthorise: true)

      Ably::Models::TokenDetails.new(response.body)
    end

    # Creates and signs a token request that can then subsequently be used by any client to request a token
    #
    # @param [Hash] options the options for the token request
    # @option options [String]  :key        complete API key for the designated application
    # @option options [String]  :client_id  client ID identifying this connection to other clients
    # @option options [Integer] :ttl        validity time in seconds for the requested {Ably::Models::TokenDetails}.  Limits may apply, see {http://docs.ably.io/other/authentication/}
    # @option options [Hash]    :capability canonicalised representation of the resource paths and associated operations
    # @option options [Boolean] :query_time when true will query the {https://ably.io Ably} system for the current time instead of using the local time
    # @option options [Time]    :timestamp  the time of the of the request
    # @option options [String]  :nonce      an unquoted, unescaped random string of at least 16 characters
    #
    # @return [Models::TokenRequest]
    #
    # @example
    #    client.auth.create_token_request(id: 'asd.asd', ttl: 3600)
    #    #<Ably::Models::TokenRequest:0x007fd5d919df78
    #    #  @hash={
    #    #   :id=>"asds.adsa",
    #    #   :clientId=>nil,
    #    #   :ttl=>3600000,
    #    #   :timestamp=>1428973674000,
    #    #   :capability=>"{\"*\":[\"*\"]}",
    #    #   :nonce=>"95e543b88299f6bae83df9b12fbd1ecd",
    #    #   :mac=>"881oZHeFo6oMim7....uE56a8gUxHw="
    #    #  }
    #    #>>
    def create_token_request(options = {})
      ensure_valid_auth_attributes options

      token_options = options.clone

      split_api_key_into_key_and_secret! token_options if token_options[:key]
      request_key_name   = token_options.delete(:key_name) || key_name
      request_key_secret = token_options.delete(:key_secret) || key_secret
      raise Ably::Exceptions::TokenRequestError, 'Key Name and Key Secret are required to generate a new token request' unless request_key_name && request_key_secret

      timestamp = if token_options[:query_time]
        client.time
      else
        token_options.delete(:timestamp) || Time.now
      end
      timestamp = Time.at(timestamp) if timestamp.kind_of?(Integer)

      token_request = {
        keyName:    token_options[:key_name] || request_key_name,
        clientId:   token_options[:client_id] || client_id,
        ttl:        ((token_options[:ttl] || TOKEN_DEFAULTS.fetch(:ttl)) * 1000).to_i,
        timestamp:  (timestamp.to_f * 1000).round,
        capability: token_options[:capability] || TOKEN_DEFAULTS.fetch(:capability),
        nonce:      token_options[:nonce] || SecureRandom.hex
      }

      token_request[:capability] = JSON.dump(token_request[:capability]) if token_request[:capability].is_a?(Hash)

      token_request[:mac] = sign_params(token_request, request_key_secret)

      # Undocumented feature to request a persisted token
      token_request[:persisted] = options[:persisted] if options[:persisted]

      Models::TokenRequest.new(token_request)
    end

    def key
      "#{key_name}:#{key_secret}" if api_key_present?
    end

    def key_name
      options[:key_name]
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
      return options[:use_token_auth] if options.has_key?(:use_token_auth)
      token || current_token_details || has_client_id? || token_creatable_externally?
    end

    def client_id
      options[:client_id]
    end

    def token
      token_object = options[:token] || options[:token_details]

      if token_object.kind_of?(Ably::Models::TokenDetails)
        token_object.token
      else
        token_object
      end
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
    # * Valid API key and token option not provided as token options cannot be determined
    # * Authentication callback for new token requests
    # * Authentication URL for new token requests
    #
    # @return [Boolean]
    def token_renewable?
      token_creatable_externally? || (api_key_present? && !token)
    end

    # Returns false when attempting to send an API Key over a non-secure connection
    # Token auth must be used for non-secure connections
    #
    # @return [Boolean]
    def authentication_security_requirements_met?
      client.use_tls? || using_token_auth?
    end

    private
    attr_reader :client, :default_token_block

    def ensure_valid_auth_attributes(attributes)
      if attributes[:timestamp]
        unless attributes[:timestamp].kind_of?(Time) || attributes[:timestamp].kind_of?(Numeric)
          raise ArgumentError, ':timestamp must be a Time or positive Integer value of seconds since epoch'
        end
      end

      if attributes[:ttl]
        unless attributes[:ttl].kind_of?(Numeric) && attributes[:ttl].to_f > 0
          raise ArgumentError, ':ttl must be a positive Numeric value representing time to live in seconds'
        end
      end

      if attributes[:auth_headers]
        unless attributes[:auth_headers].kind_of?(Hash)
          raise ArgumentError, ':auth_headers must be a valid Hash'
        end
      end

      if attributes[:auth_params]
        unless attributes[:auth_params].kind_of?(Hash)
          raise ArgumentError, ':auth_params must be a valid Hash'
        end
      end

      if attributes[:auth_method]
        unless %(get post).include?(attributes[:auth_method].to_s)
          raise ArgumentError, ':auth_method must be either :get or :post'
        end
      end
    end

    def ensure_api_key_sent_over_secure_connection
      raise Ably::Exceptions::InsecureRequestError, 'Cannot use Basic Auth over non-TLS connections' unless authentication_security_requirements_met?
    end

    # Basic Auth HTTP Authorization header value
    def basic_auth_header
      ensure_api_key_sent_over_secure_connection
      "Basic #{encode64("#{key}")}"
    end

    def split_api_key_into_key_and_secret!(options)
      api_key_parts = options[:key].to_s.match(/(?<name>[\w_-]+\.[\w_-]+):(?<secret>[\w_-]+)/)
      raise ArgumentError, 'key is invalid' unless api_key_parts

      options[:key_name]   = api_key_parts[:name].encode(Encoding::UTF_8)
      options[:key_secret] = api_key_parts[:secret].encode(Encoding::UTF_8)

      options.delete :key
    end

    # Returns the current token if it exists or authorises and retrieves a token
    def token_auth_string
      if token
        token
      else
        authorise.token
      end
    end

    # Token Auth HTTP Authorization header value
    def token_auth_header
      "Bearer #{encode64(token_auth_string)}"
    end

    # Basic Auth params to authenticate the Realtime connection
    def basic_auth_params
      ensure_api_key_sent_over_secure_connection
      {
        key: key
      }
    end

    # Token Auth params to authenticate the Realtime connection
    def token_auth_params
      {
        access_token: token_auth_string
      }
    end

    # Sign the request params using the secret
    #
    # @return [Hash]
    def sign_params(params, secret)
      text = params.values_at(
        :keyName,
        :ttl,
        :capability,
        :clientId,
        :timestamp,
        :nonce
      ).map do |val|
        "#{val}\n"
      end.join('')

      encode64(
        OpenSSL::HMAC.digest(OpenSSL::Digest::SHA256.new, secret, text)
      )
    end

    # Retrieve a token request from a specified URL, expects a JSON response
    #
    # @return [Hash]
    def token_request_from_auth_url(auth_url, options = {})
      uri = URI.parse(auth_url)
      connection = Faraday.new("#{uri.scheme}://#{uri.host}", connection_options)
      method = options[:auth_method] || :get

      response = connection.send(method) do |request|
        request.url uri.path
        request.params = options[:auth_params] || {}
        request.headers = options[:auth_headers] || {}
      end

      if !response.body.kind_of?(Hash) && response.headers['Content-Type'] != 'text/plain'
        raise Ably::Exceptions::InvalidResponseBody,
              "Content Type #{response.headers['Content-Type']} is not supported by this client library"
      end

      response.body
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
        setup_outgoing_middleware builder

        # Raise exceptions if response code is invalid
        builder.use Ably::Rest::Middleware::ExternalExceptions

        setup_incoming_middleware builder, client.logger

        # Set Faraday's HTTP adapter
        builder.adapter Faraday.default_adapter
      end
    end

    def token_callback_present?
      !!default_token_block
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
      key_name && key_secret
    end
  end
end
