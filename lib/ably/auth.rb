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
  # @!attribute [r] token
  #   @return [String] Token string provided to the {Ably::Client} constructor that is used to authenticate all requests
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
      capability:         { '*' => ['*'] },
      ttl:                60 * 60, # 1 hour in seconds
      renew_token_buffer: 10 # buffer to allow a token to be reissued before the token is considered expired (Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER)
    }.freeze

    attr_reader :options, :token_params, :current_token_details
    alias_method :auth_options, :options

    # Creates an Auth object
    #
    # @param [Ably::Rest::Client] client  {Ably::Rest::Client} this Auth object uses
    # @param [Hash] auth_options the authentication options used as a default future token requests
    # @param [Hash] token_params the token params used as a default for future token requests
    # @option (see #request_token)
    #
    def initialize(client, auth_options, token_params)
      unless auth_options.kind_of?(Hash)
        raise ArgumentError, 'Expected auth_options to be a Hash'
      end

      unless token_params.kind_of?(Hash)
        raise ArgumentError, 'Expected token_params to be a Hash'
      end

      ensure_valid_auth_attributes auth_options

      @client              = client
      @options             = auth_options.dup
      @token_params        = token_params.dup

      @options.delete :force # Forcing token auth for every request is not a valid default

      if options[:key] && (options[:key_secret] || options[:key_name])
        raise ArgumentError, 'key and key_name or key_secret are mutually exclusive. Provider either a key or key_name & key_secret'
      end

      split_api_key_into_key_and_secret! options if options[:key]

      if using_basic_auth? && !api_key_present?
        raise ArgumentError, 'key is missing. Either an API key, token, or token auth method must be provided'
      end

      if has_client_id? && !token_creatable_externally?
        raise ArgumentError, 'client_id cannot be provided without a complete API key. Key name & Secret is needed to authenticate with Ably and obtain a token' unless api_key_present?
        ensure_utf_8 :client_id, client_id
      end

      @options.freeze
      @token_params.freeze
    end

    # Ensures valid auth credentials are present for the library instance. This may rely on an already-known and valid token, and will obtain a new token if necessary.
    #
    # In the event that a new token request is made, the provided options are used.
    #
    # @param [Hash] auth_options the authentication options used for future token requests
    # @param [Hash] token_params the token params used for future token requests
    # @option auth_options [Boolean]   :force   obtains a new token even if the current token is valid
    # @option (see #request_token)
    #
    # @return (see #create_token_request)
    #
    # @example
    #    # will issue a simple token request using basic auth
    #    client = Ably::Rest::Client.new(key: 'key.id:secret')
    #    token_details = client.auth.authorise
    #
    #    # will use token request from block to authorise if not already authorised
    #    token_details = client.auth.authorise auth_callback: Proc.new do
    #      # create token_request object
    #      token_request
    #    end
    #
    def authorise(auth_options = {}, token_params = {})
      ensure_valid_auth_attributes auth_options

      auth_options = auth_options.clone

      if current_token_details && !auth_options.delete(:force)
        return current_token_details unless current_token_details.expired?
      end

      split_api_key_into_key_and_secret! auth_options if auth_options[:key]
      @options = @options.merge(auth_options) # update defaults

      token_params = (auth_options.delete(:token_params) || {}).merge(token_params)
      @token_params = @token_params.merge(token_params) # update defaults

      @current_token_details = request_token(auth_options, token_params)
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
    #    client.auth.request_token token_params: { ttl: 1.hour }
    #
    #    # token request using auth block
    #    token_details = client.auth.request_token auth_callback: Proc.new do
    #      # create token_request object
    #      token_request
    #    end
    #
    def request_token(auth_options = {}, token_params = {})
      ensure_valid_auth_attributes auth_options

      token_params = (auth_options[:token_params] || {}).merge(token_params)
      token_params = self.token_params.merge(token_params)
      auth_options = self.options.merge(auth_options)

      token_request = if auth_callback = auth_options.delete(:auth_callback)
        auth_callback.call(token_params)
      elsif auth_url = auth_options.delete(:auth_url)
        token_request_from_auth_url(auth_url, auth_options)
      else
        create_token_request(auth_options, token_params)
      end

      case token_request
        when Ably::Models::TokenDetails
          return token_request
        when Hash
          return Ably::Models::TokenDetails.new(token_request) if IdiomaticRubyWrapper(token_request).has_key?(:issued)
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
    # @param [Hash] auth_options the authentication options for the token request
    # @option auth_options [String]  :key           API key comprising the key name and key secret in a single string
    # @option auth_options [String]  :client_id     client ID identifying this connection to other clients (will use +client_id+ specified when library was instanced if provided)
    # @option auth_options [Boolean] :query_time    when true will query the {https://www.ably.io Ably} system for the current time instead of using the local time
    # @option auth_options [Hash]    :token_params   convenience to pass in +token_params+ within the +auth_options+ argument, this helps avoid the following +authorise({key: key}, {ttl: 23})+ by allowing +authorise(key:key,token_params:{ttl:23})+
    #
    # @param [Hash] token_params the token params used in the token request
    # @option token_params [String]  :client_id     A client ID to associate with this token. The generated token may be used to authenticate as this +client_id+
    # @option token_params [Integer] :ttl           validity time in seconds for the requested {Ably::Models::TokenDetails}.  Limits may apply, see {https://www.ably.io/documentation/other/authentication}
    # @option token_params [Hash]    :capability    canonicalised representation of the resource paths and associated operations
    # @option token_params [Time]    :timestamp     the time of the request
    # @option token_params [String]  :nonce         an unquoted, unescaped random string of at least 16 characters
    #
    # @return [Models::TokenRequest]
    #
    # @example
    #    client.auth.create_token_request(id: 'asd.asd', token_params: { ttl: 3600 })
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
    def create_token_request(auth_options = {}, token_params = {})
      ensure_valid_auth_attributes auth_options

      auth_options = auth_options.clone
      token_params = (auth_options[:token_params] || {}).merge(token_params)

      split_api_key_into_key_and_secret! auth_options if auth_options[:key]
      request_key_name   = auth_options.delete(:key_name) || key_name
      request_key_secret = auth_options.delete(:key_secret) || key_secret

      raise Ably::Exceptions::TokenRequestFailed, 'Key Name and Key Secret are required to generate a new token request' unless request_key_name && request_key_secret

      timestamp = if auth_options[:query_time]
        client.time
      else
        token_params.delete(:timestamp) || Time.now
      end
      timestamp = Time.at(timestamp) if timestamp.kind_of?(Integer)

      ttl = [
        (token_params[:ttl] || TOKEN_DEFAULTS.fetch(:ttl)),
        Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER + TOKEN_DEFAULTS.fetch(:renew_token_buffer) # never issue a token that will be immediately considered expired due to the buffer
      ].max

      token_request = {
        keyName:    request_key_name,
        clientId:   token_params[:client_id] || auth_options[:client_id] || client_id,
        ttl:        (ttl * 1000).to_i,
        timestamp:  (timestamp.to_f * 1000).round,
        capability: token_params[:capability] || TOKEN_DEFAULTS.fetch(:capability),
        nonce:      token_params[:nonce] || SecureRandom.hex.force_encoding('UTF-8')
      }

      token_request[:capability] = JSON.dump(token_request[:capability]) if token_request[:capability].is_a?(Hash)

      token_request[:mac] = sign_params(token_request, request_key_secret)

      # Undocumented feature to request a persisted token
      token_request[:persisted] = token_params[:persisted] if token_params[:persisted]

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
      !!(token || current_token_details || has_client_id? || token_creatable_externally?)
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
    # Will reauthorise implicitly if required and capable
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
    # Will reauthorise implicitly if required and capable
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
    attr_reader :client

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
    def token_request_from_auth_url(auth_url, auth_options)
      uri = URI.parse(auth_url)
      connection = Faraday.new("#{uri.scheme}://#{uri.host}", connection_options)
      method = auth_options[:auth_method] || :get

      response = connection.send(method) do |request|
        request.url uri.path
        request.params = CGI.parse(uri.query || '').merge(auth_options[:auth_params] || {})
        request.headers = auth_options[:auth_headers] || {}
      end

      if !response.body.kind_of?(Hash) && !response.headers['Content-Type'].to_s.match(%r{text/plain}i)
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

    def auth_callback_present?
      !!options[:auth_callback]
    end

    def token_url_present?
      !!options[:auth_url]
    end

    def token_creatable_externally?
      auth_callback_present? || token_url_present?
    end

    def has_client_id?
      !!client_id
    end

    def api_key_present?
      key_name && key_secret
    end
  end
end
