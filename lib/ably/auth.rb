require 'json'
require 'faraday'
require 'securerandom'

require 'ably/rest/middleware/external_exceptions'

module Ably
  # Auth is responsible for authentication with {https://www.ably.io Ably} using basic or token authentication
  #
  # Find out more about Ably authentication at: https://www.ably.io/documentation/general/authentication/
  #
  # @!attribute [r] client_id
  #   @return [String] The provided client ID, used for identifying this client for presence purposes
  # @!attribute [r] current_token_details
  #   @return [Ably::Models::TokenDetails] Current {Ably::Models::TokenDetails} issued by this library or one of the provided callbacks used to authenticate requests
  # @!attribute [r] key
  #   @return [String] Complete API key containing both the key name and key secret, if present
  # @!attribute [r] key_name
  #   @return [String] Key name (public part of the API key), if present
  # @!attribute [r] key_secret
  #   @return [String] Key secret (private secure part of the API key), if present
  # @!attribute [r] options
  #   @return [Hash] Default {Ably::Auth} options configured for this client
  # @!attribute [r] token_params
  #   @return [Hash] Default token params used for token requests, see {#request_token}
  #
  class Auth
    include Ably::Modules::Conversions
    include Ably::Modules::HttpHelpers

    # Default capability Hash object and TTL in seconds for issued tokens
    TOKEN_DEFAULTS = {
      renew_token_buffer: 10 # buffer to allow a token to be reissued before the token is considered expired (Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER)
    }.freeze

    API_KEY_REGEX = /^[\w-]{2,}\.[\w-]{2,}:[\w-]{2,}$/

    # Supported AuthOption keys, see https://www.ably.io/documentation/realtime/types#auth-options
    # TODO: Review client_id usage embedded incorrectly within AuthOptions.
    #       This is legacy code to configure a client with a client_id from the ClientOptions
    # TODO: Review inclusion of use_token_auth, ttl, token_params in auth options
    AUTH_OPTIONS_KEYS = %w(
      auth_callback
      auth_url
      auth_method
      auth_headers
      auth_params
      client_id
      key
      key_name
      key_secret
      query_time
      token
      token_details
      token_params
      ttl
      use_token_auth
    )

    attr_reader :options, :token_params, :current_token_details
    alias_method :auth_options, :options

    # Creates an Auth object
    #
    # @param [Ably::Rest::Client] client  {Ably::Rest::Client} this Auth object uses
    # @param [Hash] token_params the token params used as a default for future token requests
    # @param [Hash] auth_options the authentication options used as a default future token requests
    # @option (see #request_token)
    #
    def initialize(client, token_params, auth_options)
      unless auth_options.kind_of?(Hash)
        raise ArgumentError, 'Expected auth_options to be a Hash'
      end

      unless token_params.kind_of?(Hash)
        raise ArgumentError, 'Expected token_params to be a Hash'
      end

      # Ensure instance variables are defined
      @client_id = nil
      @client_id_validated = nil

      ensure_valid_auth_attributes auth_options

      @client              = client
      @options             = auth_options.dup
      @token_params        = token_params.dup
      @token_option        = options[:token] || options[:token_details]

      if options[:key] && (options[:key_secret] || options[:key_name])
        raise ArgumentError, 'key and key_name or key_secret are mutually exclusive. Provider either a key or key_name & key_secret'
      end

      split_api_key_into_key_and_secret! options if options[:key]
      store_and_delete_basic_auth_key_from_options! options

      if using_basic_auth? && !api_key_present?
        raise ArgumentError, 'key is missing. Either an API key, token, or token auth method must be provided'
      end

      if options[:client_id] == '*'
        raise ArgumentError, 'A client cannot be configured with a wildcard client_id, only a token can have a wildcard client_id privilege'
      end

      if has_client_id? && !token_creatable_externally? && !token_option
        raise ArgumentError, 'client_id cannot be provided without a complete API key or means to authenticate. An API key is needed to automatically authenticate with Ably and obtain a token' unless api_key_present?
        @client_id = ensure_utf_8(:client_id, client_id) if client_id
      end

      # If a token details object or token string is provided in the initializer
      # then the client can be authorized immediately using this token
      if token_option
        token_details = convert_to_token_details(token_option)
        if token_details
          begin
            token_details = authorize_with_token(token_details)
            logger.debug { "Auth: new token passed in to the initializer: #{token_details}" }
          rescue StandardError => e
            logger.error { "Auth: Implicit authorization using the provided token failed: #{e}" }
          end
        end
      end

      @options.freeze
      @token_params.freeze
    end

    # Ensures valid auth credentials are present for the library instance. This may rely on an already-known and valid token, and will obtain a new token if necessary.
    #
    # In the event that a new token request is made, the provided options are used.
    #
    # @param [Hash, nil] token_params the token params used for future token requests. When nil, previously configured token params are used
    # @param [Hash, nil] auth_options the authentication options used for future token requests. When nil, previously configure authentication options are used
    # @option (see #request_token)
    #
    # @return (see #create_token_request)
    #
    # @example
    #    # will issue a simple token request using basic auth
    #    client = Ably::Rest::Client.new(key: 'key.id:secret')
    #    token_details = client.auth.authorize
    #
    #    # will use token request from block to authorize if not already authorized
    #    token_details = client.auth.authorize {}, auth_callback: lambda do |token_parmas|
    #      # create token_request object
    #      token_request
    #    end
    #
    def authorize(token_params = nil, auth_options = nil)
      if auth_options.nil?
        auth_options = options # Use default options

        if options.has_key?(:query_time)
          @options = options.dup
          # Query the server time only happens once
          # the options remain in auth_options though so they are passed to request_token
          @options.delete(:query_time)
          @options.freeze
        end
      else
        ensure_valid_auth_attributes auth_options

        auth_options = auth_options.dup

        if auth_options[:token_params]
          token_params = auth_options.delete(:token_params).merge(token_params || {})
        end

        # If basic credentials are provided then overwrite existing options
        # otherwise we need to retain the existing credentials in the auth options
        split_api_key_into_key_and_secret! auth_options if auth_options[:key]
        if auth_options[:key_name] && auth_options[:key_secret]
          store_and_delete_basic_auth_key_from_options! auth_options
        end

        @options = auth_options.dup

        # Query the server time only happens once
        # the options remain in auth_options though so they are passed to request_token
        @options.delete(:query_time)

        @options.freeze
      end

      # Unless provided, defaults are used
      unless token_params.nil?
        @token_params = token_params.dup
        # Timestamp is only valid for this request
        @token_params.delete(:timestamp)
        @token_params.freeze
      end

      authorize_with_token(request_token(token_params || @token_params, auth_options)).tap do |new_token_details|
        logger.debug { "Auth: new token following authorisation: #{new_token_details}" }

        # If authorize the realtime library required auth, then yield the token in a block
        if block_given?
          yield new_token_details
        end
      end
    end

    # @deprecated Use {#authorize} instead
    def authorise(*args, &block)
      logger.warn { "Auth#authorise is deprecated and will be removed in 1.0. Please use Auth#authorize instead" }
      authorize(*args, &block)
    end

    # Request a {Ably::Models::TokenDetails} which can be used to make authenticated token based requests
    #
    # @param [Hash] auth_options (see #create_token_request)
    # @option auth_options [String]  :auth_url      a URL to be used to GET or POST a set of token request params, to obtain a signed token request
    # @option auth_options [Hash]    :auth_headers  a set of application-specific headers to be added to any request made to the +auth_url+
    # @option auth_options [Hash]    :auth_params   a set of application-specific query params to be added to any request made to the +auth_url+
    # @option auth_options [Symbol]  :auth_method   (:get) HTTP method to use with +auth_url+, must be either +:get+ or +:post+
    # @option auth_options [Proc]    :auth_callback when provided, the Proc will be called with the token params hash as the first argument, whenever a new token is required.
    #                                               The Proc should return a token string, {Ably::Models::TokenDetails} or JSON equivalent, {Ably::Models::TokenRequest} or JSON equivalent
    # @param [Hash] token_params (see #create_token_request)
    # @option (see #create_token_request)
    #
    # @return [Ably::Models::TokenDetails]
    #
    # @example
    #    # simple token request using basic auth
    #    client = Ably::Rest::Client.new(key: 'key.id:secret')
    #    token_details = client.auth.request_token
    #
    #    # token request with token params
    #    client.auth.request_token ttl: 1.hour
    #
    #    # token request using auth block
    #    token_details = client.auth.request_token {}, auth_callback: lambda do |token_params|
    #      # create token_request object
    #      token_request
    #    end
    #
    def request_token(token_params = {}, auth_options = {})
      ensure_valid_auth_attributes auth_options

      # Token param precedence (lowest to highest):
      #   Auth default => client_id => auth_options[:token_params] arg => token_params arg
      token_params = self.token_params.merge(
        (client_id ? { client_id: client_id } : {}).
          merge(auth_options[:token_params] || {}).
          merge(token_params)
      )

      auth_options = self.options.merge(auth_options)

      token_request = if auth_callback = auth_options.delete(:auth_callback)
        begin
          Timeout::timeout(client.auth_request_timeout) do
            auth_callback.call(token_params)
          end
        rescue StandardError => err
          raise Ably::Exceptions::AuthenticationFailed.new("auth_callback failed: #{err.message}", nil, nil, err, fallback_status: 500, fallback_code: Ably::Exceptions::Codes::CONNECTION_NOT_ESTABLISHED_NO_TRANSPORT_HANDLE)
        end
      elsif auth_url = auth_options.delete(:auth_url)
        begin
          Timeout::timeout(client.auth_request_timeout) do
            token_request_from_auth_url(auth_url, auth_options, token_params)
          end
        rescue StandardError => err
          raise Ably::Exceptions::AuthenticationFailed.new("auth_url failed: #{err.message}", nil, nil, err, fallback_status: 500, fallback_code: Ably::Exceptions::Codes::CONNECTION_NOT_ESTABLISHED_NO_TRANSPORT_HANDLE)
        end
      else
        create_token_request(token_params, auth_options)
      end

      convert_to_token_details(token_request).tap do |token_details|
        return token_details if token_details
      end

      send_token_request(token_request)
    end

    # Creates and signs a token request that can then subsequently be used by any client to request a token
    #
    # @param [Hash] token_params the token params used in the token request
    # @option token_params [String]  :client_id     A client ID to associate with this token. The generated token may be used to authenticate as this +client_id+
    # @option token_params [Integer] :ttl           validity time in seconds for the requested {Ably::Models::TokenDetails}.  Limits may apply, see {https://www.ably.io/documentation/other/authentication}
    # @option token_params [Hash]    :capability    canonicalised representation of the resource paths and associated operations
    # @option token_params [Time]    :timestamp     the time of the request
    # @option token_params [String]  :nonce         an unquoted, unescaped random string of at least 16 characters
    #
    # @param [Hash] auth_options the authentication options for the token request
    # @option auth_options [String]  :key           API key comprising the key name and key secret in a single string
    # @option auth_options [String]  :client_id     client ID identifying this connection to other clients (will use +client_id+ specified when library was instanced if provided)
    # @option auth_options [Boolean] :query_time    when true will query the {https://www.ably.io Ably} system for the current time instead of using the local time
    # @option auth_options [Hash]    :token_params  convenience to pass in +token_params+ within the +auth_options+ argument, especially useful when setting default token_params in the client constructor
    #
    # @return [Models::TokenRequest]
    #
    # @example
    #    client.auth.create_token_request({ ttl: 3600 }, { id: 'asd.asd' })
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
    def create_token_request(token_params = {}, auth_options = {})
      ensure_valid_auth_attributes auth_options

      auth_options = auth_options.dup
      token_params = (auth_options[:token_params] || {}).merge(token_params)

      split_api_key_into_key_and_secret! auth_options if auth_options[:key]
      request_key_name   = auth_options.delete(:key_name) || key_name
      request_key_secret = auth_options.delete(:key_secret) || key_secret

      raise Ably::Exceptions::TokenRequestFailed, 'Key Name and Key Secret are required to generate a new token request' unless request_key_name && request_key_secret

      ensure_current_time_is_based_on_server_time if auth_options[:query_time]
      timestamp = token_params.delete(:timestamp) || current_time
      timestamp = Time.at(timestamp) if timestamp.kind_of?(Integer)



      token_request = {
        keyName:    request_key_name,
        timestamp:  (timestamp.to_f * 1000).round,
        nonce:      token_params[:nonce] || SecureRandom.hex.force_encoding('UTF-8')
      }

      token_client_id = token_params[:client_id] || auth_options[:client_id] || client_id
      token_request[:clientId] = token_client_id if token_client_id

      if token_params[:ttl]
        token_ttl = [
          token_params[:ttl],
          Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER + TOKEN_DEFAULTS.fetch(:renew_token_buffer) # never issue a token that will be immediately considered expired due to the buffer
        ].max
        token_request[:ttl] = (token_ttl * 1000).to_i
      end

      token_request[:capability] = token_params[:capability] if token_params[:capability]
      if token_request[:capability].is_a?(Hash)
        lexicographic_ordered_capabilities = Hash[
          token_request[:capability].sort_by { |key, value| key }.map do |key, value|
            [key, value.sort]
          end
        ]
        token_request[:capability] = JSON.dump(lexicographic_ordered_capabilities)
      end

      token_request[:mac] = sign_params(token_request, request_key_secret)

      # Undocumented feature to request a persisted token
      token_request[:persisted] = token_params[:persisted] if token_params[:persisted]

      Models::TokenRequest.new(token_request)
    end

    def key
      "#{key_name}:#{key_secret}" if api_key_present?
    end

    def key_name
      @key_name
    end

    def key_secret
      @key_secret
    end

    # True when Basic Auth is being used to authenticate with Ably
    def using_basic_auth?
      !using_token_auth?
    end

    # True when Token Auth is being used to authenticate with Ably
    def using_token_auth?
      return options[:use_token_auth] if options.has_key?(:use_token_auth)
      !!(token_option || current_token_details || has_client_id? || token_creatable_externally?)
    end

    def client_id
      @client_id || options[:client_id]
    end

    # When a client has authenticated with Ably and the client is either anonymous (cannot assume a +client_id+)
    # or has an assigned +client_id+ (implicit in all operations), then this client has a validated +client_id+, even
    # if that client_id is +nil+ (anonymous)
    #
    # Once validated by Ably, the client library will enforce the use of the +client_id+ identity provided by Ably, rejecting
    # messages with an invalid +client_id+ immediately
    #
    # @return [Boolean]
    def client_id_validated?
      !!@client_id_validated
    end

    # Auth header string used in HTTP requests to Ably
    # Will reauthorize implicitly if required and capable
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
    # Will reauthorize implicitly if required and capable
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
      token_creatable_externally? || (api_key_present? && !token_option)
    end

    # Returns false when attempting to send an API Key over a non-secure connection
    # Token auth must be used for non-secure connections
    #
    # @return [Boolean]
    def authentication_security_requirements_met?
      client.use_tls? || using_token_auth?
    end

    # True if token provided client_id is compatible with the client's configured +client_id+, when applicable
    #
    # @return [Boolean]
    # @api private
    def token_client_id_allowed?(token_client_id)
      return true if client_id.nil? # no explicit client_id specified for this client
      return true if client_id == '*' || token_client_id == '*' # wildcard supported always
      token_client_id == client_id
    end

    # True if assumed_client_id is compatible with the client's configured or Ably assigned +client_id+
    #
    # @return [Boolean]
    # @api private
    def can_assume_client_id?(assumed_client_id)
      if client_id_validated?
        client_id == '*' || (client_id == assumed_client_id)
      elsif !options[:client_id] || options[:client_id] == '*'
        true # client ID is unknown
      else
        options[:client_id] == assumed_client_id
      end
    end

    # Configures the client ID for this client
    # Typically this occurs following an Auth or receiving a {Ably::Models::ProtocolMessage} with a +client_id+ in the {Ably::Models::ConnectionDetails}
    #
    # @api private
    def configure_client_id(new_client_id)
      # If new client ID from Ably is a wildcard, but preconfigured clientId is set, then keep the existing clientId
      if has_client_id? && new_client_id == '*'
        @client_id_validated = true
        return
      end

      # If client_id is defined and not a wildcard, prevent it changing, this is not supported
      if client_id && client_id != '*' &&  new_client_id != client_id
        raise Ably::Exceptions::IncompatibleClientId.new("Client ID is immutable once configured for a client. Client ID cannot be changed to '#{new_client_id}'")
      end
      @client_id_validated = true
      @client_id = new_client_id
    end

    # True when a client_id other than a wildcard is configured for Auth
    #
    # @api private
    def has_client_id?
      client_id && (client_id != '*')
    end

    private
    def client
      @client
    end

    def token_option
      @token_option
    end

    def authorize_when_necessary
      if current_token_details && !current_token_details.expired?
        return current_token_details
      else
        authorize
      end
    end

    # Returns the current device clock time unless the
    # the server time has previously been requested with query_time: true
    # and the @server_time_offset is configured
    def current_time
      if @server_time_offset
        Time.now + @server_time_offset
      else
        Time.now
      end
    end

    # Get the difference in time between the server
    # and the local clock and store this for future time requests
    def ensure_current_time_is_based_on_server_time
      server_time = client.time
      @server_time_offset = server_time.to_f - Time.now.to_f
    end

    def ensure_valid_auth_attributes(attributes)
      (attributes.keys.map(&:to_s) - AUTH_OPTIONS_KEYS).tap do |unsupported_keys|
        raise ArgumentError, "The key(s) #{unsupported_keys.map { |k| ":#{k}" }.join(', ')} are not valid AuthOptions" unless unsupported_keys.empty?
      end

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

      if attributes[:auth_callback]
        unless attributes[:auth_callback].respond_to?(:call)
          raise ArgumentError, ':auth_callback must be a Proc'
        end
      end
    end

    def ensure_api_key_sent_over_secure_connection
      raise Ably::Exceptions::InsecureRequest, 'Cannot use Basic Auth over non-TLS connections' unless authentication_security_requirements_met?
    end

    # Basic Auth HTTP Authorization header value
    def basic_auth_header
      ensure_api_key_sent_over_secure_connection
      "Basic #{encode64("#{key}")}"
    end

    def split_api_key_into_key_and_secret!(options)
      api_key_parts = options[:key].to_s.match(/(?<name>[\w-]+\.[\w-]+):(?<secret>[\w-]+)/)
      raise ArgumentError, 'key is invalid' unless api_key_parts

      options[:key_name]   = api_key_parts[:name].encode(Encoding::UTF_8)
      options[:key_secret] = api_key_parts[:secret].encode(Encoding::UTF_8)

      options.delete :key
    end

    def store_and_delete_basic_auth_key_from_options!(options)
      @key_name = options.delete(:key_name)
      @key_secret = options.delete(:key_secret)
    end

    # Returns the current token if it exists or authorizes and retrieves a token
    def token_auth_string
      if !current_token_details && token_option
        logger.debug { "Auth: Token auth string missing, authorizing implicitly now" }
        # A TokenRequest was configured in the ClientOptions +:token field+ and no current token exists
        # Note: If a Token or TokenDetails is provided in the initializer, the token is stored in +current_token_details+
        authorize_with_token send_token_request(token_option)
        current_token_details.token
      else
        # Authorize will use the current token if one exists and is not expired, otherwise a new token will be issued
        authorize_when_necessary.token
      end
    end

    def configure_current_token_details(token_details)
      @current_token_details = token_details
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

    # Retrieve a token request from a specified URL, expects a JSON or text response
    #
    # @return [Hash]
    def token_request_from_auth_url(auth_url, auth_options, token_params)
      uri = URI.parse(auth_url)
      connection = Faraday.new("#{uri.scheme}://#{uri.host}", connection_options)
      method = auth_options[:auth_method] || options[:auth_method] || :get
      params = (auth_options[:auth_params] || options[:auth_params] || {}).merge(token_params)

      response = connection.public_send(method) do |request|
        request.url uri.path
        request.headers = auth_options[:auth_headers] || {}
        if method.to_s.downcase == 'post'
          request.body = params
        else
          request.params = (Addressable::URI.parse(uri.to_s).query_values || {}).merge(params)
        end
      end

      if !response.body.kind_of?(Hash) && !response.headers['Content-Type'].to_s.match(%r{text/plain|application/jwt}i)
        raise Ably::Exceptions::InvalidResponseBody,
              "Content Type #{response.headers['Content-Type']} is not supported by this client library"
      end

      response.body
    end

    # Use the provided token to authenticate immediately and store the token details in +current_token_details+
    def authorize_with_token(new_token_details)
      if new_token_details && !new_token_details.from_token_string?
        if !token_client_id_allowed?(new_token_details.client_id)
          raise Ably::Exceptions::IncompatibleClientId.new("Client ID '#{new_token_details.client_id}' in the token is incompatible with the current client ID '#{client_id}'")
        end
        configure_client_id new_token_details.client_id
      end
      configure_current_token_details new_token_details
    end

    # Returns a TokenDetails object if the provided token_details_obj argument is a TokenDetails object, Token String
    # or TokenDetails JSON object.
    # If the token_details_obj is not a Token or TokenDetails +nil+ is returned
    def convert_to_token_details(token_details_obj)
      case token_details_obj
        when Ably::Models::TokenDetails
          return token_details_obj
        when Hash
          return Ably::Models::TokenDetails.new(token_details_obj) if IdiomaticRubyWrapper(token_details_obj).has_key?(:issued)
        when String
          return Ably::Models::TokenDetails.new(token: token_details_obj)
      end
    end

    # @return [Ably::Models::TokenDetails]
    def send_token_request(token_request)
      token_request = Ably::Models::TokenRequest(token_request)

      response = client.post("/keys/#{token_request.key_name}/requestToken",
                             token_request.attributes, send_auth_header: false,
                             disable_automatic_reauthorize: true)

      Ably::Models::TokenDetails.new(response.body)
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

        setup_incoming_middleware builder, logger

        # Set Faraday's HTTP adapter
        builder.adapter Faraday.default_adapter
      end
    end

    def auth_callback_present?
      !!options[:auth_callback]
    end

    def token_url_present?
      !!options[:auth_url]
    end

    def token_creatable_externally?
      auth_callback_present? || token_url_present?
    end

    def api_key_present?
      key_name && key_secret
    end

    def logger
      client.logger
    end
  end
end
