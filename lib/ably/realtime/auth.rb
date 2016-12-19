require 'ably/auth'

module Ably
  module Realtime
    # Auth is responsible for authentication with {https://www.ably.io Ably} using basic or token authentication
    # This {Ably::Realtime::Auth Realtime::Auth} class wraps the {Ably::Auth Synchronous Ably::Auth} class in an EventMachine friendly way using Deferrables for all IO.  See {Ably::Auth Ably::Auth} for more information
    #
    # Find out more about Ably authentication at: https://www.ably.io/documentation/general/authentication/
    #
    # @!attribute [r] client_id
    #   (see Ably::Auth#client_id)
    # @!attribute [r] current_token_details
    #   (see Ably::Auth#current_token_details)
    # @!attribute [r] token
    #   (see Ably::Auth#token)
    # @!attribute [r] key
    #   (see Ably::Auth#key)
    # @!attribute [r] key_name
    #   (see Ably::Auth#key_name)
    # @!attribute [r] key_secret
    #   (see Ably::Auth#key_secret)
    # @!attribute [r] options
    #   (see Ably::Auth#options)
    # @!attribute [r] token_params
    #   (see Ably::Auth#options)
    # @!attribute [r] using_basic_auth?
    #   (see Ably::Auth#using_basic_auth?)
    # @!attribute [r] using_token_auth?
    #   (see Ably::Auth#using_token_auth?)
    # @!attribute [r] token_renewable?
    #   (see Ably::Auth#token_renewable?)
    # @!attribute [r] authentication_security_requirements_met?
    #   (see Ably::Auth#authentication_security_requirements_met?)
    #
    class Auth
      extend Forwardable
      include Ably::Modules::AsyncWrapper

      def_delegators :auth_sync, :client_id
      def_delegators :auth_sync, :token_client_id_allowed?, :configure_client_id, :client_id_validated?
      def_delegators :auth_sync, :can_assume_client_id?, :has_client_id?
      def_delegators :auth_sync, :current_token_details, :token
      def_delegators :auth_sync, :key, :key_name, :key_secret, :options, :auth_options, :token_params
      def_delegators :auth_sync, :using_basic_auth?, :using_token_auth?
      def_delegators :auth_sync, :token_renewable?, :authentication_security_requirements_met?
      def_delegators :client, :logger

      def initialize(client)
        @client = client
        @auth_sync = client.rest_client.auth
      end

      # Ensures valid auth credentials are present for the library instance. This may rely on an already-known and valid token, and will obtain a new token if necessary.
      #
      # In the event that a new token request is made, the provided options are used
      #
      # @param (see Ably::Auth#authorize)
      # @option (see Ably::Auth#authorize)
      #
      # @return [Ably::Util::SafeDeferrable]
      # @yield [Ably::Models::TokenDetails]
      #
      # @example
      #    # will issue a simple token request using basic auth
      #    client = Ably::Rest::Client.new(key: 'key.id:secret')
      #    client.auth.authorize do |token_details|
      #      token_details #=> Ably::Models::TokenDetails
      #    end
      #
      def authorize(token_params = nil, auth_options = nil, &success_callback)
        async_wrap(success_callback) do
          auth_sync.authorize(token_params, auth_options, &method(:upgrade_authentication_block).to_proc)
        end.tap do |deferrable|
          deferrable.errback do |error|
            client.connection.transition_state_machine :failed, reason: error if error.kind_of?(Ably::Exceptions::IncompatibleClientId)
          end
        end
      end

      # @deprecated Use {#authorize} instead
      def authorise(*args, &block)
        logger.warn "Auth#authorise is deprecated and will be removed in 1.0. Please use Auth#authorize instead"
        authorize(*args, &block)
      end

      # Synchronous version of {#authorize}. See {Ably::Auth#authorize} for method definition
      # @param (see Ably::Auth#authorize)
      # @option (see Ably::Auth#authorize)
      # @return [Ably::Models::TokenDetails]
      #
      def authorize_sync(token_params = nil, auth_options = nil)
        auth_sync.authorize(token_params, auth_options, &method(:upgrade_authentication_block).to_proc)
      end

      # @deprecated Use {#authorize_sync} instead
      def authorise_sync(*args)
        logger.warn "Auth#authorise_sync is deprecated and will be removed in 1.0. Please use Auth#authorize_sync instead"
        authorize_sync(*args)
      end

      # Request a {Ably::Models::TokenDetails} which can be used to make authenticated token based requests
      #
      # @param (see Ably::Auth#request_token)
      # @option (see Ably::Auth#request_token)
      #
      # @return [Ably::Util::SafeDeferrable]
      # @yield [Ably::Models::TokenDetails]
      #
      # @example
      #    # simple token request using basic auth
      #    client = Ably::Rest::Client.new(key: 'key.id:secret')
      #    client.auth.request_token do |token_details|
      #      token_details #=> Ably::Models::TokenDetails
      #    end
      #
      def request_token(token_params = {}, auth_options = {}, &success_callback)
        async_wrap(success_callback) do
          request_token_sync(token_params, auth_options)
        end
      end

      # Synchronous version of {#request_token}. See {Ably::Auth#request_token} for method definition
      # @param (see Ably::Auth#authorize)
      # @option (see Ably::Auth#authorize)
      # @return [Ably::Models::TokenDetails]
      #
      def request_token_sync(token_params = {}, auth_options = {})
        auth_sync.request_token(token_params, auth_options)
      end

      # Creates and signs a token request that can then subsequently be used by any client to request a token
      #
      # @param (see Ably::Auth#create_token_request)
      # @option (see Ably::Auth#create_token_request)
      #
      # @return [Ably::Util::SafeDeferrable]
      # @yield [Models::TokenRequest]
      #
      # @example
      #   client.auth.create_token_request({ ttl: 3600 }, id: 'asd.asd') do |token_request|
      #     token_request #=> Ably::Models::TokenRequest
      #   end
      def create_token_request(token_params = {}, auth_options = {}, &success_callback)
        async_wrap(success_callback) do
          create_token_request_sync(token_params, auth_options)
        end
      end

      # Synchronous version of {#create_token_request}. See {Ably::Auth#create_token_request} for method definition
      # @param (see Ably::Auth#authorize)
      # @option (see Ably::Auth#authorize)
      # @return [Ably::Models::TokenRequest]
      #
      def create_token_request_sync(token_params = {}, auth_options = {})
        auth_sync.create_token_request(token_params, auth_options)
      end

      # Auth header string used in HTTP requests to Ably
      # Will reauthorize implicitly if required and capable
      #
      # @return [Ably::Util::SafeDeferrable]
      # @yield [String] HTTP authentication value used in HTTP_AUTHORIZATION header
      #
      def auth_header(&success_callback)
        async_wrap(success_callback) do
          auth_header_sync
        end
      end

      # Synchronous version of {#auth_header}. See {Ably::Auth#auth_header} for method definition
      # @return [String] HTTP authentication value used in HTTP_AUTHORIZATION header
      #
      def auth_header_sync
        auth_sync.auth_header
      end

      # Auth params used in URI endpoint for Realtime connections
      # Will reauthorize implicitly if required and capable
      #
      # @return [Ably::Util::SafeDeferrable]
      # @yield [Hash] Auth params for a new Realtime connection
      #
      def auth_params(&success_callback)
        fail_callback = Proc.new do |error, deferrable|
          logger.error "Failed to authenticate: #{error}"
          if error.kind_of?(Ably::Exceptions::BaseAblyException)
            # Use base exception if it exists carrying forward the status codes
            deferrable.fail Ably::Exceptions::AuthenticationFailed.new(error.message, nil, nil, error)
          else
            deferrable.fail Ably::Exceptions::AuthenticationFailed.new(error.message, 500, 80019)
          end
        end
        async_wrap(success_callback, fail_callback) do
          auth_params_sync
        end
      end

      # Synchronous version of {#auth_params}. See {Ably::Auth#auth_params} for method definition
      # @return [Hash] Auth params for a new Realtime connection
      #
      def auth_params_sync
        auth_sync.auth_params
      end

      private
      # The synchronous Auth class instanced by the Rest client
      # @return [Ably::Auth]
      def auth_sync
        @auth_sync
      end

      def client
        @client
      end

      # If authorize is called with true, this block is executed so that it
      # can perform the authentication upgrade
      def upgrade_authentication_block(new_token)
        # This block is called if the authorisation was forced
        if client.connection.connected? || client.connection.connecting?
          logger.debug "Realtime::Auth - authorize was called so forcibly disconnecting transport to initiate auth upgrade"
          block = Proc.new do
            if client.connection.transport
              logger.debug "Realtime::Auth - current transport disconnected"
              client.connection.transport.disconnect
            else
              EventMachine.add_timer(0.1, &block)
            end
          end
          block.call
        end
      end
    end
  end
end
