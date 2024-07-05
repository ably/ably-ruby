# Ably Realtime & REST Client Library 1.2.6 Specification

### Ably::Realtime::Auth
_(see [spec/acceptance/realtime/auth_spec.rb](./spec/acceptance/realtime/auth_spec.rb))_
  * using JSON protocol
    * with basic auth
      * #authentication_security_requirements_met?
        * [returns true](./spec/acceptance/realtime/auth_spec.rb#L28)
      * #key
        * [contains the API key](./spec/acceptance/realtime/auth_spec.rb#L35)
      * #key_name
        * [contains the API key name](./spec/acceptance/realtime/auth_spec.rb#L42)
      * #key_secret
        * [contains the API key secret](./spec/acceptance/realtime/auth_spec.rb#L49)
      * #using_basic_auth?
        * [is true when using Basic Auth](./spec/acceptance/realtime/auth_spec.rb#L56)
      * #using_token_auth?
        * [is false when using Basic Auth](./spec/acceptance/realtime/auth_spec.rb#L63)
    * with token auth
      * #client_id
        * [contains the ClientOptions client ID](./spec/acceptance/realtime/auth_spec.rb#L75)
      * #current_token_details
        * [contains the current token after auth](./spec/acceptance/realtime/auth_spec.rb#L82)
      * #token_renewable?
        * [is true when an API key exists](./spec/acceptance/realtime/auth_spec.rb#L92)
      * #options (auth_options)
        * [contains the configured auth options](./spec/acceptance/realtime/auth_spec.rb#L104)
      * #token_params
        * [contains the configured auth options](./spec/acceptance/realtime/auth_spec.rb#L115)
      * #using_basic_auth?
        * [is false when using Token Auth](./spec/acceptance/realtime/auth_spec.rb#L124)
      * #using_token_auth?
        * [is true when using Token Auth](./spec/acceptance/realtime/auth_spec.rb#L133)
    * methods
      * #create_token_request
        * [returns a token request asynchronously](./spec/acceptance/realtime/auth_spec.rb#L147)
      * #create_token_request_async
        * [returns a token request synchronously](./spec/acceptance/realtime/auth_spec.rb#L157)
      * #request_token
        * [returns a token asynchronously](./spec/acceptance/realtime/auth_spec.rb#L167)
      * #request_token_async
        * [returns a token synchronously](./spec/acceptance/realtime/auth_spec.rb#L178)
      * #authorize
        * with token auth
          * [returns a token asynchronously](./spec/acceptance/realtime/auth_spec.rb#L192)
        * with auth_callback blocking
          * with a slow auth callback response
            * [asynchronously authenticates](./spec/acceptance/realtime/auth_spec.rb#L215)
        * when implicitly called, with an explicit ClientOptions client_id
          * and an incompatible client_id in a TokenDetails object passed to the auth callback
            * [rejects a TokenDetails object with an incompatible client_id and fails with an exception](./spec/acceptance/realtime/auth_spec.rb#L239)
          * and an incompatible client_id in a TokenRequest object passed to the auth callback and fails with an exception
            * [rejects a TokenRequests object with an incompatible client_id and fails with an exception](./spec/acceptance/realtime/auth_spec.rb#L255)
        * when explicitly called, with an explicit ClientOptions client_id
          * and an incompatible client_id in a TokenDetails object passed to the auth callback
            * [rejects a TokenDetails object with an incompatible client_id and fails with an exception](./spec/acceptance/realtime/auth_spec.rb#L287)
        * when already authenticated with a valid token
          * [ensures message delivery continuity whilst upgrading (#RTC8a1)](./spec/acceptance/realtime/auth_spec.rb#L703)
          * when INITIALIZED
            * [obtains a token and connects to Ably (#RTC8c, #RTC8b1)](./spec/acceptance/realtime/auth_spec.rb#L328)
          * when CONNECTING
            * [aborts the current connection process, obtains a token, and connects to Ably again (#RTC8b)](./spec/acceptance/realtime/auth_spec.rb#L350)
          * when FAILED
            * [obtains a token and connects to Ably (#RTC8c, #RTC8b1)](./spec/acceptance/realtime/auth_spec.rb#L369)
          * when CLOSED
            * [obtains a token and connects to Ably (#RTC8c, #RTC8b1, #RTC8a3)](./spec/acceptance/realtime/auth_spec.rb#L386)
          * when in the CONNECTED state
            * with a valid token in the AUTH ProtocolMessage sent
              * PENDING: *[obtains a new token (that upgrades from anonymous to identified) and upgrades the connection after receiving an updated CONNECTED ProtocolMessage (#RTC8a, #RTC8a3)](./spec/acceptance/realtime/auth_spec.rb#L409)*
              * [obtains a new token (as anonymous user before & after) and upgrades the connection after receiving an updated CONNECTED ProtocolMessage (#RTC8a, #RTC8a3)](./spec/acceptance/realtime/auth_spec.rb#L445)
          * when DISCONNECTED
            * PENDING: *[obtains a token, upgrades from anonymous to identified, and connects to Ably immediately (#RTC8c, #RTC8b1)](./spec/acceptance/realtime/auth_spec.rb#L481)*
            * [obtains a similar anonymous token and connects to Ably immediately (#RTC8c, #RTC8b1)](./spec/acceptance/realtime/auth_spec.rb#L517)
          * when SUSPENDED
            * [obtains a token and connects to Ably immediately (#RTC8c, #RTC8b1)](./spec/acceptance/realtime/auth_spec.rb#L561)
          * when client is identified
            * [transitions the connection state to FAILED if the client_id changes (#RSA15c, #RTC8a2)](./spec/acceptance/realtime/auth_spec.rb#L596)
          * when auth fails
            * [transitions the connection state to the FAILED state (#RSA15c, #RTC8a2, #RTC8a3)](./spec/acceptance/realtime/auth_spec.rb#L612)
          * when the authCallback fails
            * [calls the error callback of authorize and leaves the connection intact (#RSA4c3)](./spec/acceptance/realtime/auth_spec.rb#L640)
          * when upgrading capabilities
            * [is allowed (#RTC8a1)](./spec/acceptance/realtime/auth_spec.rb#L659)
          * when downgrading capabilities (#RTC8a1)
            * [is allowed and channels are detached](./spec/acceptance/realtime/auth_spec.rb#L686)
      * #authorize_async
        * [returns a token synchronously](./spec/acceptance/realtime/auth_spec.rb#L737)
    * server initiated AUTH ProtocolMessage
      * when received
        * [should immediately start a new authentication process (#RTN22)](./spec/acceptance/realtime/auth_spec.rb#L758)
      * when not received
        * [should expect the connection to be disconnected by the server but should resume automatically (#RTN22a)](./spec/acceptance/realtime/auth_spec.rb#L781)
    * #auth_params
      * [returns the auth params asynchronously](./spec/acceptance/realtime/auth_spec.rb#L807)
    * #auth_params_sync
      * [returns the auth params synchronously](./spec/acceptance/realtime/auth_spec.rb#L816)
    * #auth_header
      * [returns an auth header asynchronously](./spec/acceptance/realtime/auth_spec.rb#L823)
    * #auth_header_sync
      * [returns an auth header synchronously](./spec/acceptance/realtime/auth_spec.rb#L832)
    * #client_id_validated?
      * when using basic auth
        * before connected
          * [is false as basic auth users do not have an identity](./spec/acceptance/realtime/auth_spec.rb#L845)
        * once connected
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L852)
          * [contains a validated wildcard client_id](./spec/acceptance/realtime/auth_spec.rb#L859)
      * when using a token string
        * with a valid client_id
          * before connected
            * [is false as identification is not possible from an opaque token string](./spec/acceptance/realtime/auth_spec.rb#L873)
            * [#client_id is nil](./spec/acceptance/realtime/auth_spec.rb#L878)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L885)
            * [#client_id is populated](./spec/acceptance/realtime/auth_spec.rb#L892)
        * with no client_id (anonymous)
          * before connected
            * [is false as identification is not possible from an opaque token string](./spec/acceptance/realtime/auth_spec.rb#L905)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L912)
        * with a wildcard client_id (anonymous)
          * before connected
            * [is false as identification is not possible from an opaque token string](./spec/acceptance/realtime/auth_spec.rb#L925)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L932)
      * when using a token
        * with a client_id
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L946)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L952)
        * with no client_id (anonymous)
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L964)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L970)
        * with a wildcard client_id (anonymous)
          * [is true](./spec/acceptance/realtime/auth_spec.rb#L982)
          * once connected
            * [is true](./spec/acceptance/realtime/auth_spec.rb#L988)
      * when using a token request with a client_id
        * [is not true as identification is not confirmed until authenticated](./spec/acceptance/realtime/auth_spec.rb#L1001)
        * once connected
          * [is true as identification is completed following CONNECTED ProtocolMessage](./spec/acceptance/realtime/auth_spec.rb#L1007)
    * deprecated #authorise
      * [logs a deprecation warning (#RSA10l)](./spec/acceptance/realtime/auth_spec.rb#L1021)
      * [returns a valid token (#RSA10l)](./spec/acceptance/realtime/auth_spec.rb#L1027)
    * when using JWT
      * when using auth_url
        * when credentials are valid
          * [client successfully fetches a channel and publishes a message](./spec/acceptance/realtime/auth_spec.rb#L1046)
        * when credentials are wrong
          * [disconnected includes and invalid signature message](./spec/acceptance/realtime/auth_spec.rb#L1059)
        * when token is expired
          * [receives a 40142 error from the server](./spec/acceptance/realtime/auth_spec.rb#L1072)
      * when using auth_callback
        * when credentials are valid
          * [authentication succeeds and client can post a message](./spec/acceptance/realtime/auth_spec.rb#L1097)
        * when credentials are invalid
          * [authentication fails and reason for disconnection is invalid signature](./spec/acceptance/realtime/auth_spec.rb#L1112)
      * when the client is initialized with ClientOptions and the token is a JWT token
        * when credentials are valid
          * [posts successfully to a channel](./spec/acceptance/realtime/auth_spec.rb#L1129)
        * when credentials are invalid
          * [fails with an invalid signature error](./spec/acceptance/realtime/auth_spec.rb#L1144)
      * when JWT token expires
        * [client disconnects, a new token is requested via auth_callback and the client gets reconnected](./spec/acceptance/realtime/auth_spec.rb#L1171)
        * and an AUTH procol message is received
          * [client reauths correctly without going through a disconnection](./spec/acceptance/realtime/auth_spec.rb#L1199)
      * when the JWT token request includes a client_id
        * [the client_id is the same that was specified in the auth_callback that generated the JWT token](./spec/acceptance/realtime/auth_spec.rb#L1227)
      * when the JWT token request includes a subscribe-only capability
        * [client fails to publish to a channel with subscribe-only capability and publishes successfully on a channel with permissions](./spec/acceptance/realtime/auth_spec.rb#L1245)

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
        * [retrieves history forwards with pagination through :limit option](./spec/acceptance/realtime/channel_history_spec.rb#L94)
        * [retrieves history backwards with pagination through :limit option](./spec/acceptance/realtime/channel_history_spec.rb#L103)
      * in multiple ProtocolMessages
        * [retrieves limited history forwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L114)
        * [retrieves limited history backwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L127)
      * and REST history
        * [return the same results with unique matching message IDs](./spec/acceptance/realtime/channel_history_spec.rb#L145)
    * with option until_attach: true
      * [retrieves all messages before channel was attached](./spec/acceptance/realtime/channel_history_spec.rb#L172)
      * [fails the deferrable unless the state is attached](./spec/acceptance/realtime/channel_history_spec.rb#L242)
      * when channel receives update event after an attachment
        * [updates attach_serial](./spec/acceptance/realtime/channel_history_spec.rb#L197)
      * and two pages of messages
        * [retrieves two pages of messages before channel was attached](./spec/acceptance/realtime/channel_history_spec.rb#L208)

### Ably::Realtime::Channel
_(see [spec/acceptance/realtime/channel_spec.rb](./spec/acceptance/realtime/channel_spec.rb))_
  * using JSON protocol
    * initialization
      * with :auto_connect option set to false on connection
        * [remains initialized when accessing a channel](./spec/acceptance/realtime/channel_spec.rb#L29)
        * [opens a connection implicitly on #attach](./spec/acceptance/realtime/channel_spec.rb#L37)
    * #attach
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/channel_spec.rb#L240)
      * [calls the SafeDeferrable callback on success (#RTL4d)](./spec/acceptance/realtime/channel_spec.rb#L245)
      * when initialized
        * [emits attaching then attached events](./spec/acceptance/realtime/channel_spec.rb#L48)
        * [ignores subsequent #attach calls but calls the success callback if provided](./spec/acceptance/realtime/channel_spec.rb#L58)
        * [attaches to a channel](./spec/acceptance/realtime/channel_spec.rb#L71)
        * [attaches to a channel and calls the provided block (#RTL4d)](./spec/acceptance/realtime/channel_spec.rb#L79)
        * [sets attach_serial property after the attachment (#RTL15a)](./spec/acceptance/realtime/channel_spec.rb#L86)
        * [sends an ATTACH and waits for an ATTACHED (#RTL4c)](./spec/acceptance/realtime/channel_spec.rb#L96)
        * [implicitly attaches the channel (#RTL7c)](./spec/acceptance/realtime/channel_spec.rb#L208)
        * context when channel options contain modes
          * [sends an ATTACH with options as flags (#RTL4l)](./spec/acceptance/realtime/channel_spec.rb#L125)
          * when channel is reattaching
            * [sends ATTACH_RESUME flag along with other modes (RTL4j)](./spec/acceptance/realtime/channel_spec.rb#L139)
        * context when channel options contain params
          * [sends an ATTACH with params (#RTL4k)](./spec/acceptance/realtime/channel_spec.rb#L167)
        * when received attached
          * [decodes flags and sets it as modes on channel options (#RTL4m)](./spec/acceptance/realtime/channel_spec.rb#L182)
          * [set params as channel options params (#RTL4k1)](./spec/acceptance/realtime/channel_spec.rb#L193)
        * when the implicit channel attach fails
          * [registers the listener anyway (#RTL7c)](./spec/acceptance/realtime/channel_spec.rb#L225)
      * when an ATTACHED acknowledge is not received on the current connection
        * [sends another ATTACH each time the connection becomes connected](./spec/acceptance/realtime/channel_spec.rb#L256)
      * when state is :attached
        * [does nothing (#RTL4a)](./spec/acceptance/realtime/channel_spec.rb#L294)
      * when state is :failed
        * [reattaches and sets the errorReason to nil (#RTL4g)](./spec/acceptance/realtime/channel_spec.rb#L314)
      * when state is :detaching
        * [does the attach operation after the completion of the pending request (#RTL4h)](./spec/acceptance/realtime/channel_spec.rb#L329)
      * with many connections and many channels on each simultaneously
        * [attaches all channels](./spec/acceptance/realtime/channel_spec.rb#L359)
      * failure as a result of insufficient key permissions
        * [emits failed event (#RTL4e)](./spec/acceptance/realtime/channel_spec.rb#L390)
        * [calls the errback of the returned Deferrable (#RTL4d)](./spec/acceptance/realtime/channel_spec.rb#L399)
        * [updates the error_reason](./spec/acceptance/realtime/channel_spec.rb#L407)
        * and subsequent authorisation with suitable permissions
          * [attaches to the channel successfully and resets the channel error_reason](./spec/acceptance/realtime/channel_spec.rb#L416)
      * with connection state
        * [is initialized (#RTL4i)](./spec/acceptance/realtime/channel_spec.rb#L460)
        * [is connecting (#RTL4i)](./spec/acceptance/realtime/channel_spec.rb#L468)
        * [is disconnected (#RTL4i)](./spec/acceptance/realtime/channel_spec.rb#L477)
      * clean attach (RTL4j)
        * when channel wasn't previously attached
          * [doesn't send ATTACH_RESUME](./spec/acceptance/realtime/channel_spec.rb#L492)
        * when channel was explicitly detached
          * [doesn't send ATTACH_RESUME](./spec/acceptance/realtime/channel_spec.rb#L507)
    * #detach
      * when state is :attached
        * [it detaches from a channel (#RTL5d)](./spec/acceptance/realtime/channel_spec.rb#L533)
        * [detaches from a channel and calls the provided block (#RTL5d, #RTL5e)](./spec/acceptance/realtime/channel_spec.rb#L546)
        * [emits :detaching then :detached events](./spec/acceptance/realtime/channel_spec.rb#L559)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/channel_spec.rb#L573)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/channel_spec.rb#L583)
        * and DETACHED message is not received within realtime request timeout
          * [fails the deferrable and returns to the previous state (#RTL5f, #RTL5e)](./spec/acceptance/realtime/channel_spec.rb#L600)
      * when state is :failed
        * [fails the deferrable (#RTL5b)](./spec/acceptance/realtime/channel_spec.rb#L620)
      * when state is :attaching
        * [waits for the attach to complete and then moves to detached](./spec/acceptance/realtime/channel_spec.rb#L633)
      * when state is :detaching
        * [ignores subsequent #detach calls but calls the callback if provided (#RTL5i)](./spec/acceptance/realtime/channel_spec.rb#L650)
      * when state is :suspended
        * [moves the channel state immediately to DETACHED state (#RTL5j)](./spec/acceptance/realtime/channel_spec.rb#L669)
      * when state is :initialized
        * [does nothing as there is no channel to detach (#RTL5a)](./spec/acceptance/realtime/channel_spec.rb#L692)
        * [returns a valid deferrable](./spec/acceptance/realtime/channel_spec.rb#L700)
      * when state is :detached
        * [does nothing as the channel is detached (#RTL5a)](./spec/acceptance/realtime/channel_spec.rb#L710)
      * when connection state is
        * closing
          * [fails the deferrable (#RTL5b)](./spec/acceptance/realtime/channel_spec.rb#L730)
        * failed and channel is failed
          * [fails the deferrable (#RTL5b)](./spec/acceptance/realtime/channel_spec.rb#L750)
        * failed and channel is detached
          * [fails the deferrable (#RTL5b)](./spec/acceptance/realtime/channel_spec.rb#L772)
        * initialized
          * [does the detach operation once the connection state is connected (#RTL5h)](./spec/acceptance/realtime/channel_spec.rb#L792)
        * connecting
          * [does the detach operation once the connection state is connected (#RTL5h)](./spec/acceptance/realtime/channel_spec.rb#L809)
        * disconnected
          * [does the detach operation once the connection state is connected (#RTL5h)](./spec/acceptance/realtime/channel_spec.rb#L830)
    * automatic channel recovery
      * when an ATTACH request times out
        * [moves to the SUSPENDED state (#RTL4f)](./spec/acceptance/realtime/channel_spec.rb#L859)
      * if a subsequent ATTACHED is received on an ATTACHED channel
        * [ignores the additional ATTACHED if resumed is true (#RTL12)](./spec/acceptance/realtime/channel_spec.rb#L873)
        * [emits an UPDATE only when resumed is true (#RTL12)](./spec/acceptance/realtime/channel_spec.rb#L887)
        * [emits an UPDATE when resumed is true and includes the reason error from the ProtocolMessage (#RTL12)](./spec/acceptance/realtime/channel_spec.rb#L903)
    * #publish
      * when channel is attached (#RTL6c1)
        * [publishes messages](./spec/acceptance/realtime/channel_spec.rb#L928)
      * #(RTL17)
        * when channel is initialized
          * [sends messages only on attach](./spec/acceptance/realtime/channel_spec.rb#L941)
        * when channel is attaching
          * [sends messages only on attach](./spec/acceptance/realtime/channel_spec.rb#L956)
        * when channel is detaching
          * [stops sending message](./spec/acceptance/realtime/channel_spec.rb#L979)
        * when channel is detached
          * [stops sending message](./spec/acceptance/realtime/channel_spec.rb#L1007)
        * when channel is failed
          * [errors when trying to send a message](./spec/acceptance/realtime/channel_spec.rb#L1033)
      * when channel is not attached in state Initializing (#RTL6c1)
        * [publishes messages immediately and does not implicitly attach (#RTL6c1)](./spec/acceptance/realtime/channel_spec.rb#L1051)
      * when channel is Attaching (#RTL6c1)
        * [publishes messages immediately (#RTL6c1)](./spec/acceptance/realtime/channel_spec.rb#L1068)
      * when channel is Detaching (#RTL6c1)
        * [publishes messages immediately (#RTL6c1)](./spec/acceptance/realtime/channel_spec.rb#L1093)
      * when channel is Detached (#RTL6c1)
        * [publishes messages immediately (#RTL6c1)](./spec/acceptance/realtime/channel_spec.rb#L1123)
      * with :queue_messages client option set to false (#RTL6c4)
        * and connection state connected (#RTL6c4)
          * [publishes the message](./spec/acceptance/realtime/channel_spec.rb#L1156)
        * and connection state initialized (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1165)
        * and connection state connecting (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1175)
        * and connection state disconnected (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1190)
        * and connection state suspended (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1190)
        * and connection state closing (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1190)
        * and connection state closed (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1190)
        * and the channel state is failed (#RTL6c4)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L1211)
      * with name and data arguments
        * [publishes the message and return true indicating success](./spec/acceptance/realtime/channel_spec.rb#L1229)
        * and additional attributes
          * [publishes the message with the attributes and return true indicating success](./spec/acceptance/realtime/channel_spec.rb#L1242)
        * and additional invalid attributes
          * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1255)
      * with an array of Hash objects with :name and :data attributes
        * [publishes an array of messages in one ProtocolMessage](./spec/acceptance/realtime/channel_spec.rb#L1269)
      * with an array of Message objects
        * [publishes an array of messages in one ProtocolMessage](./spec/acceptance/realtime/channel_spec.rb#L1297)
        * nil attributes
          * when name is nil
            * [publishes the message without a name attribute in the payload](./spec/acceptance/realtime/channel_spec.rb#L1321)
          * when data is nil
            * [publishes the message without a data attribute in the payload](./spec/acceptance/realtime/channel_spec.rb#L1345)
          * with neither name or data attributes
            * [publishes the message without any attributes in the payload](./spec/acceptance/realtime/channel_spec.rb#L1369)
        * with two invalid message out of 12
          * before client_id is known (validated)
            * [calls the errback once](./spec/acceptance/realtime/channel_spec.rb#L1393)
          * when client_id is known (validated)
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L1413)
        * only invalid messages
          * before client_id is known (validated)
            * [calls the errback once](./spec/acceptance/realtime/channel_spec.rb#L1432)
          * when client_id is known (validated)
            * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L1451)
      * with many many messages and many connections simultaneously
        * [publishes all messages, all success callbacks are called, and a history request confirms all messages were published](./spec/acceptance/realtime/channel_spec.rb#L1465)
      * with more than allowed messages in a single publish
        * [rejects the publish](./spec/acceptance/realtime/channel_spec.rb#L1488)
      * identified clients
        * when authenticated with a wildcard client_id
          * with a valid client_id in the message
            * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L1508)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1522)
          * with a non-String client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1529)
          * with an empty client_id in the message
            * [succeeds and publishes without a client_id](./spec/acceptance/realtime/channel_spec.rb#L1536)
        * when authenticated with a Token string with an implicit client_id
          * before the client is CONNECTED and the client's identity has been obtained
            * with a valid client_id in the message
              * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L1558)
            * with an invalid client_id in the message
              * [succeeds in the client library ( while connecting ) but then fails when delivered to Ably](./spec/acceptance/realtime/channel_spec.rb#L1573)
            * with an empty client_id in the message
              * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L1587)
          * after the client is CONNECTED and the client's identity is known
            * with a valid client_id in the message
              * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L1603)
            * with an invalid client_id in the message
              * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1617)
            * with an empty client_id in the message
              * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L1626)
        * when authenticated with a valid client_id
          * with a valid client_id
            * [succeeds](./spec/acceptance/realtime/channel_spec.rb#L1648)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1662)
          * with an invalid client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1669)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L1676)
        * when anonymous and no client_id
          * with a client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1697)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/realtime/channel_spec.rb#L1704)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/realtime/channel_spec.rb#L1711)
      * message size exceeded (#TO3l8)
        * and max_message_size is default (65536 bytes)
          * [should allow to send a message (32 bytes)](./spec/acceptance/realtime/channel_spec.rb#L1734)
          * [should not allow to send a message (700000 bytes)](./spec/acceptance/realtime/channel_spec.rb#L1744)
        * and max_message_size is customized (11 bytes)
          * and the message size is 30 bytes
            * [should not allow to send a message](./spec/acceptance/realtime/channel_spec.rb#L1765)
        * and max_message_size is nil
          * and the message size is 30 bytes
            * [should allow to send a message](./spec/acceptance/realtime/channel_spec.rb#L1787)
          * and the message size is 65537 bytes
            * [should not allow to send a message](./spec/acceptance/realtime/channel_spec.rb#L1806)
    * #subscribe
      * with an event argument
        * [subscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L1826)
      * before attach
        * [receives messages as soon as attached](./spec/acceptance/realtime/channel_spec.rb#L1836)
      * with no event argument
        * [subscribes for all events](./spec/acceptance/realtime/channel_spec.rb#L1850)
      * with a callback that raises an exception
        * [logs the error and continues](./spec/acceptance/realtime/channel_spec.rb#L1862)
      * many times with different event names
        * [filters events accordingly to each callback](./spec/acceptance/realtime/channel_spec.rb#L1883)
    * #unsubscribe
      * with an event argument
        * [unsubscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L1908)
      * with no event argument
        * [unsubscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L1923)
    * when connection state changes to
      * :failed
        * an :attaching channel
          * [transitions state to :failed (#RTL3a)](./spec/acceptance/realtime/channel_spec.rb#L1948)
        * an :attached channel
          * [transitions state to :failed (#RTL3a)](./spec/acceptance/realtime/channel_spec.rb#L1965)
          * [updates the channel error_reason (#RTL3a)](./spec/acceptance/realtime/channel_spec.rb#L1979)
        * a :detached channel
          * [remains in the :detached state (#RTL3a)](./spec/acceptance/realtime/channel_spec.rb#L1995)
        * a :failed channel
          * [remains in the :failed state and ignores the failure error (#RTL3a)](./spec/acceptance/realtime/channel_spec.rb#L2018)
        * a channel ATTACH request
          * [fails the deferrable (#RTL4b)](./spec/acceptance/realtime/channel_spec.rb#L2040)
      * :closed
        * an :attached channel
          * [transitions state to :detached (#RTL3b)](./spec/acceptance/realtime/channel_spec.rb#L2056)
        * an :attaching channel (#RTL3b)
          * [transitions state to :detached](./spec/acceptance/realtime/channel_spec.rb#L2069)
        * a :detached channel
          * [remains in the :detached state (#RTL3b)](./spec/acceptance/realtime/channel_spec.rb#L2086)
        * a :failed channel
          * [remains in the :failed state and retains the error_reason (#RTL3b)](./spec/acceptance/realtime/channel_spec.rb#L2109)
        * a channel ATTACH request when connection CLOSED
          * [fails the deferrable (#RTL4b)](./spec/acceptance/realtime/channel_spec.rb#L2131)
        * a channel ATTACH request when connection CLOSING
          * [fails the deferrable (#RTL4b)](./spec/acceptance/realtime/channel_spec.rb#L2145)
      * :suspended
        * an :attaching channel
          * [transitions state to :suspended (#RTL3c)](./spec/acceptance/realtime/channel_spec.rb#L2161)
        * an :attached channel
          * [transitions state to :suspended (#RTL3c)](./spec/acceptance/realtime/channel_spec.rb#L2175)
          * reattaching (#RTN15c3)
            * [transitions state automatically to :attaching once the connection is re-established ](./spec/acceptance/realtime/channel_spec.rb#L2188)
            * [sends ATTACH_RESUME flag when reattaching (RTL4j)](./spec/acceptance/realtime/channel_spec.rb#L2203)
        * a :detached channel
          * [remains in the :detached state (#RTL3c)](./spec/acceptance/realtime/channel_spec.rb#L2225)
        * a :failed channel
          * [remains in the :failed state and retains the error_reason (#RTL3c)](./spec/acceptance/realtime/channel_spec.rb#L2248)
        * a channel ATTACH request when connection SUSPENDED (#RTL4b)
          * [fails the deferrable](./spec/acceptance/realtime/channel_spec.rb#L2272)
      * :connected
        * a :suspended channel
          * [is automatically reattached (#RTL3d)](./spec/acceptance/realtime/channel_spec.rb#L2288)
          * when re-attach attempt fails
            * [returns to a suspended state (#RTL3d)](./spec/acceptance/realtime/channel_spec.rb#L2307)
      * :disconnected
        * with an initialized channel
          * [has no effect on the channel states (#RTL3e)](./spec/acceptance/realtime/channel_spec.rb#L2336)
        * with an attaching channel
          * [has no effect on the channel states (#RTL3e)](./spec/acceptance/realtime/channel_spec.rb#L2349)
        * with an attached channel
          * [has no effect on the channel states (#RTL3e)](./spec/acceptance/realtime/channel_spec.rb#L2364)
        * with a detached channel
          * [has no effect on the channel states (#RTL3e)](./spec/acceptance/realtime/channel_spec.rb#L2380)
        * with a failed channel
          * [has no effect on the channel states (#RTL3e)](./spec/acceptance/realtime/channel_spec.rb#L2404)
    * #presence
      * [returns a Ably::Realtime::Presence object](./spec/acceptance/realtime/channel_spec.rb#L2419)
    * #set_options (#RTL16a)
      * when channel is attaching
        * behaves like an update that sends ATTACH message
          * [sends an ATTACH message on options change](./spec/acceptance/realtime/channel_spec.rb#L2436)
      * when channel is attached
        * behaves like an update that sends ATTACH message
          * [sends an ATTACH message on options change](./spec/acceptance/realtime/channel_spec.rb#L2436)
      * when channel is initialized
        * [doesn't send ATTACH message](./spec/acceptance/realtime/channel_spec.rb#L2469)
    * channel state change
      * [emits a ChannelStateChange object](./spec/acceptance/realtime/channel_spec.rb#L2485)
      * ChannelStateChange object
        * [has current state](./spec/acceptance/realtime/channel_spec.rb#L2494)
        * [has a previous state](./spec/acceptance/realtime/channel_spec.rb#L2503)
        * [has the event that generated the state change (#TA5)](./spec/acceptance/realtime/channel_spec.rb#L2512)
        * [has an empty reason when there is no error](./spec/acceptance/realtime/channel_spec.rb#L2530)
        * on failure
          * [has a reason Error object when there is an error on the channel](./spec/acceptance/realtime/channel_spec.rb#L2545)
        * #resume (#RTL2f)
          * [is false when a channel first attaches](./spec/acceptance/realtime/channel_spec.rb#L2560)
          * [is true when a connection is recovered and the channel is attached](./spec/acceptance/realtime/channel_spec.rb#L2568)
          * [is false when a connection fails to recover and the channel is attached](./spec/acceptance/realtime/channel_spec.rb#L2587)
          * when a connection resume fails
            * [is false when channel_serial goes nil (RTP5a1) and the channel is automatically re-attached](./spec/acceptance/realtime/channel_spec.rb#L2609)
            * [is true when channel_serial is intact and the channel is automatically re-attached](./spec/acceptance/realtime/channel_spec.rb#L2627)
      * moves to
        * suspended
          * [all queued messages fail with NACK (#RTL11)](./spec/acceptance/realtime/channel_spec.rb#L2654)
          * [all published messages awaiting an ACK do nothing (#RTL11a)](./spec/acceptance/realtime/channel_spec.rb#L2677)
        * failed
          * [all queued messages fail with NACK (#RTL11)](./spec/acceptance/realtime/channel_spec.rb#L2654)
          * [all published messages awaiting an ACK do nothing (#RTL11a)](./spec/acceptance/realtime/channel_spec.rb#L2677)
    * when it receives a server-initiated DETACHED (#RTL13)
      * and channel is initialized (#RTL13)
        * [does nothing](./spec/acceptance/realtime/channel_spec.rb#L2712)
      * and channel is failed
        * [does nothing (#RTL13)](./spec/acceptance/realtime/channel_spec.rb#L2733)
      * and channel is attached
        * [reattaches immediately (#RTL13a) with ATTACH_RESUME flag(RTL4j)](./spec/acceptance/realtime/channel_spec.rb#L2749)
      * and channel is suspended
        * [reattaches immediately (#RTL13a) with ATTACH_RESUME flag(RTL4j)](./spec/acceptance/realtime/channel_spec.rb#L2778)
        * when connection is no longer connected
          * [will not attempt to reattach (#RTL13c)](./spec/acceptance/realtime/channel_spec.rb#L2810)
      * and channel is attaching
        * [will move to the SUSPENDED state and then attempt to ATTACH with the ATTACHING state (#RTL13b)](./spec/acceptance/realtime/channel_spec.rb#L2836)
    * when it receives an ERROR ProtocolMessage
      * [should transition to the failed state and the error_reason should be set (#RTL14)](./spec/acceptance/realtime/channel_spec.rb#L2885)

### Ably::Realtime::Channels
_(see [spec/acceptance/realtime/channels_spec.rb](./spec/acceptance/realtime/channels_spec.rb))_
  * using JSON protocol
    * when channel supposed to trigger reattachment per RTL16a (#RTS3c1)
      * [will raise an error](./spec/acceptance/realtime/channels_spec.rb#L34)
      * params keys are the same but values are different
        * [will raise an error](./spec/acceptance/realtime/channels_spec.rb#L50)
    * using shortcut method #channel on the client object
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/realtime/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/realtime/channels_spec.rb#L12)
    * using #get method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/realtime/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/realtime/channels_spec.rb#L12)
    * accessing an existing channel object with different options
      * [overrides the existing channel options and returns the channel object](./spec/acceptance/realtime/channels_spec.rb#L82)
      * [shows deprecation warning](./spec/acceptance/realtime/channels_spec.rb#L90)
    * accessing an existing channel object without specifying any channel options
      * [returns the existing channel without modifying the channel options](./spec/acceptance/realtime/channels_spec.rb#L105)
    * using undocumented array accessor [] method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/realtime/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/realtime/channels_spec.rb#L12)

### Ably::Realtime::Client
_(see [spec/acceptance/realtime/client_spec.rb](./spec/acceptance/realtime/client_spec.rb))_
  * using JSON protocol
    * initialization
      * basic auth
        * [is enabled by default with a provided :key option](./spec/acceptance/realtime/client_spec.rb#L19)
        * with an invalid API key
          * [logs an entry with a help href url matching the code #TI5](./spec/acceptance/realtime/client_spec.rb#L32)
        * :tls option
          * set to false to force a plain-text connection
            * [fails to connect because a private key cannot be sent over a non-secure connection](./spec/acceptance/realtime/client_spec.rb#L48)
      * token auth
        * with TLS enabled
          * and a pre-generated Token provided with the :token option
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L69)
          * with valid :key and :use_token_auth option set to true
            * [automatically authorizes on connect and generates a token](./spec/acceptance/realtime/client_spec.rb#L82)
        * with TLS disabled
          * and a pre-generated Token provided with the :token option
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L69)
          * with valid :key and :use_token_auth option set to true
            * [automatically authorizes on connect and generates a token](./spec/acceptance/realtime/client_spec.rb#L82)
        * with a Proc for the :auth_callback option
          * [calls the Proc](./spec/acceptance/realtime/client_spec.rb#L104)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/realtime/client_spec.rb#L111)
          * when the returned token has a client_id
            * [sets Auth#client_id to the new token's client_id immediately when connecting](./spec/acceptance/realtime/client_spec.rb#L119)
            * [sets Client#client_id to the new token's client_id immediately when connecting](./spec/acceptance/realtime/client_spec.rb#L127)
          * with a wildcard client_id token 
            * and an explicit client_id in ClientOptions
              * PENDING: *[allows uses the explicit client_id in the connection](./spec/acceptance/realtime/client_spec.rb#L146)*
            * and client_id omitted in ClientOptions
              * [uses the token provided clientId in the connection](./spec/acceptance/realtime/client_spec.rb#L162)
        * with an invalid wildcard "*" :client_id
          * [raises an exception](./spec/acceptance/realtime/client_spec.rb#L178)
      * realtime connection settings
        * defaults
          * [disconnected_retry_timeout is 15s](./spec/acceptance/realtime/client_spec.rb#L187)
          * [suspended_retry_timeout is 30s](./spec/acceptance/realtime/client_spec.rb#L192)
        * overriden in ClientOptions
          * [disconnected_retry_timeout is updated](./spec/acceptance/realtime/client_spec.rb#L201)
          * [suspended_retry_timeout is updated](./spec/acceptance/realtime/client_spec.rb#L206)
    * #connection
      * [provides access to the Connection object](./spec/acceptance/realtime/client_spec.rb#L215)
    * #channels
      * [provides access to the Channels collection object](./spec/acceptance/realtime/client_spec.rb#L222)
    * #auth
      * [provides access to the Realtime::Auth object](./spec/acceptance/realtime/client_spec.rb#L229)
    * #request (#RSC19*)
      * get
        * [returns an HttpPaginatedResponse object](./spec/acceptance/realtime/client_spec.rb#L241)
        * 404 request to invalid URL
          * [returns an object with 404 status code and error message](./spec/acceptance/realtime/client_spec.rb#L250)
        * paged results
          * [provides paging](./spec/acceptance/realtime/client_spec.rb#L264)
      * post
        * [supports post](./spec/acceptance/realtime/client_spec.rb#L295)
      * delete
        * [supports delete](./spec/acceptance/realtime/client_spec.rb#L309)
      * patch
        * [supports patch](./spec/acceptance/realtime/client_spec.rb#L326)
      * put
        * [supports put](./spec/acceptance/realtime/client_spec.rb#L350)
    * #publish (#TBC)
      * [publishing a message implicity connects and publishes the message successfully on the provided channel](./spec/acceptance/realtime/client_spec.rb#L368)
      * [publishing does not result in a channel being created](./spec/acceptance/realtime/client_spec.rb#L380)
      * [publishing supports an array of Message objects](./spec/acceptance/realtime/client_spec.rb#L408)
      * [publishing supports an array of Hash objects](./spec/acceptance/realtime/client_spec.rb#L420)
      * [publishing on a closed connection fails](./spec/acceptance/realtime/client_spec.rb#L432)
      * with extras
        * [publishing supports extras](./spec/acceptance/realtime/client_spec.rb#L396)
      * queue_messages ClientOption
        * when true
          * [will queue messages whilst connecting and publish once connected](./spec/acceptance/realtime/client_spec.rb#L448)
        * when false
          * [will reject messages on an initializing connection](./spec/acceptance/realtime/client_spec.rb#L465)
      * with more than allowed messages in a single publish
        * [rejects the publish](./spec/acceptance/realtime/client_spec.rb#L482)

### Ably::Realtime::Connection failures
_(see [spec/acceptance/realtime/connection_failures_spec.rb](./spec/acceptance/realtime/connection_failures_spec.rb))_
  * using JSON protocol
    * authentication failure
      * when API key is invalid
        * with invalid app part of the key
          * [enters the failed state and returns a not found error](./spec/acceptance/realtime/connection_failures_spec.rb#L29)
        * with invalid key name part of the key
          * [enters the failed state and returns an authorization error](./spec/acceptance/realtime/connection_failures_spec.rb#L44)
      * with auth_url
        * opening a new connection
          * request fails due to network failure
            * [the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)](./spec/acceptance/realtime/connection_failures_spec.rb#L62)
          * request fails due to invalid content
            * [the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)](./spec/acceptance/realtime/connection_failures_spec.rb#L92)
          * request fails due to slow response and subsequent timeout
            * [the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)](./spec/acceptance/realtime/connection_failures_spec.rb#L127)
          * request fails once due to slow response but succeeds the second time
            * [the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)](./spec/acceptance/realtime/connection_failures_spec.rb#L175)
        * existing CONNECTED connection
          * authorize request failure leaves connection in existing condition
            * [the connection remains in the CONNECTED state and authorize fails (#RSA4c, #RSA4c1, #RSA4c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L196)
      * with auth_callback
        * opening a new connection
          * when callback fails due to an exception
            * [the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)](./spec/acceptance/realtime/connection_failures_spec.rb#L224)
          * existing CONNECTED connection
            * when callback fails due to the request taking longer than realtime_request_timeout
              * [the authorization request fails as configured in the realtime_request_timeout (#RSA4c, #RSA4c1, #RSA4c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L255)
    * automatic connection retry
      * with invalid WebSocket host
        * when disconnected
          * [enters the suspended state after multiple attempts to connect](./spec/acceptance/realtime/connection_failures_spec.rb#L320)
          * for the first time
            * [reattempts connection immediately and then waits disconnected_retry_timeout for a subsequent attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L341)
          * #close
            * [transitions connection state to :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L358)
        * when connection state is :suspended
          * [stays in the suspended state after any number of reconnection attempts](./spec/acceptance/realtime/connection_failures_spec.rb#L377)
          * for the first time
            * [waits suspended_retry_timeout before attempting to reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L400)
          * #close
            * [transitions connection state to :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L422)
        * when connection state is :failed
          * #close
            * [will not transition state to :close and fails with an InvalidStateChange exception](./spec/acceptance/realtime/connection_failures_spec.rb#L441)
        * #error_reason
          * [contains the error when state is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L462)
          * [contains the error when state is suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L462)
          * [contains the error when state is failed](./spec/acceptance/realtime/connection_failures_spec.rb#L462)
          * [is reset to nil when :connected](./spec/acceptance/realtime/connection_failures_spec.rb#L476)
          * [is reset to nil when :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L487)
      * #connect
        * connection opening times out
          * [attempts to reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L518)
          * when retry intervals are stubbed to attempt reconnection quickly
            * [never calls the provided success block](./spec/acceptance/realtime/connection_failures_spec.rb#L542)
    * connection resume
      * when DISCONNECTED ProtocolMessage received from the server
        * [reconnects automatically and immediately (#RTN15a)](./spec/acceptance/realtime/connection_failures_spec.rb#L573)
        * when protocolMessage contains token error
          * library does not have a means to renew the token (#RTN15h1)
            * [moves connection state to failed](./spec/acceptance/realtime/connection_failures_spec.rb#L601)
          * library have a means to renew the token (#RTN15h2)
            * [attempts to reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L625)
        * connection state freshness is monitored
          * [resumes connections when disconnected within the connection_state_ttl period (#RTN15g)](./spec/acceptance/realtime/connection_failures_spec.rb#L649)
          * when connection_state_ttl period has passed since being disconnected
            * [clears the local connection state and uses a new connection when the connection_state_ttl period has passed (#RTN15g)](./spec/acceptance/realtime/connection_failures_spec.rb#L689)
          * when connection_state_ttl period has passed since last activity on the connection
            * [does not clear the local connection state when the connection_state_ttl period has passed since last activity, but the idle timeout has not passed (#RTN15g1, #RTN15g2)](./spec/acceptance/realtime/connection_failures_spec.rb#L742)
            * [clears the local connection state and uses a new connection when the connection_state_ttl + max_idle_interval period has passed since last activity (#RTN15g1, #RTN15g2)](./spec/acceptance/realtime/connection_failures_spec.rb#L774)
            * [still reattaches the channels automatically following a new connection being established (#RTN15g2)](./spec/acceptance/realtime/connection_failures_spec.rb#L807)
        * and subsequently fails to reconnect
          * [retries every 15 seconds](./spec/acceptance/realtime/connection_failures_spec.rb#L863)
      * when websocket transport is abruptly disconnected
        * [reconnects automatically](./spec/acceptance/realtime/connection_failures_spec.rb#L906)
        * hosts used
          * [reconnects with the default host](./spec/acceptance/realtime/connection_failures_spec.rb#L922)
      * after successfully reconnecting and resuming
        * [retains connection_id and updates the connection_key (#RTN15e, #RTN16d)](./spec/acceptance/realtime/connection_failures_spec.rb#L946)
        * [includes the error received in the connection state change from Ably but leaves the channels attached](./spec/acceptance/realtime/connection_failures_spec.rb#L961)
        * [retains channel subscription state](./spec/acceptance/realtime/connection_failures_spec.rb#L987)
        * [retains the client_msg_serial (#RTN15c2, #RTN15c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L1038)
        * when messages were published whilst the client was disconnected
          * [receives the messages published whilst offline](./spec/acceptance/realtime/connection_failures_spec.rb#L1005)
      * when failing to resume
        * because the connection_key is not or no longer valid
          * [updates the connection_id and connection_key](./spec/acceptance/realtime/connection_failures_spec.rb#L1078)
          * [issue a reattach for all attached channels and fail all message awaiting an ACK (#RTN15c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L1093)
          * [issue a reattach for all attaching channels and fail all queued messages (#RTN15c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L1131)
          * [issue a attach for all suspended channels (#RTN15c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L1167)
          * [sets the error reason on each channel](./spec/acceptance/realtime/connection_failures_spec.rb#L1205)
          * [continues to use the client_msg_serial (#RTN15c3)](./spec/acceptance/realtime/connection_failures_spec.rb#L1220)
        * as the DISCONNECTED window to resume has passed
          * [starts a new connection automatically and does not try and resume](./spec/acceptance/realtime/connection_failures_spec.rb#L1257)
      * when an ERROR protocol message is received
        * whilst connecting
          * with a token error code in the range 40140 <= code < 40150 (#RTN14b)
            * [triggers a re-authentication](./spec/acceptance/realtime/connection_failures_spec.rb#L1288)
          * with an error code indicating an error other than a token failure (#RTN14g, #RTN15i)
            * [causes the connection to fail](./spec/acceptance/realtime/connection_failures_spec.rb#L1304)
          * with no error code indicating an error other than a token failure (#RTN14g, #RTN15i)
            * [causes the connection to fail](./spec/acceptance/realtime/connection_failures_spec.rb#L1317)
        * whilst connected
          * with a token error code in the range 40140 <= code < 40150 (#RTN14b)
            * [triggers a re-authentication](./spec/acceptance/realtime/connection_failures_spec.rb#L1288)
          * with an error code indicating an error other than a token failure (#RTN14g, #RTN15i)
            * [causes the connection to fail](./spec/acceptance/realtime/connection_failures_spec.rb#L1304)
          * with no error code indicating an error other than a token failure (#RTN14g, #RTN15i)
            * [causes the connection to fail](./spec/acceptance/realtime/connection_failures_spec.rb#L1317)
      * whilst resuming
        * with a token error code in the region 40140 <= code < 40150 (RTN15c5)
          * [triggers a re-authentication and then resumes the connection](./spec/acceptance/realtime/connection_failures_spec.rb#L1361)
      * with any other error (#RTN15c4)
        * [moves the connection to the failed state](./spec/acceptance/realtime/connection_failures_spec.rb#L1395)
    * fallback host feature
      * with custom realtime websocket host option
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L1439)
      * with custom realtime websocket port option
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L1457)
      * with non-production environment
        * :fallback_hosts_use_default is unset
          * [uses fallback hosts by default](./spec/acceptance/realtime/connection_failures_spec.rb#L1481)
        * :fallback_hosts_use_default is true
          * [uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k7)](./spec/acceptance/realtime/connection_failures_spec.rb#L1499)
          * [does not use a fallback host if the connection connects on the default host and then later becomes disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L1517)
        * :fallback_hosts array is provided
          * [uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k6)](./spec/acceptance/realtime/connection_failures_spec.rb#L1545)
      * with production environment
        * when the Internet is down
          * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L1581)
        * when the Internet is up
          * and default options
            * [uses a fallback host + the original host once on every subsequent disconnected attempt until suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L1604)
            * [uses the primary host when suspended, and then every fallback host and the primary host again on every subsequent suspended attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L1623)
            * [uses the correct host name for the WebSocket requests to the fallback hosts](./spec/acceptance/realtime/connection_failures_spec.rb#L1646)
          * :fallback_hosts array is provided by an empty array
            * [uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k6)](./spec/acceptance/realtime/connection_failures_spec.rb#L1676)
          * :fallback_hosts array is provided
            * [uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k6)](./spec/acceptance/realtime/connection_failures_spec.rb#L1696)

### Ably::Realtime::Connection
_(see [spec/acceptance/realtime/connection_spec.rb](./spec/acceptance/realtime/connection_spec.rb))_
  * using JSON protocol
    * intialization
      * [connects automatically](./spec/acceptance/realtime/connection_spec.rb#L23)
      * current_host
        * [is available immediately after the client is instanced](./spec/acceptance/realtime/connection_spec.rb#L31)
      * with :auto_connect option set to false
        * [does not connect automatically](./spec/acceptance/realtime/connection_spec.rb#L42)
        * [connects when method #connect is called](./spec/acceptance/realtime/connection_spec.rb#L50)
      * with token auth
        * for renewable tokens
          * that are valid for the duration of the test
            * with valid pre authorized token expiring in the future
              * [uses the existing token created by Auth](./spec/acceptance/realtime/connection_spec.rb#L72)
          * that expire
            * opening a new connection
              * with almost expired tokens
                * FAILED: ~~[renews token every time after it expires](./spec/acceptance/realtime/connection_spec.rb#L107)~~
              * with immediately expired token and no fallback hosts
                * [renews the token on connect, and makes one immediate subsequent attempt to obtain a new token (#RSA4b)](./spec/acceptance/realtime/connection_spec.rb#L137)
                * when disconnected_retry_timeout is 0.5 seconds
                  * [renews the token on connect, and continues to attempt renew based on the retry schedule](./spec/acceptance/realtime/connection_spec.rb#L152)
                * using implicit token auth
                  * [uses the primary host for subsequent connection and auth requests](./spec/acceptance/realtime/connection_spec.rb#L182)
            * when connected with a valid non-expired token
              * that then expires following the connection being opened
                * the server
                  * [disconnects the client, and the client automatically renews the token and then reconnects](./spec/acceptance/realtime/connection_spec.rb#L213)
                * connection state
                  * [retains messages published when disconnected three times during authentication](./spec/acceptance/realtime/connection_spec.rb#L273)
                * and subsequent token is invalid
                  * [transitions the connection to the failed state](./spec/acceptance/realtime/connection_spec.rb#L308)
        * for non-renewable tokens
          * that are expired
            * opening a new connection
              * [transitions state to failed (#RSA4a)](./spec/acceptance/realtime/connection_spec.rb#L338)
            * when connected
              * [transitions state to failed (#RSA4a)](./spec/acceptance/realtime/connection_spec.rb#L354)
        * with opaque token string that contain an implicit client_id
          * string
            * [sets the Client#client_id and Auth#client_id once CONNECTED](./spec/acceptance/realtime/connection_spec.rb#L374)
            * that is incompatible with the current client client_id
              * PENDING: *[fails the connection](./spec/acceptance/realtime/connection_spec.rb#L387)*
          * wildcard
            * [configures the Client#client_id and Auth#client_id with a wildcard once CONNECTED](./spec/acceptance/realtime/connection_spec.rb#L401)
    * initialization state changes
      * with implicit #connect
        * [are emitted in order](./spec/acceptance/realtime/connection_spec.rb#L433)
      * with explicit #connect
        * [are emitted in order](./spec/acceptance/realtime/connection_spec.rb#L439)
    * #connect with no fallbacks
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/connection_spec.rb#L449)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/connection_spec.rb#L454)
      * [calls the provided block on success even if state changes to disconnected first](./spec/acceptance/realtime/connection_spec.rb#L461)
      * when can't connect to host
        * [logs error on failed connection attempt](./spec/acceptance/realtime/connection_spec.rb#L490)
      * when explicitly reconnecting disconnected/suspended connection in retry (#RTN11c)
        * when suspended
          * [reconnects immediately](./spec/acceptance/realtime/connection_spec.rb#L530)
        * when disconnected
          * [reconnects immediately](./spec/acceptance/realtime/connection_spec.rb#L564)
      * when reconnecting a failed connection
        * [transitions all channels state to initialized and cleares error_reason](./spec/acceptance/realtime/connection_spec.rb#L594)
      * with invalid auth details
        * [calls the Deferrable errback only once on connection failure](./spec/acceptance/realtime/connection_spec.rb#L622)
      * when already connected
        * [does nothing and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L638)
      * connection#id
        * [is null before connecting](./spec/acceptance/realtime/connection_spec.rb#L652)
      * connection#key
        * [is null before connecting](./spec/acceptance/realtime/connection_spec.rb#L659)
      * once connected
        * connection#id
          * [is a string](./spec/acceptance/realtime/connection_spec.rb#L670)
          * [is unique from the connection#key](./spec/acceptance/realtime/connection_spec.rb#L677)
          * [is unique for every connection](./spec/acceptance/realtime/connection_spec.rb#L684)
        * connection#key
          * [is a string](./spec/acceptance/realtime/connection_spec.rb#L693)
          * [is unique from the connection#id](./spec/acceptance/realtime/connection_spec.rb#L700)
          * [is unique for every connection](./spec/acceptance/realtime/connection_spec.rb#L707)
      * following a previous connection being opened and closed
        * [reconnects and is provided with a new connection ID and connection key from the server](./spec/acceptance/realtime/connection_spec.rb#L717)
      * when closing
        * [fails the deferrable before the connection is closed](./spec/acceptance/realtime/connection_spec.rb#L734)
    * #msgSerial
      * when messages are queued for publish before a connection is established
        * [the msgSerial is always incrementing (and not reset when the new connection is established) ensuring messages are never de-duped by the realtime service](./spec/acceptance/realtime/connection_spec.rb#L758)
    * #close
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/connection_spec.rb#L790)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/connection_spec.rb#L797)
      * when already closed
        * [does nothing and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L808)
      * when connection state is
        * :initialized
          * [changes the connection state to :closing and then immediately :closed without sending a ProtocolMessage CLOSE](./spec/acceptance/realtime/connection_spec.rb#L835)
        * :connecting RTN12f
          * :connected does not arrive when trying to close
            * [moves to closed](./spec/acceptance/realtime/connection_spec.rb#L853)
          * :connected arrive when trying to close
            * [moves to connected and then to closed](./spec/acceptance/realtime/connection_spec.rb#L880)
        * :connected
          * [changes the connection state to :closing and waits for the server to confirm connection is :closed with a ProtocolMessage](./spec/acceptance/realtime/connection_spec.rb#L901)
          * with an unresponsive connection
            * [force closes the connection when a :closed ProtocolMessage response is not received](./spec/acceptance/realtime/connection_spec.rb#L928)
        * :suspended RTN12d
          * [immediatly closes connection](./spec/acceptance/realtime/connection_spec.rb#L957)
        * :disconnected RTN12d
          * [immediatly closes connection](./spec/acceptance/realtime/connection_spec.rb#L992)
    * #ping
      * [echoes a heart beat (#RTN13a)](./spec/acceptance/realtime/connection_spec.rb#L1025)
      * [sends a unique ID in each protocol message (#RTN13e)](./spec/acceptance/realtime/connection_spec.rb#L1035)
      * [waits until the connection becomes CONNECTED when in the CONNETING state](./spec/acceptance/realtime/connection_spec.rb#L1059)
      * with incompatible states
        * when not connected
          * [fails the deferrable (#RTN13b)](./spec/acceptance/realtime/connection_spec.rb#L1072)
        * when suspended
          * [fails the deferrable (#RTN13b)](./spec/acceptance/realtime/connection_spec.rb#L1081)
        * when failed
          * [fails the deferrable (#RTN13b)](./spec/acceptance/realtime/connection_spec.rb#L1093)
        * when closed
          * [fails the deferrable (#RTN13b)](./spec/acceptance/realtime/connection_spec.rb#L1105)
        * when it becomes closed
          * [fails the deferrable (#RTN13b)](./spec/acceptance/realtime/connection_spec.rb#L1119)
      * with a success block that raises an exception
        * [catches the exception and logs the error](./spec/acceptance/realtime/connection_spec.rb#L1132)
      * when ping times out
        * [fails the deferrable logs a warning (#RTN13a, #RTN13c)](./spec/acceptance/realtime/connection_spec.rb#L1146)
        * [yields to the block with a nil value](./spec/acceptance/realtime/connection_spec.rb#L1165)
    * Heartbeats (#RTN23)
      * heartbeat interval
        * when reduced artificially
          * [is the sum of the max_idle_interval and realtime_request_timeout (#RTN23a)](./spec/acceptance/realtime/connection_spec.rb#L1191)
          * [disconnects the transport if no heartbeat received since connected (#RTN23a)](./spec/acceptance/realtime/connection_spec.rb#L1201)
          * [disconnects the transport if no heartbeat received since last event received (#RTN23a)](./spec/acceptance/realtime/connection_spec.rb#L1212)
      * transport-level heartbeats are supported in the websocket transport
        * [provides the heartbeats argument in the websocket connection params (#RTN23b)](./spec/acceptance/realtime/connection_spec.rb#L1227)
        * [receives websocket heartbeat messages (#RTN23b) [slow test as need to wait for heartbeat]](./spec/acceptance/realtime/connection_spec.rb#L1236)
      * with websocket heartbeats disabled (undocumented)
        * [does not provide the heartbeats argument in the websocket connection params (#RTN23b)](./spec/acceptance/realtime/connection_spec.rb#L1252)
        * [receives websocket protocol messages (#RTN23b) [slow test as need to wait for heartbeat]](./spec/acceptance/realtime/connection_spec.rb#L1261)
    * #details
      * [is nil before connected](./spec/acceptance/realtime/connection_spec.rb#L1279)
      * [contains the ConnectionDetails object once connected (#RTN21)](./spec/acceptance/realtime/connection_spec.rb#L1286)
      * [contains the new ConnectionDetails object once a subsequent connection is created (#RTN21)](./spec/acceptance/realtime/connection_spec.rb#L1295)
      * with a different default connection_state_ttl
        * [updates the private Connection#connection_state_ttl when received from Ably in ConnectionDetails](./spec/acceptance/realtime/connection_spec.rb#L1316)
    * recovery
      * #recovery_key
        * [is available when connection is in one of the states: connecting, connected, disconnected](./spec/acceptance/realtime/connection_spec.rb#L1353)
        * [is nil when connection is explicitly CLOSED](./spec/acceptance/realtime/connection_spec.rb#L1383)
      * opening a new connection using a recently disconnected connection's #recovery_key
        * connection#id after recovery
          * [remains the same](./spec/acceptance/realtime/connection_spec.rb#L1395)
        * when messages have been sent whilst the old connection is disconnected
          * the new connection
            * [recovers server-side queued messages](./spec/acceptance/realtime/connection_spec.rb#L1417)
        * when messages have been published
          * the new connection
            * [uses the correct msgSerial from the old connection](./spec/acceptance/realtime/connection_spec.rb#L1446)
        * when messages are published before the new connection is recovered
          * the new connection
            * [uses the correct msgSerial from the old connection for the queued messages](./spec/acceptance/realtime/connection_spec.rb#L1476)
      * with :recover option
        * with invalid syntax
          * [logs recovery decode error as a warning and connects successfully](./spec/acceptance/realtime/connection_spec.rb#L1523)
        * with invalid connection key
          * [connects but sets the error reason and includes the reason in the state change](./spec/acceptance/realtime/connection_spec.rb#L1538)
    * with many connections simultaneously
      * [opens each with a unique connection#id and connection#key](./spec/acceptance/realtime/connection_spec.rb#L1557)
    * when a state transition is unsupported
      * [logs the invalid state change as fatal](./spec/acceptance/realtime/connection_spec.rb#L1577)
    * protocol failure
      * receiving an invalid ProtocolMessage
        * [emits an error on the connection and logs a fatal error message](./spec/acceptance/realtime/connection_spec.rb#L1593)
    * undocumented method
      * #internet_up?
        * [returns a Deferrable](./spec/acceptance/realtime/connection_spec.rb#L1611)
        * internet up URL protocol
          * when using TLS for the connection
            * [uses TLS for the Internet check to https://internet-up.ably-realtime.com/is-the-internet-up.txt](./spec/acceptance/realtime/connection_spec.rb#L1622)
          * when using a non-secured connection
            * [uses TLS for the Internet check to http://internet-up.ably-realtime.com/is-the-internet-up.txt](./spec/acceptance/realtime/connection_spec.rb#L1632)
        * when the Internet is up
          * [calls the block with true](./spec/acceptance/realtime/connection_spec.rb#L1663)
          * [calls the success callback of the Deferrable](./spec/acceptance/realtime/connection_spec.rb#L1670)
          * with a TLS connection
            * [checks the Internet up URL over TLS](./spec/acceptance/realtime/connection_spec.rb#L1646)
          * with a non-TLS connection
            * [checks the Internet up URL over TLS](./spec/acceptance/realtime/connection_spec.rb#L1656)
        * when the Internet is down
          * [calls the block with false](./spec/acceptance/realtime/connection_spec.rb#L1685)
          * [calls the failure callback of the Deferrable](./spec/acceptance/realtime/connection_spec.rb#L1692)
    * state change side effects
      * when connection enters the :disconnected state
        * [queues messages to be sent and all channels remain attached](./spec/acceptance/realtime/connection_spec.rb#L1706)
      * when connection enters the :suspended state
        * [moves the channels into the suspended state and prevents publishing of messages on those channels](./spec/acceptance/realtime/connection_spec.rb#L1739)
      * when connection enters the :failed state
        * [sets all channels to failed and prevents publishing of messages on those channels](./spec/acceptance/realtime/connection_spec.rb#L1770)
    * connection state change
      * [emits event to all and single subscribers](./spec/acceptance/realtime/connection_spec.rb#L1784)
      * [emits a ConnectionStateChange object](./spec/acceptance/realtime/connection_spec.rb#L1799)
      * ConnectionStateChange object
        * [has current state](./spec/acceptance/realtime/connection_spec.rb#L1807)
        * [has a previous state](./spec/acceptance/realtime/connection_spec.rb#L1815)
        * [has the event that generated the state change (#TH5)](./spec/acceptance/realtime/connection_spec.rb#L1823)
        * [has an empty reason when there is no error](./spec/acceptance/realtime/connection_spec.rb#L1839)
        * on failure
          * [has a reason Error object when there is an error on the connection](./spec/acceptance/realtime/connection_spec.rb#L1852)
        * retry_in
          * [is nil when a retry is not required](./spec/acceptance/realtime/connection_spec.rb#L1867)
          * FAILED: ~~[is 0 when first attempt to connect fails](./spec/acceptance/realtime/connection_spec.rb#L1874)~~
          * [is 0 when an immediate reconnect will occur](./spec/acceptance/realtime/connection_spec.rb#L1884)
          * [contains the next retry period when an immediate reconnect will not occur](./spec/acceptance/realtime/connection_spec.rb#L1894)
      * whilst CONNECTED
        * when a CONNECTED message is received (#RTN24)
          * [emits an UPDATE event](./spec/acceptance/realtime/connection_spec.rb#L1928)
          * [updates the ConnectionDetail and Connection attributes (#RTC8a1)](./spec/acceptance/realtime/connection_spec.rb#L1943)
        * when a CONNECTED message with an error is received
          * [emits an UPDATE event](./spec/acceptance/realtime/connection_spec.rb#L1976)
    * version params
      * [sends the protocol version param v (#G4, #RTN2f)](./spec/acceptance/realtime/connection_spec.rb#L1997)
      * [sends the lib version param agent (#RCS7d)](./spec/acceptance/realtime/connection_spec.rb#L2006)
    * transport_params (#RTC1f)
      * [pases transport_params to query](./spec/acceptance/realtime/connection_spec.rb#L2019)
      * when changing default param
        * [overrides default param (#RTC1f1)](./spec/acceptance/realtime/connection_spec.rb#L2032)

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
    * a single Message object (#RSL1a)
      * [publishes the message](./spec/acceptance/realtime/message_spec.rb#L83)
    * an array of Message objects (#RSL1a)
      * [publishes three messages](./spec/acceptance/realtime/message_spec.rb#L100)
    * an array of hashes (#RSL1a)
      * [publishes three messages](./spec/acceptance/realtime/message_spec.rb#L123)
    * a name with data payload (#RSL1a, #RSL1b)
      * [publishes a message](./spec/acceptance/realtime/message_spec.rb#L144)
    * with supported extra payload content type (#RTL6h, #RSL6a2)
      * JSON Object (Hash)
        * [is encoded and decoded to the same hash](./spec/acceptance/realtime/message_spec.rb#L170)
      * JSON Array
        * [is encoded and decoded to the same Array](./spec/acceptance/realtime/message_spec.rb#L178)
      * nil
        * [is encoded and decoded to the same Array](./spec/acceptance/realtime/message_spec.rb#L184)
    * with unsupported data payload content type
      * Integer
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/message_spec.rb#L195)
      * Float
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/message_spec.rb#L204)
      * Boolean
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/message_spec.rb#L213)
      * False
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/message_spec.rb#L222)
    * with ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/realtime/message_spec.rb#L231)
    * when the message publisher has a client_id
      * [contains a #client_id attribute](./spec/acceptance/realtime/message_spec.rb#L247)
    * #connection_id attribute
      * over realtime
        * [matches the sender connection#id](./spec/acceptance/realtime/message_spec.rb#L260)
      * when retrieved over REST
        * [matches the sender connection#id](./spec/acceptance/realtime/message_spec.rb#L272)
    * local echo when published
      * [is enabled by default](./spec/acceptance/realtime/message_spec.rb#L284)
      * with :echo_messages option set to false
        * [will not echo messages to the client but will still broadcast messages to other connected clients](./spec/acceptance/realtime/message_spec.rb#L304)
        * [will not echo messages to the client from other REST clients publishing using that connection_key](./spec/acceptance/realtime/message_spec.rb#L322)
        * [will echo messages with a valid connection_id to the client from other REST clients publishing using that connection_key](./spec/acceptance/realtime/message_spec.rb#L335)
    * publishing lots of messages across two connections
      * [sends and receives the messages on both opened connections and calls the success callbacks for each message published](./spec/acceptance/realtime/message_spec.rb#L361)
    * without suitable publishing permissions
      * [calls the error callback](./spec/acceptance/realtime/message_spec.rb#L406)
    * encoding and decoding encrypted messages
      * with AES-128-CBC using crypto-data-128.json fixtures (#RTL7d)
        * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 1 with encrypted encoding cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
      * with AES-256-CBC using crypto-data-256.json fixtures (#RTL7d)
        * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 1 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 4 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 5 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 6 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 7 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 8 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 9 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 10 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 11 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 12 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 13 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 14 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 15 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 16 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 17 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 18 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 19 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 20 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 21 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 22 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 23 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 24 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 25 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 26 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 27 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 28 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 29 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 30 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 31 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 32 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 33 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 34 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 35 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 36 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 37 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 38 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 39 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 40 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 41 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 42 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 43 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 44 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 45 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 46 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 47 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 48 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 49 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 50 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 51 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 52 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 53 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 54 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 55 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 56 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 57 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 58 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 59 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 60 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 61 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 62 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 63 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 64 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 65 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 66 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 67 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 68 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 69 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 70 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 71 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 72 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
        * item 73 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L457)
              * [sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/realtime/message_spec.rb#L477)
      * with multiple sends from one client to another
        * [encrypts and decrypts all messages](./spec/acceptance/realtime/message_spec.rb#L516)
        * [receives raw messages with the correct encoding](./spec/acceptance/realtime/message_spec.rb#L533)
      * subscribing with a different transport protocol
        * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L567)
        * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L567)
        * [delivers a Hash payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L567)
      * publishing on an unencrypted channel and subscribing on an encrypted channel with another client
        * [does not attempt to decrypt the message](./spec/acceptance/realtime/message_spec.rb#L588)
      * publishing on an encrypted channel and subscribing on an unencrypted channel with another client
        * [delivers the message but still encrypted with a value in the #encoding attribute (#RTL7e)](./spec/acceptance/realtime/message_spec.rb#L608)
        * [logs a Cipher error (#RTL7e)](./spec/acceptance/realtime/message_spec.rb#L619)
      * publishing on an encrypted channel and subscribing with a different algorithm on another client
        * [delivers the message but still encrypted with the cipher detials in the #encoding attribute (#RTL7e)](./spec/acceptance/realtime/message_spec.rb#L639)
        * [emits a Cipher error on the channel (#RTL7e)](./spec/acceptance/realtime/message_spec.rb#L650)
      * publishing on an encrypted channel and subscribing with a different key on another client
        * [delivers the message but still encrypted with the cipher details in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L670)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L681)
    * when message is published, the connection disconnects before the ACK is received, and the connection is resumed
      * [publishes the message again, later receives the ACK and only one message is ever received from Ably](./spec/acceptance/realtime/message_spec.rb#L700)
    * when message is published, the connection disconnects before the ACK is received
      * the connection is not resumed
        * [calls the errback for all messages](./spec/acceptance/realtime/message_spec.rb#L745)
      * the connection becomes suspended
        * [calls the errback for all messages](./spec/acceptance/realtime/message_spec.rb#L771)
      * the connection becomes failed
        * [calls the errback for all messages](./spec/acceptance/realtime/message_spec.rb#L798)
  * message encoding interoperability
    * over a JSON transport
      * when decoding string
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L839)
      * when encoding string
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L857)
      * when decoding string
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L839)
      * when encoding string
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L857)
      * when decoding jsonObject
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L839)
      * when encoding jsonObject
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L857)
      * when decoding jsonArray
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L839)
      * when encoding jsonArray
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L857)
      * when decoding binary
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L839)
      * when encoding binary
        * [ensures that client libraries have compatible encoding and decoding using common fixtures](./spec/acceptance/realtime/message_spec.rb#L857)
    * over a MsgPack transport
      * when publishing a string using JSON protocol
        * [receives the message over MsgPack and the data matches](./spec/acceptance/realtime/message_spec.rb#L891)
      * when retrieving a string using JSON protocol
        * [is compatible with a publishes using MsgPack](./spec/acceptance/realtime/message_spec.rb#L919)
      * when publishing a string using JSON protocol
        * [receives the message over MsgPack and the data matches](./spec/acceptance/realtime/message_spec.rb#L891)
      * when retrieving a string using JSON protocol
        * [is compatible with a publishes using MsgPack](./spec/acceptance/realtime/message_spec.rb#L919)
      * when publishing a jsonObject using JSON protocol
        * [receives the message over MsgPack and the data matches](./spec/acceptance/realtime/message_spec.rb#L891)
      * when retrieving a jsonObject using JSON protocol
        * [is compatible with a publishes using MsgPack](./spec/acceptance/realtime/message_spec.rb#L919)
      * when publishing a jsonArray using JSON protocol
        * [receives the message over MsgPack and the data matches](./spec/acceptance/realtime/message_spec.rb#L891)
      * when retrieving a jsonArray using JSON protocol
        * [is compatible with a publishes using MsgPack](./spec/acceptance/realtime/message_spec.rb#L919)
      * when publishing a binary using JSON protocol
        * [receives the message over MsgPack and the data matches](./spec/acceptance/realtime/message_spec.rb#L891)
      * when retrieving a binary using JSON protocol
        * [is compatible with a publishes using MsgPack](./spec/acceptance/realtime/message_spec.rb#L919)

### Ably::Realtime::Presence history
_(see [spec/acceptance/realtime/presence_history_spec.rb](./spec/acceptance/realtime/presence_history_spec.rb))_
  * using JSON protocol
    * [provides up to the moment presence history](./spec/acceptance/realtime/presence_history_spec.rb#L21)
    * [ensures REST presence history message IDs match ProtocolMessage wrapped message and connection IDs via Realtime](./spec/acceptance/realtime/presence_history_spec.rb#L44)

### Ably::Realtime::Presence
_(see [spec/acceptance/realtime/presence_spec.rb](./spec/acceptance/realtime/presence_spec.rb))_
  * using JSON protocol
    * when attached (but not present) on a presence channel with an anonymous client (no client ID)
      * [maintains state as other clients enter and leave the channel (#RTP2e)](./spec/acceptance/realtime/presence_spec.rb#L479)
    * #sync_complete? and SYNC flags (#RTP1)
      * when attaching to a channel without any members present
        * [sync_complete? is true, no members are received and the presence channel is synced (#RTP1)](./spec/acceptance/realtime/presence_spec.rb#L707)
      * when attaching to a channel with members present
        * [sync_complete? is false, there is a presence flag, and the presence channel is subsequently synced (#RTP1)](./spec/acceptance/realtime/presence_spec.rb#L736)
    * 101 existing (present) members on a channel (2 SYNC pages)
      * requiring at least 2 SYNC ProtocolMessages
        * when a client attaches to the presence channel
          * [emits :present for each member](./spec/acceptance/realtime/presence_spec.rb#L788)
          * and a member enters before the SYNC operation is complete
            * [emits a :enter immediately and the member is :present once the sync is complete (#RTP2g)](./spec/acceptance/realtime/presence_spec.rb#L804)
          * and a member leaves before the SYNC operation is complete
            * [emits :leave immediately as the member leaves and cleans up the ABSENT member after (#RTP2f, #RTP2g)](./spec/acceptance/realtime/presence_spec.rb#L841)
            * [ignores presence events with timestamps / identifiers prior to the current :present event in the MembersMap (#RTP2c)](./spec/acceptance/realtime/presence_spec.rb#L889)
            * [does not emit :present after the :leave event has been emitted, and that member is not included in the list of members via #get (#RTP2f)](./spec/acceptance/realtime/presence_spec.rb#L934)
          * #get
            * by default
              * [waits until sync is complete (#RTP11c1)](./spec/acceptance/realtime/presence_spec.rb#L984)
            * with :wait_for_sync option set to false (#RTP11c1)
              * [it does not wait for sync](./spec/acceptance/realtime/presence_spec.rb#L1005)
    * state
      * once opened
        * [once opened, enters the :left state if the channel detaches](./spec/acceptance/realtime/presence_spec.rb#L1032)
    * #enter
      * data attribute
        * when provided as argument option to #enter
          * [changes to value provided in #leave](./spec/acceptance/realtime/presence_spec.rb#L1057)
      * message #connection_id
        * [matches the current client connection_id](./spec/acceptance/realtime/presence_spec.rb#L1081)
      * without necessary capabilities to join presence
        * [calls the Deferrable errback on capabilities failure](./spec/acceptance/realtime/presence_spec.rb#L1100)
      * it should behave like a public presence method
        * [presence enter : raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L63)
        * [presence enter : raise an exception if the channel becomes detached](./spec/acceptance/realtime/presence_spec.rb#L81)
        * [presence enter : raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L97)
        * [presence enter : raise an exception if the channel becomes failed](./spec/acceptance/realtime/presence_spec.rb#L114)
        * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L130)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L293)
        * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L300)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L308)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L318)
        * when :queue_messages client option is false
          * and connection state initialized
            * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L142)
          * and connection state connecting
            * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L152)
          * and connection state disconnected
            * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L167)
          * and connection state connected
            * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L182)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L209)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L219)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L229)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L239)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L259)
          * Float
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L268)
          * Boolean
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L277)
          * False
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L286)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L331)
    * #update
      * [without previous #enter automatically enters](./spec/acceptance/realtime/presence_spec.rb#L1112)
      * [updates the data if :data argument provided](./spec/acceptance/realtime/presence_spec.rb#L1137)
      * [updates the data to nil if :data argument is not provided (assumes nil value)](./spec/acceptance/realtime/presence_spec.rb#L1149)
      * when ENTERED
        * [has no effect on the state](./spec/acceptance/realtime/presence_spec.rb#L1122)
      * it should behave like a public presence method
        * [presence update : raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L63)
        * [presence update : raise an exception if the channel becomes detached](./spec/acceptance/realtime/presence_spec.rb#L81)
        * [presence update : raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L97)
        * [presence update : raise an exception if the channel becomes failed](./spec/acceptance/realtime/presence_spec.rb#L114)
        * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L130)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L293)
        * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L300)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L308)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L318)
        * when :queue_messages client option is false
          * and connection state initialized
            * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L142)
          * and connection state connecting
            * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L152)
          * and connection state disconnected
            * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L167)
          * and connection state connected
            * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L182)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L209)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L219)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L229)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L239)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L259)
          * Float
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L268)
          * Boolean
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L277)
          * False
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L286)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L331)
    * #leave
      * [succeeds and does not emit an event (#RTP10d)](./spec/acceptance/realtime/presence_spec.rb#L1244)
      * :data option
        * when set to a string
          * [emits the new data for the leave event](./spec/acceptance/realtime/presence_spec.rb#L1170)
        * when set to nil
          * [emits the last value for the data attribute when leaving](./spec/acceptance/realtime/presence_spec.rb#L1185)
        * when not passed as an argument (i.e. nil)
          * [emits the previous value for the data attribute when leaving](./spec/acceptance/realtime/presence_spec.rb#L1200)
        * and sync is complete
          * [does not cache members that have left](./spec/acceptance/realtime/presence_spec.rb#L1215)
      * it should behave like a public presence method
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L293)
        * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L300)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L308)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L318)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L209)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L219)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L229)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L239)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L259)
          * Float
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L268)
          * Boolean
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L277)
          * False
            * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L286)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L331)
    * :left event
      * [emits the data defined in enter](./spec/acceptance/realtime/presence_spec.rb#L1262)
      * [emits the data defined in update](./spec/acceptance/realtime/presence_spec.rb#L1275)
    * entering/updating/leaving presence state on behalf of another client_id
      * #enter_client
        * multiple times on the same channel with different client_ids
          * [has no affect on the client's presence state and only enters on behalf of the provided client_id](./spec/acceptance/realtime/presence_spec.rb#L1300)
          * [enters a channel and sets the data based on the provided :data option](./spec/acceptance/realtime/presence_spec.rb#L1314)
        * message #connection_id
          * [matches the current client connection_id](./spec/acceptance/realtime/presence_spec.rb#L1335)
        * without necessary capabilities to enter on behalf of another client
          * [calls the Deferrable errback on capabilities failure](./spec/acceptance/realtime/presence_spec.rb#L1355)
        * it should behave like a public presence method
          * [presence enter_client : raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L63)
          * [presence enter_client : raise an exception if the channel becomes detached](./spec/acceptance/realtime/presence_spec.rb#L81)
          * [presence enter_client : raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L97)
          * [presence enter_client : raise an exception if the channel becomes failed](./spec/acceptance/realtime/presence_spec.rb#L114)
          * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L130)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L293)
          * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L300)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L308)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L318)
          * when :queue_messages client option is false
            * and connection state initialized
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L142)
            * and connection state connecting
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L152)
            * and connection state disconnected
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L167)
            * and connection state connected
              * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L182)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L209)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L219)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L229)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L239)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L259)
            * Float
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L268)
            * Boolean
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L277)
            * False
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L286)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L331)
        * it should behave like a presence on behalf of another client method
          * :enter_client when authenticated with a wildcard client_id
            * and a valid client_id
              * [succeeds](./spec/acceptance/realtime/presence_spec.rb#L362)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L372)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L379)
            * and a client_id that is not a string type
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L386)
          * :enter_client when authenticated with a valid client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L402)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L411)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L421)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L428)
          * :enter_client when anonymous and no client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L444)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L453)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L463)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L470)
      * #update_client
        * multiple times on the same channel with different client_ids
          * [updates the data attribute for the member when :data option provided](./spec/acceptance/realtime/presence_spec.rb#L1369)
          * [updates the data attribute to null for the member when :data option is not provided (assumed null)](./spec/acceptance/realtime/presence_spec.rb#L1395)
          * [enters if not already entered](./spec/acceptance/realtime/presence_spec.rb#L1409)
        * it should behave like a public presence method
          * [presence update_client : raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L63)
          * [presence update_client : raise an exception if the channel becomes detached](./spec/acceptance/realtime/presence_spec.rb#L81)
          * [presence update_client : raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L97)
          * [presence update_client : raise an exception if the channel becomes failed](./spec/acceptance/realtime/presence_spec.rb#L114)
          * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L130)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L293)
          * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L300)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L308)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L318)
          * when :queue_messages client option is false
            * and connection state initialized
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L142)
            * and connection state connecting
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L152)
            * and connection state disconnected
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L167)
            * and connection state connected
              * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L182)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L209)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L219)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L229)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L239)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L259)
            * Float
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L268)
            * Boolean
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L277)
            * False
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L286)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L331)
        * it should behave like a presence on behalf of another client method
          * :update_client when authenticated with a wildcard client_id
            * and a valid client_id
              * [succeeds](./spec/acceptance/realtime/presence_spec.rb#L362)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L372)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L379)
            * and a client_id that is not a string type
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L386)
          * :update_client when authenticated with a valid client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L402)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L411)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L421)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L428)
          * :update_client when anonymous and no client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L444)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L453)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L463)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L470)
      * #leave_client
        * leaves a channel
          * multiple times on the same channel with different client_ids
            * [emits the :leave event for each client_id](./spec/acceptance/realtime/presence_spec.rb#L1441)
            * [succeeds if that client_id has not previously entered the channel](./spec/acceptance/realtime/presence_spec.rb#L1467)
          * with a new value in :data option
            * [emits the leave event with the new data value](./spec/acceptance/realtime/presence_spec.rb#L1493)
          * with a nil value in :data option
            * [emits the leave event with the previous value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L1508)
          * with no :data option
            * [emits the leave event with the previous value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L1523)
        * it should behave like a public presence method
          * [presence leave_client : raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L63)
          * [presence leave_client : raise an exception if the channel becomes detached](./spec/acceptance/realtime/presence_spec.rb#L81)
          * [presence leave_client : raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L97)
          * [presence leave_client : raise an exception if the channel becomes failed](./spec/acceptance/realtime/presence_spec.rb#L114)
          * [implicitly attaches the channel](./spec/acceptance/realtime/presence_spec.rb#L130)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L293)
          * [allows a block to be passed in that is executed upon success](./spec/acceptance/realtime/presence_spec.rb#L300)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L308)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L318)
          * when :queue_messages client option is false
            * and connection state initialized
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L142)
            * and connection state connecting
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L152)
            * and connection state disconnected
              * [fails the deferrable](./spec/acceptance/realtime/presence_spec.rb#L167)
            * and connection state connected
              * [publishes the message](./spec/acceptance/realtime/presence_spec.rb#L182)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L209)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L219)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L229)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L239)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L259)
            * Float
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L268)
            * Boolean
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L277)
            * False
              * [raises an UnsupportedDataType 40013 exception](./spec/acceptance/realtime/presence_spec.rb#L286)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L331)
        * it should behave like a presence on behalf of another client method
          * :leave_client when authenticated with a wildcard client_id
            * and a valid client_id
              * [succeeds](./spec/acceptance/realtime/presence_spec.rb#L362)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L372)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L379)
            * and a client_id that is not a string type
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L386)
          * :leave_client when authenticated with a valid client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L402)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L411)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L421)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L428)
          * :leave_client when anonymous and no client_id
            * and another invalid client_id
              * before authentication
                * [allows the operation and then Ably rejects the operation](./spec/acceptance/realtime/presence_spec.rb#L444)
              * after authentication
                * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L453)
            * and a wildcard client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L463)
            * and an empty client_id
              * [throws an exception](./spec/acceptance/realtime/presence_spec.rb#L470)
    * #get
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L1544)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L1549)
      * [catches exceptions in the provided method block](./spec/acceptance/realtime/presence_spec.rb#L1556)
      * [implicitly attaches the channel (#RTP11b)](./spec/acceptance/realtime/presence_spec.rb#L1564)
      * [fails if the connection is DETACHED (#RTP11b)](./spec/acceptance/realtime/presence_spec.rb#L1599)
      * [fails if the connection is FAILED (#RTP11b)](./spec/acceptance/realtime/presence_spec.rb#L1616)
      * [returns the current members on the channel (#RTP11a)](./spec/acceptance/realtime/presence_spec.rb#L1700)
      * [filters by connection_id option if provided (#RTP11c3)](./spec/acceptance/realtime/presence_spec.rb#L1717)
      * [filters by client_id option if provided (#RTP11c2)](./spec/acceptance/realtime/presence_spec.rb#L1739)
      * [does not wait for SYNC to complete if :wait_for_sync option is false (#RTP11c1)](./spec/acceptance/realtime/presence_spec.rb#L1763)
      * [returns the list of members and waits for SYNC to complete by default (#RTP11a)](./spec/acceptance/realtime/presence_spec.rb#L1775)
      * when the channel is SUSPENDED
        * with wait_for_sync: true
          * [results in an error with @code@ @91005@ and a @message@ stating that the presence state is out of sync (#RTP11d)](./spec/acceptance/realtime/presence_spec.rb#L1574)
        * with wait_for_sync: false
          * [returns the current PresenceMap and does not wait for the channel to change to the ATTACHED state (#RTP11d)](./spec/acceptance/realtime/presence_spec.rb#L1587)
      * during a sync
        * when :wait_for_sync is true
          * [fails if the connection becomes FAILED (#RTP11b)](./spec/acceptance/realtime/presence_spec.rb#L1653)
          * [fails if the channel becomes detached (#RTP11b)](./spec/acceptance/realtime/presence_spec.rb#L1676)
      * when a member enters and then leaves
        * [has no members](./spec/acceptance/realtime/presence_spec.rb#L1788)
      * when a member enters and the presence map is updated
        * [adds the member as being :present (#RTP2d)](./spec/acceptance/realtime/presence_spec.rb#L1803)
      * with lots of members on different clients
        * [returns a complete list of members on all clients](./spec/acceptance/realtime/presence_spec.rb#L1824)
    * #subscribe
      * [implicitly attaches](./spec/acceptance/realtime/presence_spec.rb#L1901)
      * with no arguments
        * [calls the callback for all presence events](./spec/acceptance/realtime/presence_spec.rb#L1862)
      * with event name
        * [calls the callback for specified presence event](./spec/acceptance/realtime/presence_spec.rb#L1882)
      * with a callback that raises an exception
        * [logs the error and continues](./spec/acceptance/realtime/presence_spec.rb#L1914)
    * #unsubscribe
      * with no arguments
        * [removes the callback for all presence events](./spec/acceptance/realtime/presence_spec.rb#L1935)
      * with event name
        * [removes the callback for specified presence event](./spec/acceptance/realtime/presence_spec.rb#L1953)
    * REST #get
      * [returns current members](./spec/acceptance/realtime/presence_spec.rb#L1972)
      * [returns no members once left](./spec/acceptance/realtime/presence_spec.rb#L1988)
    * client_id with ASCII_8BIT
      * in connection set up
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L2008)
      * in channel options
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L2021)
    * encoding and decoding of presence message data
      * [encrypts presence message data](./spec/acceptance/realtime/presence_spec.rb#L2047)
      * #subscribe
        * [emits decrypted enter events](./spec/acceptance/realtime/presence_spec.rb#L2066)
        * [emits decrypted update events](./spec/acceptance/realtime/presence_spec.rb#L2078)
        * [emits previously set data for leave events](./spec/acceptance/realtime/presence_spec.rb#L2092)
      * #get
        * [returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L2108)
      * REST #get
        * [returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L2122)
      * when cipher settings do not match publisher
        * [delivers an unencoded presence message left with encoding value](./spec/acceptance/realtime/presence_spec.rb#L2138)
        * [emits an error when cipher does not match and presence data cannot be decoded](./spec/acceptance/realtime/presence_spec.rb#L2151)
    * leaving
      * [expect :left event once underlying connection is closed](./spec/acceptance/realtime/presence_spec.rb#L2169)
      * [expect :left event with client data from enter event](./spec/acceptance/realtime/presence_spec.rb#L2179)
    * connection failure mid-way through a large member sync
      * [resumes the SYNC operation (#RTP3)](./spec/acceptance/realtime/presence_spec.rb#L2198)
    * server-initiated sync
      * with multiple SYNC pages
        * [is initiated with a SYNC message and completed with a later SYNC message with no cursor value part of the channelSerial (#RTP18a, #RTP18b) ](./spec/acceptance/realtime/presence_spec.rb#L2236)
      * with a single SYNC page
        * [is initiated and completed with a single SYNC message (and no channelSerial) (#RTP18a, #RTP18c) ](./spec/acceptance/realtime/presence_spec.rb#L2285)
      * when members exist in the PresenceMap before a SYNC completes
        * [removes the members that are no longer present (#RTP19)](./spec/acceptance/realtime/presence_spec.rb#L2332)
    * when the client does not have presence subscribe privileges but is present on the channel
      * [receives presence updates for all presence events generated by the current connection and the presence map is kept up to date (#RTP17a)](./spec/acceptance/realtime/presence_spec.rb#L2389)
    * local PresenceMap for presence members entered by this client
      * [maintains a copy of the member map for any member that shares this connection's connection ID (#RTP17)](./spec/acceptance/realtime/presence_spec.rb#L2437)
      * #RTP17b
        * [updates presence members on leave](./spec/acceptance/realtime/presence_spec.rb#L2465)
        * [does no update presence members on fabricated leave](./spec/acceptance/realtime/presence_spec.rb#L2490)
      * when a channel becomes attached again
        * and the resume flag is false
          * and the presence flag is false
            * [immediately resends all local presence members (#RTP5c2, #RTP19a)](./spec/acceptance/realtime/presence_spec.rb#L2539)
        * when re-entering a client automatically, if the re-enter fails for any reason
          * [should emit an ErrorInfo with error code 91004 (#RTP5c3)](./spec/acceptance/realtime/presence_spec.rb#L2614)
    * channel state side effects (RTP5)
      * channel transitions to the ATTACHED state (RTP5b)
        * [all queued presence messages are sent](./spec/acceptance/realtime/presence_spec.rb#L2668)
      * channel transitions to the FAILED state
        * [clears the PresenceMap and local member map copy and does not emit any presence events (#RTP5a)](./spec/acceptance/realtime/presence_spec.rb#L2688)
      * channel transitions to the DETACHED state
        * [clears the PresenceMap and local member map copy and does not emit any presence events (#RTP5a)](./spec/acceptance/realtime/presence_spec.rb#L2715)
      * channel transitions to the SUSPENDED state
        * [maintains the PresenceMap and only publishes presence event changes since the last attached state (#RTP5f)](./spec/acceptance/realtime/presence_spec.rb#L2753)

### Ably::Realtime::Push::Admin
_(see [spec/acceptance/realtime/push_admin_spec.rb](./spec/acceptance/realtime/push_admin_spec.rb))_
  * using JSON protocol
    * #publish
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/push_admin_spec.rb#L35)
      * [accepts valid push data and recipient](./spec/acceptance/realtime/push_admin_spec.rb#L125)
      * invalid arguments
        * [raises an exception with a nil recipient](./spec/acceptance/realtime/push_admin_spec.rb#L44)
        * [raises an exception with a empty recipient](./spec/acceptance/realtime/push_admin_spec.rb#L49)
        * [raises an exception with a nil recipient](./spec/acceptance/realtime/push_admin_spec.rb#L54)
        * [raises an exception with a empty recipient](./spec/acceptance/realtime/push_admin_spec.rb#L59)
      * invalid recipient
        * [raises an error after receiving a 40x realtime response](./spec/acceptance/realtime/push_admin_spec.rb#L68)
      * invalid push data
        * [raises an error after receiving a 40x realtime response](./spec/acceptance/realtime/push_admin_spec.rb#L79)
      * recipient variable case
        * [is converted to snakeCase](./spec/acceptance/realtime/push_admin_spec.rb#L117)
      * using test environment channel recipient (#RSH1a)
        * [triggers a push notification](./spec/acceptance/realtime/push_admin_spec.rb#L155)
    * #device_registrations
      * without permissions
        * [raises a permissions not authorized exception](./spec/acceptance/realtime/push_admin_spec.rb#L183)
      * #list
        * [returns a PaginatedResult object containing DeviceDetails objects](./spec/acceptance/realtime/push_admin_spec.rb#L233)
        * [supports paging](./spec/acceptance/realtime/push_admin_spec.rb#L241)
        * [raises an exception if params are invalid](./spec/acceptance/realtime/push_admin_spec.rb#L257)
      * #get
        * [returns a DeviceDetails object if a device ID string is provided](./spec/acceptance/realtime/push_admin_spec.rb#L296)
        * with a failed request
          * [raises a ResourceMissing exception if device ID does not exist](./spec/acceptance/realtime/push_admin_spec.rb#L313)
      * #save
        * [saves the new DeviceDetails Hash object](./spec/acceptance/realtime/push_admin_spec.rb#L362)
        * with a failed request
          * [fails if data is invalid](./spec/acceptance/realtime/push_admin_spec.rb#L380)
      * #remove_where
        * [removes all matching device registrations by client_id](./spec/acceptance/realtime/push_admin_spec.rb#L418)
      * #remove
        * [removes the provided device id string](./spec/acceptance/realtime/push_admin_spec.rb#L457)
    * #channel_subscriptions
      * #list
        * [returns a PaginatedResult object containing DeviceDetails objects](./spec/acceptance/realtime/push_admin_spec.rb#L533)
        * [supports paging](./spec/acceptance/realtime/push_admin_spec.rb#L541)
        * [raises an exception if none of the required filters are provided](./spec/acceptance/realtime/push_admin_spec.rb#L557)
      * #list_channels
        * [returns a PaginatedResult object containing String objects](./spec/acceptance/realtime/push_admin_spec.rb#L584)
      * #save
        * [saves the new client_id PushChannelSubscription Hash object](./spec/acceptance/realtime/push_admin_spec.rb#L599)
        * [raises an exception for invalid params](./spec/acceptance/realtime/push_admin_spec.rb#L610)
        * failed requests
          * [fails for invalid requests](./spec/acceptance/realtime/push_admin_spec.rb#L623)
      * #remove_where
        * [removes matching client_ids](./spec/acceptance/realtime/push_admin_spec.rb#L650)
        * [succeeds on no match](./spec/acceptance/realtime/push_admin_spec.rb#L677)
        * failed requests
          * [device_id and client_id filters in the same request are not supported](./spec/acceptance/realtime/push_admin_spec.rb#L669)
      * #remove
        * [removes match for Hash object by channel and client_id](./spec/acceptance/realtime/push_admin_spec.rb#L697)
        * [succeeds even if there is no match](./spec/acceptance/realtime/push_admin_spec.rb#L709)

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
    * [has immutable options](./spec/acceptance/rest/auth_spec.rb#L48)
    * #request_token
      * [creates a TokenRequest automatically and sends it to Ably to obtain a token](./spec/acceptance/rest/auth_spec.rb#L63)
      * [returns a valid TokenDetails object in the expected format with valid issued and expires attributes](./spec/acceptance/rest/auth_spec.rb#L72)
      * with token_param :client_id
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L105)
      * with token_param :capability
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L105)
      * with token_param :nonce
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L105)
      * with token_param :timestamp
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L105)
      * with token_param :ttl
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L105)
      * with :key option
        * [key_name is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L135)
      * with :key_name & :key_secret options
        * [key_name is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L165)
      * with :query_time option
        * [queries the server for the time (#RSA10k)](./spec/acceptance/rest/auth_spec.rb#L173)
      * without :query_time option
        * [does not query the server for the time](./spec/acceptance/rest/auth_spec.rb#L182)
      * with :auth_url option merging
        * with existing configured auth options
          * using unspecified :auth_method
            * [requests a token using a GET request with provided headers, and merges client_id into auth_params](./spec/acceptance/rest/auth_spec.rb#L222)
            * with provided token_params
              * [merges provided token_params with existing auth_params and client_id](./spec/acceptance/rest/auth_spec.rb#L230)
            * with provided auth option auth_params and auth_headers
              * [replaces any preconfigured auth_params](./spec/acceptance/rest/auth_spec.rb#L238)
          * using :get :auth_method and query params in the URL
            * [requests a token using a GET request with provided headers, and merges client_id into auth_params and existing URL querystring into new URL querystring](./spec/acceptance/rest/auth_spec.rb#L249)
          * using :post :auth_method
            * [requests a token using a POST request with provided headers, and merges client_id into auth_params as form-encoded post data](./spec/acceptance/rest/auth_spec.rb#L259)
      * with :auth_url option
        * when response from :auth_url is a valid token request
          * [requests a token from :auth_url using an HTTP GET request](./spec/acceptance/rest/auth_spec.rb#L309)
          * [returns a valid token generated from the token request](./spec/acceptance/rest/auth_spec.rb#L314)
          * with :query_params
            * [requests a token from :auth_url with the :query_params](./spec/acceptance/rest/auth_spec.rb#L321)
          * with :headers
            * [requests a token from :auth_url with the HTTP headers set](./spec/acceptance/rest/auth_spec.rb#L329)
          * with POST
            * [requests a token from :auth_url using an HTTP POST instead of the default GET](./spec/acceptance/rest/auth_spec.rb#L337)
        * when response from :auth_url is a token details object
          * [returns TokenDetails created from the token JSON](./spec/acceptance/rest/auth_spec.rb#L362)
        * when response from :auth_url is text/plain content type and a token string
          * [returns TokenDetails created from the token JSON](./spec/acceptance/rest/auth_spec.rb#L380)
        * when response is invalid
          * 500
            * [raises ServerError](./spec/acceptance/rest/auth_spec.rb#L394)
          * XML
            * [raises InvalidResponseBody](./spec/acceptance/rest/auth_spec.rb#L405)
      * with a Proc for the :auth_callback option
        * that returns a TokenRequest
          * [calls the Proc with token_params when authenticating to obtain the request token](./spec/acceptance/rest/auth_spec.rb#L428)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L432)
          * when authorized
            * [sets Auth#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L439)
            * [sets Client#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L443)
        * that returns a TokenDetails JSON object
          * [calls the lambda when authenticating to obtain the request token](./spec/acceptance/rest/auth_spec.rb#L477)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L482)
          * when authorized
            * [sets Auth#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L494)
            * [sets Client#client_id to the new token's client_id](./spec/acceptance/rest/auth_spec.rb#L498)
        * that returns a TokenDetails object
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L513)
        * that returns a Token string
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L529)
      * with auth_option :client_id
        * [returns a token with the client_id](./spec/acceptance/rest/auth_spec.rb#L559)
      * with token_param :client_id
        * [returns a token with the client_id](./spec/acceptance/rest/auth_spec.rb#L568)
    * before #authorize has been called
      * [has no current_token_details](./spec/acceptance/rest/auth_spec.rb#L575)
    * #authorize (#RSA10, #RSA10j)
      * [updates the persisted token params that are then used for subsequent authorize requests](./spec/acceptance/rest/auth_spec.rb#L742)
      * [updates the persisted auth options that are then used for subsequent authorize requests](./spec/acceptance/rest/auth_spec.rb#L748)
      * when called for the first time since the client has been instantiated
        * [passes all auth_options and token_params to #request_token](./spec/acceptance/rest/auth_spec.rb#L589)
        * [returns a valid token](./spec/acceptance/rest/auth_spec.rb#L594)
        * [issues a new token every time (#RSA10a)](./spec/acceptance/rest/auth_spec.rb#L598)
      * query_time: true with authorize
        * [only queries the server time once and then works out the offset, query_time option is never persisted (#RSA10k)](./spec/acceptance/rest/auth_spec.rb#L612)
      * query_time: true ClientOption when instanced
        * [only queries the server time once and then works out the offset, query_time option is never persisted (#RSA10k)](./spec/acceptance/rest/auth_spec.rb#L632)
      * TokenParams argument
        * [has no effect on the defaults when null and TokenParam defaults remain the same](./spec/acceptance/rest/auth_spec.rb#L649)
        * [updates defaults when present and all previous configured TokenParams are discarded (#RSA10g)](./spec/acceptance/rest/auth_spec.rb#L656)
        * [updates Auth#token_params attribute with an immutable hash](./spec/acceptance/rest/auth_spec.rb#L664)
        * [uses TokenParams#timestamp for this request but obtains a new timestamp for subsequence requests (#RSA10g)](./spec/acceptance/rest/auth_spec.rb#L669)
      * AuthOptions argument
        * [has no effect on the defaults when null and AuthOptions defaults remain the same](./spec/acceptance/rest/auth_spec.rb#L694)
        * [updates defaults when present and all previous configured AuthOptions are discarded (#RSA10g)](./spec/acceptance/rest/auth_spec.rb#L700)
        * [updates Auth#options attribute with an immutable hash](./spec/acceptance/rest/auth_spec.rb#L707)
        * [uses AuthOptions#query_time for this request and will not query_time for subsequent requests (#RSA10g)](./spec/acceptance/rest/auth_spec.rb#L712)
        * [uses AuthOptions#query_time for this request and will query_time again if provided subsequently](./spec/acceptance/rest/auth_spec.rb#L718)
      * with previous authorisation
        * [requests a new token if token is expired](./spec/acceptance/rest/auth_spec.rb#L731)
        * [issues a new token every time #authorize is called](./spec/acceptance/rest/auth_spec.rb#L737)
      * with a lambda for the :auth_callback option
        * [calls the lambda](./spec/acceptance/rest/auth_spec.rb#L765)
        * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L769)
        * for every subsequent #request_token
          * without a :auth_callback lambda
            * [calls the originally provided block](./spec/acceptance/rest/auth_spec.rb#L775)
          * with a provided block
            * [does not call the originally provided lambda and calls the new #request_token :auth_callback lambda](./spec/acceptance/rest/auth_spec.rb#L782)
      * with an explicit token string that expires
        * and a lambda for the :auth_callback option to provide a means to renew the token
          * [calls the lambda once the token has expired and the new token is used](./spec/acceptance/rest/auth_spec.rb#L809)
      * with an explicit ClientOptions client_id
        * and an incompatible client_id in a TokenDetails object passed to the auth callback
          * [rejects a TokenDetails object with an incompatible client_id and raises an exception](./spec/acceptance/rest/auth_spec.rb#L827)
        * and an incompatible client_id in a TokenRequest object passed to the auth callback and raises an exception
          * [rejects a TokenRequests object with an incompatible client_id and raises an exception](./spec/acceptance/rest/auth_spec.rb#L835)
        * and a token string without any retrievable client_id
          * [rejects a TokenRequests object with an incompatible client_id and raises an exception](./spec/acceptance/rest/auth_spec.rb#L843)
    * #create_token_request
      * [returns a TokenRequest object](./spec/acceptance/rest/auth_spec.rb#L858)
      * [returns a TokenRequest that can be passed to a client that can use it for authentication without an API key](./spec/acceptance/rest/auth_spec.rb#L862)
      * [uses the key name from the client](./spec/acceptance/rest/auth_spec.rb#L869)
      * [specifies no TTL (#RSA5)](./spec/acceptance/rest/auth_spec.rb#L873)
      * [specifies no capability (#RSA6)](./spec/acceptance/rest/auth_spec.rb#L887)
      * with a :ttl option below the Token expiry buffer that ensures tokens are renewed 15s before they expire as they are considered expired
        * [uses the Token expiry buffer default + 10s to allow for a token request in flight](./spec/acceptance/rest/auth_spec.rb#L881)
      * the nonce
        * [is unique for every request](./spec/acceptance/rest/auth_spec.rb#L892)
        * [is at least 16 characters](./spec/acceptance/rest/auth_spec.rb#L897)
      * with token param :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L908)
      * with token param :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L908)
      * with token param :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L908)
      * when specifying capability
        * [overrides the default](./spec/acceptance/rest/auth_spec.rb#L919)
        * [uses these capabilities when Ably issues an actual token](./spec/acceptance/rest/auth_spec.rb#L923)
      * with additional invalid attributes
        * [are ignored](./spec/acceptance/rest/auth_spec.rb#L933)
      * when required fields are missing
        * [should raise an exception if key secret is missing](./spec/acceptance/rest/auth_spec.rb#L944)
        * [should raise an exception if key name is missing](./spec/acceptance/rest/auth_spec.rb#L948)
      * timestamp attribute
        * [is a Time object in Ruby and is set to the local time](./spec/acceptance/rest/auth_spec.rb#L975)
        * with :query_time auth_option
          * [queries the server for the timestamp](./spec/acceptance/rest/auth_spec.rb#L960)
        * with :timestamp option
          * [uses the provided timestamp in the token request](./spec/acceptance/rest/auth_spec.rb#L970)
      * signing
        * [generates a valid HMAC](./spec/acceptance/rest/auth_spec.rb#L999)
        * lexicographic ordering of channels and operations
          * [HMAC is lexicographic ordered and thus the HMAC is identical](./spec/acceptance/rest/auth_spec.rb#L1026)
          * [is valid when used for authentication](./spec/acceptance/rest/auth_spec.rb#L1032)
    * using token authentication
      * with :token option
        * [authenticates successfully using the provided :token](./spec/acceptance/rest/auth_spec.rb#L1059)
        * [disallows publishing on unspecified capability channels](./spec/acceptance/rest/auth_spec.rb#L1063)
        * [fails if timestamp is invalid](./spec/acceptance/rest/auth_spec.rb#L1071)
        * [cannot be renewed automatically](./spec/acceptance/rest/auth_spec.rb#L1079)
        * and the token expires
          * [should indicate an error and not retry the request (#RSA4a)](./spec/acceptance/rest/auth_spec.rb#L1113)
      * when token expires
        * [automatically renews the token (#RSA4b)](./spec/acceptance/rest/auth_spec.rb#L1143)
        * [fails if the token renewal fails (#RSA4b)](./spec/acceptance/rest/auth_spec.rb#L1153)
      * when token does not expire
        * for the next 2 hours
          * [should not request for the new token (#RSA4b1)](./spec/acceptance/rest/auth_spec.rb#L1177)
      * when :client_id is provided in a token
        * [#client_id contains the client_id](./spec/acceptance/rest/auth_spec.rb#L1195)
    * #client_id_validated?
      * when using basic auth
        * [is false as basic auth users do not have an identity](./spec/acceptance/rest/auth_spec.rb#L1207)
      * when using a token auth string for a token with a client_id
        * [is false as identification is not possible from an opaque token string](./spec/acceptance/rest/auth_spec.rb#L1215)
      * when using a token
        * with a client_id
          * [is true](./spec/acceptance/rest/auth_spec.rb#L1224)
        * with no client_id (anonymous)
          * [is true](./spec/acceptance/rest/auth_spec.rb#L1232)
        * with a wildcard client_id (anonymous)
          * [is false](./spec/acceptance/rest/auth_spec.rb#L1240)
      * when using a token request with a client_id
        * [is not true as identification is not confirmed until authenticated](./spec/acceptance/rest/auth_spec.rb#L1249)
        * after authentication
          * [is true as identification is completed during implicit authentication](./spec/acceptance/rest/auth_spec.rb#L1256)
    * when using a :key and basic auth
      * [#using_token_auth? is false](./spec/acceptance/rest/auth_spec.rb#L1264)
      * [#key attribute contains the key string](./spec/acceptance/rest/auth_spec.rb#L1268)
      * [#using_basic_auth? is true](./spec/acceptance/rest/auth_spec.rb#L1272)
    * deprecated #authorise
      * [logs a deprecation warning (#RSA10l)](./spec/acceptance/rest/auth_spec.rb#L1281)
      * [returns a valid token (#RSA10l)](./spec/acceptance/rest/auth_spec.rb#L1286)
    * when using JWT
      * [authenticates correctly using the JWT token generated by the echo server](./spec/acceptance/rest/auth_spec.rb#L1298)
      * when the JWT embeds an Ably token
        * [authenticates correctly using the embedded token](./spec/acceptance/rest/auth_spec.rb#L1305)
        * and the requested token is encrypted
          * [authenticates correctly using the embedded token](./spec/acceptance/rest/auth_spec.rb#L1312)
      * when the token requested is returned with application/jwt content type
        * [authenticates correctly and pulls stats](./spec/acceptance/rest/auth_spec.rb#L1323)

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
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L96)
      * 500 server error without a valid JSON response body
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L109)
    * token authentication failures
      * when auth#token_renewable?
        * [should automatically reissue a token](./spec/acceptance/rest/base_spec.rb#L147)
      * when NOT auth#token_renewable?
        * [should raise an TokenExpired exception](./spec/acceptance/rest/base_spec.rb#L162)

### Ably::Rest::Channel
_(see [spec/acceptance/rest/channel_spec.rb](./spec/acceptance/rest/channel_spec.rb))_
  * using JSON protocol
    * #publish
      * with name and data arguments
        * [publishes the message and return true indicating success](./spec/acceptance/rest/channel_spec.rb#L23)
        * and additional attributes
          * [publishes the message with the attributes and return true indicating success](./spec/acceptance/rest/channel_spec.rb#L32)
      * with a client_id configured in the ClientOptions
        * [publishes the message without a client_id](./spec/acceptance/rest/channel_spec.rb#L43)
        * [expects a client_id to be added by the realtime service](./spec/acceptance/rest/channel_spec.rb#L51)
      * with an array of Hash objects with :name and :data attributes
        * [publishes an array of messages in one HTTP request](./spec/acceptance/rest/channel_spec.rb#L64)
      * with an array of Message objects
        * when max_message_size and max_frame_size is not set
          * and messages size (130 bytes) is smaller than the max_message_size
            * [publishes an array of messages in one HTTP request](./spec/acceptance/rest/channel_spec.rb#L89)
          * and messages size (177784 bytes) is bigger than the max_message_size
            * [should not publish and raise Ably::Exceptions::MaxMessageSizeExceeded](./spec/acceptance/rest/channel_spec.rb#L105)
        * when max_message_size is 655 bytes
          * and messages size (130 bytes) is smaller than the max_message_size
            * [publishes an array of messages in one HTTP request](./spec/acceptance/rest/channel_spec.rb#L127)
          * and messages size (177784 bytes) is bigger than the max_message_size
            * [should not publish and raise Ably::Exceptions::MaxMessageSizeExceeded](./spec/acceptance/rest/channel_spec.rb#L143)
      * with a Message object
        * [publishes the message](./spec/acceptance/rest/channel_spec.rb#L158)
      * with a Message object and query params
        * [should fail to publish the message (RSL1l1)](./spec/acceptance/rest/channel_spec.rb#L170)
      * with Messages and query params
        * [should fail to publish the message (RSL1l1)](./spec/acceptance/rest/channel_spec.rb#L183)
      * without adequate permissions on the channel
        * [raises a permission error when publishing](./spec/acceptance/rest/channel_spec.rb#L193)
      * null attributes
        * when name is null
          * [publishes the message without a name attribute in the payload](./spec/acceptance/rest/channel_spec.rb#L202)
        * when data is null
          * [publishes the message without a data attribute in the payload](./spec/acceptance/rest/channel_spec.rb#L213)
        * with neither name or data attributes
          * [publishes the message without any attributes in the payload](./spec/acceptance/rest/channel_spec.rb#L224)
      * identified clients
        * when authenticated with a wildcard client_id
          * with a valid client_id in the message
            * [succeeds](./spec/acceptance/rest/channel_spec.rb#L241)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L250)
          * with an empty client_id in the message
            * [succeeds and publishes without a client_id](./spec/acceptance/rest/channel_spec.rb#L256)
        * when authenticated with a Token string with an implicit client_id
          * without having a confirmed identity
            * with a valid client_id in the message
              * [succeeds](./spec/acceptance/rest/channel_spec.rb#L273)
            * with an invalid client_id in the message
              * [succeeds in the client library but then fails when published to Ably](./spec/acceptance/rest/channel_spec.rb#L282)
            * with an empty client_id in the message
              * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L288)
        * when authenticated with TokenDetails with a valid client_id
          * with a valid client_id in the message
            * [succeeds](./spec/acceptance/rest/channel_spec.rb#L305)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L314)
          * with an invalid client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L320)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L326)
        * when anonymous and no client_id
          * with a client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L342)
          * with a wildcard client_id in the message
            * [throws an exception](./spec/acceptance/rest/channel_spec.rb#L348)
          * with an empty client_id in the message
            * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L354)
      * with a non ASCII channel name
        * stubbed
          * [correctly encodes the channel name](./spec/acceptance/rest/channel_spec.rb#L376)
      * with a frozen message event name
        * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L386)
      * with a frozen payload
        * [succeeds and publishes with an implicit client_id](./spec/acceptance/rest/channel_spec.rb#L408)
      * message size is exceeded (#TO3l8)
        * [should raise Ably::Exceptions::MaxMessageSizeExceeded exception](./spec/acceptance/rest/channel_spec.rb#L423)
    * #history
      * [returns a PaginatedResult model](./spec/acceptance/rest/channel_spec.rb#L447)
      * [returns the current message history for the channel](./spec/acceptance/rest/channel_spec.rb#L451)
      * [returns paged history using the PaginatedResult model](./spec/acceptance/rest/channel_spec.rb#L479)
      * message timestamps
        * [are after the messages were published](./spec/acceptance/rest/channel_spec.rb#L464)
      * message IDs
        * [is unique](./spec/acceptance/rest/channel_spec.rb#L472)
      * direction
        * [returns paged history backwards by default](./spec/acceptance/rest/channel_spec.rb#L506)
        * [returns history forward if specified in the options](./spec/acceptance/rest/channel_spec.rb#L512)
      * limit
        * [defaults to 100](./spec/acceptance/rest/channel_spec.rb#L524)
    * #history option
      * :start
        * with milliseconds since epoch value
          * [uses this value in the history request](./spec/acceptance/rest/channel_spec.rb#L564)
        * with a Time object value
          * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/channel_spec.rb#L574)
      * :end
        * with milliseconds since epoch value
          * [uses this value in the history request](./spec/acceptance/rest/channel_spec.rb#L564)
        * with a Time object value
          * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/channel_spec.rb#L574)
      * when argument start is after end
        * [should raise an exception](./spec/acceptance/rest/channel_spec.rb#L584)
    * #presence
      * [returns a REST Presence object](./spec/acceptance/rest/channel_spec.rb#L594)
    * #status
      * [should return channel details status (#RSL8, #RSL8a)](./spec/acceptance/rest/channel_spec.rb#L604)

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
    * #set_options (#RTL16)
      * [updates channel's options](./spec/acceptance/rest/channels_spec.rb#L38)
      * when providing Ably::Models::ChannelOptions object
        * [updates channel's options](./spec/acceptance/rest/channels_spec.rb#L45)
    * accessing an existing channel object with different options
      * [overrides the existing channel options and returns the channel object (RSN3c)](./spec/acceptance/rest/channels_spec.rb#L55)
    * accessing an existing channel object without specifying any channel options
      * [returns the existing channel without modifying the channel options](./spec/acceptance/rest/channels_spec.rb#L67)
    * using undocumented array accessor [] method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)
    * using a frozen channel name
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)

### Ably::Rest::Client
_(see [spec/acceptance/rest/client_spec.rb](./spec/acceptance/rest/client_spec.rb))_
  * using JSON protocol
    * #initialize
      * with only an API key
        * [uses basic authentication](./spec/acceptance/rest/client_spec.rb#L25)
      * with an invalid API key
        * [logs an entry with a help href url matching the code #TI5](./spec/acceptance/rest/client_spec.rb#L33)
      * with an explicit string :token
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L46)
      * with :use_token_auth set to true
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L54)
      * with a non string :client_id
        * [raises an ArgumentError](./spec/acceptance/rest/client_spec.rb#L62)
      * with an invalid wildcard "*" :client_id
        * [raises an exception](./spec/acceptance/rest/client_spec.rb#L68)
      * with an :auth_callback lambda
        * [calls the auth lambda to get a new token](./spec/acceptance/rest/client_spec.rb#L76)
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L81)
      * with :default_token_params
        * [overides the default token params (#TO3j11)](./spec/acceptance/rest/client_spec.rb#L95)
      * with an :auth_callback lambda (clientId provided in library options instead of as a token_request param)
        * [correctly sets the clientId on the token](./spec/acceptance/rest/client_spec.rb#L105)
      * with an auth URL
        * [uses token authentication](./spec/acceptance/rest/client_spec.rb#L115)
        * before any REST request
          * [sends an HTTP request to the provided auth URL to get a new token](./spec/acceptance/rest/client_spec.rb#L126)
      * auth headers
        * with basic auth
          * [sends the API key in authentication part of the secure URL (the Authorization: Basic header is not used with the Faraday HTTP library by default)](./spec/acceptance/rest/client_spec.rb#L147)
        * with token auth
          * without specifying protocol
            * [sends the token string over HTTPS in the Authorization Bearer header with Base64 encoding](./spec/acceptance/rest/client_spec.rb#L166)
          * when setting constructor ClientOption :tls to false
            * [sends the token string over HTTP in the Authorization Bearer header with Base64 encoding](./spec/acceptance/rest/client_spec.rb#L176)
    * using tokens
      * when expired
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L209)
        * with a different client_id in the subsequent token
          * [fails to authenticate and raises an exception](./spec/acceptance/rest/client_spec.rb#L222)
      * when token has not expired
        * [reuses the existing token for every request](./spec/acceptance/rest/client_spec.rb#L233)
    * connection transport
      * defaults
        * for default host
          * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L250)
          * [is configured to timeout connection requests in 10 seconds](./spec/acceptance/rest/client_spec.rb#L254)
        * for the fallback hosts
          * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L260)
          * [is configured to timeout connection requests in 10 seconds](./spec/acceptance/rest/client_spec.rb#L264)
      * with custom http_open_timeout and http_request_timeout options
        * for default host
          * [is configured to use custom open timeout](./spec/acceptance/rest/client_spec.rb#L276)
          * [is configured to use custom request timeout](./spec/acceptance/rest/client_spec.rb#L280)
        * for the fallback hosts
          * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L286)
          * [is configured to timeout connection requests in 10 seconds](./spec/acceptance/rest/client_spec.rb#L290)
    * fallback hosts
      * configured
        * [should make connection attempts to a.ably-realtime.com, b.ably-realtime.com, c.ably-realtime.com, d.ably-realtime.com, e.ably-realtime.com (#RSC15a)](./spec/acceptance/rest/client_spec.rb#L304)
      * when environment is NOT production (#RSC15b)
        * and custom fallback hosts are empty
          * [does not retry failed requests with fallback hosts when there is a connection error](./spec/acceptance/rest/client_spec.rb#L322)
        * and no custom fallback hosts are provided
          * [should make connection attempts to sandbox-a-fallback.ably-realtime.com, sandbox-b-fallback.ably-realtime.com, sandbox-c-fallback.ably-realtime.com, sandbox-d-fallback.ably-realtime.com, sandbox-e-fallback.ably-realtime.com (#RSC15a)](./spec/acceptance/rest/client_spec.rb#L330)
      * when environment is production
        * and connection times out
          * [tries fallback hosts 3 times (#RSC15b, #RSC15b)](./spec/acceptance/rest/client_spec.rb#L374)
          * and the total request time exeeds 15 seconds
            * [makes no further attempts to any fallback hosts](./spec/acceptance/rest/client_spec.rb#L389)
        * and connection fails
          * [tries fallback hosts 3 times](./spec/acceptance/rest/client_spec.rb#L405)
        * and first request to primary endpoint fails
          * [tries a fallback host, and for the next request tries the primary endpoint again (#RSC15e)](./spec/acceptance/rest/client_spec.rb#L439)
        * and basic authentication fails
          * [does not attempt the fallback hosts as this is an authentication failure](./spec/acceptance/rest/client_spec.rb#L466)
        * and server returns a 50x error
          * [attempts the fallback hosts as this is an authentication failure (#RSC15d)](./spec/acceptance/rest/client_spec.rb#L488)
      * when environment is production and server returns a 50x error
        * with custom fallback hosts provided
          * [attempts the fallback hosts as this is an authentication failure (#RSC15b, #RSC15a, #TO3k6)](./spec/acceptance/rest/client_spec.rb#L537)
        * with an empty array of fallback hosts provided (#RSC15b, #RSC15a, #TO3k6)
          * [does not attempt the fallback hosts as this is an authentication failure](./spec/acceptance/rest/client_spec.rb#L550)
        * using a local web-server
          * and timing out the primary host
            * POST with request timeout less than max_retry_duration
              * [tries the primary host, then both fallback hosts (#RSC15d)](./spec/acceptance/rest/client_spec.rb#L614)
            * GET with request timeout less than max_retry_duration
              * [tries the primary host, then both fallback hosts (#RSC15d)](./spec/acceptance/rest/client_spec.rb#L637)
            * POST with request timeout more than max_retry_duration
              * [does not try any fallback hosts (#RSC15d)](./spec/acceptance/rest/client_spec.rb#L660)
            * GET with request timeout more than max_retry_duration
              * [does not try any fallback hosts (#RSC15d)](./spec/acceptance/rest/client_spec.rb#L682)
          * and failing the primary host
            * [tries one of the fallback hosts](./spec/acceptance/rest/client_spec.rb#L727)
          * to fail the primary host, allow a fallback to succeed, then later trigger a fallback to the primary host (#RSC15f)
            * [succeeds and remembers fallback host preferences across requests](./spec/acceptance/rest/client_spec.rb#L783)
            * with custom :fallback_retry_timeout
              * [stops using the preferred fallback after this time](./spec/acceptance/rest/client_spec.rb#L820)
      * when environment is not production and server returns a 50x error
        * with no fallback hosts provided (#TBC, see https://github.com/ably/wiki/issues/361)
          * [uses the default fallback hosts for that environment as this is not an authentication failure](./spec/acceptance/rest/client_spec.rb#L874)
        * with custom fallback hosts provided (#RSC15b, #TO3k6)
          * [attempts the fallback hosts as this is not an authentication failure](./spec/acceptance/rest/client_spec.rb#L902)
        * with an empty array of fallback hosts provided (#RSC15b, #TO3k6)
          * [does not attempt the fallback hosts as this is an authentication failure](./spec/acceptance/rest/client_spec.rb#L915)
        * with fallback_hosts_use_default: true (#RSC15b, #TO3k7)
          * [attempts the default fallback hosts as this is an authentication failure](./spec/acceptance/rest/client_spec.rb#L940)
    * with a custom host
      * that does not exist
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L956)
        * fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L977)
      * that times out
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L992)
        * fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L1005)
    * HTTP configuration options
      * [is frozen](./spec/acceptance/rest/client_spec.rb#L1062)
      * defaults
        * [#http_open_timeout is 4s](./spec/acceptance/rest/client_spec.rb#L1017)
        * [#http_request_timeout is 10s](./spec/acceptance/rest/client_spec.rb#L1021)
        * [#http_max_retry_count is 3](./spec/acceptance/rest/client_spec.rb#L1025)
        * [#http_max_retry_duration is 15s](./spec/acceptance/rest/client_spec.rb#L1029)
      * configured
        * [#http_open_timeout uses provided value](./spec/acceptance/rest/client_spec.rb#L1045)
        * [#http_request_timeout uses provided value](./spec/acceptance/rest/client_spec.rb#L1049)
        * [#http_max_retry_count uses provided value](./spec/acceptance/rest/client_spec.rb#L1053)
        * [#http_max_retry_duration uses provided value](./spec/acceptance/rest/client_spec.rb#L1057)
    * #auth
      * [is provides access to the Auth object](./spec/acceptance/rest/client_spec.rb#L1073)
      * [configures the Auth object with all ClientOptions passed to client in the initializer](./spec/acceptance/rest/client_spec.rb#L1077)
    * version headers
      * with default agent
        * [sends a protocol version and lib version header (#G4, #RSC7a, #RSC7b)](./spec/acceptance/rest/client_spec.rb#L1097)
      * with custom ably-ruby/1.1.1 ruby/3.1.1 agent
        * [sends a protocol version and lib version header (#G4, #RSC7a, #RSC7b)](./spec/acceptance/rest/client_spec.rb#L1097)
    * #request (#RSC19*, #TO3l9)
      * get
        * [returns an HttpPaginatedResponse object](./spec/acceptance/rest/client_spec.rb#L1119)
        * 404 request to invalid URL
          * [returns an object with 404 status code and error message](./spec/acceptance/rest/client_spec.rb#L1126)
        * paged results
          * [provides paging](./spec/acceptance/rest/client_spec.rb#L1138)
      * post
        * [supports post](./spec/acceptance/rest/client_spec.rb#L1163)
        * [raises an exception once body size in bytes exceeded](./spec/acceptance/rest/client_spec.rb#L1169)
      * delete
        * [supports delete](./spec/acceptance/rest/client_spec.rb#L1182)
      * patch
        * [supports patch](./spec/acceptance/rest/client_spec.rb#L1198)
        * [raises an exception once body size in bytes exceeded](./spec/acceptance/rest/client_spec.rb#L1204)
      * put
        * [supports put](./spec/acceptance/rest/client_spec.rb#L1227)
        * [raises an exception once body size in bytes exceeded](./spec/acceptance/rest/client_spec.rb#L1233)
    * request_id generation (#RSC7c)
      * Timeout error
        * with option add_request_ids: true and no fallback hosts
          * [has an error with the same request_id of the request](./spec/acceptance/rest/client_spec.rb#L1256)
        * with option add_request_ids: true and REST operations with a message body
          * with mocks to inspect the params
            * with a single publish
              * [succeeds and sends the request_id as a param](./spec/acceptance/rest/client_spec.rb#L1278)
            * with an array publish
              * [succeeds and sends the request_id as a param](./spec/acceptance/rest/client_spec.rb#L1285)
          * without mocks to ensure the requests are accepted
            * with a single publish
              * [succeeds and sends the request_id as a param](./spec/acceptance/rest/client_spec.rb#L1294)
            * with an array publish
              * [succeeds and sends the request_id as a param](./spec/acceptance/rest/client_spec.rb#L1301)
        * option add_request_ids: true and specified fallback hosts
          * [request_id is the same across retries](./spec/acceptance/rest/client_spec.rb#L1326)
        * without request_id and no fallback hosts
          * [does not include request_id in ConnectionTimeout error](./spec/acceptance/rest/client_spec.rb#L1338)
      * UnauthorizedRequest nonce error
        * [includes request_id in UnauthorizedRequest error due to replayed nonce](./spec/acceptance/rest/client_spec.rb#L1351)
    * failed request logging
      * [is absent when requests do not fail](./spec/acceptance/rest/client_spec.rb#L1368)
      * with the first request failing
        * [is present with success message when requests do not actually fail](./spec/acceptance/rest/client_spec.rb#L1383)
      * with all requests failing
        * [is present when all requests fail](./spec/acceptance/rest/client_spec.rb#L1400)

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
      * [is converted into UTF_8](./spec/acceptance/rest/message_spec.rb#L19)
    * a single Message object (#RSL1a)
      * [publishes the message](./spec/acceptance/rest/message_spec.rb#L32)
    * an array of Message objects (#RSL1a)
      * [publishes three messages](./spec/acceptance/rest/message_spec.rb#L47)
    * an array of hashes (#RSL1a)
      * [publishes three messages](./spec/acceptance/rest/message_spec.rb#L59)
    * a name with data payload (#RSL1a, #RSL1b)
      * [publishes the message](./spec/acceptance/rest/message_spec.rb#L69)
    * with supported data payload content type
      * JSON Object (Hash)
        * [is encoded and decoded to the same hash](./spec/acceptance/rest/message_spec.rb#L82)
      * JSON Array
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L91)
      * String
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L100)
      * Binary
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L109)
    * with supported extra payload content type (#RSL1h, #RSL6a2)
      * JSON Object (Hash)
        * [is encoded and decoded to the same hash](./spec/acceptance/rest/message_spec.rb#L122)
      * JSON Array
        * [is encoded and decoded to the same deep multi-type object](./spec/acceptance/rest/message_spec.rb#L131)
      * nil
        * [is encoded and decoded to the same Array](./spec/acceptance/rest/message_spec.rb#L138)
    * idempotency (#RSL1k)
      * [idempotent publishing is set as per clientOptions](./spec/acceptance/rest/message_spec.rb#L207)
      * [idempotent publishing is enabled by default (#TO3n)](./spec/acceptance/rest/message_spec.rb#L217)
      * when ID is not included (#RSL1k2)
        * with Message object
          * [publishes the same message three times](./spec/acceptance/rest/message_spec.rb#L154)
        * with #publish arguments only
          * [publishes the same message three times](./spec/acceptance/rest/message_spec.rb#L161)
      * when ID is included (#RSL1k2, #RSL1k5)
        * [the ID provided is used for the published messages](./spec/acceptance/rest/message_spec.rb#L186)
        * [for multiple messages in one publish operation (#RSL1k3)](./spec/acceptance/rest/message_spec.rb#L191)
        * [for multiple messages in one publish operation with IDs following the required format described in RSL1k1 (#RSL1k3)](./spec/acceptance/rest/message_spec.rb#L198)
        * with Message object
          * [three REST publishes result in only one message being published](./spec/acceptance/rest/message_spec.rb#L172)
        * with #publish arguments only
          * [three REST publishes result in only one message being published](./spec/acceptance/rest/message_spec.rb#L180)
      * when idempotent publishing is enabled in the client library ClientOptions (#TO3n)
        * [the ID is populated with a random ID and serial 0 from this lib (#RSL1k1)](./spec/acceptance/rest/message_spec.rb#L280)
        * when there is a network failure triggering an automatic retry (#RSL1k4)
          * [for multiple messages in one publish operation](./spec/acceptance/rest/message_spec.rb#L273)
          * with Message object
            * [two REST publish retries result in only one message being published](./spec/acceptance/rest/message_spec.rb#L243)
          * with #publish arguments only
            * [two REST publish retries result in only one message being published](./spec/acceptance/rest/message_spec.rb#L253)
          * with explicitly provided message ID
            * [two REST publish retries result in only one message being published](./spec/acceptance/rest/message_spec.rb#L265)
        * when publishing a batch of messages
          * [the ID is populated with a single random ID and sequence of serials from this lib (#RSL1k1)](./spec/acceptance/rest/message_spec.rb#L288)
    * with unsupported data payload content type
      * Integer
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/rest/message_spec.rb#L305)
      * Float
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/rest/message_spec.rb#L313)
      * Boolean
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/rest/message_spec.rb#L321)
      * False
        * [is raises an UnsupportedDataType 40013 exception](./spec/acceptance/rest/message_spec.rb#L329)
    * encryption and encoding
      * with #publish and #history
        * with AES-128-CBC using crypto-data-128.json fixtures (#RTL7d)
          * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 1 with encrypted encoding cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
        * with AES-256-CBC using crypto-data-256.json fixtures (#RTL7d)
          * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 1 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 4 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 5 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 6 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 7 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 8 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 9 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 10 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 11 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 12 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 13 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 14 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 15 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 16 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 17 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 18 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 19 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 20 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 21 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 22 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 23 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 24 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 25 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 26 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 27 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 28 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 29 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 30 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 31 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 32 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 33 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 34 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 35 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 36 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 37 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 38 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 39 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 40 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 41 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 42 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 43 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 44 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 45 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 46 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 47 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 48 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 49 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 50 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 51 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 52 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 53 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 54 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 55 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 56 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 57 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 58 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 59 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 60 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 61 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 62 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 63 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 64 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 65 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 66 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 67 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 68 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 69 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 70 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 71 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 72 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
          * item 73 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * [encrypts message automatically when published (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L374)
              * [sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)](./spec/acceptance/rest/message_spec.rb#L389)
        * when publishing lots of messages
          * [encrypts on #publish and decrypts on #history](./spec/acceptance/rest/message_spec.rb#L422)
        * when retrieving #history with a different protocol
          * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/rest/message_spec.rb#L449)
          * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/rest/message_spec.rb#L449)
          * [delivers a Hash payload to the receiver](./spec/acceptance/rest/message_spec.rb#L449)
        * when publishing on an unencrypted channel and retrieving with #history on an encrypted channel
          * [does not attempt to decrypt the message](./spec/acceptance/rest/message_spec.rb#L465)
        * when publishing on an encrypted channel and retrieving with #history on an unencrypted channel
          * [retrieves the message that remains encrypted with an encrypted encoding attribute (#RTL7e)](./spec/acceptance/rest/message_spec.rb#L486)
          * [logs a Cipher exception (#RTL7e)](./spec/acceptance/rest/message_spec.rb#L492)
        * publishing on an encrypted channel and retrieving #history with a different algorithm on another client (#RTL7e)
          * [retrieves the message that remains encrypted with an encrypted encoding attribute (#RTL7e)](./spec/acceptance/rest/message_spec.rb#L513)
          * [logs a Cipher exception (#RTL7e)](./spec/acceptance/rest/message_spec.rb#L519)
        * publishing on an encrypted channel and subscribing with a different key on another client
          * [retrieves the message that remains encrypted with an encrypted encoding attribute](./spec/acceptance/rest/message_spec.rb#L540)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L546)

### Ably::Rest::Presence
_(see [spec/acceptance/rest/presence_spec.rb](./spec/acceptance/rest/presence_spec.rb))_
  * using JSON protocol
    * tested against presence fixture data set up in test app
      * #get
        * [returns current members on the channel with their action set to :present](./spec/acceptance/rest/presence_spec.rb#L41)
        * with :limit option
          * [returns a paged response limiting number of members per page](./spec/acceptance/rest/presence_spec.rb#L57)
        * default :limit
          * [defaults to a limit of 100](./spec/acceptance/rest/presence_spec.rb#L86)
        * with :client_id option
          * [returns a list members filtered by the provided client ID](./spec/acceptance/rest/presence_spec.rb#L95)
        * with :connection_id option
          * [returns a list members filtered by the provided connection ID](./spec/acceptance/rest/presence_spec.rb#L106)
          * [returns a list members filtered by the provided connection ID](./spec/acceptance/rest/presence_spec.rb#L110)
        * with a non ASCII channel name
          * stubbed
            * [correctly encodes the channel name](./spec/acceptance/rest/presence_spec.rb#L127)
      * #history
        * [returns recent presence activity](./spec/acceptance/rest/presence_spec.rb#L138)
        * default behaviour
          * [uses backwards direction](./spec/acceptance/rest/presence_spec.rb#L153)
        * with options
          * direction: :forwards
            * [returns recent presence activity forwards with most recent history last](./spec/acceptance/rest/presence_spec.rb#L165)
          * direction: :backwards
            * [returns recent presence activity backwards with most recent history first](./spec/acceptance/rest/presence_spec.rb#L180)
    * #history
      * with options
        * limit options
          * default
            * [is set to 100](./spec/acceptance/rest/presence_spec.rb#L225)
          * set to 1000
            * [is passes the limit query param value 1000](./spec/acceptance/rest/presence_spec.rb#L238)
        * with time range options
          * :start
            * with milliseconds since epoch value
              * [uses this value in the history request](./spec/acceptance/rest/presence_spec.rb#L268)
            * with Time object value
              * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/presence_spec.rb#L278)
          * :end
            * with milliseconds since epoch value
              * [uses this value in the history request](./spec/acceptance/rest/presence_spec.rb#L268)
            * with Time object value
              * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/presence_spec.rb#L278)
          * when argument start is after end
            * [should raise an exception](./spec/acceptance/rest/presence_spec.rb#L289)
    * decoding
      * with encoded fixture data
        * #history
          * [decodes encoded and encryped presence fixture data automatically](./spec/acceptance/rest/presence_spec.rb#L308)
        * #get
          * [decodes encoded and encryped presence fixture data automatically](./spec/acceptance/rest/presence_spec.rb#L315)
    * decoding permutations using mocked #history
      * valid decodeable content
        * #get
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L368)
        * #history
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L385)
      * invalid data
        * #get
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L416)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L420)
        * #history
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L440)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L444)

### Ably::Rest::Push::Admin
_(see [spec/acceptance/rest/push_admin_spec.rb](./spec/acceptance/rest/push_admin_spec.rb))_
  * using JSON protocol
    * #publish
      * [accepts valid push data and recipient (#RSH1a)](./spec/acceptance/rest/push_admin_spec.rb#L111)
      * without publish permissions
        * [raises a permissions issue exception](./spec/acceptance/rest/push_admin_spec.rb#L40)
      * invalid arguments (#RHS1a)
        * [raises an exception with a nil recipient](./spec/acceptance/rest/push_admin_spec.rb#L46)
        * [raises an exception with a empty recipient](./spec/acceptance/rest/push_admin_spec.rb#L50)
        * [raises an exception with a nil recipient](./spec/acceptance/rest/push_admin_spec.rb#L54)
        * [raises an exception with a empty recipient](./spec/acceptance/rest/push_admin_spec.rb#L58)
      * invalid recipient (#RSH1a)
        * [raises an error after receiving a 40x realtime response](./spec/acceptance/rest/push_admin_spec.rb#L64)
      * invalid push data (#RSH1a)
        * [raises an error after receiving a 40x realtime response](./spec/acceptance/rest/push_admin_spec.rb#L70)
      * recipient variable case
        * [is converted to snakeCase](./spec/acceptance/rest/push_admin_spec.rb#L105)
      * using test environment channel recipient (#RSH1a)
        * [triggers a push notification](./spec/acceptance/rest/push_admin_spec.rb#L136)
    * #device_registrations (#RSH1b)
      * without permissions
        * [raises a permissions not authorized exception](./spec/acceptance/rest/push_admin_spec.rb#L156)
      * #list (#RSH1b2)
        * [returns a PaginatedResult object containing DeviceDetails objects](./spec/acceptance/rest/push_admin_spec.rb#L197)
        * [returns an empty PaginatedResult if not params match](./spec/acceptance/rest/push_admin_spec.rb#L203)
        * [supports paging](./spec/acceptance/rest/push_admin_spec.rb#L209)
        * [provides filtering](./spec/acceptance/rest/push_admin_spec.rb#L221)
      * #get (#RSH1b1)
        * [returns a DeviceDetails object if a device ID string is provided](./spec/acceptance/rest/push_admin_spec.rb#L266)
        * [returns a DeviceDetails object if a DeviceDetails object is provided](./spec/acceptance/rest/push_admin_spec.rb#L274)
        * [raises a ResourceMissing exception if device ID does not exist](./spec/acceptance/rest/push_admin_spec.rb#L282)
      * #save (#RSH1b3)
        * [saves the new DeviceDetails Hash object](./spec/acceptance/rest/push_admin_spec.rb#L327)
        * [saves the associated DevicePushDetails](./spec/acceptance/rest/push_admin_spec.rb#L342)
        * [does not allow some fields to be configured](./spec/acceptance/rest/push_admin_spec.rb#L401)
        * [allows device_secret to be configured](./spec/acceptance/rest/push_admin_spec.rb#L414)
        * [saves the new DeviceDetails object](./spec/acceptance/rest/push_admin_spec.rb#L423)
        * [allows arbitrary number of subsequent saves](./spec/acceptance/rest/push_admin_spec.rb#L432)
        * [fails if data is invalid](./spec/acceptance/rest/push_admin_spec.rb#L445)
        * with FCM target
          * [saves the associated DevicePushDetails](./spec/acceptance/rest/push_admin_spec.rb#L356)
        * with web target
          * [saves the associated DevicePushDetails](./spec/acceptance/rest/push_admin_spec.rb#L378)
      * #remove_where (#RSH1b5)
        * [removes all matching device registrations by client_id](./spec/acceptance/rest/push_admin_spec.rb#L497)
        * [removes device by device_id](./spec/acceptance/rest/push_admin_spec.rb#L502)
        * [succeeds even if there is no match](./spec/acceptance/rest/push_admin_spec.rb#L507)
      * #remove (#RSH1b4)
        * [removes the provided device id string](./spec/acceptance/rest/push_admin_spec.rb#L560)
        * [removes the provided DeviceDetails](./spec/acceptance/rest/push_admin_spec.rb#L565)
        * [succeeds if the item does not exist](./spec/acceptance/rest/push_admin_spec.rb#L570)
    * #channel_subscriptions (#RSH1c)
      * #list (#RSH1c1)
        * [returns a PaginatedResult object containing DeviceDetails objects](./spec/acceptance/rest/push_admin_spec.rb#L638)
        * [returns an empty PaginatedResult if params do not match](./spec/acceptance/rest/push_admin_spec.rb#L644)
        * [supports paging](./spec/acceptance/rest/push_admin_spec.rb#L650)
        * [provides filtering](./spec/acceptance/rest/push_admin_spec.rb#L662)
        * [raises an exception if none of the required filters are provided](./spec/acceptance/rest/push_admin_spec.rb#L690)
      * #list_channels (#RSH1c2)
        * [returns a PaginatedResult object containing String objects](./spec/acceptance/rest/push_admin_spec.rb#L717)
        * [supports paging](./spec/acceptance/rest/push_admin_spec.rb#L724)
        * [returns an accurate number of channels after devices are deleted](./spec/acceptance/rest/push_admin_spec.rb#L739)
      * #save (#RSH1c3)
        * [saves the new client_id PushChannelSubscription Hash object](./spec/acceptance/rest/push_admin_spec.rb#L764)
        * [saves the new device_id PushChannelSubscription Hash object](./spec/acceptance/rest/push_admin_spec.rb#L775)
        * [saves the client_id PushChannelSubscription object](./spec/acceptance/rest/push_admin_spec.rb#L786)
        * [saves the device_id PushChannelSubscription object](./spec/acceptance/rest/push_admin_spec.rb#L797)
        * [allows arbitrary number of subsequent saves](./spec/acceptance/rest/push_admin_spec.rb#L808)
        * [fails if data is invalid](./spec/acceptance/rest/push_admin_spec.rb#L821)
      * #remove_where (#RSH1c5)
        * PENDING: *[removes matching channels](./spec/acceptance/rest/push_admin_spec.rb#L856)*
        * [removes matching client_ids](./spec/acceptance/rest/push_admin_spec.rb#L864)
        * [removes matching device_ids](./spec/acceptance/rest/push_admin_spec.rb#L870)
        * [device_id and client_id filters in the same request are not suppoorted](./spec/acceptance/rest/push_admin_spec.rb#L876)
        * [succeeds on no match](./spec/acceptance/rest/push_admin_spec.rb#L880)
      * #remove (#RSH1c4)
        * [removes match for Hash object by channel and client_id](./spec/acceptance/rest/push_admin_spec.rb#L910)
        * [removes match for PushChannelSubscription object by channel and client_id](./spec/acceptance/rest/push_admin_spec.rb#L915)
        * [removes match for Hash object by channel and device_id](./spec/acceptance/rest/push_admin_spec.rb#L922)
        * [removes match for PushChannelSubscription object by channel and client_id](./spec/acceptance/rest/push_admin_spec.rb#L927)
        * [succeeds even if there is no match](./spec/acceptance/rest/push_admin_spec.rb#L934)

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

### Ably::Models::ChannelOptions
_(see [spec/lib/unit/models/channel_options_spec.rb](./spec/lib/unit/models/channel_options_spec.rb))_
  * #modes_to_flags
    * [converts modes to ProtocolMessage#flags correctly](./spec/lib/unit/models/channel_options_spec.rb#L17)
  * #set_modes_from_flags
    * [converts flags to ChannelOptions#modes correctly](./spec/lib/unit/models/channel_options_spec.rb#L30)
  * #set_params
    * [should be able to overwrite attributes](./spec/lib/unit/models/channel_options_spec.rb#L43)
    * [should be able to make params empty](./spec/lib/unit/models/channel_options_spec.rb#L48)

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
    * [should have no default TTL](./spec/unit/auth_spec.rb#L71)
    * [should have no default capability](./spec/unit/auth_spec.rb#L75)

### Ably::Logger
_(see [spec/unit/logger_spec.rb](./spec/unit/logger_spec.rb))_
  * [uses the language provided Logger by default](./spec/unit/logger_spec.rb#L15)
  * with a custom Logger
    * with an invalid interface
      * [raises an exception](./spec/unit/logger_spec.rb#L118)
    * with a valid interface
      * [is used](./spec/unit/logger_spec.rb#L129)
  * with blocks
    * [does not call the block unless the log level is met](./spec/unit/logger_spec.rb#L143)
    * with an exception in the logger block
      * [catches the error and continues](./spec/unit/logger_spec.rb#L158)

### Ably::Models::AuthDetails
_(see [spec/unit/models/auth_details_spec.rb](./spec/unit/models/auth_details_spec.rb))_
  * behaves like a model
    * attributes
      * #access_token
        * [retrieves attribute :access_token](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * ==
    * [is true when attributes are the same](./spec/unit/models/auth_details_spec.rb#L17)
    * [is false when attributes are not the same](./spec/unit/models/auth_details_spec.rb#L22)
    * [is false when class type differs](./spec/unit/models/auth_details_spec.rb#L26)

### Ably::Models::ChannelDetails
_(see [spec/unit/models/channel_details_spec.rb](./spec/unit/models/channel_details_spec.rb))_
  * #channel_id
    * [should return channel id](./spec/unit/models/channel_details_spec.rb#L8)
  * #name
    * [should return name](./spec/unit/models/channel_details_spec.rb#L14)
  * #status
    * [should return status](./spec/unit/models/channel_details_spec.rb#L20)

### Ably::Models::ChannelMetrics
_(see [spec/unit/models/channel_metrics_spec.rb](./spec/unit/models/channel_metrics_spec.rb))_
  * #connections
    * [should return integer](./spec/unit/models/channel_metrics_spec.rb#L8)
  * #presence_connections
    * [should return integer](./spec/unit/models/channel_metrics_spec.rb#L14)
  * #presence_members
    * [should return integer](./spec/unit/models/channel_metrics_spec.rb#L20)
  * #presence_subscribers
    * [should return integer](./spec/unit/models/channel_metrics_spec.rb#L26)
  * #publishers
    * [should return integer](./spec/unit/models/channel_metrics_spec.rb#L32)
  * #subscribers
    * [should return integer](./spec/unit/models/channel_metrics_spec.rb#L38)

### Ably::Models::ChannelOccupancy
_(see [spec/unit/models/channel_occupancy_spec.rb](./spec/unit/models/channel_occupancy_spec.rb))_
  * #metrics
    * [should return attributes](./spec/unit/models/channel_occupancy_spec.rb#L8)

### Ably::Models::ChannelStateChange
_(see [spec/unit/models/channel_state_change_spec.rb](./spec/unit/models/channel_state_change_spec.rb))_
  * #current (#TH1)
    * [is required](./spec/unit/models/channel_state_change_spec.rb#L10)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L14)
  * #previous (#TH2)
    * [is required](./spec/unit/models/channel_state_change_spec.rb#L20)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L24)
  * #event (#TH5)
    * [is not required](./spec/unit/models/channel_state_change_spec.rb#L30)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L34)
  * #reason (#TH3)
    * [is not required](./spec/unit/models/channel_state_change_spec.rb#L40)
    * [is an attribute](./spec/unit/models/channel_state_change_spec.rb#L44)
  * #resumed (#TH4)
    * [is false when ommitted](./spec/unit/models/channel_state_change_spec.rb#L50)
    * [is true when provided](./spec/unit/models/channel_state_change_spec.rb#L54)
  * invalid attributes
    * [raises an argument error](./spec/unit/models/channel_state_change_spec.rb#L60)

### Ably::Models::ChannelStatus
_(see [spec/unit/models/channel_status_spec.rb](./spec/unit/models/channel_status_spec.rb))_
  * #is_active
    * when occupancy is active
      * [should return true](./spec/unit/models/channel_status_spec.rb#L11)
    * when occupancy is not active
      * [should return false](./spec/unit/models/channel_status_spec.rb#L19)
  * #occupancy
    * [should return occupancy object](./spec/unit/models/channel_status_spec.rb#L26)

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
    * #connection_state_ttl (#CD2f)
      * [retrieves attribute :connection_state_ttl and converts it from ms to s](./spec/unit/models/connection_details_spec.rb#L20)
    * #max_idle_interval (#CD2h)
      * [retrieves attribute :max_idle_interval and converts it from ms to s](./spec/unit/models/connection_details_spec.rb#L30)
  * ==
    * [is true when attributes are the same](./spec/unit/models/connection_details_spec.rb#L39)
    * [is false when attributes are not the same](./spec/unit/models/connection_details_spec.rb#L44)
    * [is false when class type differs](./spec/unit/models/connection_details_spec.rb#L48)

### Ably::Models::ConnectionStateChange
_(see [spec/unit/models/connection_state_change_spec.rb](./spec/unit/models/connection_state_change_spec.rb))_
  * #current (#TA2)
    * [is required](./spec/unit/models/connection_state_change_spec.rb#L10)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L14)
  * #previous(#TA2)
    * [is required](./spec/unit/models/connection_state_change_spec.rb#L20)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L24)
  * #event(#TA5)
    * [is not required](./spec/unit/models/connection_state_change_spec.rb#L30)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L34)
  * #retry_in (#TA2)
    * [is not required](./spec/unit/models/connection_state_change_spec.rb#L41)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L45)
  * #reason (#TA3)
    * [is not required](./spec/unit/models/connection_state_change_spec.rb#L51)
    * [is an attribute](./spec/unit/models/connection_state_change_spec.rb#L55)
  * invalid attributes
    * [raises an argument error](./spec/unit/models/connection_state_change_spec.rb#L61)

### Ably::Models::DeltaExtras
_(see [spec/unit/models/delta_extras_spec.rb](./spec/unit/models/delta_extras_spec.rb))_
  * [should have `from` attribute](./spec/unit/models/delta_extras_spec.rb#L7)
  * [should have `format` attribute](./spec/unit/models/delta_extras_spec.rb#L11)

### Ably::Models::DeviceDetails
_(see [spec/unit/models/device_details_spec.rb](./spec/unit/models/device_details_spec.rb))_
  * #id and #id=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/device_details_spec.rb#L16)
    * [setter accepts nil](./spec/unit/models/device_details_spec.rb#L22)
    * [rejects non string or nil values](./spec/unit/models/device_details_spec.rb#L29)
  * #platform and #platform=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/device_details_spec.rb#L16)
    * [setter accepts nil](./spec/unit/models/device_details_spec.rb#L22)
    * [rejects non string or nil values](./spec/unit/models/device_details_spec.rb#L29)
  * #form_factor and #form_factor=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/device_details_spec.rb#L16)
    * [setter accepts nil](./spec/unit/models/device_details_spec.rb#L22)
    * [rejects non string or nil values](./spec/unit/models/device_details_spec.rb#L29)
  * #client_id and #client_id=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/device_details_spec.rb#L16)
    * [setter accepts nil](./spec/unit/models/device_details_spec.rb#L22)
    * [rejects non string or nil values](./spec/unit/models/device_details_spec.rb#L29)
  * #device_secret and #device_secret=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/device_details_spec.rb#L16)
    * [setter accepts nil](./spec/unit/models/device_details_spec.rb#L22)
    * [rejects non string or nil values](./spec/unit/models/device_details_spec.rb#L29)
  * camelCase constructor attributes
    * [are rubyfied and exposed as underscore case](./spec/unit/models/device_details_spec.rb#L39)
    * [are generated when the object is serialised to JSON](./spec/unit/models/device_details_spec.rb#L43)
  * #metadata and #metadata=
    * [setter accepts a Hash value and getter returns the new value](./spec/unit/models/device_details_spec.rb#L51)
    * [setter accepts nil but always returns an empty hash](./spec/unit/models/device_details_spec.rb#L57)
    * [rejects non Hash or nil values](./spec/unit/models/device_details_spec.rb#L64)
  * #push and #push=
    * [setter accepts a DevicePushDetails object and getter returns a DevicePushDetails object](./spec/unit/models/device_details_spec.rb#L74)
    * [setter accepts a Hash value and getter returns a DevicePushDetails object](./spec/unit/models/device_details_spec.rb#L82)
    * [setter accepts nil but always returns a DevicePushDetails object](./spec/unit/models/device_details_spec.rb#L90)
    * [rejects non Hash, DevicePushDetails or nil values](./spec/unit/models/device_details_spec.rb#L98)

### Ably::Models::DevicePushDetails
_(see [spec/unit/models/device_push_details_spec.rb](./spec/unit/models/device_push_details_spec.rb))_
  * #state and #state=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/device_push_details_spec.rb#L16)
    * [setter accepts nil](./spec/unit/models/device_push_details_spec.rb#L22)
    * [rejects non string or nil values](./spec/unit/models/device_push_details_spec.rb#L29)
  * camelCase constructor attributes
    * [are rubyfied and exposed as underscore case](./spec/unit/models/device_push_details_spec.rb#L39)
    * [are generated when the object is serialised to JSON](./spec/unit/models/device_push_details_spec.rb#L44)
  * #recipient and #recipient=
    * [setter accepts a Hash value and getter returns the new value](./spec/unit/models/device_push_details_spec.rb#L52)
    * [setter accepts nil but always returns an empty hash](./spec/unit/models/device_push_details_spec.rb#L58)
    * [rejects non Hash or nil values](./spec/unit/models/device_push_details_spec.rb#L65)
  * #error_reason and #error_reason=
    * [setter accepts a ErrorInfo object and getter returns a ErrorInfo object](./spec/unit/models/device_push_details_spec.rb#L74)
    * [setter accepts a Hash value and getter returns a ErrorInfo object](./spec/unit/models/device_push_details_spec.rb#L82)
    * [setter accepts nil values](./spec/unit/models/device_push_details_spec.rb#L90)
    * [rejects non Hash, ErrorInfo or nil values](./spec/unit/models/device_push_details_spec.rb#L97)

### Ably::Models::ErrorInfo
_(see [spec/unit/models/error_info_spec.rb](./spec/unit/models/error_info_spec.rb))_
  * #TI1, #TI4
    * behaves like a model
      * attributes
        * #code
          * [retrieves attribute :code](./spec/shared/model_behaviour.rb#L15)
        * #status_code
          * [retrieves attribute :status_code](./spec/shared/model_behaviour.rb#L15)
        * #href
          * [retrieves attribute :href](./spec/shared/model_behaviour.rb#L15)
        * #message
          * [retrieves attribute :message](./spec/shared/model_behaviour.rb#L15)
        * #request_id
          * [retrieves attribute :request_id](./spec/shared/model_behaviour.rb#L15)
        * #cause
          * [retrieves attribute :cause](./spec/shared/model_behaviour.rb#L15)
      * #==
        * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
        * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
        * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
      * is immutable
        * [prevents changes](./spec/shared/model_behaviour.rb#L76)
        * [dups options](./spec/shared/model_behaviour.rb#L80)
  * #status #TI1, #TI2
    * [is an alias for #status_code](./spec/unit/models/error_info_spec.rb#L15)
  * #request_id #RSC7c
    * [should return request ID](./spec/unit/models/error_info_spec.rb#L24)
  * #cause #TI1
    * [should return cause attribute](./spec/unit/models/error_info_spec.rb#L32)
  * log entries container help link #TI5
    * without an error code
      * [does not include the help URL](./spec/unit/models/error_info_spec.rb#L41)
    * with a specified error code
      * [includes https://help.ably.io/error/[CODE] in the stringified object](./spec/unit/models/error_info_spec.rb#L49)
    * with an error code and an href attribute
      * [includes the specified href in the stringified object](./spec/unit/models/error_info_spec.rb#L57)
    * with an error code and a message with the same error URL
      * [includes the specified error URL only once in the stringified object](./spec/unit/models/error_info_spec.rb#L66)
    * with an error code and a message with a different error URL
      * [includes the specified error URL from the message and the error code URL in the stringified object](./spec/unit/models/error_info_spec.rb#L74)

### Ably::Models::HttpPaginatedResponse: #HP1 -> #HP8
_(see [spec/unit/models/http_paginated_result_spec.rb](./spec/unit/models/http_paginated_result_spec.rb))_
  * #items
    * [returns correct length from body](./spec/unit/models/http_paginated_result_spec.rb#L33)
    * [is Enumerable](./spec/unit/models/http_paginated_result_spec.rb#L37)
    * [is iterable](./spec/unit/models/http_paginated_result_spec.rb#L41)
    * [provides [] accessor method](./spec/unit/models/http_paginated_result_spec.rb#L59)
    * [#first gets the first item in page](./spec/unit/models/http_paginated_result_spec.rb#L65)
    * [#last gets the last item in page](./spec/unit/models/http_paginated_result_spec.rb#L69)
    * #each
      * [returns an enumerator](./spec/unit/models/http_paginated_result_spec.rb#L46)
      * [yields each item](./spec/unit/models/http_paginated_result_spec.rb#L50)
  * with non paged http response
    * [is the last page](./spec/unit/models/http_paginated_result_spec.rb#L174)
    * [does not have next page](./spec/unit/models/http_paginated_result_spec.rb#L178)
    * [does not support pagination](./spec/unit/models/http_paginated_result_spec.rb#L182)
    * [returns nil when accessing next page](./spec/unit/models/http_paginated_result_spec.rb#L186)
    * [returns nil when accessing first page](./spec/unit/models/http_paginated_result_spec.rb#L190)
  * with paged http response
    * [has next page](./spec/unit/models/http_paginated_result_spec.rb#L208)
    * [is not the last page](./spec/unit/models/http_paginated_result_spec.rb#L212)
    * [supports pagination](./spec/unit/models/http_paginated_result_spec.rb#L216)
    * accessing next page
      * [returns another HttpPaginatedResponse](./spec/unit/models/http_paginated_result_spec.rb#L244)
      * [retrieves the next page of results](./spec/unit/models/http_paginated_result_spec.rb#L248)
      * [does not have a next page](./spec/unit/models/http_paginated_result_spec.rb#L253)
      * [is the last page](./spec/unit/models/http_paginated_result_spec.rb#L257)
      * [returns nil when trying to access the last page when it is the last page](./spec/unit/models/http_paginated_result_spec.rb#L261)
      * and then first page
        * [returns a HttpPaginatedResponse](./spec/unit/models/http_paginated_result_spec.rb#L272)
        * [retrieves the first page of results](./spec/unit/models/http_paginated_result_spec.rb#L276)
  * response metadata
    * successful response
      * [#success? is true](./spec/unit/models/http_paginated_result_spec.rb#L288)
      * [#status_code reflects status code](./spec/unit/models/http_paginated_result_spec.rb#L292)
      * [#error_code to be empty](./spec/unit/models/http_paginated_result_spec.rb#L296)
      * [#error_message to be empty](./spec/unit/models/http_paginated_result_spec.rb#L300)
      * [#headers to be a hash](./spec/unit/models/http_paginated_result_spec.rb#L304)
    * failed response
      * [#success? is false](./spec/unit/models/http_paginated_result_spec.rb#L313)
      * [#status_code reflects status code](./spec/unit/models/http_paginated_result_spec.rb#L317)
      * [#error_code to be populated](./spec/unit/models/http_paginated_result_spec.rb#L321)
      * [#error_message to be populated](./spec/unit/models/http_paginated_result_spec.rb#L325)
      * [#headers to be present](./spec/unit/models/http_paginated_result_spec.rb#L329)
  * #items Array conversion and nil handling #HP3
    * with Json Array
      * [is an array](./spec/unit/models/http_paginated_result_spec.rb#L344)
    * with Json Object
      * [is an array](./spec/unit/models/http_paginated_result_spec.rb#L354)
    * with empty response
      * [is an array](./spec/unit/models/http_paginated_result_spec.rb#L365)
    * with nil response
      * [is an array](./spec/unit/models/http_paginated_result_spec.rb#L375)

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
        * [leaves the message data intact as Base64 encoding is not necessary](./spec/unit/models/message_encoders/base64_spec.rb#L69)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L73)
      * already encoded message with binary payload
        * [leaves the message data intact as Base64 encoding is not necessary](./spec/unit/models/message_encoders/base64_spec.rb#L81)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L85)
      * message with UTF-8 payload
        * [leaves the data intact](./spec/unit/models/message_encoders/base64_spec.rb#L93)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L97)
      * message with nil payload
        * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L105)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L109)
      * message with empty binary string payload
        * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L117)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L121)
    * over text transport
      * message with binary payload
        * [encodes binary data as base64](./spec/unit/models/message_encoders/base64_spec.rb#L136)
        * [adds the encoding](./spec/unit/models/message_encoders/base64_spec.rb#L140)
      * already encoded message with binary payload
        * [encodes binary data as base64](./spec/unit/models/message_encoders/base64_spec.rb#L148)
        * [adds the encoding](./spec/unit/models/message_encoders/base64_spec.rb#L152)
      * message with UTF-8 payload
        * [leaves the data intact](./spec/unit/models/message_encoders/base64_spec.rb#L160)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L164)
      * message with nil payload
        * [leaves the message data intact](./spec/unit/models/message_encoders/base64_spec.rb#L172)
        * [leaves the encoding intact](./spec/unit/models/message_encoders/base64_spec.rb#L176)

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
  * serialization of the Message object (#RSL1j)
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
  * #id (#RSL1j)
    * [exposes the #id attribute](./spec/unit/models/message_spec.rb#L25)
    * [#as_json exposes the #id attribute](./spec/unit/models/message_spec.rb#L29)
  * #timestamp
    * [retrieves attribute :timestamp as Time object from ProtocolMessage](./spec/unit/models/message_spec.rb#L37)
  * #extras (#TM2i)
    * when missing
      * [is nil](./spec/unit/models/message_spec.rb#L48)
    * when a string
      * [raises an exception](./spec/unit/models/message_spec.rb#L55)
    * when a Hash
      * [contains a Hash Json object](./spec/unit/models/message_spec.rb#L62)
    * when a Json Array
      * [contains a Json Array object](./spec/unit/models/message_spec.rb#L69)
  * #connection_id attribute
    * when this model has a connectionId attribute
      * but no protocol message
        * [uses the model value](./spec/unit/models/message_spec.rb#L84)
      * with a protocol message with a different connectionId
        * [uses the model value](./spec/unit/models/message_spec.rb#L92)
    * when this model has no connectionId attribute
      * and no protocol message
        * [uses the model value](./spec/unit/models/message_spec.rb#L102)
      * with a protocol message with a connectionId
        * [uses the model value](./spec/unit/models/message_spec.rb#L110)
  * initialized with
    * :name
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L137)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L141)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L149)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L153)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L161)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L165)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L173)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L181)
    * :client_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L137)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L141)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L149)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L153)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L161)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L165)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L173)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L181)
    * :encoding
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L137)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L141)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L149)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L153)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L161)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L165)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L173)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L181)
  * #size
    * String (#TO3l8a)
      * [should return 33 bytes](./spec/unit/models/message_spec.rb#L223)
    * Object (#TO3l8b)
      * [should return 38 bytes](./spec/unit/models/message_spec.rb#L234)
    * Array (#TO3l8b)
      * [should return 24 bytes](./spec/unit/models/message_spec.rb#L245)
    * extras (#TO3l8d)
      * [should return 57 bytes](./spec/unit/models/message_spec.rb#L256)
    * nil (#TO3l8e)
      * [should return 19 bytes](./spec/unit/models/message_spec.rb#L267)
  * #protocol_message_index (#RTL21)
    * [should return correct protocol_message_index](./spec/unit/models/message_spec.rb#L280)
  * #from_encoded (#TM3)
    * with no encoding
      * [returns a message object](./spec/unit/models/message_spec.rb#L510)
      * with a block
        * [does not call the block](./spec/unit/models/message_spec.rb#L518)
    * with an encoding
      * [returns a message object](./spec/unit/models/message_spec.rb#L535)
    * with a custom encoding
      * [returns a message object with the residual incompatible transforms left in the encoding property](./spec/unit/models/message_spec.rb#L550)
    * with a Cipher encoding
      * [returns a message object with the residual incompatible transforms left in the encoding property](./spec/unit/models/message_spec.rb#L569)
    * with invalid Cipher encoding
      * without a block
        * [raises an exception](./spec/unit/models/message_spec.rb#L587)
      * with a block
        * [calls the block with the exception](./spec/unit/models/message_spec.rb#L593)
  * #from_encoded_array (#TM3)
    * with no encoding
      * [returns an Array of message objects](./spec/unit/models/message_spec.rb#L612)
  * #delta_extras (TM2i)
    * when delta
      * [should return vcdiff format](./spec/unit/models/message_spec.rb#L630)
      * [should return 1234-1234-5678-9009 message id](./spec/unit/models/message_spec.rb#L634)
    * when no delta
      * [should return nil](./spec/unit/models/message_spec.rb#L642)

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
  * #size
    * String (#TO3l8a)
      * [should return 20 bytes](./spec/unit/models/presence_message_spec.rb#L230)
    * Object (#TO3l8b)
      * [should return 32 bytes](./spec/unit/models/presence_message_spec.rb#L239)
    * Array (#TO3l8b)
      * [should return 18 bytes](./spec/unit/models/presence_message_spec.rb#L248)
    * extras (#TO3l8d)
      * [should return 51 bytes](./spec/unit/models/presence_message_spec.rb#L257)
    * nil (#TO3l8e)
      * [should return 1 bytes](./spec/unit/models/presence_message_spec.rb#L266)
  * #from_encoded (#TP4)
    * with no encoding
      * [returns a presence message object](./spec/unit/models/presence_message_spec.rb#L444)
      * with a block
        * [does not call the block](./spec/unit/models/presence_message_spec.rb#L452)
    * with an encoding
      * [returns a presence message object](./spec/unit/models/presence_message_spec.rb#L469)
    * with a custom encoding
      * [returns a presence message object with the residual incompatible transforms left in the encoding property](./spec/unit/models/presence_message_spec.rb#L484)
    * with a Cipher encoding
      * [returns a presence message object with the residual incompatible transforms left in the encoding property](./spec/unit/models/presence_message_spec.rb#L503)
    * with invalid Cipher encoding
      * without a block
        * [raises an exception](./spec/unit/models/presence_message_spec.rb#L520)
      * with a block
        * [calls the block with the exception](./spec/unit/models/presence_message_spec.rb#L526)
  * #from_encoded_array (#TP4)
    * with no encoding
      * [returns an Array of presence message objects](./spec/unit/models/presence_message_spec.rb#L545)
  * #shallow_clone
    * with inherited attributes from ProtocolMessage
      * [creates a duplicate of the message without any ProtocolMessage dependency](./spec/unit/models/presence_message_spec.rb#L565)
    * with embedded attributes for all fields
      * [creates a duplicate of the message without any ProtocolMessage dependency](./spec/unit/models/presence_message_spec.rb#L579)
    * with new attributes passed in to the method
      * [creates a duplicate of the message without any ProtocolMessage dependency](./spec/unit/models/presence_message_spec.rb#L595)
      * with an invalid ProtocolMessage (missing an ID)
        * [allows an ID to be passed in to the shallow clone that takes precedence](./spec/unit/models/presence_message_spec.rb#L607)
      * with mixing of cases
        * [resolves case issues and can use camelCase or snake_case](./spec/unit/models/presence_message_spec.rb#L614)

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
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * attributes
    * #timestamp
      * [retrieves attribute :timestamp as Time object](./spec/unit/models/protocol_message_spec.rb#L75)
    * #count
      * when missing
        * [is 1](./spec/unit/models/protocol_message_spec.rb#L84)
      * when non numeric
        * [is 1](./spec/unit/models/protocol_message_spec.rb#L91)
      * when greater than 1
        * [is the value of count](./spec/unit/models/protocol_message_spec.rb#L98)
    * #message_serial
      * [converts :msg_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L106)
    * #has_message_serial?
      * without msg_serial
        * [returns false](./spec/unit/models/protocol_message_spec.rb#L116)
      * with msg_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L124)
    * #flags (#TR4i)
      * when nil
        * [is zero](./spec/unit/models/protocol_message_spec.rb#L134)
      * when numeric
        * [is an Integer](./spec/unit/models/protocol_message_spec.rb#L142)
      * when presence flag present
        * [#has_presence_flag? is true](./spec/unit/models/protocol_message_spec.rb#L150)
        * [#has_channel_resumed_flag? is false](./spec/unit/models/protocol_message_spec.rb#L154)
      * when channel resumed flag present
        * [#has_channel_resumed_flag? is true](./spec/unit/models/protocol_message_spec.rb#L162)
        * [#has_presence_flag? is false](./spec/unit/models/protocol_message_spec.rb#L166)
      * when attach resumed flag
        * flags is 34
          * [#has_attach_resume_flag? is true](./spec/unit/models/protocol_message_spec.rb#L175)
          * [#has_attach_presence_flag? is false](./spec/unit/models/protocol_message_spec.rb#L179)
        * flags is 0
          * [should raise an exception if flags is a float number](./spec/unit/models/protocol_message_spec.rb#L187)
      * when channel resumed and presence flags present
        * [#has_channel_resumed_flag? is true](./spec/unit/models/protocol_message_spec.rb#L196)
        * [#has_presence_flag? is true](./spec/unit/models/protocol_message_spec.rb#L200)
      * when has another future flag
        * [#has_presence_flag? is false](./spec/unit/models/protocol_message_spec.rb#L208)
        * [#has_backlog_flag? is true](./spec/unit/models/protocol_message_spec.rb#L212)
    * #params (#RTL4k1)
      * when present
        * [is expected to eq {:foo=>:bar}](./spec/unit/models/protocol_message_spec.rb#L224)
      * when empty
        * [is expected to eq {}](./spec/unit/models/protocol_message_spec.rb#L230)
    * #error
      * with no error attribute
        * [returns nil](./spec/unit/models/protocol_message_spec.rb#L240)
      * with nil error
        * [returns nil](./spec/unit/models/protocol_message_spec.rb#L248)
      * with error
        * [returns a valid ErrorInfo object](./spec/unit/models/protocol_message_spec.rb#L256)
    * #messages (#TR4k)
      * [contains Message objects](./spec/unit/models/protocol_message_spec.rb#L266)
    * #messages (#RTL21)
      * [contains Message objects in ascending order](./spec/unit/models/protocol_message_spec.rb#L284)
    * #presence (#TR4l)
      * [contains PresenceMessage objects](./spec/unit/models/protocol_message_spec.rb#L296)
    * #message_size (#TO3l8)
      * on presence
        * [should return 13 bytes (sum in bytes: data and client_id)](./spec/unit/models/protocol_message_spec.rb#L309)
      * on message
        * [should return 76 bytes (sum in bytes: data, client_id, name, extras)](./spec/unit/models/protocol_message_spec.rb#L319)
    * #connection_details (#TR4o)
      * with a JSON value
        * [contains a ConnectionDetails object](./spec/unit/models/protocol_message_spec.rb#L331)
        * [contains the attributes from the JSON connectionDetails](./spec/unit/models/protocol_message_spec.rb#L335)
      * without a JSON value
        * [contains an empty ConnectionDetails object](./spec/unit/models/protocol_message_spec.rb#L344)
    * #auth (#TR4p)
      * with a JSON value
        * [contains a AuthDetails object](./spec/unit/models/protocol_message_spec.rb#L358)
        * [contains the attributes from the JSON auth details](./spec/unit/models/protocol_message_spec.rb#L362)
      * without a JSON value
        * [contains an empty AuthDetails object](./spec/unit/models/protocol_message_spec.rb#L370)

### Ably::Models::PushChannelSubscription
_(see [spec/unit/models/push_channel_subscription_spec.rb](./spec/unit/models/push_channel_subscription_spec.rb))_
  * #channel and #channel=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/push_channel_subscription_spec.rb#L21)
    * [setter accepts nil](./spec/unit/models/push_channel_subscription_spec.rb#L27)
    * [rejects non string or nil values](./spec/unit/models/push_channel_subscription_spec.rb#L34)
  * #client_id and #client_id=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/push_channel_subscription_spec.rb#L21)
    * [setter accepts nil](./spec/unit/models/push_channel_subscription_spec.rb#L27)
    * [rejects non string or nil values](./spec/unit/models/push_channel_subscription_spec.rb#L34)
  * #device_id and #device_id=
    * [setter accepts a string value and getter returns the new value](./spec/unit/models/push_channel_subscription_spec.rb#L21)
    * [setter accepts nil](./spec/unit/models/push_channel_subscription_spec.rb#L27)
    * [rejects non string or nil values](./spec/unit/models/push_channel_subscription_spec.rb#L34)
  * camelCase constructor attributes
    * [are rubyfied and exposed as underscore case](./spec/unit/models/push_channel_subscription_spec.rb#L44)
    * [are generated when the object is serialised to JSON](./spec/unit/models/push_channel_subscription_spec.rb#L48)
  * conversion method PushChannelSubscription
    * [accepts a PushChannelSubscription object](./spec/unit/models/push_channel_subscription_spec.rb#L57)
  * #for_client_id constructor
    * with a valid object
      * [accepts a Hash object](./spec/unit/models/push_channel_subscription_spec.rb#L70)
    * with an invalid valid object
      * [accepts a Hash object](./spec/unit/models/push_channel_subscription_spec.rb#L81)

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
        * [is true](./spec/unit/models/token_details_spec.rb#L64)
      * within grace period buffer
        * [is false](./spec/unit/models/token_details_spec.rb#L72)
      * when expires is not available (i.e. string tokens)
        * [is always false](./spec/unit/models/token_details_spec.rb#L80)
      * with :from attribute
        * [is false](./spec/unit/models/token_details_spec.rb#L90)
        * [is true](./spec/unit/models/token_details_spec.rb#L95)
  * ==
    * [is true when attributes are the same](./spec/unit/models/token_details_spec.rb#L105)
    * [is false when attributes are not the same](./spec/unit/models/token_details_spec.rb#L110)
    * [is false when class type differs](./spec/unit/models/token_details_spec.rb#L114)
  * to_json
    * with all attributes and values
      * [returns all attributes](./spec/unit/models/token_details_spec.rb#L146)
    * with only a token string
      * [returns populated attributes](./spec/unit/models/token_details_spec.rb#L159)
  * from_json (#TD7)
    * with Ruby idiomatic Hash object
      * [returns a valid TokenDetails object](./spec/unit/models/token_details_spec.rb#L185)
    * with JSON-like object
      * [returns a valid TokenDetails object](./spec/unit/models/token_details_spec.rb#L208)
    * with JSON string
      * [returns a valid TokenDetails object](./spec/unit/models/token_details_spec.rb#L230)

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
  * from_json (#TE6)
    * with Ruby idiomatic Hash object
      * [returns a valid TokenRequest object](./spec/unit/models/token_request_spec.rb#L130)
    * with JSON-like object
      * [returns a valid TokenRequest object](./spec/unit/models/token_request_spec.rb#L152)
    * with JSON string
      * [returns a valid TokenRequest object](./spec/unit/models/token_request_spec.rb#L174)

### Ably::Modules::EventEmitter
_(see [spec/unit/modules/event_emitter_spec.rb](./spec/unit/modules/event_emitter_spec.rb))_
  * #emit event fan out
    * [should emit an event for any number of subscribers](./spec/unit/modules/event_emitter_spec.rb#L21)
    * [sends only messages to matching event names](./spec/unit/modules/event_emitter_spec.rb#L30)
    * #on subscribe to multiple events
      * [with the same block](./spec/unit/modules/event_emitter_spec.rb#L62)
    * event callback changes within the callback block
      * when new event callbacks are added
        * [is unaffected and processes the prior event callbacks once (#RTE6b)](./spec/unit/modules/event_emitter_spec.rb#L86)
        * [adds them for the next emitted event (#RTE6b)](./spec/unit/modules/event_emitter_spec.rb#L92)
      * when callbacks are removed
        * [is unaffected and processes the prior event callbacks once (#RTE6b)](./spec/unit/modules/event_emitter_spec.rb#L113)
        * [removes them for the next emitted event (#RTE6b)](./spec/unit/modules/event_emitter_spec.rb#L118)
  * #on (#RTE3)
    * with event specified
      * [calls the block every time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L132)
      * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L139)
    * with no event specified
      * [calls the block every time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L149)
      * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L156)
  * #once (#RTE4)
    * with event specified
      * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L182)
      * [does not remove other blocks after it is called](./spec/unit/modules/event_emitter_spec.rb#L189)
      * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L197)
    * with no event specified
      * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L207)
      * [does not remove other blocks after it is called](./spec/unit/modules/event_emitter_spec.rb#L214)
      * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L222)
  * #unsafe_once
    * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L233)
    * [does not catch exceptions in provided blocks](./spec/unit/modules/event_emitter_spec.rb#L240)
  * #off
    * with event specified in on handler
      * with event names as arguments
        * [deletes matching callbacks when a block is provided](./spec/unit/modules/event_emitter_spec.rb#L259)
        * [deletes all matching callbacks when a block is not provided](./spec/unit/modules/event_emitter_spec.rb#L264)
        * [continues if the block does not exist](./spec/unit/modules/event_emitter_spec.rb#L269)
      * without any event names
        * [deletes all matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L276)
        * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L281)
    * when on callback is configured for all events
      * with event names as arguments
        * [does not remove the all events callback when a block is provided](./spec/unit/modules/event_emitter_spec.rb#L298)
        * [does not remove the all events callback when a block is not provided](./spec/unit/modules/event_emitter_spec.rb#L303)
        * [does not remove the all events callback when the block does not match](./spec/unit/modules/event_emitter_spec.rb#L308)
      * without any event names
        * [deletes all matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L315)
        * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L320)
    * with unsafe_on subscribers
      * [does not deregister them](./spec/unit/modules/event_emitter_spec.rb#L336)
    * with unsafe_once subscribers
      * [does not deregister them](./spec/unit/modules/event_emitter_spec.rb#L351)
  * #unsafe_off
    * with unsafe_on subscribers
      * [deregisters them](./spec/unit/modules/event_emitter_spec.rb#L370)
    * with unsafe_once subscribers
      * [deregister them](./spec/unit/modules/event_emitter_spec.rb#L385)
    * with on subscribers
      * [does not deregister them](./spec/unit/modules/event_emitter_spec.rb#L400)
    * with once subscribers
      * [does not deregister them](./spec/unit/modules/event_emitter_spec.rb#L415)

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
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L82)
    * as SHIFT_JIS string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L90)
    * as ASCII_8BIT string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L98)
    * as Integer
      * [raises an argument error](./spec/unit/realtime/channel_spec.rb#L106)
    * as Nil
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L114)
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/channel_spec.rb#L121)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/channel_spec.rb#L127)
  * subscriptions
    * #subscribe
      * [without a block raises an invalid ArgumentError](./spec/unit/realtime/channel_spec.rb#L169)
      * [with no event name specified subscribes the provided block to all events](./spec/unit/realtime/channel_spec.rb#L173)
      * [with a single event name subscribes that block to matching events](./spec/unit/realtime/channel_spec.rb#L179)
      * [with a multiple event name arguments subscribes that block to all of those event names](./spec/unit/realtime/channel_spec.rb#L186)
      * [with a multiple duplicate event name arguments subscribes that block to all of those unique event names once](./spec/unit/realtime/channel_spec.rb#L198)
    * #unsubscribe
      * [with no event name specified unsubscribes that block from all events](./spec/unit/realtime/channel_spec.rb#L215)
      * [with a single event name argument unsubscribes the provided block with the matching event name](./spec/unit/realtime/channel_spec.rb#L221)
      * [with multiple event name arguments unsubscribes each of those matching event names with the provided block](./spec/unit/realtime/channel_spec.rb#L227)
      * [with a non-matching event name argument has no effect](./spec/unit/realtime/channel_spec.rb#L233)
      * [with no block argument unsubscribes all blocks for the event name argument](./spec/unit/realtime/channel_spec.rb#L239)

### Ably::Realtime::Channels
_(see [spec/unit/realtime/channels_spec.rb](./spec/unit/realtime/channels_spec.rb))_
  * creating channels
    * [[] creates a channel](./spec/unit/realtime/channels_spec.rb#L81)
    * #get
      * when channel doesn't exist
        * hash
          * [is expected to be a kind of Hash](./spec/unit/realtime/channels_spec.rb#L28)
          * [creates a channel (RTS3a)](./spec/unit/realtime/channels_spec.rb#L20)
        * ChannelOptions object
          * [is expected to be a kind of Ably::Models::ChannelOptions](./spec/unit/realtime/channels_spec.rb#L35)
          * [creates a channel (RTS3a)](./spec/unit/realtime/channels_spec.rb#L20)
      * when an existing channel exists
        * [will update the options on the channel if provided (RSN3c)](./spec/unit/realtime/channels_spec.rb#L64)
        * [will leave the options intact on the channel if not provided](./spec/unit/realtime/channels_spec.rb#L72)
        * hash
          * [is expected to be a kind of Hash](./spec/unit/realtime/channels_spec.rb#L52)
          * [will reuse a channel object if it exists (RTS3a)](./spec/unit/realtime/channels_spec.rb#L43)
        * ChannelOptions object
          * [is expected to be a kind of Ably::Models::ChannelOptions](./spec/unit/realtime/channels_spec.rb#L59)
          * [will reuse a channel object if it exists (RTS3a)](./spec/unit/realtime/channels_spec.rb#L43)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/realtime/channels_spec.rb#L88)
    * [calls the block if channel is missing](./spec/unit/realtime/channels_spec.rb#L93)
  * destroying channels
    * [#release detaches and then releases the channel resources](./spec/unit/realtime/channels_spec.rb#L101)
  * is Enumerable
    * [allows enumeration](./spec/unit/realtime/channels_spec.rb#L118)
    * [provides #length](./spec/unit/realtime/channels_spec.rb#L134)
    * #each
      * [returns an enumerator](./spec/unit/realtime/channels_spec.rb#L123)
      * [yields each channel](./spec/unit/realtime/channels_spec.rb#L127)

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
    * with valid arguments
      * key only
        * [connects to the Ably service](./spec/shared/client_initializer_behaviour.rb#L79)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L83)
      * with a string key instead of options hash
        * [sets the key](./spec/shared/client_initializer_behaviour.rb#L103)
        * [sets the key_name](./spec/shared/client_initializer_behaviour.rb#L107)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L111)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L115)
      * with a string token key instead of options hash
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L127)
      * with token
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L135)
      * with token_details
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L143)
      * with token_params
        * [configures default_token_params](./spec/shared/client_initializer_behaviour.rb#L151)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L162)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L169)
        * with rest_host option
          * PENDING: *[uses an alternate endpoint for REST clients](./spec/shared/client_initializer_behaviour.rb#L177)*
        * with realtime_host option
          * [uses an alternate endpoint for Realtime clients](./spec/shared/client_initializer_behaviour.rb#L186)
        * with port option and non-TLS connections
          * [uses the custom port for non-TLS requests](./spec/shared/client_initializer_behaviour.rb#L195)
        * with tls_port option and a TLS connection
          * [uses the custom port for TLS requests](./spec/shared/client_initializer_behaviour.rb#L203)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L226)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L217)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L221)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L237)
          * [specifies Logger::WARN log level](./spec/shared/client_initializer_behaviour.rb#L241)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L249)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L259)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L263)
      * environment
        * when set without custom fallback hosts configured
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L275)
          * [uses the default fallback hosts (#TBC, see https://github.com/ably/wiki/issues/361)](./spec/shared/client_initializer_behaviour.rb#L279)
        * when set with custom fallback hosts configured
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L289)
          * [uses the custom provided fallback hosts (#RSC15a)](./spec/shared/client_initializer_behaviour.rb#L293)
        * when set with fallback_hosts_use_default
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L304)
          * [uses the production default fallback hosts (#RTN17b)](./spec/shared/client_initializer_behaviour.rb#L308)
      * rest_host
        * when set without custom fallback hosts configured
          * [sets the custom_host attribute](./spec/shared/client_initializer_behaviour.rb#L319)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L323)
        * when set with environment and without custom fallback hosts configured
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L333)
          * [sets the custom_host attribute](./spec/shared/client_initializer_behaviour.rb#L337)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L341)
        * when set with custom fallback hosts configured
          * [sets the custom_host attribute](./spec/shared/client_initializer_behaviour.rb#L351)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L355)
      * realtime_host
        * when set without custom fallback hosts configured
          * [sets the realtime_host option](./spec/shared/client_initializer_behaviour.rb#L368)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L372)
      * custom port
        * when set without custom fallback hosts configured
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L383)
      * custom TLS port
        * when set without custom fallback hosts configured
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L394)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L408)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L413)
  * delegation to the REST Client
    * [passes on the options to the initializer](./spec/unit/realtime/client_spec.rb#L15)
    * for attribute
      * [#environment](./spec/unit/realtime/client_spec.rb#L23)
      * [#use_tls?](./spec/unit/realtime/client_spec.rb#L23)
      * [#log_level](./spec/unit/realtime/client_spec.rb#L23)
      * [#custom_host](./spec/unit/realtime/client_spec.rb#L23)
  * when :transport_params option is passed
    * [converts options to strings](./spec/unit/realtime/client_spec.rb#L39)
  * push
    * [#device is not supported and raises an exception](./spec/unit/realtime/client_spec.rb#L47)
    * [#push returns a Push object](./spec/unit/realtime/client_spec.rb#L51)

### Ably::Realtime::Connection
_(see [spec/unit/realtime/connection_spec.rb](./spec/unit/realtime/connection_spec.rb))_
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/connection_spec.rb#L21)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/connection_spec.rb#L27)

### Ably::Realtime::Presence
_(see [spec/unit/realtime/presence_spec.rb](./spec/unit/realtime/presence_spec.rb))_
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/presence_spec.rb#L13)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/presence_spec.rb#L19)
  * subscriptions
    * #subscribe
      * [without a block raises an invalid ArgumentError](./spec/unit/realtime/presence_spec.rb#L63)
      * [with no action specified subscribes the provided block to all action](./spec/unit/realtime/presence_spec.rb#L67)
      * [with a single action argument subscribes that block to matching actions](./spec/unit/realtime/presence_spec.rb#L73)
      * [with a multiple action arguments subscribes that block to all of those actions](./spec/unit/realtime/presence_spec.rb#L80)
      * [with a multiple duplicate action arguments subscribes that block to all of those unique actions once](./spec/unit/realtime/presence_spec.rb#L92)
    * #unsubscribe
      * [with no action specified unsubscribes that block from all events](./spec/unit/realtime/presence_spec.rb#L107)
      * [with a single action argument unsubscribes the provided block with the matching action](./spec/unit/realtime/presence_spec.rb#L113)
      * [with multiple action arguments unsubscribes each of those matching actions with the provided block](./spec/unit/realtime/presence_spec.rb#L119)
      * [with a non-matching action argument has no effect](./spec/unit/realtime/presence_spec.rb#L125)
      * [with no block argument unsubscribes all blocks for the action argument](./spec/unit/realtime/presence_spec.rb#L131)

### Ably::Realtime::Channel::PushChannel
_(see [spec/unit/realtime/push_channel_spec.rb](./spec/unit/realtime/push_channel_spec.rb))_
  * [is constructed with a channel](./spec/unit/realtime/push_channel_spec.rb#L10)
  * [raises an exception if constructed with an invalid type](./spec/unit/realtime/push_channel_spec.rb#L14)
  * [exposes the channel as attribute #channel](./spec/unit/realtime/push_channel_spec.rb#L18)
  * [is available in the #push attribute of the channel](./spec/unit/realtime/push_channel_spec.rb#L22)
  * methods not implemented as push notifications
    * [#subscribe_device raises an unsupported exception](./spec/unit/realtime/push_channel_spec.rb#L31)
    * [#subscribe_client_id raises an unsupported exception](./spec/unit/realtime/push_channel_spec.rb#L31)
    * [#unsubscribe_device raises an unsupported exception](./spec/unit/realtime/push_channel_spec.rb#L31)
    * [#unsubscribe_client_id raises an unsupported exception](./spec/unit/realtime/push_channel_spec.rb#L31)
    * [#get_subscriptions raises an unsupported exception](./spec/unit/realtime/push_channel_spec.rb#L31)

### Ably::Realtime
_(see [spec/unit/realtime/realtime_spec.rb](./spec/unit/realtime/realtime_spec.rb))_
  * [constructor returns an Ably::Realtime::Client](./spec/unit/realtime/realtime_spec.rb#L6)

### Ably::Realtime::RecoveryKeyContext
_(see [spec/unit/realtime/recovery_key_context_spec.rb](./spec/unit/realtime/recovery_key_context_spec.rb))_
  * connection recovery key
    * [should encode recovery key - RTN16i, RTN16f, RTN16j](./spec/unit/realtime/recovery_key_context_spec.rb#L8)
    * [should decode recovery key - RTN16i, RTN16f, RTN16j](./spec/unit/realtime/recovery_key_context_spec.rb#L21)
    * [should return nil for invalid recovery key - RTN16i, RTN16f, RTN16j](./spec/unit/realtime/recovery_key_context_spec.rb#L29)

### Ably::Models::ProtocolMessage
_(see [spec/unit/realtime/safe_deferrable_spec.rb](./spec/unit/realtime/safe_deferrable_spec.rb))_
  * behaves like a safe Deferrable
    * #errback
      * [adds a callback that is called when #fail is called](./spec/shared/safe_deferrable_behaviour.rb#L15)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L22)
    * #fail
      * [calls the callbacks defined with #errback, but not the ones added for success #callback](./spec/shared/safe_deferrable_behaviour.rb#L34)
    * #callback
      * [adds a callback that is called when #succed is called](./spec/shared/safe_deferrable_behaviour.rb#L46)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L53)
    * #succeed
      * [calls the callbacks defined with #callback, but not the ones added for #errback](./spec/shared/safe_deferrable_behaviour.rb#L65)

### Ably::Models::Message
_(see [spec/unit/realtime/safe_deferrable_spec.rb](./spec/unit/realtime/safe_deferrable_spec.rb))_
  * behaves like a safe Deferrable
    * #errback
      * [adds a callback that is called when #fail is called](./spec/shared/safe_deferrable_behaviour.rb#L15)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L22)
    * #fail
      * [calls the callbacks defined with #errback, but not the ones added for success #callback](./spec/shared/safe_deferrable_behaviour.rb#L34)
    * #callback
      * [adds a callback that is called when #succed is called](./spec/shared/safe_deferrable_behaviour.rb#L46)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L53)
    * #succeed
      * [calls the callbacks defined with #callback, but not the ones added for #errback](./spec/shared/safe_deferrable_behaviour.rb#L65)

### Ably::Models::PresenceMessage
_(see [spec/unit/realtime/safe_deferrable_spec.rb](./spec/unit/realtime/safe_deferrable_spec.rb))_
  * behaves like a safe Deferrable
    * #errback
      * [adds a callback that is called when #fail is called](./spec/shared/safe_deferrable_behaviour.rb#L15)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L22)
    * #fail
      * [calls the callbacks defined with #errback, but not the ones added for success #callback](./spec/shared/safe_deferrable_behaviour.rb#L34)
    * #callback
      * [adds a callback that is called when #succed is called](./spec/shared/safe_deferrable_behaviour.rb#L46)
      * [catches exceptions in the callback and logs the error to the logger](./spec/shared/safe_deferrable_behaviour.rb#L53)
    * #succeed
      * [calls the callbacks defined with #callback, but not the ones added for #errback](./spec/shared/safe_deferrable_behaviour.rb#L65)

### Ably::Rest::Channel
_(see [spec/unit/rest/channel_spec.rb](./spec/unit/rest/channel_spec.rb))_
  * #initializer
    * as UTF_8 string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L24)
      * [remains as UTF-8](./spec/unit/rest/channel_spec.rb#L28)
    * as frozen UTF_8 string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L37)
      * [remains as UTF-8](./spec/unit/rest/channel_spec.rb#L41)
    * as SHIFT_JIS string
      * [gets converted to UTF-8](./spec/unit/rest/channel_spec.rb#L49)
      * [is compatible with original encoding](./spec/unit/rest/channel_spec.rb#L53)
    * as ASCII_8BIT string
      * [gets converted to UTF-8](./spec/unit/rest/channel_spec.rb#L61)
      * [is compatible with original encoding](./spec/unit/rest/channel_spec.rb#L65)
    * as Integer
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L73)
    * as Nil
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L81)
  * #publish name argument
    * as UTF_8 string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L93)
    * as frozen UTF_8 string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L102)
    * as SHIFT_JIS string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L110)
    * as ASCII_8BIT string
      * [is permitted](./spec/unit/rest/channel_spec.rb#L118)
    * as Integer
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L126)
    * max message size exceeded
      * when max_message_size is nil
        * and a message size is 65537 bytes
          * [should raise Ably::Exceptions::MaxMessageSizeExceeded](./spec/unit/rest/channel_spec.rb#L134)
      * when max_message_size is 65536 bytes
        * and a message size is 65537 bytes
          * [should raise Ably::Exceptions::MaxMessageSizeExceeded](./spec/unit/rest/channel_spec.rb#L144)
        * and a message size is 10 bytes
          * [should send a message](./spec/unit/rest/channel_spec.rb#L150)
      * when max_message_size is 10 bytes
        * and a message size is 11 bytes
          * [should raise Ably::Exceptions::MaxMessageSizeExceeded](./spec/unit/rest/channel_spec.rb#L160)
        * and a message size is 2 bytes
          * [should send a message](./spec/unit/rest/channel_spec.rb#L166)

### Ably::Rest::Channels
_(see [spec/unit/rest/channels_spec.rb](./spec/unit/rest/channels_spec.rb))_
  * [[] creates a channel](./spec/unit/rest/channels_spec.rb#L91)
  * #get
    * when channel doesn't exist
      * hash
        * [is expected to be a kind of Hash](./spec/unit/rest/channels_spec.rb#L24)
        * [creates a channel (RSN3a)](./spec/unit/rest/channels_spec.rb#L16)
      * ChannelOptions object
        * [is expected to be a kind of Ably::Models::ChannelOptions](./spec/unit/rest/channels_spec.rb#L31)
        * [creates a channel (RSN3a)](./spec/unit/rest/channels_spec.rb#L16)
    * when an existing channel exists
      * hash
        * [is expected to be a kind of Hash](./spec/unit/rest/channels_spec.rb#L48)
        * [will reuse a channel object if it exists (RSN3a)](./spec/unit/rest/channels_spec.rb#L39)
      * ChannelOptions object
        * [is expected to be a kind of Ably::Models::ChannelOptions](./spec/unit/rest/channels_spec.rb#L55)
        * [will reuse a channel object if it exists (RSN3a)](./spec/unit/rest/channels_spec.rb#L39)
      * with new channel_options modes
        * hash
          * [is expected to be a kind of Hash](./spec/unit/rest/channels_spec.rb#L76)
          * [will update channel with provided options modes (RSN3c)](./spec/unit/rest/channels_spec.rb#L62)
        * ChannelOptions object
          * [is expected to be a kind of Ably::Models::ChannelOptions](./spec/unit/rest/channels_spec.rb#L83)
          * [will update channel with provided options modes (RSN3c)](./spec/unit/rest/channels_spec.rb#L62)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/rest/channels_spec.rb#L97)
    * [calls the block if channel is missing](./spec/unit/rest/channels_spec.rb#L102)
  * destroying channels
    * [#release releases the channel resoures](./spec/unit/rest/channels_spec.rb#L110)
  * is Enumerable
    * [allows enumeration](./spec/unit/rest/channels_spec.rb#L126)
    * [provides #length](./spec/unit/rest/channels_spec.rb#L142)
    * #each
      * [returns an enumerator](./spec/unit/rest/channels_spec.rb#L131)
      * [yields each channel](./spec/unit/rest/channels_spec.rb#L135)

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
    * with valid arguments
      * key only
        * [connects to the Ably service](./spec/shared/client_initializer_behaviour.rb#L79)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L83)
      * with a string key instead of options hash
        * [sets the key](./spec/shared/client_initializer_behaviour.rb#L103)
        * [sets the key_name](./spec/shared/client_initializer_behaviour.rb#L107)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L111)
        * [uses basic auth](./spec/shared/client_initializer_behaviour.rb#L115)
      * with a string token key instead of options hash
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L127)
      * with token
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L135)
      * with token_details
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L143)
      * with token_params
        * [configures default_token_params](./spec/shared/client_initializer_behaviour.rb#L151)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L162)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L169)
        * with rest_host option
          * [uses an alternate endpoint for REST clients](./spec/shared/client_initializer_behaviour.rb#L177)
        * with realtime_host option
          * PENDING: *[uses an alternate endpoint for Realtime clients](./spec/shared/client_initializer_behaviour.rb#L186)*
        * with port option and non-TLS connections
          * [uses the custom port for non-TLS requests](./spec/shared/client_initializer_behaviour.rb#L195)
        * with tls_port option and a TLS connection
          * [uses the custom port for TLS requests](./spec/shared/client_initializer_behaviour.rb#L203)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L226)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L217)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L221)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L237)
          * [specifies Logger::WARN log level](./spec/shared/client_initializer_behaviour.rb#L241)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L249)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L259)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L263)
      * environment
        * when set without custom fallback hosts configured
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L275)
          * [uses the default fallback hosts (#TBC, see https://github.com/ably/wiki/issues/361)](./spec/shared/client_initializer_behaviour.rb#L279)
        * when set with custom fallback hosts configured
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L289)
          * [uses the custom provided fallback hosts (#RSC15a)](./spec/shared/client_initializer_behaviour.rb#L293)
        * when set with fallback_hosts_use_default
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L304)
          * [uses the production default fallback hosts (#RTN17b)](./spec/shared/client_initializer_behaviour.rb#L308)
      * rest_host
        * when set without custom fallback hosts configured
          * [sets the custom_host attribute](./spec/shared/client_initializer_behaviour.rb#L319)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L323)
        * when set with environment and without custom fallback hosts configured
          * [sets the environment attribute](./spec/shared/client_initializer_behaviour.rb#L333)
          * [sets the custom_host attribute](./spec/shared/client_initializer_behaviour.rb#L337)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L341)
        * when set with custom fallback hosts configured
          * [sets the custom_host attribute](./spec/shared/client_initializer_behaviour.rb#L351)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L355)
      * realtime_host
        * when set without custom fallback hosts configured
          * [sets the realtime_host option](./spec/shared/client_initializer_behaviour.rb#L368)
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L372)
      * custom port
        * when set without custom fallback hosts configured
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L383)
      * custom TLS port
        * when set without custom fallback hosts configured
          * [has no default fallback hosts](./spec/shared/client_initializer_behaviour.rb#L394)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L408)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L413)
  * initializer options
    * TLS
      * disabled
        * [fails for any operation with basic auth and attempting to send an API key over a non-secure connection (#RSA1)](./spec/unit/rest/client_spec.rb#L17)
    * fallback_retry_timeout (#RSC15f)
      * default
        * [is set to 10 minutes](./spec/unit/rest/client_spec.rb#L27)
      * when provided
        * [configures a new timeout](./spec/unit/rest/client_spec.rb#L35)
    * use agent
      * set agent to non-default value
        * default agent
          * [should return default ably agent](./spec/unit/rest/client_spec.rb#L46)
        * custom agent
          * [should overwrite client.agent](./spec/unit/rest/client_spec.rb#L54)
    * :use_token_auth
      * set to false
        * with a key and :tls => false
          * [fails for any operation with basic auth and attempting to send an API key over a non-secure connection](./spec/unit/rest/client_spec.rb#L66)
        * without a key
          * [fails as a key is required if not using token auth](./spec/unit/rest/client_spec.rb#L74)
      * set to true
        * without a key or token
          * [fails as a key is required to issue tokens](./spec/unit/rest/client_spec.rb#L84)
    * max_message_size
      * is not present
        * [should return default 65536 (#TO3l8)](./spec/unit/rest/client_spec.rb#L95)
      * is nil
        * [should return default 65536 (#TO3l8)](./spec/unit/rest/client_spec.rb#L103)
      * is customized 131072 bytes
        * [should return 131072](./spec/unit/rest/client_spec.rb#L112)
  * request_id generation
    * [includes request_id in URL](./spec/unit/rest/client_spec.rb#L121)
  * push
    * [#device is not supported and raises an exception](./spec/unit/rest/client_spec.rb#L129)
    * [#push returns a Push object](./spec/unit/rest/client_spec.rb#L133)

### Ably::Rest::Channel::PushChannel
_(see [spec/unit/rest/push_channel_spec.rb](./spec/unit/rest/push_channel_spec.rb))_
  * [is constructed with a channel](./spec/unit/rest/push_channel_spec.rb#L10)
  * [raises an exception if constructed with an invalid type](./spec/unit/rest/push_channel_spec.rb#L14)
  * [exposes the channel as attribute #channel](./spec/unit/rest/push_channel_spec.rb#L18)
  * [is available in the #push attribute of the channel](./spec/unit/rest/push_channel_spec.rb#L22)
  * methods not implemented as push notifications
    * [#subscribe_device raises an unsupported exception](./spec/unit/rest/push_channel_spec.rb#L31)
    * [#subscribe_client_id raises an unsupported exception](./spec/unit/rest/push_channel_spec.rb#L31)
    * [#unsubscribe_device raises an unsupported exception](./spec/unit/rest/push_channel_spec.rb#L31)
    * [#unsubscribe_client_id raises an unsupported exception](./spec/unit/rest/push_channel_spec.rb#L31)
    * [#get_subscriptions raises an unsupported exception](./spec/unit/rest/push_channel_spec.rb#L31)

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
  * #encrypt & #decrypt
    * [encrypts and decrypts a non-empty string](./spec/unit/util/crypto_spec.rb#L79)
    * [encrypts and decrypts an empty string](./spec/unit/util/crypto_spec.rb#L88)
  * using shared client lib fixture data
    * with AES-128-CBC
      * behaves like an Ably encrypter and decrypter (#RTL7d)
        * text payload
          * [encrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L116)
          * [decrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L120)
    * with AES-256-CBC
      * behaves like an Ably encrypter and decrypter (#RTL7d)
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

  * Passing tests: 2491
  * Pending tests: 7
  * Failing tests: 2
