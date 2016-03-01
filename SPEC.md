# Ably Realtime & REST Client Library 0.8.9 Specification

### Ably::Realtime::Auth
_(see [spec/acceptance/realtime/auth_spec.rb](./spec/acceptance/realtime/auth_spec.rb))_
  * using JSON protocol
    * with basic auth
      * #authentication_security_requirements_met?
        * [returns true](./spec/acceptance/realtime/auth_spec.rb#L20)
      * #key
        * [contains the API key](./spec/acceptance/realtime/auth_spec.rb#L27)
      * #key_name
        * [contains the API key name](./spec/acceptance/realtime/auth_spec.rb#L34)
      * #key_secret
        * [contains the API key secret](./spec/acceptance/realtime/auth_spec.rb#L41)
      * #using_basic_auth?
        * [is true when using Basic Auth](./spec/acceptance/realtime/auth_spec.rb#L48)
      * #using_token_auth?
        * [is false when using Basic Auth](./spec/acceptance/realtime/auth_spec.rb#L55)
    * with token auth
      * #client_id
        * [contains the ClientOptions client ID](./spec/acceptance/realtime/auth_spec.rb#L67)
      * #current_token_details
        * [contains the current token after auth](./spec/acceptance/realtime/auth_spec.rb#L74)
      * #token_renewable?
        * [is true when an API key exists](./spec/acceptance/realtime/auth_spec.rb#L84)
      * #options (auth_options)
        * [contains the configured auth options](./spec/acceptance/realtime/auth_spec.rb#L95)
      * #token_params
        * [contains the configured auth options](./spec/acceptance/realtime/auth_spec.rb#L106)
      * #using_basic_auth?
        * [is false when using Token Auth](./spec/acceptance/realtime/auth_spec.rb#L115)
      * #using_token_auth?
        * [is true when using Token Auth](./spec/acceptance/realtime/auth_spec.rb#L124)
    * 
      * #create_token_request
        * [returns a token request asynchronously](./spec/acceptance/realtime/auth_spec.rb#L138)
      * #create_token_request_async
        * [returns a token request synchronously](./spec/acceptance/realtime/auth_spec.rb#L148)
      * #request_token
        * [returns a token asynchronously](./spec/acceptance/realtime/auth_spec.rb#L158)
      * #request_token_async
        * [returns a token synchronously](./spec/acceptance/realtime/auth_spec.rb#L169)
      * #authorise
        * [returns a token asynchronously](./spec/acceptance/realtime/auth_spec.rb#L180)
        * when implicitly called, with an explicit ClientOptions client_id
          * and an incompatible client_id in a TokenDetails object passed to the auth callback
            * [rejects a TokenDetails object with an incompatible client_id and raises an exception](./spec/acceptance/realtime/auth_spec.rb#L197)
          * and an incompatible client_id in a TokenRequest object passed to the auth callback and raises an exception
            * [rejects a TokenRequests object with an incompatible client_id and raises an exception](./spec/acceptance/realtime/auth_spec.rb#L212)
        * when explicitly called, with an explicit ClientOptions client_id
          * and an incompatible client_id in a TokenDetails object passed to the auth callback
            * [rejects a TokenDetails object with an incompatible client_id and raises an exception](./spec/acceptance/realtime/auth_spec.rb#L243)
      * #authorise_async
        * [returns a token synchronously](./spec/acceptance/realtime/auth_spec.rb#L260)
    * #auth_params
      * [returns the auth params asynchronously](./spec/acceptance/realtime/auth_spec.rb#L272)
    * #auth_params_sync
      * [returns the auth params synchronously](./spec/acceptance/realtime/auth_spec.rb#L281)
    * #auth_header
      * [returns an auth header asynchronously](./spec/acceptance/realtime/auth_spec.rb#L288)
    * #auth_header_sync
      * [returns an auth header synchronously](./spec/acceptance/realtime/auth_spec.rb#L297)
    * #client_id_validated?
      * when using basic auth
        * before connected
          * [is false as basic auth users do not have an identity](./spec/acceptance/realtime/auth_spec.rb#L310)
        * once connected
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L317)
          * [contains a validated wildcard client_id](./spec/acceptance/realtime/auth_spec.rb#L324)
      * when using a token string
        * with a valid client_id
          * before connected
            * [is false as identification is not possible from an opaque token string](./spec/acceptance/realtime/auth_spec.rb#L338)
            * [#client_id is nil](./spec/acceptance/realtime/auth_spec.rb#L343)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L350)
            * [#client_id is populated](./spec/acceptance/realtime/auth_spec.rb#L357)
        * with no client_id (anonymous)
          * before connected
            * [is false as identification is not possible from an opaque token string](./spec/acceptance/realtime/auth_spec.rb#L370)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L377)
        * with a wildcard client_id (anonymous)
          * before connected
            * [is false as identification is not possible from an opaque token string](./spec/acceptance/realtime/auth_spec.rb#L390)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L397)
      * when using a token
        * with a client_id
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L411)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L417)
        * with no client_id (anonymous)
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L429)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L435)
        * with a wildcard client_id (anonymous)
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L447)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L453)
      * when using a token request with a client_id
        * [is not true as identification is not confirmed until authenticated](./spec/acceptance/realtime/auth_spec.rb#L466)
        * once connected
          * [is true as identification is completed following CONNECTED ProtocolMessage](./spec/acceptance/realtime/auth_spec.rb#L472)

### Ably::Realtime::Channel#history
_(see [spec/acceptance/realtime/channel_history_spec.rb](./spec/acceptance/realtime/channel_history_spec.rb))_
  * using JSON protocol
    * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/channel_history_spec.rb#L21)
    * with a single client publishing and receiving
      * [retrieves realtime history](./spec/acceptance/realtime/channel_history_spec.rb#L34)
    * with two clients publishing messages on the same channel
      * [retrieves realtime history on both channels](./spec/acceptance/realtime/channel_history_spec.rb#L46)
    * with lots of messages published with a single client and channel
      * as one ProtocolMessage
        * [retrieves history forwards with pagination through :limit option](./spec/acceptance/realtime/channel_history_spec.rb#L88)
        * [retrieves history backwards with pagination through :limit option](./spec/acceptance/realtime/channel_history_spec.rb#L97)
      * in multiple ProtocolMessages
        * [retrieves limited history forwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L108)
        * [retrieves limited history backwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L119)
      * and REST history
        * [return the same results with unique matching message IDs](./spec/acceptance/realtime/channel_history_spec.rb#L135)
    * with option until_attach: true
      * [retrieves all messages before channel was attached](./spec/acceptance/realtime/channel_history_spec.rb#L160)
      * [raises an exception unless state is attached](./spec/acceptance/realtime/channel_history_spec.rb#L209)
      * and two pages of messages
        * [retrieves two pages of messages before channel was attached](./spec/acceptance/realtime/channel_history_spec.rb#L175)

### Ably::Realtime::Channel
_(see [spec/acceptance/realtime/channel_spec.rb](./spec/acceptance/realtime/channel_spec.rb))_
  * using JSON protocol
    * initialization
      * with :auto_connect option set to false on connection
        * [remains initialized when accessing a channel](./spec/acceptance/realtime/channel_spec.rb#L21)
        * [opens a connection implicitly on #attach](./spec/acceptance/realtime/channel_spec.rb#L29)
    * #attach
      * [emits attaching then attached events](./spec/acceptance/realtime/channel_spec.rb#L39)
      * [ignores subsequent #attach calls but calls the success callback if provided](./spec/acceptance/realtime/channel_spec.rb#L49)
      * [attaches to a channel](./spec/acceptance/realtime/channel_spec.rb#L62)
      * [attaches to a channel and calls the provided block](./spec/acceptance/realtime/channel_spec.rb#L70)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/channel_spec.rb#L77)
      * [calls the SafeDeferrable callback on success](./spec/acceptance/realtime/channel_spec.rb#L82)
      * when state is :failed
        * [reattaches](./spec/acceptance/realtime/channel_spec.rb#L93)
      * when state is :detaching
        * [moves straight to attaching and skips detached](./spec/acceptance/realtime/channel_spec.rb#L106)
      * with many connections and many channels on each simultaneously
        * [attaches all channels](./spec/acceptance/realtime/channel_spec.rb#L132)
      * failure as a result of insufficient key permissions
        * [emits failed event](./spec/acceptance/realtime/channel_spec.rb#L155)
        * [calls the errback of the returned Deferrable](./spec/acceptance/realtime/channel_spec.rb#L164)
        * [emits an error event](./spec/acceptance/realtime/channel_spec.rb#L172)
        * [updates the error_reason](./spec/acceptance/realtime/channel_spec.rb#L181)
        * and subsequent authorisation with suitable permissions
          * [attaches to the channel successfully and resets the channel error_reason](./spec/acceptance/realtime/channel_spec.rb#L190)
    * #detach
      * [detaches from a channel](./spec/acceptance/realtime/channel_spec.rb#L212)
      * [detaches from a channel and calls the provided block](./spec/acceptance/realtime/channel_spec.rb#L222)
      * [emits :detaching then :detached events](./spec/acceptance/realtime/channel_spec.rb#L232)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/channel_spec.rb#L244)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/channel_spec.rb#L251)
      * when state is :failed
        * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L264)
      * when state is :attaching
        * [moves straight to :detaching state and skips :attached](./spec/acceptance/realtime/channel_spec.rb#L275)
      * when state is :detaching
        * [ignores subsequent #detach calls but calls the callback if provided](./spec/acceptance/realtime/channel_spec.rb#L293)
      * when state is :initialized
        * [does nothing as there is no channel to detach](./spec/acceptance/realtime/channel_spec.rb#L310)
        * [returns a valid deferrable](./spec/acceptance/realtime/channel_spec.rb#L318)
    * channel recovery in :attaching state
      * the transport is disconnected before the ATTACHED protocol message is received
        * PENDING: *[attach times out and fails if not ATTACHED protocol message received](./spec/acceptance/realtime/channel_spec.rb#L330)*
        * PENDING: *[channel is ATTACHED if ATTACHED protocol message is later received](./spec/acceptance/realtime/channel_spec.rb#L331)*
        * PENDING: *[sends an ATTACH protocol message in response to a channel message being received on the attaching channel](./spec/acceptance/realtime/channel_spec.rb#L332)*
    * #publish
      * when attached
        * [publishes messages](./spec/acceptance/realtime/channel_spec.rb#L341)
      * when not yet attached
        * [publishes queued messages once attached](./spec/acceptance/realtime/channel_spec.rb#L353)
        * [publishes queued messages within a single protocol message](./spec/acceptance/realtime/channel_spec.rb#L361)
        * with :queue_messages client option set to false
          * and connection state initialized
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L384)
          * and connection state connecting
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L392)
          * and connection state disconnected
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L404)
          * and connection state connected
            * [publishes the message](./spec/acceptance/realtime/channel_spec.rb#L417)
      * with name and data arguments
        * [publishes the message and return true indicating success](./spec/acceptance/realtime/channel_spec.rb#L428)
        * and additional attributes
          * [publishes the message with the attributes and return true indicating success](./spec/acceptance/realtime/channel_spec.rb#L441)
      * with an array of Hash objects with :name and :data attributes
        * [publishes an array of messages in one ProtocolMessage](./spec/acceptance/realtime/channel_spec.rb#L459)
      * with an array of Message objects
        * [publishes an array of messages in one ProtocolMessage](./spec/acceptance/realtime/channel_spec.rb#L487)
        * nil attributes
          * when name is nil
            * [publishes the message without a name attribute in the payload](./spec/acceptance/realtime/channel_spec.rb#L511)
          * when data is nil
            * [publishes the message without a data attribute in the payload](./spec/acceptance/realtime/channel_spec.rb#L534)
          * with neither name or data attributes
            * [publishes the message without any attributes in the payload](./spec/acceptance/realtime/channel_spec.rb#L557)
        * with two invalid message out of 12
          * before client_id is known (validated)
            * [calls the errback once](./spec/acceptance/realtime/channel_spec.rb#L581)
          * when client_id is known (validated)
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L601)
        * only invalid messages
          * before client_id is known (validated)
            * [calls the errback once](./spec/acceptance/realtime/channel_spec.rb#L620)
          * when client_id is known (validated)
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L639)
      * with many many messages and many connections simultaneously
        * [publishes all messages, all success callbacks are called, and a history request confirms all messages were published](./spec/acceptance/realtime/channel_spec.rb#L653)
      * identified clients
        * when authenticated with a wildcard client_id
          * with a valid client_id in the message
            * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L681)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L693)
          * with an empty client_id in the message
            * [succeeds and publishes without a client_id](./spec/acceptance/realtime/channel_spec.rb#L700)
        * when authenticated with a Token string with an implicit client_id
          * before the client is CONNECTED and the client's identity has been obtained
            * with a valid client_id in the message
              * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L720)
            * with an invalid client_id in the message
              * [succeeds in the client library but then fails when delivered to Ably](./spec/acceptance/realtime/channel_spec.rb#L733)
            * with an empty client_id in the message
              * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L744)
          * after the client is CONNECTED and the client's identity is known
            * with a valid client_id in the message
              * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L758)
            * with an invalid client_id in the message
              * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L772)
            * with an empty client_id in the message
              * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L781)
        * when authenticated with a valid client_id
          * with a valid client_id
            * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L803)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L815)
          * with an invalid client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L822)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L829)
        * when anonymous and no client_id
          * with a client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L848)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L855)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L862)
    * #subscribe
      * with an event argument
        * [subscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L878)
      * before attach
        * [receives messages as soon as attached](./spec/acceptance/realtime/channel_spec.rb#L888)
      * with no event argument
        * [subscribes for all events](./spec/acceptance/realtime/channel_spec.rb#L902)
      * many times with different event names
        * [filters events accordingly to each callback](./spec/acceptance/realtime/channel_spec.rb#L912)
    * #unsubscribe
      * with an event argument
        * [unsubscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L935)
      * with no event argument
        * [unsubscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L948)
    * when connection state changes to
      * :failed
        * an :attached channel
          * [transitions state to :failed](./spec/acceptance/realtime/channel_spec.rb#L971)
          * [emits an error event on the channel](./spec/acceptance/realtime/channel_spec.rb#L983)
          * [updates the channel error_reason](./spec/acceptance/realtime/channel_spec.rb#L994)
        * a :detached channel
          * [remains in the :detached state](./spec/acceptance/realtime/channel_spec.rb#L1008)
        * a :failed channel
          * [remains in the :failed state and ignores the failure error](./spec/acceptance/realtime/channel_spec.rb#L1028)
        * a channel ATTACH request
          * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L1049)
      * :closed
        * an :attached channel
          * [transitions state to :detached](./spec/acceptance/realtime/channel_spec.rb#L1063)
        * a :detached channel
          * [remains in the :detached state](./spec/acceptance/realtime/channel_spec.rb#L1074)
        * a :failed channel
          * [remains in the :failed state and retains the error_reason](./spec/acceptance/realtime/channel_spec.rb#L1095)
        * a channel ATTACH request when connection CLOSED
          * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L1116)
        * a channel ATTACH request when connection CLOSING
          * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L1128)
      * :suspended
        * an :attached channel
          * [transitions state to :detached](./spec/acceptance/realtime/channel_spec.rb#L1144)
        * a :detached channel
          * [remains in the :detached state](./spec/acceptance/realtime/channel_spec.rb#L1155)
        * a :failed channel
          * [remains in the :failed state and retains the error_reason](./spec/acceptance/realtime/channel_spec.rb#L1176)
        * a channel ATTACH request when connection SUSPENDED
          * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L1199)
    * #presence
      * [returns a Ably::Realtime::Presence object](./spec/acceptance/realtime/channel_spec.rb#L1213)
    * channel state change
      * [emits a ChannelStateChange object](./spec/acceptance/realtime/channel_spec.rb#L1220)
      * ChannelStateChange object
        * [has current state](./spec/acceptance/realtime/channel_spec.rb#L1229)
        * [has a previous state](./spec/acceptance/realtime/channel_spec.rb#L1237)
        * [has an empty reason when there is no error](./spec/acceptance/realtime/channel_spec.rb#L1254)
        * on failure
          * [has a reason Error object when there is an error on the channel](./spec/acceptance/realtime/channel_spec.rb#L1267)

### Ably::Realtime::Channels
_(see [spec/acceptance/realtime/channels_spec.rb](./spec/acceptance/realtime/channels_spec.rb))_
  * using JSON protocol
    * using shortcut method #channel on the client object
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/realtime/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/realtime/channels_spec.rb#L12)
    * using #get method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/realtime/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/realtime/channels_spec.rb#L12)
    * accessing an existing channel object with different options
      * [overrides the existing channel options and returns the channel object](./spec/acceptance/realtime/channels_spec.rb#L41)
    * accessing an existing channel object without specifying any channel options
      * [returns the existing channel without modifying the channel options](./spec/acceptance/realtime/channels_spec.rb#L53)
    * using undocumented array accessor [] method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/realtime/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/realtime/channels_spec.rb#L12)

### Ably::Realtime::Client
_(see [spec/acceptance/realtime/client_spec.rb](./spec/acceptance/realtime/client_spec.rb))_
  * using JSON protocol
    * initialization
      * basic auth
        * [is enabled by default with a provided :key option](./spec/acceptance/realtime/client_spec.rb#L18)
        * :tls option
          * set to false to force a plain-text connection
            * [fails to connect because a private key cannot be sent over a non-secure connection](./spec/acceptance/realtime/client_spec.rb#L31)
      * token auth
        * with TLS enabled
          * and a pre-generated Token provided with the :token option
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L52)
          * with valid :key and :use_token_auth option set to true
            * [automatically authorises on connect and generates a token](./spec/acceptance/realtime/client_spec.rb#L65)
          * with client_id
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L78)
        * with TLS disabled
          * and a pre-generated Token provided with the :token option
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L52)
          * with valid :key and :use_token_auth option set to true
            * [automatically authorises on connect and generates a token](./spec/acceptance/realtime/client_spec.rb#L65)
          * with client_id
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L78)
        * with a Proc for the :auth_callback option
          * [calls the Proc](./spec/acceptance/realtime/client_spec.rb#L103)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/realtime/client_spec.rb#L110)
          * when the returned token has a client_id
            * [sets Auth#client_id to the new token's client_id immediately when connecting](./spec/acceptance/realtime/client_spec.rb#L118)
            * [sets Client#client_id to the new token's client_id immediately when connecting](./spec/acceptance/realtime/client_spec.rb#L126)
          * with a wildcard client_id token
            * and an explicit client_id in ClientOptions
              * [allows uses the explicit client_id in the connection](./spec/acceptance/realtime/client_spec.rb#L144)
            * and client_id omitted in ClientOptions
              * [uses the token provided clientId in the connection](./spec/acceptance/realtime/client_spec.rb#L160)
        * with an invalid wildcard "*" :client_id
          * [raises an exception](./spec/acceptance/realtime/client_spec.rb#L176)
      * realtime connection settings
        * defaults
          * [disconnected_retry_timeout is 15s](./spec/acceptance/realtime/client_spec.rb#L185)
          * [suspended_retry_timeout is 30s](./spec/acceptance/realtime/client_spec.rb#L190)
        * overriden in ClientOptions
          * [disconnected_retry_timeout is updated](./spec/acceptance/realtime/client_spec.rb#L199)
          * [suspended_retry_timeout is updated](./spec/acceptance/realtime/client_spec.rb#L204)
    * #connection
      * [provides access to the Connection object](./spec/acceptance/realtime/client_spec.rb#L213)
    * #channels
      * [provides access to the Channels collection object](./spec/acceptance/realtime/client_spec.rb#L220)
    * #auth
      * [provides access to the Realtime::Auth object](./spec/acceptance/realtime/client_spec.rb#L227)

### Ably::Realtime::Connection failures
_(see [spec/acceptance/realtime/connection_failures_spec.rb](./spec/acceptance/realtime/connection_failures_spec.rb))_
  * using JSON protocol
    * authentication failure
      * when API key is invalid
        * with invalid app part of the key
          * [enters the failed state and returns a not found error](./spec/acceptance/realtime/connection_failures_spec.rb#L26)
        * with invalid key name part of the key
          * [enters the failed state and returns an authorization error](./spec/acceptance/realtime/connection_failures_spec.rb#L41)
    * automatic connection retry
      * with invalid WebSocket host
        * when disconnected
          * [enters the suspended state after multiple attempts to connect](./spec/acceptance/realtime/connection_failures_spec.rb#L95)
          * for the first time
            * [reattempts connection immediately and then waits disconnected_retry_timeout for a subsequent attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * #close
            * [transitions connection state to :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L133)
        * when connection state is :suspended
          * [stays in the suspended state after any number of reconnection attempts](./spec/acceptance/realtime/connection_failures_spec.rb#L152)
          * for the first time
            * [waits suspended_retry_timeout before attempting to reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L175)
          * #close
            * [transitions connection state to :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L197)
        * when connection state is :failed
          * #close
            * [will not transition state to :close and raises a InvalidStateChange exception](./spec/acceptance/realtime/connection_failures_spec.rb#L216)
        * #error_reason
          * [contains the error when state is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L234)
          * [contains the error when state is suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L234)
          * [contains the error when state is failed](./spec/acceptance/realtime/connection_failures_spec.rb#L234)
          * [is reset to nil when :connected](./spec/acceptance/realtime/connection_failures_spec.rb#L248)
          * [is reset to nil when :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L259)
      * #connect
        * connection opening times out
          * [attempts to reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L290)
          * when retry intervals are stubbed to attempt reconnection quickly
            * [never calls the provided success block](./spec/acceptance/realtime/connection_failures_spec.rb#L314)
    * connection resume
      * when DISCONNECTED ProtocolMessage received from the server
        * [reconnects automatically and immediately](./spec/acceptance/realtime/connection_failures_spec.rb#L345)
        * and subsequently fails to reconnect
          * [retries every 15 seconds](./spec/acceptance/realtime/connection_failures_spec.rb#L377)
      * when websocket transport is closed
        * [reconnects automatically](./spec/acceptance/realtime/connection_failures_spec.rb#L420)
      * after successfully reconnecting and resuming
        * [retains connection_id and updates the connection_key](./spec/acceptance/realtime/connection_failures_spec.rb#L437)
        * [emits any error received from Ably but leaves the channels attached](./spec/acceptance/realtime/connection_failures_spec.rb#L452)
        * [retains channel subscription state](./spec/acceptance/realtime/connection_failures_spec.rb#L483)
        * when messages were published whilst the client was disconnected
          * [receives the messages published whilst offline](./spec/acceptance/realtime/connection_failures_spec.rb#L511)
      * when failing to resume
        * because the connection_key is not or no longer valid
          * [updates the connection_id and connection_key](./spec/acceptance/realtime/connection_failures_spec.rb#L554)
          * [detaches all channels](./spec/acceptance/realtime/connection_failures_spec.rb#L569)
          * [emits an error on the channel and sets the error reason](./spec/acceptance/realtime/connection_failures_spec.rb#L589)
    * fallback host feature
      * with custom realtime websocket host option
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L629)
      * with custom realtime websocket port option
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L647)
      * with non-production environment
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L666)
      * with production environment
        * when the Internet is down
          * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L696)
        * when the Internet is up
          * [uses a fallback host on every subsequent disconnected attempt until suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L716)
          * [uses the primary host when suspended, and a fallback host on every subsequent suspended attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L735)

### Ably::Realtime::Connection
_(see [spec/acceptance/realtime/connection_spec.rb](./spec/acceptance/realtime/connection_spec.rb))_
  * using JSON protocol
    * intialization
      * [connects automatically](./spec/acceptance/realtime/connection_spec.rb#L23)
      * with :auto_connect option set to false
        * [does not connect automatically](./spec/acceptance/realtime/connection_spec.rb#L35)
        * [connects when method #connect is called](./spec/acceptance/realtime/connection_spec.rb#L43)
      * with token auth
        * for renewable tokens
          * that are valid for the duration of the test
            * with valid pre authorised token expiring in the future
              * [uses the existing token created by Auth](./spec/acceptance/realtime/connection_spec.rb#L64)
            * with implicit authorisation
              * [uses the token created by the implicit authorisation](./spec/acceptance/realtime/connection_spec.rb#L76)
          * that expire
            * opening a new connection
              * with almost expired tokens
                * [renews token every time after it expires](./spec/acceptance/realtime/connection_spec.rb#L110)
              * with immediately expired token
                * [renews the token on connect, and makes one immediate subsequent attempt to obtain a new token](./spec/acceptance/realtime/connection_spec.rb#L140)
                * when disconnected_retry_timeout is 0.5 seconds
                  * [renews the token on connect, and continues to attempt renew based on the retry schedule](./spec/acceptance/realtime/connection_spec.rb#L155)
                * using implicit token auth
                  * [uses the primary host for subsequent connection and auth requests](./spec/acceptance/realtime/connection_spec.rb#L177)
            * when connected with a valid non-expired token
              * that then expires following the connection being opened
                * the server
                  * [disconnects the client, and the client automatically renews the token and then reconnects](./spec/acceptance/realtime/connection_spec.rb#L204)
                * connection state
                  * [retains messages published when disconnected twice during authentication](./spec/acceptance/realtime/connection_spec.rb#L273)
                * and subsequent token is invalid
                  * [transitions the connection to the failed state](./spec/acceptance/realtime/connection_spec.rb#L302)
        * for non-renewable tokens
          * that are expired
            * opening a new connection
              * [transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L331)
            * when connected
              * PENDING: *[transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L344)*
        * with opaque token string that contain an implicit client_id
          * string
            * [sets the Client#client_id and Auth#client_id once CONNECTED](./spec/acceptance/realtime/connection_spec.rb#L357)
            * that is incompatible with the current client client_id
              * [fails the connection](./spec/acceptance/realtime/connection_spec.rb#L369)
          * wildcard
            * [configures the Client#client_id and Auth#client_id with a wildcard once CONNECTED](./spec/acceptance/realtime/connection_spec.rb#L383)
    * initialization state changes
      * with implicit #connect
        * [are emitted in order](./spec/acceptance/realtime/connection_spec.rb#L415)
      * with explicit #connect
        * [are emitted in order](./spec/acceptance/realtime/connection_spec.rb#L421)
    * #connect
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/connection_spec.rb#L429)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/connection_spec.rb#L434)
      * [calls the provided block on success even if state changes to disconnected first](./spec/acceptance/realtime/connection_spec.rb#L441)
      * with invalid auth details
        * [calls the Deferrable errback only once on connection failure](./spec/acceptance/realtime/connection_spec.rb#L470)
      * when already connected
        * [does nothing and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L486)
      * connection#id
        * [is null before connecting](./spec/acceptance/realtime/connection_spec.rb#L500)
      * connection#key
        * [is null before connecting](./spec/acceptance/realtime/connection_spec.rb#L507)
      * once connected
        * connection#id
          * [is a string](./spec/acceptance/realtime/connection_spec.rb#L518)
          * [is unique from the connection#key](./spec/acceptance/realtime/connection_spec.rb#L525)
          * [is unique for every connection](./spec/acceptance/realtime/connection_spec.rb#L532)
        * connection#key
          * [is a string](./spec/acceptance/realtime/connection_spec.rb#L541)
          * [is unique from the connection#id](./spec/acceptance/realtime/connection_spec.rb#L548)
          * [is unique for every connection](./spec/acceptance/realtime/connection_spec.rb#L555)
      * following a previous connection being opened and closed
        * [reconnects and is provided with a new connection ID and connection key from the server](./spec/acceptance/realtime/connection_spec.rb#L565)
      * when closing
        * [raises an exception before the connection is closed](./spec/acceptance/realtime/connection_spec.rb#L582)
    * #serial connection serial
      * [is set to -1 when a new connection is opened](./spec/acceptance/realtime/connection_spec.rb#L597)
      * [is set to 0 when a message sent ACK is received](./spec/acceptance/realtime/connection_spec.rb#L618)
      * [is set to 1 when the second message sent ACK is received](./spec/acceptance/realtime/connection_spec.rb#L625)
      * when a message is sent but the ACK has not yet been received
        * [the sent message msgSerial is 0 but the connection serial remains at -1](./spec/acceptance/realtime/connection_spec.rb#L605)
    * #close
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/connection_spec.rb#L636)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/connection_spec.rb#L643)
      * when already closed
        * [does nothing and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L654)
      * when connection state is
        * :initialized
          * [changes the connection state to :closing and then immediately :closed without sending a ProtocolMessage CLOSE](./spec/acceptance/realtime/connection_spec.rb#L682)
        * :connected
          * [changes the connection state to :closing and waits for the server to confirm connection is :closed with a ProtocolMessage](./spec/acceptance/realtime/connection_spec.rb#L700)
          * with an unresponsive connection
            * [force closes the connection when a :closed ProtocolMessage response is not received](./spec/acceptance/realtime/connection_spec.rb#L728)
    * #ping
      * [echoes a heart beat](./spec/acceptance/realtime/connection_spec.rb#L751)
      * when not connected
        * [raises an exception](./spec/acceptance/realtime/connection_spec.rb#L761)
      * with a success block that raises an exception
        * [catches the exception and logs the error](./spec/acceptance/realtime/connection_spec.rb#L768)
      * when ping times out
        * [logs a warning](./spec/acceptance/realtime/connection_spec.rb#L781)
        * [yields to the block with a nil value](./spec/acceptance/realtime/connection_spec.rb#L791)
    * #details
      * [is nil before connected](./spec/acceptance/realtime/connection_spec.rb#L806)
      * [contains the ConnectionDetails object once connected](./spec/acceptance/realtime/connection_spec.rb#L813)
      * [contains the new ConnectionDetails object once a subsequent connection is created](./spec/acceptance/realtime/connection_spec.rb#L822)
    * recovery
      * #recovery_key
        * [is composed of connection key and serial that is kept up to date with each message ACK received](./spec/acceptance/realtime/connection_spec.rb#L864)
        * [is available when connection is in one of the states: connecting, connected, disconnected, suspended, failed](./spec/acceptance/realtime/connection_spec.rb#L887)
        * [is nil when connection is explicitly CLOSED](./spec/acceptance/realtime/connection_spec.rb#L916)
      * opening a new connection using a recently disconnected connection's #recovery_key
        * connection#id and connection#key after recovery
          * [remains the same for id and party for key](./spec/acceptance/realtime/connection_spec.rb#L928)
        * when messages have been sent whilst the old connection is disconnected
          * the new connection
            * [recovers server-side queued messages](./spec/acceptance/realtime/connection_spec.rb#L970)
      * with :recover option
        * with invalid syntax
          * [raises an exception](./spec/acceptance/realtime/connection_spec.rb#L996)
        * with invalid formatted value sent to server
          * [emits a fatal error on the connection object, sets the #error_reason and disconnects](./spec/acceptance/realtime/connection_spec.rb#L1005)
        * with expired (missing) value sent to server
          * [emits an error on the connection object, sets the #error_reason, yet will connect anyway](./spec/acceptance/realtime/connection_spec.rb#L1020)
    * with many connections simultaneously
      * [opens each with a unique connection#id and connection#key](./spec/acceptance/realtime/connection_spec.rb#L1039)
    * when a state transition is unsupported
      * [emits a InvalidStateChange](./spec/acceptance/realtime/connection_spec.rb#L1059)
    * protocol failure
      * receiving an invalid ProtocolMessage
        * [emits an error on the connection and logs a fatal error message](./spec/acceptance/realtime/connection_spec.rb#L1075)
    * undocumented method
      * #internet_up?
        * [returns a Deferrable](./spec/acceptance/realtime/connection_spec.rb#L1091)
        * internet up URL protocol
          * when using TLS for the connection
            * [uses TLS for the Internet check to https://internet-up.ably-realtime.com/is-the-internet-up.txt](./spec/acceptance/realtime/connection_spec.rb#L1102)
          * when using a non-secured connection
            * [uses TLS for the Internet check to http://internet-up.ably-realtime.com/is-the-internet-up.txt](./spec/acceptance/realtime/connection_spec.rb#L1112)
        * when the Internet is up
          * [calls the block with true](./spec/acceptance/realtime/connection_spec.rb#L1143)
          * [calls the success callback of the Deferrable](./spec/acceptance/realtime/connection_spec.rb#L1150)
          * with a TLS connection
            * [checks the Internet up URL over TLS](./spec/acceptance/realtime/connection_spec.rb#L1126)
          * with a non-TLS connection
            * [checks the Internet up URL over TLS](./spec/acceptance/realtime/connection_spec.rb#L1136)
        * when the Internet is down
          * [calls the block with false](./spec/acceptance/realtime/connection_spec.rb#L1165)
          * [calls the failure callback of the Deferrable](./spec/acceptance/realtime/connection_spec.rb#L1172)
    * state change side effects
      * when connection enters the :disconnected state
        * [queues messages to be sent and all channels remain attached](./spec/acceptance/realtime/connection_spec.rb#L1186)
      * when connection enters the :suspended state
        * [detaches the channels and prevents publishing of messages on those channels](./spec/acceptance/realtime/connection_spec.rb#L1219)
      * when connection enters the :failed state
        * [sets all channels to failed and prevents publishing of messages on those channels](./spec/acceptance/realtime/connection_spec.rb#L1248)
    * connection state change
      * [emits a ConnectionStateChange object](./spec/acceptance/realtime/connection_spec.rb#L1259)
      * ConnectionStateChange object
        * [has current state](./spec/acceptance/realtime/connection_spec.rb#L1267)
        * [has a previous state](./spec/acceptance/realtime/connection_spec.rb#L1274)
        * [has an empty reason when there is no error](./spec/acceptance/realtime/connection_spec.rb#L1289)
        * on failure
          * [has a reason Error object when there is an error on the connection](./spec/acceptance/realtime/connection_spec.rb#L1302)
        * retry_in
          * [is nil when a retry is not required](./spec/acceptance/realtime/connection_spec.rb#L1317)
          * [is 0 when first attempt to connect fails](./spec/acceptance/realtime/connection_spec.rb#L1324)
          * [is 0 when an immediate reconnect will occur](./spec/acceptance/realtime/connection_spec.rb#L1334)
          * [contains the next retry period when an immediate reconnect will not occur](./spec/acceptance/realtime/connection_spec.rb#L1344)

### Ably::Realtime::Channel Message
_(see [spec/acceptance/realtime/message_spec.rb](./spec/acceptance/realtime/message_spec.rb))_
  * using JSON protocol
    * [sends a String data payload](./spec/acceptance/realtime/message_spec.rb#L25)
    * with supported data payload content type
      * JSON Object (Hash)
        * [is encoded and decoded to the same hash](./spec/acceptance/realtime/message_spec.rb#L48)
      * JSON Array
        * [is encoded and decoded to the same Array](./spec/acceptance/realtime/message_spec.rb#L56)
      * String
        * [is encoded and decoded to the same Array](./spec/acceptance/realtime/message_spec.rb#L64)
      * Binary
        * [is encoded and decoded to the same Array](./spec/acceptance/realtime/message_spec.rb#L72)
    * with unsupported data payload content type
      * Integer
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/message_spec.rb#L82)
      * Float
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/message_spec.rb#L91)
      * Boolean
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/message_spec.rb#L100)
      * False
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/message_spec.rb#L109)
    * with ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/realtime/message_spec.rb#L118)
    * when the message publisher has a client_id
      * [contains a #client_id attribute](./spec/acceptance/realtime/message_spec.rb#L134)
    * #connection_id attribute
      * over realtime
        * [matches the sender connection#id](./spec/acceptance/realtime/message_spec.rb#L147)
      * when retrieved over REST
        * [matches the sender connection#id](./spec/acceptance/realtime/message_spec.rb#L159)
    * local echo when published
      * [is enabled by default](./spec/acceptance/realtime/message_spec.rb#L171)
      * with :echo_messages option set to false
        * [will not echo messages to the client but will still broadcast messages to other connected clients](./spec/acceptance/realtime/message_spec.rb#L191)
        * [will not echo messages to the client from other REST clients publishing using that connection_key](./spec/acceptance/realtime/message_spec.rb#L210)
        * [will echo messages with a valid connection_id to the client from other REST clients publishing using that connection_key](./spec/acceptance/realtime/message_spec.rb#L223)
    * publishing lots of messages across two connections
      * [sends and receives the messages on both opened connections and calls the success callbacks for each message published](./spec/acceptance/realtime/message_spec.rb#L249)
    * without suitable publishing permissions
      * [calls the error callback](./spec/acceptance/realtime/message_spec.rb#L294)
    * server incorrectly resends a message that was already received by the client library
      * [discards the message and logs it as an error to the channel](./spec/acceptance/realtime/message_spec.rb#L313)
    * encoding and decoding encrypted messages
      * with AES-128-CBC using crypto-data-128.json fixtures
        * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
        * item 1 with encrypted encoding cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
      * with AES-256-CBC using crypto-data-256.json fixtures
        * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
        * item 1 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L377)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L395)
      * with multiple sends from one client to another
        * [encrypts and decrypts all messages](./spec/acceptance/realtime/message_spec.rb#L434)
        * [receives raw messages with the correct encoding](./spec/acceptance/realtime/message_spec.rb#L451)
      * subscribing with a different transport protocol
        * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L485)
        * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L485)
        * [delivers a Hash payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L485)
      * publishing on an unencrypted channel and subscribing on an encrypted channel with another client
        * [does not attempt to decrypt the message](./spec/acceptance/realtime/message_spec.rb#L504)
      * publishing on an encrypted channel and subscribing on an unencrypted channel with another client
        * [delivers the message but still encrypted with a value in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L522)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L531)
      * publishing on an encrypted channel and subscribing with a different algorithm on another client
        * [delivers the message but still encrypted with the cipher detials in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L553)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L562)
      * publishing on an encrypted channel and subscribing with a different key on another client
        * [delivers the message but still encrypted with the cipher details in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L584)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L595)
    * when message is published, the connection disconnects before the ACK is received, and the connection is resumed
      * [publishes the message again, later receives the ACK and only one message is ever received from Ably](./spec/acceptance/realtime/message_spec.rb#L616)
    * when message is published, the connection disconnects before the ACK is received
      * the connection is not resumed
        * [calls the errback for all messages](./spec/acceptance/realtime/message_spec.rb#L659)
      * the connection becomes suspended
        * [calls the errback for all messages](./spec/acceptance/realtime/message_spec.rb#L685)
      * the connection becomes failed
        * [calls the errback for all messages](./spec/acceptance/realtime/message_spec.rb#L712)

### Ably::Realtime::Presence history
_(see [spec/acceptance/realtime/presence_history_spec.rb](./spec/acceptance/realtime/presence_history_spec.rb))_
  * using JSON protocol
    * [provides up to the moment presence history](./spec/acceptance/realtime/presence_history_spec.rb#L21)
    * [ensures REST presence history message IDs match ProtocolMessage wrapped message and connection IDs via Realtime](./spec/acceptance/realtime/presence_history_spec.rb#L42)
    * with option until_attach: true
      * [retrieves all presence messages before channel was attached](./spec/acceptance/realtime/presence_history_spec.rb#L61)
      * [raises an exception unless state is attached](./spec/acceptance/realtime/presence_history_spec.rb#L97)
      * and two pages of messages
        * [retrieves two pages of messages before channel was attached](./spec/acceptance/realtime/presence_history_spec.rb#L78)

### Ably::Realtime::Presence
_(see [spec/acceptance/realtime/presence_spec.rb](./spec/acceptance/realtime/presence_spec.rb))_
  * using JSON protocol
    * when attached (but not present) on a presence channel with an anonymous client (no client ID)
      * [maintains state as other clients enter and leave the channel](./spec/acceptance/realtime/presence_spec.rb#L412)
    * #sync_complete?
      * when attaching to a channel without any members present
        * [is true and the presence channel is considered synced immediately](./spec/acceptance/realtime/presence_spec.rb#L488)
      * when attaching to a channel with members present
        * [is false and the presence channel will subsequently be synced](./spec/acceptance/realtime/presence_spec.rb#L497)
    * 250 existing (present) members on a channel (3 SYNC pages)
      * requires at least 3 SYNC ProtocolMessages
        * when a client attaches to the presence channel
          * [emits :present for each member](./spec/acceptance/realtime/presence_spec.rb#L533)
          * and a member leaves before the SYNC operation is complete
            * [emits :leave immediately as the member leaves](./spec/acceptance/realtime/presence_spec.rb#L547)
            * [ignores presence events with timestamps prior to the current :present event in the MembersMap](./spec/acceptance/realtime/presence_spec.rb#L588)
            * [does not emit :present after the :leave event has been emitted, and that member is not included in the list of members via #get with :wait_for_sync](./spec/acceptance/realtime/presence_spec.rb#L630)
          * #get
            * with :wait_for_sync option set to true
              * [waits until sync is complete](./spec/acceptance/realtime/presence_spec.rb#L680)
            * by default
              * [it does not wait for sync](./spec/acceptance/realtime/presence_spec.rb#L699)
    * state
      * once opened
        * [once opened, enters the :left state if the channel detaches](./spec/acceptance/realtime/presence_spec.rb#L725)
    * #enter
      * data attribute
        * when provided as argument option to #enter
          * [changes to value provided in #leave](./spec/acceptance/realtime/presence_spec.rb#L750)
      * message #connection_id
        * [matches the current client connection_id](./spec/acceptance/realtime/presence_spec.rb#L774)
      * without necessary capabilities to join presence
        * [calls the Deferrable errback on capabilities failure](./spec/acceptance/realtime/presence_spec.rb#L793)
      * it should behave like a public presence method
        * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L54)
        * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L66)
        * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L77)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L234)
        * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L241)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L249)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L259)
        * when :queue_messages client option is false
          * and connection state initialized
            * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L89)
          * and connection state connecting
            * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L97)
          * and connection state disconnected
            * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L110)
          * and connection state connected
            * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L123)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L150)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L160)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L170)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L180)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L200)
          * Float
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L209)
          * Boolean
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L218)
          * False
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L227)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L271)
    * #update
      * [without previous #enter automatically enters](./spec/acceptance/realtime/presence_spec.rb#L805)
      * [updates the data if :data argument provided](./spec/acceptance/realtime/presence_spec.rb#L830)
      * [updates the data to nil if :data argument is not provided (assumes nil value)](./spec/acceptance/realtime/presence_spec.rb#L840)
      * when ENTERED
        * [has no effect on the state](./spec/acceptance/realtime/presence_spec.rb#L815)
      * it should behave like a public presence method
        * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L54)
        * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L66)
        * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L77)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L234)
        * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L241)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L249)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L259)
        * when :queue_messages client option is false
          * and connection state initialized
            * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L89)
          * and connection state connecting
            * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L97)
          * and connection state disconnected
            * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L110)
          * and connection state connected
            * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L123)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L150)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L160)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L170)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L180)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L200)
          * Float
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L209)
          * Boolean
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L218)
          * False
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L227)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L271)
    * #leave
      * [raises an exception if not entered](./spec/acceptance/realtime/presence_spec.rb#L914)
      * :data option
        * when set to a string
          * [emits the new data for the leave event](./spec/acceptance/realtime/presence_spec.rb#L859)
        * when set to nil
          * [emits the last value for the data attribute when leaving](./spec/acceptance/realtime/presence_spec.rb#L872)
        * when not passed as an argument (i.e. nil)
          * [emits the previous value for the data attribute when leaving](./spec/acceptance/realtime/presence_spec.rb#L885)
        * and sync is complete
          * [does not cache members that have left](./spec/acceptance/realtime/presence_spec.rb#L898)
      * it should behave like a public presence method
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L234)
        * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L241)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L249)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L259)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L150)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L160)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L170)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L180)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L200)
          * Float
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L209)
          * Boolean
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L218)
          * False
            * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L227)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L271)
    * :left event
      * [emits the data defined in enter](./spec/acceptance/realtime/presence_spec.rb#L923)
      * [emits the data defined in update](./spec/acceptance/realtime/presence_spec.rb#L934)
    * entering/updating/leaving presence state on behalf of another client_id
      * #enter_client
        * multiple times on the same channel with different client_ids
          * [has no affect on the client's presence state and only enters on behalf of the provided client_id](./spec/acceptance/realtime/presence_spec.rb#L957)
          * [enters a channel and sets the data based on the provided :data option](./spec/acceptance/realtime/presence_spec.rb#L971)
        * message #connection_id
          * [matches the current client connection_id](./spec/acceptance/realtime/presence_spec.rb#L990)
        * without necessary capabilities to enter on behalf of another client
          * [calls the Deferrable errback on capabilities failure](./spec/acceptance/realtime/presence_spec.rb#L1010)
        * it should behave like a public presence method
          * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L54)
          * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L66)
          * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L77)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L234)
          * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L241)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L249)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L259)
          * when :queue_messages client option is false
            * and connection state initialized
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L89)
            * and connection state connecting
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L97)
            * and connection state disconnected
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L110)
            * and connection state connected
              * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L123)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L150)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L160)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L170)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L180)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L200)
            * Float
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L209)
            * Boolean
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L218)
            * False
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L227)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L271)
        * it should behave like a presence on behalf of another client method
          * :enter_client when authenticated with a wildcard client_id
            * and a valid client_id
              * [succeeds](./spec/acceptance/realtime/presence_spec.rb#L302)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L312)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L319)
          * :enter_client when authenticated with a valid client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L335)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L344)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L354)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L361)
          * :enter_client when anonymous and no client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L377)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L386)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L396)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L403)
      * #update_client
        * multiple times on the same channel with different client_ids
          * [updates the data attribute for the member when :data option provided](./spec/acceptance/realtime/presence_spec.rb#L1024)
          * [updates the data attribute to null for the member when :data option is not provided (assumed null)](./spec/acceptance/realtime/presence_spec.rb#L1048)
          * [enters if not already entered](./spec/acceptance/realtime/presence_spec.rb#L1060)
        * it should behave like a public presence method
          * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L54)
          * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L66)
          * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L77)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L234)
          * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L241)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L249)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L259)
          * when :queue_messages client option is false
            * and connection state initialized
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L89)
            * and connection state connecting
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L97)
            * and connection state disconnected
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L110)
            * and connection state connected
              * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L123)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L150)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L160)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L170)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L180)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L200)
            * Float
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L209)
            * Boolean
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L218)
            * False
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L227)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L271)
        * it should behave like a presence on behalf of another client method
          * :update_client when authenticated with a wildcard client_id
            * and a valid client_id
              * [succeeds](./spec/acceptance/realtime/presence_spec.rb#L302)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L312)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L319)
          * :update_client when authenticated with a valid client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L335)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L344)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L354)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L361)
          * :update_client when anonymous and no client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L377)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L386)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L396)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L403)
      * #leave_client
        * leaves a channel
          * multiple times on the same channel with different client_ids
            * [emits the :leave event for each client_id](./spec/acceptance/realtime/presence_spec.rb#L1090)
            * [succeeds if that client_id has not previously entered the channel](./spec/acceptance/realtime/presence_spec.rb#L1114)
          * with a new value in :data option
            * [emits the leave event with the new data value](./spec/acceptance/realtime/presence_spec.rb#L1138)
          * with a nil value in :data option
            * [emits the leave event with the previous value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L1151)
          * with no :data option
            * [emits the leave event with the previous value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L1164)
        * it should behave like a public presence method
          * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L54)
          * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L66)
          * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L77)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L234)
          * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L241)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L249)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L259)
          * when :queue_messages client option is false
            * and connection state initialized
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L89)
            * and connection state connecting
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L97)
            * and connection state disconnected
              * [raises an exception](./spec/acceptance/realtime/presence_spec.rb#L110)
            * and connection state connected
              * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L123)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L150)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L160)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L170)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L180)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L200)
            * Float
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L209)
            * Boolean
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L218)
            * False
              * [raises an UnsupportedDataType 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L227)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L271)
        * it should behave like a presence on behalf of another client method
          * :leave_client when authenticated with a wildcard client_id
            * and a valid client_id
              * [succeeds](./spec/acceptance/realtime/presence_spec.rb#L302)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L312)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L319)
          * :leave_client when authenticated with a valid client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L335)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L344)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L354)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L361)
          * :leave_client when anonymous and no client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L377)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L386)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L396)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L403)
    * #get
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L1183)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L1188)
      * [catches exceptions in the provided method block](./spec/acceptance/realtime/presence_spec.rb#L1195)
      * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L1202)
      * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L1212)
      * [returns the current members on the channel](./spec/acceptance/realtime/presence_spec.rb#L1292)
      * [filters by connection_id option if provided](./spec/acceptance/realtime/presence_spec.rb#L1307)
      * [filters by client_id option if provided](./spec/acceptance/realtime/presence_spec.rb#L1329)
      * [does not wait for SYNC to complete if :wait_for_sync option is false](./spec/acceptance/realtime/presence_spec.rb#L1353)
      * during a sync
        * when :wait_for_sync is true
          * [fails if the connection fails](./spec/acceptance/realtime/presence_spec.rb#L1243)
          * [fails if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L1266)
      * when a member enters and then leaves
        * [has no members](./spec/acceptance/realtime/presence_spec.rb#L1363)
      * with lots of members on different clients
        * [returns a complete list of members on all clients](./spec/acceptance/realtime/presence_spec.rb#L1382)
    * #subscribe
      * [implicitly attaches](./spec/acceptance/realtime/presence_spec.rb#L1457)
      * with no arguments
        * [calls the callback for all presence events](./spec/acceptance/realtime/presence_spec.rb#L1418)
      * with event name
        * [calls the callback for specified presence event](./spec/acceptance/realtime/presence_spec.rb#L1438)
    * #unsubscribe
      * with no arguments
        * [removes the callback for all presence events](./spec/acceptance/realtime/presence_spec.rb#L1470)
      * with event name
        * [removes the callback for specified presence event](./spec/acceptance/realtime/presence_spec.rb#L1488)
    * REST #get
      * [returns current members](./spec/acceptance/realtime/presence_spec.rb#L1507)
      * [returns no members once left](./spec/acceptance/realtime/presence_spec.rb#L1520)
    * client_id with ASCII_8BIT
      * in connection set up
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L1537)
      * in channel options
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L1550)
    * encoding and decoding of presence message data
      * [encrypts presence message data](./spec/acceptance/realtime/presence_spec.rb#L1576)
      * #subscribe
        * [emits decrypted enter events](./spec/acceptance/realtime/presence_spec.rb#L1595)
        * [emits decrypted update events](./spec/acceptance/realtime/presence_spec.rb#L1607)
        * [emits previously set data for leave events](./spec/acceptance/realtime/presence_spec.rb#L1621)
      * #get
        * [returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L1637)
      * REST #get
        * [returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L1650)
      * when cipher settings do not match publisher
        * [delivers an unencoded presence message left with encoding value](./spec/acceptance/realtime/presence_spec.rb#L1665)
        * [emits an error when cipher does not match and presence data cannot be decoded](./spec/acceptance/realtime/presence_spec.rb#L1678)
    * leaving
      * [expect :left event once underlying connection is closed](./spec/acceptance/realtime/presence_spec.rb#L1695)
      * [expect :left event with client data from enter event](./spec/acceptance/realtime/presence_spec.rb#L1705)
    * connection failure mid-way through a large member sync
      * [resumes the SYNC operation](./spec/acceptance/realtime/presence_spec.rb#L1724)

### Ably::Realtime::Client#stats
_(see [spec/acceptance/realtime/stats_spec.rb](./spec/acceptance/realtime/stats_spec.rb))_
  * using JSON protocol
    * fetching stats
      * [returns a PaginatedResult](./spec/acceptance/realtime/stats_spec.rb#L10)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/stats_spec.rb#L29)
      * with options
        * [passes the option arguments to the REST stat method](./spec/acceptance/realtime/stats_spec.rb#L20)

### Ably::Realtime::Client#time
_(see [spec/acceptance/realtime/time_spec.rb](./spec/acceptance/realtime/time_spec.rb))_
  * using JSON protocol
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/realtime/time_spec.rb#L10)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/time_spec.rb#L19)
      * with reconfigured HTTP timeout
        * [should raise a timeout exception](./spec/acceptance/realtime/time_spec.rb#L31)

### Ably::Auth
_(see [spec/acceptance/rest/auth_spec.rb](./spec/acceptance/rest/auth_spec.rb))_
  * using JSON protocol
    * [has immutable options](./spec/acceptance/rest/auth_spec.rb#L60)
    * #request_token
      * [creates a TokenRequest automatically and sends it to Ably to obtain a token](./spec/acceptance/rest/auth_spec.rb#L75)
      * [returns a valid TokenDetails object in the expected format with valid issued and expires attributes](./spec/acceptance/rest/auth_spec.rb#L84)
      * with token_param :client_id
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L117)
      * with token_param :capability
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L117)
      * with token_param :nonce
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L117)
      * with token_param :timestamp
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L117)
      * with token_param :ttl
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L117)
      * with :key option
        * [key_name is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L147)
      * with :key_name & :key_secret options
        * [key_name is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L177)
      * with :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L185)
      * without :query_time option
        * [does not query the server for the time](./spec/acceptance/rest/auth_spec.rb#L194)
      * with :auth_url option merging
        * with existing configured auth options
          * using unspecified :auth_method
            * [requests a token using a GET request with provided headers, and merges client_id into auth_params](./spec/acceptance/rest/auth_spec.rb#L234)
            * with provided token_params
              * [merges provided token_params with existing auth_params and client_id](./spec/acceptance/rest/auth_spec.rb#L242)
            * with provided auth option auth_params and auth_headers
              * [replaces any preconfigured auth_params](./spec/acceptance/rest/auth_spec.rb#L250)
          * using :get :auth_method and query params in the URL
            * [requests a token using a GET request with provided headers, and merges client_id into auth_params and existing URL querystring into new URL querystring](./spec/acceptance/rest/auth_spec.rb#L261)
          * using :post :auth_method
            * [requests a token using a POST request with provided headers, and merges client_id into auth_params as form-encoded post data](./spec/acceptance/rest/auth_spec.rb#L271)
      * with :auth_url option
        * when response from :auth_url is a valid token request
          * [requests a token from :auth_url using an HTTP GET request](./spec/acceptance/rest/auth_spec.rb#L321)
          * [returns a valid token generated from the token request](./spec/acceptance/rest/auth_spec.rb#L326)
          * with :query_params
            * [requests a token from :auth_url with the :query_params](./spec/acceptance/rest/auth_spec.rb#L333)
          * with :headers
            * [requests a token from :auth_url with the HTTP headers set](./spec/acceptance/rest/auth_spec.rb#L341)
          * with POST
            * [requests a token from :auth_url using an HTTP POST instead of the default GET](./spec/acceptance/rest/auth_spec.rb#L349)
        * when response from :auth_url is a token details object
          * [returns TokenDetails created from the token JSON](./spec/acceptance/rest/auth_spec.rb#L374)
        * when response from :auth_url is text/plain content type and a token string
          * [returns TokenDetails created from the token JSON](./spec/acceptance/rest/auth_spec.rb#L392)
        * when response is invalid
          * 500
            * [raises ServerError](./spec/acceptance/rest/auth_spec.rb#L406)
          * XML
            * [raises InvalidResponseBody](./spec/acceptance/rest/auth_spec.rb#L417)
      * with a Proc for the :auth_callback option
        * that returns a TokenRequest
          * [calls the Proc with token_params when authenticating to obtain the request token](./spec/acceptance/rest/auth_spec.rb#L440)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L444)
          * when authorised
            * [sets Auth#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L451)
            * [sets Client#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L455)
        * that returns a TokenDetails JSON object
          * [calls the Proc when authenticating to obtain the request token](./spec/acceptance/rest/auth_spec.rb#L489)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L494)
          * when authorised
            * [sets Auth#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L506)
            * [sets Client#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L510)
        * that returns a TokenDetails object
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L525)
        * that returns a Token string
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L541)
      * with auth_option :client_id
        * [returns a token with the client_id](./spec/acceptance/rest/auth_spec.rb#L571)
      * with token_param :client_id
        * [returns a token with the client_id](./spec/acceptance/rest/auth_spec.rb#L580)
    * before #authorise has been called
      * [has no current_token_details](./spec/acceptance/rest/auth_spec.rb#L587)
    * #authorise
      * [updates the persisted token params that are then used for subsequent authorise requests](./spec/acceptance/rest/auth_spec.rb#L637)
      * [updates the persisted token params that are then used for subsequent authorise requests](./spec/acceptance/rest/auth_spec.rb#L643)
      * when called for the first time since the client has been instantiated
        * [passes all auth_options and token_params to #request_token](./spec/acceptance/rest/auth_spec.rb#L601)
        * [returns a valid token](./spec/acceptance/rest/auth_spec.rb#L606)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L610)
      * with previous authorisation
        * [does not request a token if current_token_details has not expired](./spec/acceptance/rest/auth_spec.rb#L621)
        * [requests a new token if token is expired](./spec/acceptance/rest/auth_spec.rb#L626)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L632)
      * with a Proc for the :auth_callback option
        * [calls the Proc](./spec/acceptance/rest/auth_spec.rb#L659)
        * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L663)
        * for every subsequent #request_token
          * without a :auth_callback Proc
            * [calls the originally provided block](./spec/acceptance/rest/auth_spec.rb#L669)
          * with a provided block
            * [does not call the originally provided Proc and calls the new #request_token :auth_callback Proc](./spec/acceptance/rest/auth_spec.rb#L676)
      * with an explicit token string that expires
        * and a Proc for the :auth_callback option to provide a means to renew the token
          * [calls the Proc once the token has expired and the new token is used](./spec/acceptance/rest/auth_spec.rb#L703)
      * with an explicit ClientOptions client_id
        * and an incompatible client_id in a TokenDetails object passed to the auth callback
          * [rejects a TokenDetails object with an incompatible client_id and raises an exception](./spec/acceptance/rest/auth_spec.rb#L721)
        * and an incompatible client_id in a TokenRequest object passed to the auth callback and raises an exception
          * [rejects a TokenRequests object with an incompatible client_id and raises an exception](./spec/acceptance/rest/auth_spec.rb#L729)
        * and a token string without any retrievable client_id
          * [rejects a TokenRequests object with an incompatible client_id and raises an exception](./spec/acceptance/rest/auth_spec.rb#L737)
    * #create_token_request
      * [returns a TokenRequest object](./spec/acceptance/rest/auth_spec.rb#L752)
      * [returns a TokenRequest that can be passed to a client that can use it for authentication without an API key](./spec/acceptance/rest/auth_spec.rb#L756)
      * [uses the key name from the client](./spec/acceptance/rest/auth_spec.rb#L763)
      * [uses the default TTL](./spec/acceptance/rest/auth_spec.rb#L767)
      * [uses the default capability](./spec/acceptance/rest/auth_spec.rb#L780)
      * with a :ttl option below the Token expiry buffer that ensures tokens are renewed 15s before they expire as they are considered expired
        * [uses the Token expiry buffer default + 10s to allow for a token request in flight](./spec/acceptance/rest/auth_spec.rb#L774)
      * the nonce
        * [is unique for every request](./spec/acceptance/rest/auth_spec.rb#L785)
        * [is at least 16 characters](./spec/acceptance/rest/auth_spec.rb#L790)
      * with token param :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L801)
      * with token param :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L801)
      * with token param :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L801)
      * when specifying capability
        * [overrides the default](./spec/acceptance/rest/auth_spec.rb#L812)
        * [uses these capabilities when Ably issues an actual token](./spec/acceptance/rest/auth_spec.rb#L816)
      * with additional invalid attributes
        * [are ignored](./spec/acceptance/rest/auth_spec.rb#L826)
      * when required fields are missing
        * [should raise an exception if key secret is missing](./spec/acceptance/rest/auth_spec.rb#L837)
        * [should raise an exception if key name is missing](./spec/acceptance/rest/auth_spec.rb#L841)
      * timestamp attribute
        * [is a Time object in Ruby and is set to the local time](./spec/acceptance/rest/auth_spec.rb#L868)
        * with :query_time auth_option
          * [queries the server for the timestamp](./spec/acceptance/rest/auth_spec.rb#L853)
        * with :timestamp option
          * [uses the provided timestamp in the token request](./spec/acceptance/rest/auth_spec.rb#L863)
      * signing
        * [generates a valid HMAC](./spec/acceptance/rest/auth_spec.rb#L892)
    * using token authentication
      * with :token option
        * [authenticates successfully using the provided :token](./spec/acceptance/rest/auth_spec.rb#L915)
        * [disallows publishing on unspecified capability channels](./spec/acceptance/rest/auth_spec.rb#L919)
        * [fails if timestamp is invalid](./spec/acceptance/rest/auth_spec.rb#L927)
        * [cannot be renewed automatically](./spec/acceptance/rest/auth_spec.rb#L935)
      * when implicit as a result of using :client_id
        * and requests to the Ably server are mocked
          * [will send a token request to the server](./spec/acceptance/rest/auth_spec.rb#L963)
        * a token is created
          * [before a request is made](./spec/acceptance/rest/auth_spec.rb#L972)
          * [when a message is published](./spec/acceptance/rest/auth_spec.rb#L976)
          * [with capability and TTL defaults](./spec/acceptance/rest/auth_spec.rb#L980)
          * [#client_id contains the client_id](./spec/acceptance/rest/auth_spec.rb#L991)
      * when :client_id is provided in a token
        * [#client_id contains the client_id](./spec/acceptance/rest/auth_spec.rb#L1006)
    * #client_id_validated?
      * when using basic auth
        * [is false as basic auth users do not have an identity](./spec/acceptance/rest/auth_spec.rb#L1018)
      * when using a token auth string for a token with a client_id
        * [is false as identification is not possible from an opaque token string](./spec/acceptance/rest/auth_spec.rb#L1026)
      * when using a token
        * with a client_id
          * [is true](./spec/acceptance/rest/auth_spec.rb#L1035)
        * with no client_id (anonymous)
          * [is true](./spec/acceptance/rest/auth_spec.rb#L1043)
        * with a wildcard client_id (anonymous)
          * [is false](./spec/acceptance/rest/auth_spec.rb#L1051)
      * when using a token request with a client_id
        * [is not true as identification is not confirmed until authenticated](./spec/acceptance/rest/auth_spec.rb#L1060)
        * after authentication
          * [is true as identification is completed during implicit authentication](./spec/acceptance/rest/auth_spec.rb#L1067)
    * when using a :key and basic auth
      * [#using_token_auth? is false](./spec/acceptance/rest/auth_spec.rb#L1075)
      * [#key attribute contains the key string](./spec/acceptance/rest/auth_spec.rb#L1079)
      * [#using_basic_auth? is true](./spec/acceptance/rest/auth_spec.rb#L1083)

### Ably::Rest
_(see [spec/acceptance/rest/base_spec.rb](./spec/acceptance/rest/base_spec.rb))_
  * transport protocol
    * when protocol is not defined it defaults to :msgpack
      * [uses MsgPack](./spec/acceptance/rest/base_spec.rb#L27)
    * when option {:protocol=>:json} is used
      * [uses JSON](./spec/acceptance/rest/base_spec.rb#L43)
    * when option {:use_binary_protocol=>false} is used
      * [uses JSON](./spec/acceptance/rest/base_spec.rb#L43)
    * when option {:protocol=>:msgpack} is used
      * [uses MsgPack](./spec/acceptance/rest/base_spec.rb#L60)
    * when option {:use_binary_protocol=>true} is used
      * [uses MsgPack](./spec/acceptance/rest/base_spec.rb#L60)
  * using JSON protocol
    * failed requests
      * due to invalid Auth
        * [should raise an InvalidRequest exception with a valid error message and code](./spec/acceptance/rest/base_spec.rb#L75)
      * server error with JSON error response body
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L94)
      * 500 server error without a valid JSON response body
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L105)
    * token authentication failures
      * when auth#token_renewable?
        * [should automatically reissue a token](./spec/acceptance/rest/base_spec.rb#L143)
      * when NOT auth#token_renewable?
        * [should raise an TokenExpired exception](./spec/acceptance/rest/base_spec.rb#L158)

### Ably::Rest::Channel
_(see [spec/acceptance/rest/channel_spec.rb](./spec/acceptance/rest/channel_spec.rb))_
  * using JSON protocol
    * #publish
      * with name and data arguments
        * [publishes the message and return true indicating success](./spec/acceptance/rest/channel_spec.rb#L21)
        * and additional attributes
          * [publishes the message with the attributes and return true indicating success](./spec/acceptance/rest/channel_spec.rb#L30)
      * with a client_id configured in the ClientOptions
        * [publishes the message without a client_id](./spec/acceptance/rest/channel_spec.rb#L41)
        * [expects a client_id to be added by the realtime service](./spec/acceptance/rest/channel_spec.rb#L49)
      * with an array of Hash objects with :name and :data attributes
        * [publishes an array of messages in one HTTP request](./spec/acceptance/rest/channel_spec.rb#L62)
      * with an array of Message objects
        * [publishes an array of messages in one HTTP request](./spec/acceptance/rest/channel_spec.rb#L77)
      * without adequate permissions on the channel
        * [raises a permission error when publishing](./spec/acceptance/rest/channel_spec.rb#L89)
      * null attributes
        * when name is null
          * [publishes the message without a name attribute in the payload](./spec/acceptance/rest/channel_spec.rb#L98)
        * when data is null
          * [publishes the message without a data attribute in the payload](./spec/acceptance/rest/channel_spec.rb#L109)
        * with neither name or data attributes
          * [publishes the message without any attributes in the payload](./spec/acceptance/rest/channel_spec.rb#L120)
      * identified clients
        * when authenticated with a wildcard client_id
          * with a valid client_id in the message
            * [succeeds](./spec/acceptance/rest/channel_spec.rb#L137)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L146)
          * with an empty client_id in the message
            * [succeeds and publishes without a client_id](./spec/acceptance/rest/channel_spec.rb#L152)
        * when authenticated with a Token string with an implicit client_id
          * without having a confirmed identity
            * with a valid client_id in the message
              * [succeeds](./spec/acceptance/rest/channel_spec.rb#L169)
            * with an invalid client_id in the message
              * [succeeds in the client library but then fails when published to Ably](./spec/acceptance/rest/channel_spec.rb#L178)
            * with an empty client_id in the message
              * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L184)
        * when authenticated with TokenDetails with a valid client_id
          * with a valid client_id in the message
            * [succeeds](./spec/acceptance/rest/channel_spec.rb#L201)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L210)
          * with an invalid client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L216)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L222)
        * when anonymous and no client_id
          * with a client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L238)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L244)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L250)
    * #history
      * [returns a PaginatedResult model](./spec/acceptance/rest/channel_spec.rb#L278)
      * [returns the current message history for the channel](./spec/acceptance/rest/channel_spec.rb#L282)
      * [returns paged history using the PaginatedResult model](./spec/acceptance/rest/channel_spec.rb#L310)
      * message timestamps
        * [are after the messages were published](./spec/acceptance/rest/channel_spec.rb#L295)
      * message IDs
        * [is unique](./spec/acceptance/rest/channel_spec.rb#L303)
      * direction
        * [returns paged history backwards by default](./spec/acceptance/rest/channel_spec.rb#L331)
        * [returns history forward if specified in the options](./spec/acceptance/rest/channel_spec.rb#L337)
      * limit
        * [defaults to 100](./spec/acceptance/rest/channel_spec.rb#L349)
    * #history option
      * :start
        * with milliseconds since epoch value
          * [uses this value in the history request](./spec/acceptance/rest/channel_spec.rb#L392)
        * with a Time object value
          * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/channel_spec.rb#L402)
      * :end
        * with milliseconds since epoch value
          * [uses this value in the history request](./spec/acceptance/rest/channel_spec.rb#L392)
        * with a Time object value
          * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/channel_spec.rb#L402)
      * when argument start is after end
        * [should raise an exception](./spec/acceptance/rest/channel_spec.rb#L412)
    * #presence
      * [returns a REST Presence object](./spec/acceptance/rest/channel_spec.rb#L422)

### Ably::Rest::Channels
_(see [spec/acceptance/rest/channels_spec.rb](./spec/acceptance/rest/channels_spec.rb))_
  * using JSON protocol
    * using shortcut method #channel on the client object
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)
    * using #get method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)
    * accessing an existing channel object with different options
      * [overrides the existing channel options and returns the channel object](./spec/acceptance/rest/channels_spec.rb#L39)
    * accessing an existing channel object without specifying any channel options
      * [returns the existing channel without modifying the channel options](./spec/acceptance/rest/channels_spec.rb#L50)
    * using undocumented array accessor [] method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)

### Ably::Rest::Client
_(see [spec/acceptance/rest/client_spec.rb](./spec/acceptance/rest/client_spec.rb))_
  * using JSON protocol
    * #initialize
      * with only an API key
        * [uses basic authentication](./spec/acceptance/rest/client_spec.rb#L24)
      * with an explicit string :token
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L32)
      * with :use_token_auth set to true
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L40)
      * with a :client_id configured
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L48)
      * with an invalid wildcard "*" :client_id
        * [raises an exception](./spec/acceptance/rest/client_spec.rb#L54)
      * with an :auth_callback Proc
        * [calls the auth Proc to get a new token](./spec/acceptance/rest/client_spec.rb#L62)
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L67)
      * with an :auth_callback Proc (clientId provided in library options instead of as a token_request param)
        * [correctly sets the clientId on the token](./spec/acceptance/rest/client_spec.rb#L76)
      * with an auth URL
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L86)
        * before any REST request
          * [sends an HTTP request to the provided auth URL to get a new token](./spec/acceptance/rest/client_spec.rb#L97)
      * auth headers
        * with basic auth
          * [sends the API key in authentication part of the secure URL (the Authorization: Basic header is not used with the Faraday HTTP library by default)](./spec/acceptance/rest/client_spec.rb#L117)
        * with token auth
          * without specifying protocol
            * [sends the token string over HTTPS in the Authorization Bearer header with Base64 encoding](./spec/acceptance/rest/client_spec.rb#L136)
          * when setting constructor ClientOption :tls to false
            * [sends the token string over HTTP in the Authorization Bearer header with Base64 encoding](./spec/acceptance/rest/client_spec.rb#L146)
    * using tokens
      * when expired
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L179)
        * with a different client_id in the subsequent token
          * [fails to authenticate and raises an exception](./spec/acceptance/rest/client_spec.rb#L192)
      * when token has not expired
        * [reuses the existing token for every request](./spec/acceptance/rest/client_spec.rb#L203)
    * connection transport
      * defaults
        * for default host
          * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L220)
          * [is configured to timeout connection requests in 15 seconds](./spec/acceptance/rest/client_spec.rb#L224)
        * for the fallback hosts
          * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L230)
          * [is configured to timeout connection requests in 15 seconds](./spec/acceptance/rest/client_spec.rb#L234)
      * with custom http_open_timeout and http_request_timeout options
        * for default host
          * [is configured to use custom open timeout](./spec/acceptance/rest/client_spec.rb#L246)
          * [is configured to use custom request timeout](./spec/acceptance/rest/client_spec.rb#L250)
        * for the fallback hosts
          * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L256)
          * [is configured to timeout connection requests in 15 seconds](./spec/acceptance/rest/client_spec.rb#L260)
    * fallback hosts
      * configured
        * [should make connection attempts to A.ably-realtime.com, B.ably-realtime.com, C.ably-realtime.com, D.ably-realtime.com, E.ably-realtime.com](./spec/acceptance/rest/client_spec.rb#L274)
      * when environment is NOT production
        * [does not retry failed requests with fallback hosts when there is a connection error](./spec/acceptance/rest/client_spec.rb#L291)
      * when environment is production
        * and connection times out
          * [tries fallback hosts 3 times](./spec/acceptance/rest/client_spec.rb#L329)
          * and the total request time exeeds 10 seconds
            * [makes no further attempts to any fallback hosts](./spec/acceptance/rest/client_spec.rb#L344)
        * and connection fails
          * [tries fallback hosts 3 times](./spec/acceptance/rest/client_spec.rb#L360)
        * and basic authentication fails
          * [does not attempt the fallback hosts as this is an authentication failure](./spec/acceptance/rest/client_spec.rb#L384)
        * and server returns a 50x error
          * [attempts the fallback hosts as this is an authentication failure](./spec/acceptance/rest/client_spec.rb#L406)
    * with a custom host
      * that does not exist
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L422)
        * fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L443)
      * that times out
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L458)
        * fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L471)
    * HTTP configuration options
      * [is frozen](./spec/acceptance/rest/client_spec.rb#L528)
      * defaults
        * [#http_open_timeout is 4s](./spec/acceptance/rest/client_spec.rb#L483)
        * [#http_request_timeout is 15s](./spec/acceptance/rest/client_spec.rb#L487)
        * [#http_max_retry_count is 3](./spec/acceptance/rest/client_spec.rb#L491)
        * [#http_max_retry_duration is 10s](./spec/acceptance/rest/client_spec.rb#L495)
      * configured
        * [#http_open_timeout uses provided value](./spec/acceptance/rest/client_spec.rb#L511)
        * [#http_request_timeout uses provided value](./spec/acceptance/rest/client_spec.rb#L515)
        * [#http_max_retry_count uses provided value](./spec/acceptance/rest/client_spec.rb#L519)
        * [#http_max_retry_duration uses provided value](./spec/acceptance/rest/client_spec.rb#L523)
    * #auth
      * [is provides access to the Auth object](./spec/acceptance/rest/client_spec.rb#L539)
      * [configures the Auth object with all ClientOptions passed to client in the initializer](./spec/acceptance/rest/client_spec.rb#L543)

### Ably::Models::MessageEncoders
_(see [spec/acceptance/rest/encoders_spec.rb](./spec/acceptance/rest/encoders_spec.rb))_
  * with binary transport protocol
    * without encryption
      * with UTF-8 data
        * [does not apply any encoding](./spec/acceptance/rest/encoders_spec.rb#L41)
      * with binary data
        * [does not apply any encoding](./spec/acceptance/rest/encoders_spec.rb#L52)
      * with JSON data
        * [stringifies the JSON and sets the encoding attribute to "json"](./spec/acceptance/rest/encoders_spec.rb#L63)
    * with encryption
      * with UTF-8 data
        * [applies utf-8 and cipher encoding and sets the encoding attribute to "utf-8/cipher+aes-128-cbc"](./spec/acceptance/rest/encoders_spec.rb#L78)
      * with binary data
        * [applies cipher encoding and sets the encoding attribute to "cipher+aes-128-cbc"](./spec/acceptance/rest/encoders_spec.rb#L89)
      * with JSON data
        * [applies json, utf-8 and cipher encoding and sets the encoding attribute to "json/utf-8/cipher+aes-128-cbc"](./spec/acceptance/rest/encoders_spec.rb#L100)
  * with text transport protocol
    * without encryption
      * with UTF-8 data
        * [does not apply any encoding](./spec/acceptance/rest/encoders_spec.rb#L117)
      * with binary data
        * [applies a base64 encoding and sets the encoding attribute to "base64"](./spec/acceptance/rest/encoders_spec.rb#L128)
      * with JSON data
        * [stringifies the JSON and sets the encoding attribute to "json"](./spec/acceptance/rest/encoders_spec.rb#L139)
    * with encryption
      * with UTF-8 data
        * [applies utf-8, cipher and base64 encodings and sets the encoding attribute to "utf-8/cipher+aes-128-cbc/base64"](./spec/acceptance/rest/encoders_spec.rb#L154)
      * with binary data
        * [applies cipher and base64 encoding and sets the encoding attribute to "cipher+aes-128-cbc/base64"](./spec/acceptance/rest/encoders_spec.rb#L165)
      * with JSON data
        * [applies json, utf-8, cipher and base64 encoding and sets the encoding attribute to "json/utf-8/cipher+aes-128-cbc/base64"](./spec/acceptance/rest/encoders_spec.rb#L176)

### Ably::Rest::Channel messages
_(see [spec/acceptance/rest/message_spec.rb](./spec/acceptance/rest/message_spec.rb))_
  * using JSON protocol
    * publishing with an ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/rest/message_spec.rb#L18)
    * with supported data payload content type
      * JSON Object (Hash)
        * [is encoded and decoded to the same hash](./spec/acceptance/rest/message_spec.rb#L30)
      * JSON Array
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L39)
      * String
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L48)
      * Binary
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L57)
    * with unsupported data payload content type
      * Integer
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/rest/message_spec.rb#L68)
      * Float
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/rest/message_spec.rb#L76)
      * Boolean
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/rest/message_spec.rb#L84)
      * False
        * [is raises an UnsupportedDataType 40011 exception](./spec/acceptance/rest/message_spec.rb#L92)
    * encryption and encoding
      * with #publish and #history
        * with AES-128-CBC using crypto-data-128.json fixtures
          * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
          * item 1 with encrypted encoding cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
        * with AES-256-CBC using crypto-data-256.json fixtures
          * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
          * item 1 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L137)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L152)
        * when publishing lots of messages
          * [encrypts on #publish and decrypts on #history](./spec/acceptance/rest/message_spec.rb#L185)
        * when retrieving #history with a different protocol
          * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/rest/message_spec.rb#L212)
          * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/rest/message_spec.rb#L212)
          * [delivers a Hash payload to the receiver](./spec/acceptance/rest/message_spec.rb#L212)
        * when publishing on an unencrypted channel and retrieving with #history on an encrypted channel
          * [does not attempt to decrypt the message](./spec/acceptance/rest/message_spec.rb#L228)
        * when publishing on an encrypted channel and retrieving with #history on an unencrypted channel
          * [retrieves the message that remains encrypted with an encrypted encoding attribute](./spec/acceptance/rest/message_spec.rb#L249)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L255)
        * publishing on an encrypted channel and retrieving #history with a different algorithm on another client
          * [retrieves the message that remains encrypted with an encrypted encoding attribute](./spec/acceptance/rest/message_spec.rb#L276)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L282)
        * publishing on an encrypted channel and subscribing with a different key on another client
          * [retrieves the message that remains encrypted with an encrypted encoding attribute](./spec/acceptance/rest/message_spec.rb#L303)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L309)

### Ably::Rest::Presence
_(see [spec/acceptance/rest/presence_spec.rb](./spec/acceptance/rest/presence_spec.rb))_
  * using JSON protocol
    * tested against presence fixture data set up in test app
      * #get
        * [returns current members on the channel with their action set to :present](./spec/acceptance/rest/presence_spec.rb#L41)
        * with :limit option
          * [returns a paged response limiting number of members per page](./spec/acceptance/rest/presence_spec.rb#L57)
        * default :limit
          * [defaults to a limit of 100](./spec/acceptance/rest/presence_spec.rb#L89)
        * with :client_id option
          * [returns a list members filtered by the provided client ID](./spec/acceptance/rest/presence_spec.rb#L98)
        * with :connection_id option
          * [returns a list members filtered by the provided connection ID](./spec/acceptance/rest/presence_spec.rb#L109)
          * [returns a list members filtered by the provided connection ID](./spec/acceptance/rest/presence_spec.rb#L113)
      * #history
        * [returns recent presence activity](./spec/acceptance/rest/presence_spec.rb#L122)
        * default behaviour
          * [uses backwards direction](./spec/acceptance/rest/presence_spec.rb#L137)
        * with options
          * direction: :forwards
            * [returns recent presence activity forwards with most recent history last](./spec/acceptance/rest/presence_spec.rb#L149)
          * direction: :backwards
            * [returns recent presence activity backwards with most recent history first](./spec/acceptance/rest/presence_spec.rb#L164)
    * #history
      * with options
        * limit options
          * default
            * [is set to 100](./spec/acceptance/rest/presence_spec.rb#L212)
          * set to 1000
            * [is passes the limit query param value 1000](./spec/acceptance/rest/presence_spec.rb#L225)
        * with time range options
          * :start
            * with milliseconds since epoch value
              * [uses this value in the history request](./spec/acceptance/rest/presence_spec.rb#L255)
            * with Time object value
              * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/presence_spec.rb#L265)
          * :end
            * with milliseconds since epoch value
              * [uses this value in the history request](./spec/acceptance/rest/presence_spec.rb#L255)
            * with Time object value
              * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/presence_spec.rb#L265)
          * when argument start is after end
            * [should raise an exception](./spec/acceptance/rest/presence_spec.rb#L276)
    * decoding
      * with encoded fixture data
        * #history
          * [decodes encoded and encryped presence fixture data automatically](./spec/acceptance/rest/presence_spec.rb#L295)
        * #get
          * [decodes encoded and encryped presence fixture data automatically](./spec/acceptance/rest/presence_spec.rb#L302)
    * decoding permutations using mocked #history
      * valid decodeable content
        * #get
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L358)
        * #history
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L375)
      * invalid data
        * #get
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L406)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L410)
        * #history
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L430)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L434)

### Ably::Rest::Client#stats
_(see [spec/acceptance/rest/stats_spec.rb](./spec/acceptance/rest/stats_spec.rb))_
  * using JSON protocol
    * fetching application stats
      * [returns a PaginatedResult object](./spec/acceptance/rest/stats_spec.rb#L54)
      * by minute
        * with no options
          * [uses the minute interval by default](./spec/acceptance/rest/stats_spec.rb#L66)
        * with :from set to last interval and :limit set to 1
          * [retrieves only one stat](./spec/acceptance/rest/stats_spec.rb#L75)
          * [returns zero value for any missing metrics](./spec/acceptance/rest/stats_spec.rb#L79)
          * [returns all aggregated message data](./spec/acceptance/rest/stats_spec.rb#L84)
          * [returns inbound realtime all data](./spec/acceptance/rest/stats_spec.rb#L89)
          * [returns inbound realtime message data](./spec/acceptance/rest/stats_spec.rb#L94)
          * [returns outbound realtime all data](./spec/acceptance/rest/stats_spec.rb#L99)
          * [returns persisted presence all data](./spec/acceptance/rest/stats_spec.rb#L104)
          * [returns connections all data](./spec/acceptance/rest/stats_spec.rb#L109)
          * [returns channels all data](./spec/acceptance/rest/stats_spec.rb#L114)
          * [returns api_requests data](./spec/acceptance/rest/stats_spec.rb#L119)
          * [returns token_requests data](./spec/acceptance/rest/stats_spec.rb#L124)
          * [returns stat objects with #interval_granularity equal to :minute](./spec/acceptance/rest/stats_spec.rb#L129)
          * [returns stat objects with #interval_id matching :start](./spec/acceptance/rest/stats_spec.rb#L133)
          * [returns stat objects with #interval_time matching :start Time](./spec/acceptance/rest/stats_spec.rb#L137)
        * with :start set to first interval, :limit set to 1 and direction :forwards
          * [returns the first interval stats as stats are provided forwards from :start](./spec/acceptance/rest/stats_spec.rb#L147)
          * [returns 3 pages of stats](./spec/acceptance/rest/stats_spec.rb#L151)
        * with :end set to last interval, :limit set to 1 and direction :backwards
          * [returns the 3rd interval stats first as stats are provided backwards from :end](./spec/acceptance/rest/stats_spec.rb#L163)
          * [returns 3 pages of stats](./spec/acceptance/rest/stats_spec.rb#L167)
        * with :end set to last interval and :limit set to 3 to ensure only last years stats are included
          * the REST API
            * [defaults to direction :backwards](./spec/acceptance/rest/stats_spec.rb#L179)
        * with :end set to previous year interval
          * the REST API
            * [defaults to 100 items for pagination](./spec/acceptance/rest/stats_spec.rb#L191)
      * by hour
        * [should aggregate the stats for that period](./spec/acceptance/rest/stats_spec.rb#L215)
      * by day
        * [should aggregate the stats for that period](./spec/acceptance/rest/stats_spec.rb#L215)
      * by month
        * [should aggregate the stats for that period](./spec/acceptance/rest/stats_spec.rb#L215)
      * when argument start is after end
        * [should raise an exception](./spec/acceptance/rest/stats_spec.rb#L227)

### Ably::Rest::Client#time
_(see [spec/acceptance/rest/time_spec.rb](./spec/acceptance/rest/time_spec.rb))_
  * using JSON protocol
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/rest/time_spec.rb#L10)
      * with reconfigured HTTP timeout
        * [should raise a timeout exception](./spec/acceptance/rest/time_spec.rb#L19)

### Ably::Auth
_(see [spec/unit/auth_spec.rb](./spec/unit/auth_spec.rb))_
  * client_id option
    * with nil value
      * [is permitted](./spec/unit/auth_spec.rb#L20)
    * as UTF_8 string
      * [is permitted](./spec/unit/auth_spec.rb#L28)
      * [remains as UTF-8](./spec/unit/auth_spec.rb#L32)
    * as SHIFT_JIS string
      * [gets converted to UTF-8](./spec/unit/auth_spec.rb#L40)
      * [is compatible with original encoding](./spec/unit/auth_spec.rb#L44)
    * as ASCII_8BIT string
      * [gets converted to UTF-8](./spec/unit/auth_spec.rb#L52)
      * [is compatible with original encoding](./spec/unit/auth_spec.rb#L56)
    * as Integer
      * [raises an argument error](./spec/unit/auth_spec.rb#L64)
  * defaults
    * [should default TTL to 1 hour](./spec/unit/auth_spec.rb#L74)
    * [should default capability to all](./spec/unit/auth_spec.rb#L78)
    * [should have defaults for :ttl and :capability](./spec/unit/auth_spec.rb#L82)

### Ably::Logger
_(see [spec/unit/logger_spec.rb](./spec/unit/logger_spec.rb))_
  * [uses the language provided Logger by default](./spec/unit/logger_spec.rb#L15)
  * with a custom Logger
    * with an invalid interface
      * [raises an exception](./spec/unit/logger_spec.rb#L116)
    * with a valid interface
      * [is used](./spec/unit/logger_spec.rb#L135)

### Ably::Models::ChannelStateChange
_(see [spec/unit/models/channel_state_change_spec.rb](./spec/unit/models/channel_state_change_spec.rb))_
  * #current
    * [is required](./spec/unit/models/channel_state_change_spec.rb#L10)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L14)
  * #previous
    * [is required](./spec/unit/models/channel_state_change_spec.rb#L20)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L24)
  * #reason
    * [is not required](./spec/unit/models/channel_state_change_spec.rb#L30)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L34)
  * invalid attributes
    * [raises an argument error](./spec/unit/models/channel_state_change_spec.rb#L40)

### Ably::Models::CipherParams
_(see [spec/unit/models/cipher_params_spec.rb](./spec/unit/models/cipher_params_spec.rb))_
  * :key missing from constructor
    * [raises an exception](./spec/unit/models/cipher_params_spec.rb#L8)
  * #key
    * with :key in constructor
      * as nil
        * [raises an exception](./spec/unit/models/cipher_params_spec.rb#L20)
      * as a base64 encoded string
        * [is a binary representation of the base64 encoded string](./spec/unit/models/cipher_params_spec.rb#L29)
      * as a URL safe base64 encoded string
        * [is a binary representation of the URL safe base64 encoded string](./spec/unit/models/cipher_params_spec.rb#L40)
      * as a binary encoded string
        * [contains the binary string](./spec/unit/models/cipher_params_spec.rb#L48)
      * with an incompatible :key_length constructor param
        * [raises an exception](./spec/unit/models/cipher_params_spec.rb#L58)
      * with an unsupported :key_length for aes-cbc encryption
        * [raises an exception](./spec/unit/models/cipher_params_spec.rb#L67)
      * with an invalid type
        * [raises an exception](./spec/unit/models/cipher_params_spec.rb#L76)
  * with specified params in the constructor
    * #cipher_type
      * [contains the complete algorithm string as an upper case string](./spec/unit/models/cipher_params_spec.rb#L88)
    * #mode
      * [contains the mode](./spec/unit/models/cipher_params_spec.rb#L94)
    * #algorithm
      * [contains the algorithm](./spec/unit/models/cipher_params_spec.rb#L100)
    * #key_length
      * [contains the key_length](./spec/unit/models/cipher_params_spec.rb#L106)
  * with combined param in the constructor
    * #cipher_type
      * [contains the complete algorithm string as an upper case string](./spec/unit/models/cipher_params_spec.rb#L117)
    * #mode
      * [contains the mode](./spec/unit/models/cipher_params_spec.rb#L123)
    * #algorithm
      * [contains the algorithm](./spec/unit/models/cipher_params_spec.rb#L129)
    * #key_length
      * [contains the key_length](./spec/unit/models/cipher_params_spec.rb#L135)

### Ably::Models::ConnectionDetails
_(see [spec/unit/models/connection_details_spec.rb](./spec/unit/models/connection_details_spec.rb))_
  * behaves like a model
    * attributes
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
      * #connection_key
        * [retrieves attribute :connection_key](./spec/shared/model_behaviour.rb#L15)
      * #max_message_size
        * [retrieves attribute :max_message_size](./spec/shared/model_behaviour.rb#L15)
      * #max_frame_size
        * [retrieves attribute :max_frame_size](./spec/shared/model_behaviour.rb#L15)
      * #max_inbound_rate
        * [retrieves attribute :max_inbound_rate](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * attributes
    * #connection_state_ttl
      * [retrieves attribute :connection_state_ttl and converts it from ms to s](./spec/unit/models/connection_details_spec.rb#L19)
  * ==
    * [is true when attributes are the same](./spec/unit/models/connection_details_spec.rb#L28)
    * [is false when attributes are not the same](./spec/unit/models/connection_details_spec.rb#L33)
    * [is false when class type differs](./spec/unit/models/connection_details_spec.rb#L37)

### Ably::Models::ConnectionStateChange
_(see [spec/unit/models/connection_state_change_spec.rb](./spec/unit/models/connection_state_change_spec.rb))_
  * #current
    * [is required](./spec/unit/models/connection_state_change_spec.rb#L10)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L14)
  * #previous
    * [is required](./spec/unit/models/connection_state_change_spec.rb#L20)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L24)
  * #retry_in
    * [is not required](./spec/unit/models/connection_state_change_spec.rb#L30)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L34)
  * #reason
    * [is not required](./spec/unit/models/connection_state_change_spec.rb#L40)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L44)
  * invalid attributes
    * [raises an argument error](./spec/unit/models/connection_state_change_spec.rb#L50)

### Ably::Models::ErrorInfo
_(see [spec/unit/models/error_info_spec.rb](./spec/unit/models/error_info_spec.rb))_
  * behaves like a model
    * attributes
      * #code
        * [retrieves attribute :code](./spec/shared/model_behaviour.rb#L15)
      * #status_code
        * [retrieves attribute :status_code](./spec/shared/model_behaviour.rb#L15)
      * #message
        * [retrieves attribute :message](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * #status
    * [is an alias for #status_code](./spec/unit/models/error_info_spec.rb#L13)

### Ably::Models::MessageEncoders::Base64
_(see [spec/unit/models/message_encoders/base64_spec.rb](./spec/unit/models/message_encoders/base64_spec.rb))_
  * #decode
    * message with base64 payload
      * [decodes base64](./spec/unit/models/message_encoders/base64_spec.rb#L24)
      * [strips the encoding](./spec/unit/models/message_encoders/base64_spec.rb#L28)
    * message with base64 payload before other payloads
      * [decodes base64](./spec/unit/models/message_encoders/base64_spec.rb#L36)
      * [strips the encoding](./spec/unit/models/message_encoders/base64_spec.rb#L40)
    * message with another payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L48)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L52)
  * #encode
    * over binary transport
      * message with binary payload
        * [leaves the message data intact as Base64 encoding is not necessary](./spec/unit/models/message_encoders/base64_spec.rb#L68)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L72)
      * already encoded message with binary payload
        * [leaves the message data intact as Base64 encoding is not necessary](./spec/unit/models/message_encoders/base64_spec.rb#L80)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L84)
      * message with UTF-8 payload
        * [leaves the data intact](./spec/unit/models/message_encoders/base64_spec.rb#L92)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L96)
      * message with nil payload
        * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L104)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L108)
      * message with empty binary string payload
        * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L116)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L120)
    * over text transport
      * message with binary payload
        * [encodes binary data as base64](./spec/unit/models/message_encoders/base64_spec.rb#L135)
        * [adds the encoding](./spec/unit/models/message_encoders/base64_spec.rb#L139)
      * already encoded message with binary payload
        * [encodes binary data as base64](./spec/unit/models/message_encoders/base64_spec.rb#L147)
        * [adds the encoding](./spec/unit/models/message_encoders/base64_spec.rb#L151)
      * message with UTF-8 payload
        * [leaves the data intact](./spec/unit/models/message_encoders/base64_spec.rb#L159)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L163)
      * message with nil payload
        * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L171)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L175)

### Ably::Models::MessageEncoders::Cipher
_(see [spec/unit/models/message_encoders/cipher_spec.rb](./spec/unit/models/message_encoders/cipher_spec.rb))_
  * #decode
    * with channel set up for AES-128-CBC
      * valid cipher data
        * message with cipher payload
          * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L32)
          * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L36)
        * message with cipher payload before other payloads
          * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L44)
          * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L48)
        * message with binary payload
          * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L56)
          * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L60)
          * [returns ASCII_8BIT encoded binary data](./spec/unit/models/message_encoders/cipher_spec.rb#L64)
        * message with another payload
          * [leaves the message data intact](./spec/unit/models/message_encoders/cipher_spec.rb#L72)
          * [leaves the encoding intact](./spec/unit/models/message_encoders/cipher_spec.rb#L76)
      * 256 bit key
        * with invalid channel_option cipher params
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L90)
        * without any configured encryption
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L100)
      * with invalid cipher data
        * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L110)
    * with AES-256-CBC
      * message with cipher payload
        * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L127)
        * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L131)
  * #encode
    * with channel set up for AES-128-CBC
      * with encrypted set to true
        * message with string payload
          * [encodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L151)
          * [adds the encoding with utf-8](./spec/unit/models/message_encoders/cipher_spec.rb#L156)
        * message with binary payload
          * [encodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L164)
          * [adds the encoding without utf-8 prefixed](./spec/unit/models/message_encoders/cipher_spec.rb#L169)
          * [returns ASCII_8BIT encoded binary data](./spec/unit/models/message_encoders/cipher_spec.rb#L173)
        * message with json payload
          * [encodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L181)
          * [adds the encoding with utf-8](./spec/unit/models/message_encoders/cipher_spec.rb#L186)
        * message with existing cipher encoding before
          * [leaves message intact as it is already encrypted](./spec/unit/models/message_encoders/cipher_spec.rb#L194)
          * [leaves encoding intact](./spec/unit/models/message_encoders/cipher_spec.rb#L198)
        * with encryption set to to false
          * [leaves message intact as encryption is not enable](./spec/unit/models/message_encoders/cipher_spec.rb#L207)
          * [leaves encoding intact](./spec/unit/models/message_encoders/cipher_spec.rb#L211)
      * channel_option cipher params
        * have invalid key length
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L223)
        * have invalid algorithm
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L230)
        * have missing key
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L237)
    * with AES-256-CBC
      * message with cipher payload
        * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L255)
        * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L260)

### Ably::Models::MessageEncoders::Json
_(see [spec/unit/models/message_encoders/json_spec.rb](./spec/unit/models/message_encoders/json_spec.rb))_
  * #decode
    * message with json payload
      * [decodes json](./spec/unit/models/message_encoders/json_spec.rb#L24)
      * [strips the encoding](./spec/unit/models/message_encoders/json_spec.rb#L28)
    * message with json payload in camelCase
      * [decodes json](./spec/unit/models/message_encoders/json_spec.rb#L36)
      * [strips the encoding](./spec/unit/models/message_encoders/json_spec.rb#L40)
    * message with json payload before other payloads
      * [decodes json](./spec/unit/models/message_encoders/json_spec.rb#L48)
      * [strips the encoding](./spec/unit/models/message_encoders/json_spec.rb#L52)
    * message with another payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L60)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L64)
  * #encode
    * message with hash payload
      * [encodes hash payload data as json](./spec/unit/models/message_encoders/json_spec.rb#L78)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L82)
    * message with hash payload and underscore case keys
      * [encodes hash payload data as json and leaves underscore case in tact](./spec/unit/models/message_encoders/json_spec.rb#L90)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L94)
    * already encoded message with hash payload
      * [encodes hash payload data as json](./spec/unit/models/message_encoders/json_spec.rb#L102)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L106)
    * message with Array payload
      * [encodes Array payload data as json](./spec/unit/models/message_encoders/json_spec.rb#L114)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L118)
    * message with UTF-8 payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L126)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L130)
    * message with nil payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L138)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L142)
    * message with no data payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L150)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L154)

### Ably::Models::MessageEncoders::Utf8
_(see [spec/unit/models/message_encoders/utf8_spec.rb](./spec/unit/models/message_encoders/utf8_spec.rb))_
  * #decode
    * message with utf8 payload
      * [sets the encoding](./spec/unit/models/message_encoders/utf8_spec.rb#L21)
      * [strips the encoding](./spec/unit/models/message_encoders/utf8_spec.rb#L26)
    * message with utf8 payload before other payloads
      * [sets the encoding](./spec/unit/models/message_encoders/utf8_spec.rb#L34)
      * [strips the encoding](./spec/unit/models/message_encoders/utf8_spec.rb#L39)
    * message with another payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/utf8_spec.rb#L47)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/utf8_spec.rb#L51)

### Ably::Models::Message
_(see [spec/unit/models/message_spec.rb](./spec/unit/models/message_spec.rb))_
  * behaves like a model
    * attributes
      * #id
        * [retrieves attribute :id](./spec/shared/model_behaviour.rb#L15)
      * #name
        * [retrieves attribute :name](./spec/shared/model_behaviour.rb#L15)
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
      * #data
        * [retrieves attribute :data](./spec/shared/model_behaviour.rb#L15)
      * #encoding
        * [retrieves attribute :encoding](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * #timestamp
    * [retrieves attribute :timestamp as Time object from ProtocolMessage](./spec/unit/models/message_spec.rb#L22)
  * #connection_id attribute
    * when this model has a connectionId attribute
      * but no protocol message
        * [uses the model value](./spec/unit/models/message_spec.rb#L37)
      * with a protocol message with a different connectionId
        * [uses the model value](./spec/unit/models/message_spec.rb#L45)
    * when this model has no connectionId attribute
      * and no protocol message
        * [uses the model value](./spec/unit/models/message_spec.rb#L55)
      * with a protocol message with a connectionId
        * [uses the model value](./spec/unit/models/message_spec.rb#L63)
  * initialized with
    * :name
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L90)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L94)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L102)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L106)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L114)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L118)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L126)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L134)
    * :client_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L90)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L94)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L102)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L106)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L114)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L118)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L126)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L134)
    * :encoding
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L90)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L94)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L102)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L106)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L114)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L118)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L126)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L134)

### Ably::Models::PaginatedResult
_(see [spec/unit/models/paginated_result_spec.rb](./spec/unit/models/paginated_result_spec.rb))_
  * #items
    * [returns correct length from body](./spec/unit/models/paginated_result_spec.rb#L31)
    * [is Enumerable](./spec/unit/models/paginated_result_spec.rb#L35)
    * [is iterable](./spec/unit/models/paginated_result_spec.rb#L39)
    * [provides [] accessor method](./spec/unit/models/paginated_result_spec.rb#L57)
    * [#first gets the first item in page](./spec/unit/models/paginated_result_spec.rb#L63)
    * [#last gets the last item in page](./spec/unit/models/paginated_result_spec.rb#L67)
    * #each
      * [returns an enumerator](./spec/unit/models/paginated_result_spec.rb#L44)
      * [yields each item](./spec/unit/models/paginated_result_spec.rb#L48)
  * with non paged http response
    * [is the last page](./spec/unit/models/paginated_result_spec.rb#L172)
    * [does not have next page](./spec/unit/models/paginated_result_spec.rb#L176)
    * [does not support pagination](./spec/unit/models/paginated_result_spec.rb#L180)
    * [returns nil when accessing next page](./spec/unit/models/paginated_result_spec.rb#L184)
    * [returns nil when accessing first page](./spec/unit/models/paginated_result_spec.rb#L188)
  * with paged http response
    * [has next page](./spec/unit/models/paginated_result_spec.rb#L206)
    * [is not the last page](./spec/unit/models/paginated_result_spec.rb#L210)
    * [supports pagination](./spec/unit/models/paginated_result_spec.rb#L214)
    * accessing next page
      * [returns another PaginatedResult](./spec/unit/models/paginated_result_spec.rb#L242)
      * [retrieves the next page of results](./spec/unit/models/paginated_result_spec.rb#L246)
      * [does not have a next page](./spec/unit/models/paginated_result_spec.rb#L251)
      * [is the last page](./spec/unit/models/paginated_result_spec.rb#L255)
      * [returns nil when trying to access the last page when it is the last page](./spec/unit/models/paginated_result_spec.rb#L259)
      * and then first page
        * [returns a PaginatedResult](./spec/unit/models/paginated_result_spec.rb#L270)
        * [retrieves the first page of results](./spec/unit/models/paginated_result_spec.rb#L274)

### Ably::Models::PresenceMessage
_(see [spec/unit/models/presence_message_spec.rb](./spec/unit/models/presence_message_spec.rb))_
  * behaves like a model
    * attributes
      * #id
        * [retrieves attribute :id](./spec/shared/model_behaviour.rb#L15)
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
      * #data
        * [retrieves attribute :data](./spec/shared/model_behaviour.rb#L15)
      * #encoding
        * [retrieves attribute :encoding](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * #connection_id attribute
    * when this model has a connectionId attribute
      * but no protocol message
        * [uses the model value](./spec/unit/models/presence_message_spec.rb#L25)
      * with a protocol message with a different connectionId
        * [uses the model value](./spec/unit/models/presence_message_spec.rb#L33)
    * when this model has no connectionId attribute
      * and no protocol message
        * [uses the model value](./spec/unit/models/presence_message_spec.rb#L43)
      * with a protocol message with a connectionId
        * [uses the model value](./spec/unit/models/presence_message_spec.rb#L51)
  * #member_key attribute
    * [is string in format connection_id:client_id](./spec/unit/models/presence_message_spec.rb#L61)
    * with the same client id across multiple connections
      * [is unique](./spec/unit/models/presence_message_spec.rb#L69)
    * with a single connection and different client_ids
      * [is unique](./spec/unit/models/presence_message_spec.rb#L78)
  * #timestamp
    * [retrieves attribute :timestamp as a Time object from ProtocolMessage](./spec/unit/models/presence_message_spec.rb#L86)
  * initialized with
    * :client_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L138)
        * [remains as UTF-8](./spec/unit/models/presence_message_spec.rb#L142)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L150)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L154)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L162)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L166)
      * as Integer
        * [raises an argument error](./spec/unit/models/presence_message_spec.rb#L174)
      * as Nil
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L182)
    * :connection_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L138)
        * [remains as UTF-8](./spec/unit/models/presence_message_spec.rb#L142)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L150)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L154)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L162)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L166)
      * as Integer
        * [raises an argument error](./spec/unit/models/presence_message_spec.rb#L174)
      * as Nil
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L182)
    * :encoding
      * as UTF_8 string
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L138)
        * [remains as UTF-8](./spec/unit/models/presence_message_spec.rb#L142)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L150)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L154)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L162)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L166)
      * as Integer
        * [raises an argument error](./spec/unit/models/presence_message_spec.rb#L174)
      * as Nil
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L182)

### Ably::Models::ProtocolMessage
_(see [spec/unit/models/protocol_message_spec.rb](./spec/unit/models/protocol_message_spec.rb))_
  * behaves like a model
    * attributes
      * #id
        * [retrieves attribute :id](./spec/shared/model_behaviour.rb#L15)
      * #channel
        * [retrieves attribute :channel](./spec/shared/model_behaviour.rb#L15)
      * #channel_serial
        * [retrieves attribute :channel_serial](./spec/shared/model_behaviour.rb#L15)
      * #connection_id
        * [retrieves attribute :connection_id](./spec/shared/model_behaviour.rb#L15)
      * #connection_key
        * [retrieves attribute :connection_key](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * attributes
    * #timestamp
      * [retrieves attribute :timestamp as Time object](./spec/unit/models/protocol_message_spec.rb#L74)
    * #count
      * when missing
        * [is 1](./spec/unit/models/protocol_message_spec.rb#L83)
      * when non numeric
        * [is 1](./spec/unit/models/protocol_message_spec.rb#L90)
      * when greater than 1
        * [is the value of count](./spec/unit/models/protocol_message_spec.rb#L97)
    * #message_serial
      * [converts :msg_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L105)
    * #has_message_serial?
      * without msg_serial
        * [returns false](./spec/unit/models/protocol_message_spec.rb#L115)
      * with msg_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L123)
    * #connection_serial
      * [converts :connection_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L131)
    * #flags
      * when nil
        * [is zero](./spec/unit/models/protocol_message_spec.rb#L141)
      * when numeric
        * [is an Integer](./spec/unit/models/protocol_message_spec.rb#L149)
      * when has_presence
        * [#has_presence_flag? is true](./spec/unit/models/protocol_message_spec.rb#L157)
      * when has another future flag
        * [#has_presence_flag? is false](./spec/unit/models/protocol_message_spec.rb#L165)
    * #has_connection_serial?
      * without connection_serial
        * [returns false](./spec/unit/models/protocol_message_spec.rb#L175)
      * with connection_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L183)
    * #serial
      * with underlying msg_serial
        * [converts :msg_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L192)
      * with underlying connection_serial
        * [converts :connection_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L200)
      * with underlying connection_serial and msg_serial
        * [prefers connection_serial and converts :connection_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L208)
    * #has_serial?
      * without msg_serial or connection_serial
        * [returns false](./spec/unit/models/protocol_message_spec.rb#L219)
      * with msg_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L227)
      * with connection_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L235)
    * #error
      * with no error attribute
        * [returns nil](./spec/unit/models/protocol_message_spec.rb#L245)
      * with nil error
        * [returns nil](./spec/unit/models/protocol_message_spec.rb#L253)
      * with error
        * [returns a valid ErrorInfo object](./spec/unit/models/protocol_message_spec.rb#L261)
    * #messages
      * [contains Message objects](./spec/unit/models/protocol_message_spec.rb#L271)
    * #presence
      * [contains PresenceMessage objects](./spec/unit/models/protocol_message_spec.rb#L281)
    * #connection_details
      * with a JSON value
        * [contains a ConnectionDetails object](./spec/unit/models/protocol_message_spec.rb#L294)
        * [contains the attributes from the JSON connectionDetails](./spec/unit/models/protocol_message_spec.rb#L298)
      * without a JSON value
        * [contains an empty ConnectionDetails object](./spec/unit/models/protocol_message_spec.rb#L307)
    * #connection_key
      * existing only in #connection_details.connection_key
        * [is returned](./spec/unit/models/protocol_message_spec.rb#L319)
      * existing in both #connection_key and #connection_details.connection_key
        * [returns #connection_details.connection_key as #connection_key will be deprecated > 0.8](./spec/unit/models/protocol_message_spec.rb#L327)

### Ably::Models::Stats
_(see [spec/unit/models/stats_spec.rb](./spec/unit/models/stats_spec.rb))_
  * #all stats
    * [returns a MessageTypes object](./spec/unit/models/stats_spec.rb#L17)
    * [returns value for message counts](./spec/unit/models/stats_spec.rb#L21)
    * [returns value for all data transferred](./spec/unit/models/stats_spec.rb#L25)
    * [returns zero for empty values](./spec/unit/models/stats_spec.rb#L29)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L33)
    * #all
      * [is a MessageCount object](./spec/unit/models/stats_spec.rb#L39)
    * #presence
      * [is a MessageCount object](./spec/unit/models/stats_spec.rb#L39)
    * #messages
      * [is a MessageCount object](./spec/unit/models/stats_spec.rb#L39)
  * #persisted stats
    * [returns a MessageTypes object](./spec/unit/models/stats_spec.rb#L17)
    * [returns value for message counts](./spec/unit/models/stats_spec.rb#L21)
    * [returns value for all data transferred](./spec/unit/models/stats_spec.rb#L25)
    * [returns zero for empty values](./spec/unit/models/stats_spec.rb#L29)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L33)
    * #all
      * [is a MessageCount object](./spec/unit/models/stats_spec.rb#L39)
    * #presence
      * [is a MessageCount object](./spec/unit/models/stats_spec.rb#L39)
    * #messages
      * [is a MessageCount object](./spec/unit/models/stats_spec.rb#L39)
  * #inbound stats
    * [returns a MessageTraffic object](./spec/unit/models/stats_spec.rb#L59)
    * [returns value for realtime message counts](./spec/unit/models/stats_spec.rb#L63)
    * [returns value for all presence data](./spec/unit/models/stats_spec.rb#L67)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L71)
    * #realtime
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
    * #rest
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
    * #webhook
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
    * #all
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
  * #outbound stats
    * [returns a MessageTraffic object](./spec/unit/models/stats_spec.rb#L59)
    * [returns value for realtime message counts](./spec/unit/models/stats_spec.rb#L63)
    * [returns value for all presence data](./spec/unit/models/stats_spec.rb#L67)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L71)
    * #realtime
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
    * #rest
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
    * #webhook
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
    * #all
      * [is a MessageTypes object](./spec/unit/models/stats_spec.rb#L77)
  * #connections stats
    * [returns a ConnectionTypes object](./spec/unit/models/stats_spec.rb#L91)
    * [returns value for tls opened counts](./spec/unit/models/stats_spec.rb#L95)
    * [returns value for all peak connections](./spec/unit/models/stats_spec.rb#L99)
    * [returns zero for empty values](./spec/unit/models/stats_spec.rb#L103)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L107)
    * #tls
      * [is a ResourceCount object](./spec/unit/models/stats_spec.rb#L113)
    * #plain
      * [is a ResourceCount object](./spec/unit/models/stats_spec.rb#L113)
    * #all
      * [is a ResourceCount object](./spec/unit/models/stats_spec.rb#L113)
  * #channels stats
    * [returns a ResourceCount object](./spec/unit/models/stats_spec.rb#L126)
    * [returns value for opened counts](./spec/unit/models/stats_spec.rb#L130)
    * [returns value for peak channels](./spec/unit/models/stats_spec.rb#L134)
    * [returns zero for empty values](./spec/unit/models/stats_spec.rb#L138)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L142)
    * #opened
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L148)
    * #peak
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L148)
    * #mean
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L148)
    * #min
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L148)
    * #refused
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L148)
  * #api_requests stats
    * [returns a RequestCount object](./spec/unit/models/stats_spec.rb#L164)
    * [returns value for succeeded](./spec/unit/models/stats_spec.rb#L168)
    * [returns value for failed](./spec/unit/models/stats_spec.rb#L172)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L176)
    * #succeeded
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L182)
    * #failed
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L182)
    * #refused
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L182)
  * #token_requests stats
    * [returns a RequestCount object](./spec/unit/models/stats_spec.rb#L164)
    * [returns value for succeeded](./spec/unit/models/stats_spec.rb#L168)
    * [returns value for failed](./spec/unit/models/stats_spec.rb#L172)
    * [raises an exception for unknown attributes](./spec/unit/models/stats_spec.rb#L176)
    * #succeeded
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L182)
    * #failed
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L182)
    * #refused
      * [is a Integer object](./spec/unit/models/stats_spec.rb#L182)
  * #interval_granularity
    * [returns the granularity of the interval_id](./spec/unit/models/stats_spec.rb#L193)
  * #interval_time
    * [returns a Time object representing the start of the interval](./spec/unit/models/stats_spec.rb#L201)
  * class methods
    * #to_interval_id
      * when time zone of time argument is UTC
        * [converts time 2014-02-03:05:06 with granularity :month into 2014-02](./spec/unit/models/stats_spec.rb#L209)
        * [converts time 2014-02-03:05:06 with granularity :day into 2014-02-03](./spec/unit/models/stats_spec.rb#L213)
        * [converts time 2014-02-03:05:06 with granularity :hour into 2014-02-03:05](./spec/unit/models/stats_spec.rb#L217)
        * [converts time 2014-02-03:05:06 with granularity :minute into 2014-02-03:05:06](./spec/unit/models/stats_spec.rb#L221)
        * [fails with invalid granularity](./spec/unit/models/stats_spec.rb#L225)
        * [fails with invalid time](./spec/unit/models/stats_spec.rb#L229)
      * when time zone of time argument is +02:00
        * [converts time 2014-02-03:06 with granularity :hour into 2014-02-03:04 at UTC +00:00](./spec/unit/models/stats_spec.rb#L235)
    * #from_interval_id
      * [converts a month interval_id 2014-02 into a Time object in UTC 0](./spec/unit/models/stats_spec.rb#L242)
      * [converts a day interval_id 2014-02-03 into a Time object in UTC 0](./spec/unit/models/stats_spec.rb#L247)
      * [converts an hour interval_id 2014-02-03:05 into a Time object in UTC 0](./spec/unit/models/stats_spec.rb#L252)
      * [converts a minute interval_id 2014-02-03:05:06 into a Time object in UTC 0](./spec/unit/models/stats_spec.rb#L257)
      * [fails with an invalid interval_id 14-20](./spec/unit/models/stats_spec.rb#L262)
    * #granularity_from_interval_id
      * [returns a :month interval_id for 2014-02](./spec/unit/models/stats_spec.rb#L268)
      * [returns a :day interval_id for 2014-02-03](./spec/unit/models/stats_spec.rb#L272)
      * [returns a :hour interval_id for 2014-02-03:05](./spec/unit/models/stats_spec.rb#L276)
      * [returns a :minute interval_id for 2014-02-03:05:06](./spec/unit/models/stats_spec.rb#L280)
      * [fails with an invalid interval_id 14-20](./spec/unit/models/stats_spec.rb#L284)

### Ably::Models::TokenDetails
_(see [spec/unit/models/token_details_spec.rb](./spec/unit/models/token_details_spec.rb))_
  * behaves like a model
    * attributes
      * #token
        * [retrieves attribute :token](./spec/shared/model_behaviour.rb#L15)
      * #key_name
        * [retrieves attribute :key_name](./spec/shared/model_behaviour.rb#L15)
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * attributes
    * #capability
      * [retrieves attribute :capability as parsed JSON](./spec/unit/models/token_details_spec.rb#L21)
    * 
      * #issued with :issued option as milliseconds in constructor
        * [retrieves attribute :issued as Time](./spec/unit/models/token_details_spec.rb#L32)
      * #issued with :issued option as a Time in constructor
        * [retrieves attribute :issued as Time](./spec/unit/models/token_details_spec.rb#L41)
      * #issued when converted to JSON
        * [is in milliseconds](./spec/unit/models/token_details_spec.rb#L50)
      * #expires with :expires option as milliseconds in constructor
        * [retrieves attribute :expires as Time](./spec/unit/models/token_details_spec.rb#L32)
      * #expires with :expires option as a Time in constructor
        * [retrieves attribute :expires as Time](./spec/unit/models/token_details_spec.rb#L41)
      * #expires when converted to JSON
        * [is in milliseconds](./spec/unit/models/token_details_spec.rb#L50)
    * #expired?
      * once grace period buffer has passed
        * [is true](./spec/unit/models/token_details_spec.rb#L63)
      * within grace period buffer
        * [is false](./spec/unit/models/token_details_spec.rb#L71)
      * when expires is not available (i.e. string tokens)
        * [is always false](./spec/unit/models/token_details_spec.rb#L79)
  * ==
    * [is true when attributes are the same](./spec/unit/models/token_details_spec.rb#L89)
    * [is false when attributes are not the same](./spec/unit/models/token_details_spec.rb#L94)
    * [is false when class type differs](./spec/unit/models/token_details_spec.rb#L98)

### Ably::Models::TokenRequest
_(see [spec/unit/models/token_request_spec.rb](./spec/unit/models/token_request_spec.rb))_
  * behaves like a model
    * attributes
      * #key_name
        * [retrieves attribute :key_name](./spec/shared/model_behaviour.rb#L15)
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
      * #nonce
        * [retrieves attribute :nonce](./spec/shared/model_behaviour.rb#L15)
      * #mac
        * [retrieves attribute :mac](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * attributes
    * #capability
      * [retrieves attribute :capability as parsed JSON](./spec/unit/models/token_request_spec.rb#L18)
    * #timestamp
      * with :timestamp option as milliseconds in constructor
        * [retrieves attribute :timestamp as Time](./spec/unit/models/token_request_spec.rb#L29)
      * with :timestamp option as Time in constructor
        * [retrieves attribute :timestamp as Time](./spec/unit/models/token_request_spec.rb#L38)
      * when converted to JSON
        * [is in milliseconds since epoch](./spec/unit/models/token_request_spec.rb#L47)
    * #ttl
      * with :ttl option as milliseconds in constructor
        * [retrieves attribute :ttl as seconds](./spec/unit/models/token_request_spec.rb#L59)
      * when converted to JSON
        * [is in milliseconds since epoch](./spec/unit/models/token_request_spec.rb#L68)
  * ==
    * [is true when attributes are the same](./spec/unit/models/token_request_spec.rb#L78)
    * [is false when attributes are not the same](./spec/unit/models/token_request_spec.rb#L83)
    * [is false when class type differs](./spec/unit/models/token_request_spec.rb#L87)

### Ably::Modules::EventEmitter
_(see [spec/unit/modules/event_emitter_spec.rb](./spec/unit/modules/event_emitter_spec.rb))_
  * #emit event fan out
    * [should emit an event for any number of subscribers](./spec/unit/modules/event_emitter_spec.rb#L21)
    * [sends only messages to matching event names](./spec/unit/modules/event_emitter_spec.rb#L30)
    * #on subscribe to multiple events
      * [with the same block](./spec/unit/modules/event_emitter_spec.rb#L62)
    * event callback changes within the callback block
      * when new event callbacks are added
        * [is unaffected and processes the prior event callbacks once](./spec/unit/modules/event_emitter_spec.rb#L86)
        * [adds them for the next emitted event](./spec/unit/modules/event_emitter_spec.rb#L92)
      * when callbacks are removed
        * [is unaffected and processes the prior event callbacks once](./spec/unit/modules/event_emitter_spec.rb#L113)
        * [removes them for the next emitted event](./spec/unit/modules/event_emitter_spec.rb#L118)
  * #on
    * [calls the block every time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L131)
    * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L138)
  * #once
    * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L160)
    * [does not remove other blocks after it is called](./spec/unit/modules/event_emitter_spec.rb#L167)
    * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L175)
  * #unsafe_once
    * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L183)
    * [does not catch exceptions in provided blocks](./spec/unit/modules/event_emitter_spec.rb#L190)
  * #off
    * with event names as arguments
      * [deletes matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L208)
      * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L213)
      * [continues if the block does not exist](./spec/unit/modules/event_emitter_spec.rb#L218)
    * without any event names
      * [deletes all matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L225)
      * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L230)

### Ably::Modules::StateEmitter
_(see [spec/unit/modules/state_emitter_spec.rb](./spec/unit/modules/state_emitter_spec.rb))_
  * [#state returns current state](./spec/unit/modules/state_emitter_spec.rb#L28)
  * [#state= sets current state](./spec/unit/modules/state_emitter_spec.rb#L32)
  * [#change_state sets current state](./spec/unit/modules/state_emitter_spec.rb#L36)
  * #change_state with arguments
    * [passes the arguments through to the executed callback](./spec/unit/modules/state_emitter_spec.rb#L44)
  * #state?
    * [returns true if state matches](./spec/unit/modules/state_emitter_spec.rb#L55)
    * [returns false if state does not match](./spec/unit/modules/state_emitter_spec.rb#L59)
    * and convenience predicates for states
      * [returns true for #initializing? if state matches](./spec/unit/modules/state_emitter_spec.rb#L64)
      * [returns false for #connecting? if state does not match](./spec/unit/modules/state_emitter_spec.rb#L68)

### Ably::Realtime::Channel
_(see [spec/unit/realtime/channel_spec.rb](./spec/unit/realtime/channel_spec.rb))_
  * #initializer
    * as UTF_8 string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L19)
      * [remains as UTF-8](./spec/unit/realtime/channel_spec.rb#L23)
    * as SHIFT_JIS string
      * [gets converted to UTF-8](./spec/unit/realtime/channel_spec.rb#L31)
      * [is compatible with original encoding](./spec/unit/realtime/channel_spec.rb#L35)
    * as ASCII_8BIT string
      * [gets converted to UTF-8](./spec/unit/realtime/channel_spec.rb#L43)
      * [is compatible with original encoding](./spec/unit/realtime/channel_spec.rb#L47)
    * as Integer
      * [raises an argument error](./spec/unit/realtime/channel_spec.rb#L55)
    * as Nil
      * [raises an argument error](./spec/unit/realtime/channel_spec.rb#L63)
  * #publish name argument
    * as UTF_8 string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L81)
    * as SHIFT_JIS string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L89)
    * as ASCII_8BIT string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L97)
    * as Integer
      * [raises an argument error](./spec/unit/realtime/channel_spec.rb#L105)
    * as Nil
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L113)
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/channel_spec.rb#L120)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/channel_spec.rb#L126)
  * subscriptions
    * #subscribe
      * [without a block raises an invalid ArgumentError](./spec/unit/realtime/channel_spec.rb#L168)
      * [with no event name specified subscribes the provided block to all events](./spec/unit/realtime/channel_spec.rb#L172)
      * [with a single event name subscribes that block to matching events](./spec/unit/realtime/channel_spec.rb#L178)
      * [with a multiple event name arguments subscribes that block to all of those event names](./spec/unit/realtime/channel_spec.rb#L185)
      * [with a multiple duplicate event name arguments subscribes that block to all of those unique event names once](./spec/unit/realtime/channel_spec.rb#L197)
    * #unsubscribe
      * [with no event name specified unsubscribes that block from all events](./spec/unit/realtime/channel_spec.rb#L214)
      * [with a single event name argument unsubscribes the provided block with the matching event name](./spec/unit/realtime/channel_spec.rb#L220)
      * [with multiple event name arguments unsubscribes each of those matching event names with the provided block](./spec/unit/realtime/channel_spec.rb#L226)
      * [with a non-matching event name argument has no effect](./spec/unit/realtime/channel_spec.rb#L232)
      * [with no block argument unsubscribes all blocks for the event name argument](./spec/unit/realtime/channel_spec.rb#L238)

### Ably::Realtime::Channels
_(see [spec/unit/realtime/channels_spec.rb](./spec/unit/realtime/channels_spec.rb))_
  * creating channels
    * [[] creates a channel](./spec/unit/realtime/channels_spec.rb#L43)
    * #get
      * [creates a channel if it does not exist](./spec/unit/realtime/channels_spec.rb#L14)
      * when an existing channel exists
        * [will reuse a channel object if it exists](./spec/unit/realtime/channels_spec.rb#L20)
        * [will update the options on the channel if provided](./spec/unit/realtime/channels_spec.rb#L26)
        * [will leave the options intact on the channel if not provided](./spec/unit/realtime/channels_spec.rb#L34)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/realtime/channels_spec.rb#L50)
    * [calls the block if channel is missing](./spec/unit/realtime/channels_spec.rb#L55)
  * destroying channels
    * [#release detaches and then releases the channel resources](./spec/unit/realtime/channels_spec.rb#L63)
  * is Enumerable
    * [allows enumeration](./spec/unit/realtime/channels_spec.rb#L80)
    * [provides #length](./spec/unit/realtime/channels_spec.rb#L96)
    * #each
      * [returns an enumerator](./spec/unit/realtime/channels_spec.rb#L85)
      * [yields each channel](./spec/unit/realtime/channels_spec.rb#L89)

### Ably::Realtime::Client
_(see [spec/unit/realtime/client_spec.rb](./spec/unit/realtime/client_spec.rb))_
  * behaves like a client initializer
    * with invalid arguments
      * empty hash
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L28)
      * nil
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L36)
      * key: "invalid"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L44)
      * key: "invalid:asdad"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L52)
      * key and key_name
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L60)
      * key and key_secret
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L68)
      * client_id as only option
        * [requires a valid key](./spec/shared/client_initializer_behaviour.rb#L76)
    * with valid arguments
      * key only
        * [connects to the Ably service](./spec/shared/client_initializer_behaviour.rb#L87)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L91)
      * with a string key instead of options hash
        * [sets the key](./spec/shared/client_initializer_behaviour.rb#L111)
        * [sets the key_name](./spec/shared/client_initializer_behaviour.rb#L115)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L119)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L123)
      * with a string token key instead of options hash
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L135)
      * with token
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L143)
      * with token_details
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L151)
      * with token_params
        * [configures the default token_params](./spec/shared/client_initializer_behaviour.rb#L159)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L170)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L177)
        * with rest_host option
          * PENDING: *[uses an alternate endpoint for REST clients](./spec/shared/client_initializer_behaviour.rb#L185)*
        * with realtime_host option
          * [uses an alternate endpoint for Realtime clients](./spec/shared/client_initializer_behaviour.rb#L194)
        * with port option and non-TLS connections
          * [uses the custom port for non-TLS requests](./spec/shared/client_initializer_behaviour.rb#L203)
        * with tls_port option and a TLS connection
          * [uses the custom port for TLS requests](./spec/shared/client_initializer_behaviour.rb#L211)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L234)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L225)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L229)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L245)
          * [specifies Logger::WARN log level](./spec/shared/client_initializer_behaviour.rb#L249)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L257)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L275)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L279)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L293)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L298)
  * delegation to the REST Client
    * [passes on the options to the initializer](./spec/unit/realtime/client_spec.rb#L15)
    * for attribute
      * [#environment](./spec/unit/realtime/client_spec.rb#L23)
      * [#use_tls?](./spec/unit/realtime/client_spec.rb#L23)
      * [#log_level](./spec/unit/realtime/client_spec.rb#L23)
      * [#custom_host](./spec/unit/realtime/client_spec.rb#L23)

### Ably::Realtime::Connection
_(see [spec/unit/realtime/connection_spec.rb](./spec/unit/realtime/connection_spec.rb))_
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/connection_spec.rb#L18)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/connection_spec.rb#L24)

### Ably::Realtime::Presence
_(see [spec/unit/realtime/presence_spec.rb](./spec/unit/realtime/presence_spec.rb))_
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/presence_spec.rb#L13)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/presence_spec.rb#L19)
  * subscriptions
    * #subscribe
      * [without a block raises an invalid ArgumentError](./spec/unit/realtime/presence_spec.rb#L62)
      * [with no action specified subscribes the provided block to all action](./spec/unit/realtime/presence_spec.rb#L66)
      * [with a single action argument subscribes that block to matching actions](./spec/unit/realtime/presence_spec.rb#L72)
      * [with a multiple action arguments subscribes that block to all of those actions](./spec/unit/realtime/presence_spec.rb#L79)
      * [with a multiple duplicate action arguments subscribes that block to all of those unique actions once](./spec/unit/realtime/presence_spec.rb#L91)
    * #unsubscribe
      * [with no action specified unsubscribes that block from all events](./spec/unit/realtime/presence_spec.rb#L106)
      * [with a single action argument unsubscribes the provided block with the matching action](./spec/unit/realtime/presence_spec.rb#L112)
      * [with multiple action arguments unsubscribes each of those matching actions with the provided block](./spec/unit/realtime/presence_spec.rb#L118)
      * [with a non-matching action argument has no effect](./spec/unit/realtime/presence_spec.rb#L124)
      * [with no block argument unsubscribes all blocks for the action argument](./spec/unit/realtime/presence_spec.rb#L130)

### Ably::Realtime
_(see [spec/unit/realtime/realtime_spec.rb](./spec/unit/realtime/realtime_spec.rb))_
  * [constructor returns an Ably::Realtime::Client](./spec/unit/realtime/realtime_spec.rb#L6)

### Ably::Models::ProtocolMessage
_(see [spec/unit/realtime/safe_deferrable_spec.rb](./spec/unit/realtime/safe_deferrable_spec.rb))_
  * behaves like a safe Deferrable
    * #errback
      * [adds a callback that is called when #fail is called](./spec/shared/safe_deferrable_behaviour.rb#L15)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L22)
    * #fail
      * [calls the callbacks defined with #errback, but not the ones added for success #callback](./spec/shared/safe_deferrable_behaviour.rb#L32)
    * #callback
      * [adds a callback that is called when #succed is called](./spec/shared/safe_deferrable_behaviour.rb#L44)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L51)
    * #succeed
      * [calls the callbacks defined with #callback, but not the ones added for #errback](./spec/shared/safe_deferrable_behaviour.rb#L61)

### Ably::Models::Message
_(see [spec/unit/realtime/safe_deferrable_spec.rb](./spec/unit/realtime/safe_deferrable_spec.rb))_
  * behaves like a safe Deferrable
    * #errback
      * [adds a callback that is called when #fail is called](./spec/shared/safe_deferrable_behaviour.rb#L15)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L22)
    * #fail
      * [calls the callbacks defined with #errback, but not the ones added for success #callback](./spec/shared/safe_deferrable_behaviour.rb#L32)
    * #callback
      * [adds a callback that is called when #succed is called](./spec/shared/safe_deferrable_behaviour.rb#L44)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L51)
    * #succeed
      * [calls the callbacks defined with #callback, but not the ones added for #errback](./spec/shared/safe_deferrable_behaviour.rb#L61)

### Ably::Models::PresenceMessage
_(see [spec/unit/realtime/safe_deferrable_spec.rb](./spec/unit/realtime/safe_deferrable_spec.rb))_
  * behaves like a safe Deferrable
    * #errback
      * [adds a callback that is called when #fail is called](./spec/shared/safe_deferrable_behaviour.rb#L15)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L22)
    * #fail
      * [calls the callbacks defined with #errback, but not the ones added for success #callback](./spec/shared/safe_deferrable_behaviour.rb#L32)
    * #callback
      * [adds a callback that is called when #succed is called](./spec/shared/safe_deferrable_behaviour.rb#L44)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L51)
    * #succeed
      * [calls the callbacks defined with #callback, but not the ones added for #errback](./spec/shared/safe_deferrable_behaviour.rb#L61)

### Ably::Rest::Channel
_(see [spec/unit/rest/channel_spec.rb](./spec/unit/rest/channel_spec.rb))_
  * #initializer
    * as UTF_8 string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L16)
      * [remains as UTF-8](./spec/unit/rest/channel_spec.rb#L20)
    * as SHIFT_JIS string
      * [gets converted to UTF-8](./spec/unit/rest/channel_spec.rb#L28)
      * [is compatible with original encoding](./spec/unit/rest/channel_spec.rb#L32)
    * as ASCII_8BIT string
      * [gets converted to UTF-8](./spec/unit/rest/channel_spec.rb#L40)
      * [is compatible with original encoding](./spec/unit/rest/channel_spec.rb#L44)
    * as Integer
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L52)
    * as Nil
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L60)
  * #publish name argument
    * as UTF_8 string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L72)
    * as SHIFT_JIS string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L80)
    * as ASCII_8BIT string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L88)
    * as Integer
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L96)

### Ably::Rest::Channels
_(see [spec/unit/rest/channels_spec.rb](./spec/unit/rest/channels_spec.rb))_
  * creating channels
    * [#get creates a channel](./spec/unit/rest/channels_spec.rb#L12)
    * [#get will reuse the channel object](./spec/unit/rest/channels_spec.rb#L17)
    * [[] creates a channel](./spec/unit/rest/channels_spec.rb#L23)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/rest/channels_spec.rb#L30)
    * [calls the block if channel is missing](./spec/unit/rest/channels_spec.rb#L35)
  * destroying channels
    * [#release releases the channel resoures](./spec/unit/rest/channels_spec.rb#L43)
  * is Enumerable
    * [allows enumeration](./spec/unit/rest/channels_spec.rb#L59)
    * [provides #length](./spec/unit/rest/channels_spec.rb#L75)
    * #each
      * [returns an enumerator](./spec/unit/rest/channels_spec.rb#L64)
      * [yields each channel](./spec/unit/rest/channels_spec.rb#L68)

### Ably::Rest::Client
_(see [spec/unit/rest/client_spec.rb](./spec/unit/rest/client_spec.rb))_
  * behaves like a client initializer
    * with invalid arguments
      * empty hash
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L28)
      * nil
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L36)
      * key: "invalid"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L44)
      * key: "invalid:asdad"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L52)
      * key and key_name
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L60)
      * key and key_secret
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L68)
      * client_id as only option
        * [requires a valid key](./spec/shared/client_initializer_behaviour.rb#L76)
    * with valid arguments
      * key only
        * [connects to the Ably service](./spec/shared/client_initializer_behaviour.rb#L87)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L91)
      * with a string key instead of options hash
        * [sets the key](./spec/shared/client_initializer_behaviour.rb#L111)
        * [sets the key_name](./spec/shared/client_initializer_behaviour.rb#L115)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L119)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L123)
      * with a string token key instead of options hash
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L135)
      * with token
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L143)
      * with token_details
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L151)
      * with token_params
        * [configures the default token_params](./spec/shared/client_initializer_behaviour.rb#L159)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L170)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L177)
        * with rest_host option
          * [uses an alternate endpoint for REST clients](./spec/shared/client_initializer_behaviour.rb#L185)
        * with realtime_host option
          * PENDING: *[uses an alternate endpoint for Realtime clients](./spec/shared/client_initializer_behaviour.rb#L194)*
        * with port option and non-TLS connections
          * [uses the custom port for non-TLS requests](./spec/shared/client_initializer_behaviour.rb#L203)
        * with tls_port option and a TLS connection
          * [uses the custom port for TLS requests](./spec/shared/client_initializer_behaviour.rb#L211)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L234)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L225)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L229)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L245)
          * [specifies Logger::WARN log level](./spec/shared/client_initializer_behaviour.rb#L249)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L257)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L275)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L279)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L293)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L298)
  * initializer options
    * TLS
      * disabled
        * [fails for any operation with basic auth and attempting to send an API key over a non-secure connection](./spec/unit/rest/client_spec.rb#L17)
    * :use_token_auth
      * set to false
        * with a key and :tls => false
          * [fails for any operation with basic auth and attempting to send an API key over a non-secure connection](./spec/unit/rest/client_spec.rb#L28)
        * without a key
          * [fails as a key is required if not using token auth](./spec/unit/rest/client_spec.rb#L36)
      * set to true
        * without a key or token
          * [fails as a key is required to issue tokens](./spec/unit/rest/client_spec.rb#L46)

### Ably::Rest
_(see [spec/unit/rest/rest_spec.rb](./spec/unit/rest/rest_spec.rb))_
  * [constructor returns an Ably::Rest::Client](./spec/unit/rest/rest_spec.rb#L7)

### Ably::Util::Crypto
_(see [spec/unit/util/crypto_spec.rb](./spec/unit/util/crypto_spec.rb))_
  * defaults
    * [match other client libraries](./spec/unit/util/crypto_spec.rb#L19)
  * get_default_params
    * with just a :key param
      * [uses the defaults](./spec/unit/util/crypto_spec.rb#L29)
      * [contains the provided key](./spec/unit/util/crypto_spec.rb#L35)
      * [returns a CipherParams object](./spec/unit/util/crypto_spec.rb#L39)
    * without a :key param
      * [raises an exception](./spec/unit/util/crypto_spec.rb#L47)
    * with a base64-encoded :key param
      * [converts the key to binary](./spec/unit/util/crypto_spec.rb#L55)
    * with provided params
      * [overrides the defaults](./spec/unit/util/crypto_spec.rb#L67)
  * encrypts & decrypt
    * [#encrypt encrypts a string](./spec/unit/util/crypto_spec.rb#L79)
    * [#decrypt decrypts a string](./spec/unit/util/crypto_spec.rb#L84)
  * encrypting an empty string
    * [raises an ArgumentError](./spec/unit/util/crypto_spec.rb#L93)
  * using shared client lib fixture data
    * with AES-128-CBC
      * behaves like an Ably encrypter and decrypter
        * text payload
          * [encrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L116)
          * [decrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L120)
    * with AES-256-CBC
      * behaves like an Ably encrypter and decrypter
        * text payload
          * [encrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L116)
          * [decrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L120)

### Ably::Util::PubSub
_(see [spec/unit/util/pub_sub_spec.rb](./spec/unit/util/pub_sub_spec.rb))_
  * event fan out
    * [#publish allows publishing to more than on subscriber](./spec/unit/util/pub_sub_spec.rb#L11)
    * [#publish sends only messages to #subscribe callbacks matching event names](./spec/unit/util/pub_sub_spec.rb#L19)
  * #unsubscribe
    * [deletes matching callbacks](./spec/unit/util/pub_sub_spec.rb#L71)
    * [deletes all callbacks if not block given](./spec/unit/util/pub_sub_spec.rb#L76)
    * [continues if the block does not exist](./spec/unit/util/pub_sub_spec.rb#L81)

  -------

  ## Test summary

  * Passing tests: 1492
  * Pending tests: 6
  * Failing tests: 0
