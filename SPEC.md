# Ably Client Library Specification

### Ably::Realtime::Channel
  * over json
    * [returns a Deferrable](./spec/acceptance/realtime/channel_history_spec.rb#L27)
    * [retrieves real-time history](./spec/acceptance/realtime/channel_history_spec.rb#L36)
    * [retrieves real-time history across two channels](./spec/acceptance/realtime/channel_history_spec.rb#L48)
    * with multiple messages
      * as one ProtocolMessage
        * [retrieves limited history forwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L86)
        * [retrieves limited history backwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L96)
      * in multiple ProtocolMessages
        * [retrieves limited history forwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L108)
        * [retrieves limited history backwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L120)
      * message IDs for messages with identical event name & data
        * [are unqiue and match between Rest & Real-time](./spec/acceptance/realtime/channel_history_spec.rb#L137)
  * over msgpack
    * [returns a Deferrable](./spec/acceptance/realtime/channel_history_spec.rb#L27)
    * [retrieves real-time history](./spec/acceptance/realtime/channel_history_spec.rb#L36)
    * [retrieves real-time history across two channels](./spec/acceptance/realtime/channel_history_spec.rb#L48)
    * with multiple messages
      * as one ProtocolMessage
        * [retrieves limited history forwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L86)
        * [retrieves limited history backwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L96)
      * in multiple ProtocolMessages
        * [retrieves limited history forwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L108)
        * [retrieves limited history backwards with pagination](./spec/acceptance/realtime/channel_history_spec.rb#L120)
      * message IDs for messages with identical event name & data
        * [are unqiue and match between Rest & Real-time](./spec/acceptance/realtime/channel_history_spec.rb#L137)

### Ably::Realtime::Channel
  * over json
    * [attaches to a channel](./spec/acceptance/realtime/channel_spec.rb#L184)
    * [attaches to a channel with a block](./spec/acceptance/realtime/channel_spec.rb#L194)
    * [detaches from a channel with a block](./spec/acceptance/realtime/channel_spec.rb#L203)
    * [publishes 3 messages once attached](./spec/acceptance/realtime/channel_spec.rb#L214)
    * [publishes 3 messages from queue before attached](./spec/acceptance/realtime/channel_spec.rb#L228)
    * [publishes 3 messages from queue before attached in a single protocol message](./spec/acceptance/realtime/channel_spec.rb#L240)
    * [subscribes and unsubscribes](./spec/acceptance/realtime/channel_spec.rb#L261)
    * [subscribes and unsubscribes from multiple channels](./spec/acceptance/realtime/channel_spec.rb#L277)
    * [opens many connections and then many channels simultaneously](./spec/acceptance/realtime/channel_spec.rb#L303)
    * [opens many connections and attaches to channels before connected](./spec/acceptance/realtime/channel_spec.rb#L339)
    * connection with connect_automatically option set to false
      * [remains initialized when accessing a channel](./spec/acceptance/realtime/channel_spec.rb#L23)
      * [opens implicitly if attaching to a channel](./spec/acceptance/realtime/channel_spec.rb#L33)
      * [opens implicitly if accessing the presence object](./spec/acceptance/realtime/channel_spec.rb#L42)
    * when :failed
      * [#attach reattaches](./spec/acceptance/realtime/channel_spec.rb#L58)
      * [#detach raises an exception](./spec/acceptance/realtime/channel_spec.rb#L71)
    * when :attaching
      * [emits attaching then attached events](./spec/acceptance/realtime/channel_spec.rb#L84)
      * [#detach moves straight to detaching and skips attached](./spec/acceptance/realtime/channel_spec.rb#L96)
      * [ignores subsequent #attach calls but calls the callback if provided](./spec/acceptance/realtime/channel_spec.rb#L114)
    * when :detaching
      * [emits detaching then detached events](./spec/acceptance/realtime/channel_spec.rb#L131)
      * [#attach moves straight to attaching and skips detached](./spec/acceptance/realtime/channel_spec.rb#L145)
      * [ignores subsequent #detach calls but calls the callback if provided](./spec/acceptance/realtime/channel_spec.rb#L166)
    * attach failure
      * [triggers failed event](./spec/acceptance/realtime/channel_spec.rb#L369)
      * [triggers an error event](./spec/acceptance/realtime/channel_spec.rb#L380)
      * [updates the error_reason](./spec/acceptance/realtime/channel_spec.rb#L391)
    * when connection
      * fails
        * a attached channel
          * [transitions state to :failed](./spec/acceptance/realtime/channel_spec.rb#L408)
          * [triggers an error event for the channel](./spec/acceptance/realtime/channel_spec.rb#L421)
          * [updates the error_reason](./spec/acceptance/realtime/channel_spec.rb#L434)
        * a detached channel
          * [remains in the same state](./spec/acceptance/realtime/channel_spec.rb#L449)
        * a failed channel
          * [remains in the same state](./spec/acceptance/realtime/channel_spec.rb#L471)
      * closes
        * a attached channel
          * [transitions state to :detached](./spec/acceptance/realtime/channel_spec.rb#L496)
        * a detached channel
          * [remains in the same state](./spec/acceptance/realtime/channel_spec.rb#L510)
        * failed channel
          * [remains in the same state](./spec/acceptance/realtime/channel_spec.rb#L533)

### Ably::Realtime::Client
  * over msgpack
    * with API key
      * [connects using basic auth by default](./spec/acceptance/realtime/client_spec.rb#L20)
      * with TLS disabled
        * [fails to connect because the key cannot be sent over a non-secure connection](./spec/acceptance/realtime/client_spec.rb#L34)
    * with TLS enabled
      * with token provided
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L54)
      * with API key and token auth set to true
        * PENDING: *[automatically generates a token and connects using token auth](./spec/acceptance/realtime/client_spec.rb#L67)*
      * with client_id
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L74)
    * with TLS disabled
      * with token provided
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L54)
      * with API key and token auth set to true
        * PENDING: *[automatically generates a token and connects using token auth](./spec/acceptance/realtime/client_spec.rb#L67)*
      * with client_id
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L74)
  * over json
    * with API key
      * [connects using basic auth by default](./spec/acceptance/realtime/client_spec.rb#L20)
      * with TLS disabled
        * [fails to connect because the key cannot be sent over a non-secure connection](./spec/acceptance/realtime/client_spec.rb#L34)
    * with TLS enabled
      * with token provided
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L54)
      * with API key and token auth set to true
        * PENDING: *[automatically generates a token and connects using token auth](./spec/acceptance/realtime/client_spec.rb#L67)*
      * with client_id
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L74)
    * with TLS disabled
      * with token provided
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L54)
      * with API key and token auth set to true
        * PENDING: *[automatically generates a token and connects using token auth](./spec/acceptance/realtime/client_spec.rb#L67)*
      * with client_id
        * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L74)

### Ably::Realtime::Connection
  * failures over json
    * authentication failure
      * when API key is invalid
        * [sets the #error_reason to the failed reason](./spec/acceptance/realtime/connection_failures_spec.rb#L27)
    * retrying new connections
      * [#open times out automatically and attempts a reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L241)
      * with invalid app part of the key
        * [enters the failed state and returns a not found error](./spec/acceptance/realtime/connection_failures_spec.rb#L49)
      * with invalid key ID part of the key
        * [enters the failed state and returns an authorization error](./spec/acceptance/realtime/connection_failures_spec.rb#L66)
      * with invalid WebSocket host
        * [enters the disconnected state and then transitions to closed when requested](./spec/acceptance/realtime/connection_failures_spec.rb#L152)
        * [enters the suspended state after multiple attempts to connect](./spec/acceptance/realtime/connection_failures_spec.rb#L170)
        * [enters the suspended state and transitions to closed when requested](./spec/acceptance/realtime/connection_failures_spec.rb#L188)
        * [enters the failed state after multiple attempts when in the suspended state](./spec/acceptance/realtime/connection_failures_spec.rb#L205)
        * #error_reason
          * [contains the error when state is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * [contains the error when state is suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * [contains the error when state is failed](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * [resets the error state when :connected](./spec/acceptance/realtime/connection_failures_spec.rb#L127)
          * [resets the error state when :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L140)
        * when entering the failed state
          * [should disallow a transition to closed when requested](./spec/acceptance/realtime/connection_failures_spec.rb#L227)
    * resuming existing connections
      * [reconnects automatically when disconnected message received from the server](./spec/acceptance/realtime/connection_failures_spec.rb#L273)
      * [reconnects automatically when websocket transport is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L292)
      * resumes connection when disconnected
        * [retains channel subscription state](./spec/acceptance/realtime/connection_failures_spec.rb#L311)
        * [receives server-side messages that were queued whilst disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L332)
    * fallback hosts
      * with custom realtime websocket host
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L389)
      * with non-production environment
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L408)
      * with production environment
        * [uses a fallback host on every subsequent disconnected attempt until suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L433)
        * [uses the primary host when suspended, and a fallback host on every subsequent suspended attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L454)
  * failures over msgpack
    * authentication failure
      * when API key is invalid
        * [sets the #error_reason to the failed reason](./spec/acceptance/realtime/connection_failures_spec.rb#L27)
    * retrying new connections
      * [#open times out automatically and attempts a reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L241)
      * with invalid app part of the key
        * [enters the failed state and returns a not found error](./spec/acceptance/realtime/connection_failures_spec.rb#L49)
      * with invalid key ID part of the key
        * [enters the failed state and returns an authorization error](./spec/acceptance/realtime/connection_failures_spec.rb#L66)
      * with invalid WebSocket host
        * [enters the disconnected state and then transitions to closed when requested](./spec/acceptance/realtime/connection_failures_spec.rb#L152)
        * [enters the suspended state after multiple attempts to connect](./spec/acceptance/realtime/connection_failures_spec.rb#L170)
        * [enters the suspended state and transitions to closed when requested](./spec/acceptance/realtime/connection_failures_spec.rb#L188)
        * [enters the failed state after multiple attempts when in the suspended state](./spec/acceptance/realtime/connection_failures_spec.rb#L205)
        * #error_reason
          * [contains the error when state is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * [contains the error when state is suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * [contains the error when state is failed](./spec/acceptance/realtime/connection_failures_spec.rb#L116)
          * [resets the error state when :connected](./spec/acceptance/realtime/connection_failures_spec.rb#L127)
          * [resets the error state when :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L140)
        * when entering the failed state
          * [should disallow a transition to closed when requested](./spec/acceptance/realtime/connection_failures_spec.rb#L227)
    * resuming existing connections
      * [reconnects automatically when disconnected message received from the server](./spec/acceptance/realtime/connection_failures_spec.rb#L273)
      * [reconnects automatically when websocket transport is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L292)
      * resumes connection when disconnected
        * [retains channel subscription state](./spec/acceptance/realtime/connection_failures_spec.rb#L311)
        * [receives server-side messages that were queued whilst disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L332)
    * fallback hosts
      * with custom realtime websocket host
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L389)
      * with non-production environment
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L408)
      * with production environment
        * [uses a fallback host on every subsequent disconnected attempt until suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L433)
        * [uses the primary host when suspended, and a fallback host on every subsequent suspended attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L454)

### Ably::Realtime::Connection
  * over json
    * [connects, closes the connection, and then reconnects with a new connection ID](./spec/acceptance/realtime/connection_spec.rb#L235)
    * [opens many connections simultaneously](./spec/acceptance/realtime/connection_spec.rb#L541)
    * new connection
      * [connects automatically](./spec/acceptance/realtime/connection_spec.rb#L25)
      * with connect_automatically option set to false
        * [does not connect automatically](./spec/acceptance/realtime/connection_spec.rb#L39)
        * [connects on #connect](./spec/acceptance/realtime/connection_spec.rb#L49)
    * initialization phases
      * with implicit #connect
        * [are triggered in order](./spec/acceptance/realtime/connection_spec.rb#L80)
      * with explicit #connect
        * [are triggered in order](./spec/acceptance/realtime/connection_spec.rb#L88)
    * repeated requests to
      * #connect
        * [are ignored and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L107)
      * #close
        * [are ignored and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L121)
    * #close
      * [before connection is opened closes the connection immediately and changes the connection state to closing & then immediately closed](./spec/acceptance/realtime/connection_spec.rb#L149)
      * [changes state to closing and waits for the server to confirm connection is closed with a ProtocolMessage](./spec/acceptance/realtime/connection_spec.rb#L167)
      * [#close changes state to closing and will force close the connection within TIMEOUTS[:close] if CLOSED is not received](./spec/acceptance/realtime/connection_spec.rb#L187)
    * #ping
      * [echoes a heart beat](./spec/acceptance/realtime/connection_spec.rb#L216)
      * [when not connected, it raises an exception](./spec/acceptance/realtime/connection_spec.rb#L227)
    * connection recovery
      * [ensures connection id and serial is up to date when sending messages](./spec/acceptance/realtime/connection_spec.rb#L258)
      * #recovery_key for use with recover option
        * [is available for connecting, connected, disconnected, suspended, failed states](./spec/acceptance/realtime/connection_spec.rb#L298)
        * [is nil when connection is explicitly CLOSED](./spec/acceptance/realtime/connection_spec.rb#L324)
      * with messages sent whilst disconnected
        * [recovers server-side queued messages](./spec/acceptance/realtime/connection_spec.rb#L337)
      * recover client option
        * syntax invalid
          * [raises an exception](./spec/acceptance/realtime/connection_spec.rb#L362)
        * invalid value
          * PENDING: *[moves to state :failed when recover option is invalid](./spec/acceptance/realtime/connection_spec.rb#L373)*
    * token auth
      * for renewable tokens
        * that are valid for the duration of the test
          * with valid pre authorised token expiring in the future
            * [uses the existing token created by Auth](./spec/acceptance/realtime/connection_spec.rb#L397)
          * with implicit authorisation
            * [uses the token created by the implicit authorisation](./spec/acceptance/realtime/connection_spec.rb#L410)
        * that expire
          * opening a new connection
            * with recently expired token
              * [renews the token on connect](./spec/acceptance/realtime/connection_spec.rb#L432)
            * with immediately expiring token
              * FAILED: ~~[renews the token on connect, and only makes one subequent attempt to obtain a new token](./spec/acceptance/realtime/connection_spec.rb#L448)~~
              * FAILED: ~~[uses the primary host for subsequent connection and auth requests](./spec/acceptance/realtime/connection_spec.rb#L460)~~
          * when connected
            * with a new successful token request
              * PENDING: *[changes state to disconnected, renews the token and then reconnects](./spec/acceptance/realtime/connection_spec.rb#L483)*
              * PENDING: *[retains connection state](./spec/acceptance/realtime/connection_spec.rb#L505)*
              * PENDING: *[changes state to failed if a new token cannot be issued](./spec/acceptance/realtime/connection_spec.rb#L506)*
      * for non-renewable tokens
        * that are expired
          * opening a new connection
            * FAILED: ~~[transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L521)~~
          * when connected
            * PENDING: *[transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L535)*
    * when state transition is unsupported
      * [emits a StateChangeError if a state transition is unsupported](./spec/acceptance/realtime/connection_spec.rb#L565)
  * over msgpack
    * [connects, closes the connection, and then reconnects with a new connection ID](./spec/acceptance/realtime/connection_spec.rb#L235)
    * [opens many connections simultaneously](./spec/acceptance/realtime/connection_spec.rb#L541)
    * new connection
      * [connects automatically](./spec/acceptance/realtime/connection_spec.rb#L25)
      * with connect_automatically option set to false
        * [does not connect automatically](./spec/acceptance/realtime/connection_spec.rb#L39)
        * [connects on #connect](./spec/acceptance/realtime/connection_spec.rb#L49)
    * initialization phases
      * with implicit #connect
        * [are triggered in order](./spec/acceptance/realtime/connection_spec.rb#L80)
      * with explicit #connect
        * [are triggered in order](./spec/acceptance/realtime/connection_spec.rb#L88)
    * repeated requests to
      * #connect
        * [are ignored and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L107)
      * #close
        * [are ignored and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L121)
    * #close
      * [before connection is opened closes the connection immediately and changes the connection state to closing & then immediately closed](./spec/acceptance/realtime/connection_spec.rb#L149)
      * [changes state to closing and waits for the server to confirm connection is closed with a ProtocolMessage](./spec/acceptance/realtime/connection_spec.rb#L167)
      * [#close changes state to closing and will force close the connection within TIMEOUTS[:close] if CLOSED is not received](./spec/acceptance/realtime/connection_spec.rb#L187)
    * #ping
      * [echoes a heart beat](./spec/acceptance/realtime/connection_spec.rb#L216)
      * [when not connected, it raises an exception](./spec/acceptance/realtime/connection_spec.rb#L227)
    * connection recovery
      * [ensures connection id and serial is up to date when sending messages](./spec/acceptance/realtime/connection_spec.rb#L258)
      * #recovery_key for use with recover option
        * [is available for connecting, connected, disconnected, suspended, failed states](./spec/acceptance/realtime/connection_spec.rb#L298)
        * [is nil when connection is explicitly CLOSED](./spec/acceptance/realtime/connection_spec.rb#L324)
      * with messages sent whilst disconnected
        * [recovers server-side queued messages](./spec/acceptance/realtime/connection_spec.rb#L337)
      * recover client option
        * syntax invalid
          * [raises an exception](./spec/acceptance/realtime/connection_spec.rb#L362)
        * invalid value
          * PENDING: *[moves to state :failed when recover option is invalid](./spec/acceptance/realtime/connection_spec.rb#L373)*
    * token auth
      * for renewable tokens
        * that are valid for the duration of the test
          * with valid pre authorised token expiring in the future
            * [uses the existing token created by Auth](./spec/acceptance/realtime/connection_spec.rb#L397)
          * with implicit authorisation
            * [uses the token created by the implicit authorisation](./spec/acceptance/realtime/connection_spec.rb#L410)
        * that expire
          * opening a new connection
            * with recently expired token
              * [renews the token on connect](./spec/acceptance/realtime/connection_spec.rb#L432)
            * with immediately expiring token
              * FAILED: ~~[renews the token on connect, and only makes one subequent attempt to obtain a new token](./spec/acceptance/realtime/connection_spec.rb#L448)~~
              * FAILED: ~~[uses the primary host for subsequent connection and auth requests](./spec/acceptance/realtime/connection_spec.rb#L460)~~
          * when connected
            * with a new successful token request
              * PENDING: *[changes state to disconnected, renews the token and then reconnects](./spec/acceptance/realtime/connection_spec.rb#L483)*
              * PENDING: *[retains connection state](./spec/acceptance/realtime/connection_spec.rb#L505)*
              * PENDING: *[changes state to failed if a new token cannot be issued](./spec/acceptance/realtime/connection_spec.rb#L506)*
      * for non-renewable tokens
        * that are expired
          * opening a new connection
            * FAILED: ~~[transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L521)~~
          * when connected
            * PENDING: *[transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L535)*
    * when state transition is unsupported
      * [emits a StateChangeError if a state transition is unsupported](./spec/acceptance/realtime/connection_spec.rb#L565)

### Ably::Realtime::Channel Messages
  * over msgpack
    * [sends a string message](./spec/acceptance/realtime/message_spec.rb#L28)
    * [sends a single message with an echo on another connection](./spec/acceptance/realtime/message_spec.rb#L56)
    * with ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/realtime/message_spec.rb#L42)
    * with echo_messages => false
      * [sends a single message without a reply yet the messages is echoed on another normal connection](./spec/acceptance/realtime/message_spec.rb#L74)
    * with multiple messages
      * [sends and receives the messages on both opened connections and calls the callbacks (expects twice number of messages due to local echos)](./spec/acceptance/realtime/message_spec.rb#L107)
    * without suitable publishing permissions
      * [calls the error callback](./spec/acceptance/realtime/message_spec.rb#L164)
    * encoding and decoding encrypted messages
      * with AES-128-CBC
        * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 1 with encrypted encoding cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
      * with AES-256-CBC
        * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 1 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
      * multiple sends from one client to another
        * [encrypt and decrypt messages](./spec/acceptance/realtime/message_spec.rb#L281)
      * sending using protocol msgpack and subscribing with a different protocol
        * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L326)
        * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L326)
        * [delivers a Hash payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L326)
      * publishing on an unencrypted channel and subscribing on an encrypted channel with another client
        * [does not attempt to decrypt the message](./spec/acceptance/realtime/message_spec.rb#L347)
      * publishing on an encrypted channel and subscribing on an unencrypted channel with another client
        * [delivers the message but still encrypted](./spec/acceptance/realtime/message_spec.rb#L367)
        * [triggers a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L378)
      * publishing on an encrypted channel and subscribing with a different algorithm on another client
        * [delivers the message but still encrypted](./spec/acceptance/realtime/message_spec.rb#L402)
        * [triggers a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L413)
      * publishing on an encrypted channel and subscribing with a different key on another client
        * [delivers the message but still encrypted](./spec/acceptance/realtime/message_spec.rb#L437)
        * [triggers a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L448)
  * over json
    * [sends a string message](./spec/acceptance/realtime/message_spec.rb#L28)
    * [sends a single message with an echo on another connection](./spec/acceptance/realtime/message_spec.rb#L56)
    * with ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/realtime/message_spec.rb#L42)
    * with echo_messages => false
      * [sends a single message without a reply yet the messages is echoed on another normal connection](./spec/acceptance/realtime/message_spec.rb#L74)
    * with multiple messages
      * [sends and receives the messages on both opened connections and calls the callbacks (expects twice number of messages due to local echos)](./spec/acceptance/realtime/message_spec.rb#L107)
    * without suitable publishing permissions
      * [calls the error callback](./spec/acceptance/realtime/message_spec.rb#L164)
    * encoding and decoding encrypted messages
      * with AES-128-CBC
        * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 1 with encrypted encoding cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
      * with AES-256-CBC
        * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 1 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * publish & subscribe
              * [encrypts message automatically when published](./spec/acceptance/realtime/message_spec.rb#L220)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L240)
      * multiple sends from one client to another
        * [encrypt and decrypt messages](./spec/acceptance/realtime/message_spec.rb#L281)
      * sending using protocol json and subscribing with a different protocol
        * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L326)
        * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L326)
        * [delivers a Hash payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L326)
      * publishing on an unencrypted channel and subscribing on an encrypted channel with another client
        * [does not attempt to decrypt the message](./spec/acceptance/realtime/message_spec.rb#L347)
      * publishing on an encrypted channel and subscribing on an unencrypted channel with another client
        * [delivers the message but still encrypted](./spec/acceptance/realtime/message_spec.rb#L367)
        * [triggers a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L378)
      * publishing on an encrypted channel and subscribing with a different algorithm on another client
        * [delivers the message but still encrypted](./spec/acceptance/realtime/message_spec.rb#L402)
        * [triggers a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L413)
      * publishing on an encrypted channel and subscribing with a different key on another client
        * [delivers the message but still encrypted](./spec/acceptance/realtime/message_spec.rb#L437)
        * [triggers a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L448)

### Ably::Realtime::Presence Messages
  * over msgpack
    * [provides up to the moment presence history](./spec/acceptance/realtime/presence_history_spec.rb#L23)
    * [ensures REST presence history message IDs match ProtocolMessage wrapped message IDs via Realtime](./spec/acceptance/realtime/presence_history_spec.rb#L44)
  * over json
    * [provides up to the moment presence history](./spec/acceptance/realtime/presence_history_spec.rb#L23)
    * [ensures REST presence history message IDs match ProtocolMessage wrapped message IDs via Realtime](./spec/acceptance/realtime/presence_history_spec.rb#L44)

### Ably::Realtime::Presence Messages
  * over msgpack
    * [an attached channel that is not presence maintains presence state](./spec/acceptance/realtime/presence_spec.rb#L28)
    * [#enter allows client_id to be set on enter for anonymous clients](./spec/acceptance/realtime/presence_spec.rb#L81)
    * [enters and then leaves](./spec/acceptance/realtime/presence_spec.rb#L92)
    * [enters the :left state if the channel detaches](./spec/acceptance/realtime/presence_spec.rb#L109)
    * [#get returns the current member on the channel](./spec/acceptance/realtime/presence_spec.rb#L129)
    * [#get returns no members on the channel following an enter and leave](./spec/acceptance/realtime/presence_spec.rb#L145)
    * [verify two clients appear in members from #get](./spec/acceptance/realtime/presence_spec.rb#L156)
    * [#subscribe and #unsubscribe to presence events](./spec/acceptance/realtime/presence_spec.rb#L184)
    * [REST #get returns current members](./spec/acceptance/realtime/presence_spec.rb#L214)
    * [REST #get returns no members once left](./spec/acceptance/realtime/presence_spec.rb#L229)
    * [expect :left event once underlying connection is closed](./spec/acceptance/realtime/presence_spec.rb#L418)
    * [expect :left event with no client data to retain original data in Leave event](./spec/acceptance/realtime/presence_spec.rb#L430)
    * [#update automatically connects](./spec/acceptance/realtime/presence_spec.rb#L443)
    * [#update changes the data](./spec/acceptance/realtime/presence_spec.rb#L452)
    * [raises an exception if client_id is not set](./spec/acceptance/realtime/presence_spec.rb#L464)
    * [#leave raises an exception if not entered](./spec/acceptance/realtime/presence_spec.rb#L471)
    * PENDING: *[ensure member_id is unique an updated on ENTER](./spec/acceptance/realtime/presence_spec.rb#L478)*
    * PENDING: *[stop a call to get when the channel has not been entered](./spec/acceptance/realtime/presence_spec.rb#L479)*
    * PENDING: *[stop a call to get when the channel has been entered but the list is not up to date](./spec/acceptance/realtime/presence_spec.rb#L480)*
    * automatic channel attach on access to presence object
      * [is implicit if presence state is initalized](./spec/acceptance/realtime/presence_spec.rb#L54)
      * [is disabled if presence state is not initalized](./spec/acceptance/realtime/presence_spec.rb#L64)
    * with ASCII_8BIT client_id
      * in connection set up
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L247)
      * in channel options
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L262)
    * encoding and decoding of presence message data
      * [encrypts presence message data](./spec/acceptance/realtime/presence_spec.rb#L288)
      * [#subscribe emits decrypted enter events](./spec/acceptance/realtime/presence_spec.rb#L308)
      * [#subscribe emits decrypted update events](./spec/acceptance/realtime/presence_spec.rb#L322)
      * [#subscribe emits decrypted leave events](./spec/acceptance/realtime/presence_spec.rb#L338)
      * [#get returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L354)
      * [REST #get returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L367)
      * when cipher settings do not match publisher
        * [delivers an unencoded presence message left with encoding value](./spec/acceptance/realtime/presence_spec.rb#L385)
        * [emits an error when cipher does not match and presence data cannot be decoded](./spec/acceptance/realtime/presence_spec.rb#L400)
  * over json
    * [an attached channel that is not presence maintains presence state](./spec/acceptance/realtime/presence_spec.rb#L28)
    * [#enter allows client_id to be set on enter for anonymous clients](./spec/acceptance/realtime/presence_spec.rb#L81)
    * [enters and then leaves](./spec/acceptance/realtime/presence_spec.rb#L92)
    * [enters the :left state if the channel detaches](./spec/acceptance/realtime/presence_spec.rb#L109)
    * [#get returns the current member on the channel](./spec/acceptance/realtime/presence_spec.rb#L129)
    * [#get returns no members on the channel following an enter and leave](./spec/acceptance/realtime/presence_spec.rb#L145)
    * [verify two clients appear in members from #get](./spec/acceptance/realtime/presence_spec.rb#L156)
    * [#subscribe and #unsubscribe to presence events](./spec/acceptance/realtime/presence_spec.rb#L184)
    * [REST #get returns current members](./spec/acceptance/realtime/presence_spec.rb#L214)
    * [REST #get returns no members once left](./spec/acceptance/realtime/presence_spec.rb#L229)
    * [expect :left event once underlying connection is closed](./spec/acceptance/realtime/presence_spec.rb#L418)
    * [expect :left event with no client data to retain original data in Leave event](./spec/acceptance/realtime/presence_spec.rb#L430)
    * [#update automatically connects](./spec/acceptance/realtime/presence_spec.rb#L443)
    * [#update changes the data](./spec/acceptance/realtime/presence_spec.rb#L452)
    * [raises an exception if client_id is not set](./spec/acceptance/realtime/presence_spec.rb#L464)
    * [#leave raises an exception if not entered](./spec/acceptance/realtime/presence_spec.rb#L471)
    * PENDING: *[ensure member_id is unique an updated on ENTER](./spec/acceptance/realtime/presence_spec.rb#L478)*
    * PENDING: *[stop a call to get when the channel has not been entered](./spec/acceptance/realtime/presence_spec.rb#L479)*
    * PENDING: *[stop a call to get when the channel has been entered but the list is not up to date](./spec/acceptance/realtime/presence_spec.rb#L480)*
    * automatic channel attach on access to presence object
      * [is implicit if presence state is initalized](./spec/acceptance/realtime/presence_spec.rb#L54)
      * [is disabled if presence state is not initalized](./spec/acceptance/realtime/presence_spec.rb#L64)
    * with ASCII_8BIT client_id
      * in connection set up
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L247)
      * in channel options
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L262)
    * encoding and decoding of presence message data
      * [encrypts presence message data](./spec/acceptance/realtime/presence_spec.rb#L288)
      * [#subscribe emits decrypted enter events](./spec/acceptance/realtime/presence_spec.rb#L308)
      * [#subscribe emits decrypted update events](./spec/acceptance/realtime/presence_spec.rb#L322)
      * [#subscribe emits decrypted leave events](./spec/acceptance/realtime/presence_spec.rb#L338)
      * [#get returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L354)
      * [REST #get returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L367)
      * when cipher settings do not match publisher
        * [delivers an unencoded presence message left with encoding value](./spec/acceptance/realtime/presence_spec.rb#L385)
        * [emits an error when cipher does not match and presence data cannot be decoded](./spec/acceptance/realtime/presence_spec.rb#L400)

### Ably::Realtime::Client stats
  * over msgpack
    * fetching stats
      * [should return a Hash](./spec/acceptance/realtime/stats_spec.rb#L13)
      * [should return a deferrable object](./spec/acceptance/realtime/stats_spec.rb#L22)
  * over json
    * fetching stats
      * [should return a Hash](./spec/acceptance/realtime/stats_spec.rb#L13)
      * [should return a deferrable object](./spec/acceptance/realtime/stats_spec.rb#L22)

### Ably::Realtime::Client time
  * over msgpack
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/realtime/time_spec.rb#L13)
      * [should return a deferrable object](./spec/acceptance/realtime/time_spec.rb#L22)
  * over json
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/realtime/time_spec.rb#L13)
      * [should return a deferrable object](./spec/acceptance/realtime/time_spec.rb#L22)

### Ably::Auth
  * over msgpack
    * [has immutable options](./spec/acceptance/rest/auth_spec.rb#L38)
    * #request_token
      * [returns the requested token](./spec/acceptance/rest/auth_spec.rb#L46)
      * option :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :capability
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :timestamp
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * with :key_id & :key_secret options
        * [key_id is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L106)
      * with :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L114)
      * without :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L123)
      * with :auth_url option
        * valid
          * and default options
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L171)
          * with params
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L179)
          * with headers
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L187)
          * with POST
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L195)
        * when response is invalid
          * 500
            * [raises ServerError](./spec/acceptance/rest/auth_spec.rb#L208)
          * XML
            * [raises InvalidResponseBody](./spec/acceptance/rest/auth_spec.rb#L219)
      * with auth_block
        * [calls the block](./spec/acceptance/rest/auth_spec.rb#L237)
        * [uses the token request when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L242)
    * #authorise
      * [updates auth options for subsequent authorise requests such as automatic token renewal](./spec/acceptance/rest/auth_spec.rb#L306)
      * with no previous authorisation
        * [has no current_token](./spec/acceptance/rest/auth_spec.rb#L254)
        * [passes all options to request_token](./spec/acceptance/rest/auth_spec.rb#L258)
        * [returns a valid token](./spec/acceptance/rest/auth_spec.rb#L263)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L267)
        * basic/token auth attributes
          * [#using_token_auth? is true](./spec/acceptance/rest/auth_spec.rb#L274)
          * [#using_basic_auth? is false](./spec/acceptance/rest/auth_spec.rb#L278)
      * with previous authorisation
        * [does not request a token if token is not expired](./spec/acceptance/rest/auth_spec.rb#L290)
        * [requests a new token if token is expired](./spec/acceptance/rest/auth_spec.rb#L295)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L301)
    * #create_token_request
      * [uses the key ID from the client](./spec/acceptance/rest/auth_spec.rb#L319)
      * [uses the default TTL](./spec/acceptance/rest/auth_spec.rb#L323)
      * [uses the default capability](./spec/acceptance/rest/auth_spec.rb#L327)
      * [has a unique nonce](./spec/acceptance/rest/auth_spec.rb#L331)
      * [has a nonce of at least 16 characters](./spec/acceptance/rest/auth_spec.rb#L336)
      * with option :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :capability
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :timestamp
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * invalid attributes
        * [are ignored](./spec/acceptance/rest/auth_spec.rb#L354)
      * missing key ID and/or secret
        * [should raise an exception if key secret is missing](./spec/acceptance/rest/auth_spec.rb#L364)
        * [should raise an exception if key id is missing](./spec/acceptance/rest/auth_spec.rb#L368)
      * with :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L377)
      * with :timestamp option
        * [uses the provided timestamp](./spec/acceptance/rest/auth_spec.rb#L387)
      * signing
        * [generates a valid HMAC](./spec/acceptance/rest/auth_spec.rb#L404)
    * client with token authentication
      * with token_id argument
        * [authenticates successfully](./spec/acceptance/rest/auth_spec.rb#L427)
        * [disallows publishing on unspecified capability channels](./spec/acceptance/rest/auth_spec.rb#L431)
        * [fails if timestamp is invalid](./spec/acceptance/rest/auth_spec.rb#L439)
        * [cannot be renewed](./spec/acceptance/rest/auth_spec.rb#L447)
      * implicit through client id
        * stubbed
          * [will create a token request](./spec/acceptance/rest/auth_spec.rb#L477)
        * will create a token
          * [before a request is made](./spec/acceptance/rest/auth_spec.rb#L486)
          * [when a message is published](./spec/acceptance/rest/auth_spec.rb#L490)
          * [with capability and TTL defaults](./spec/acceptance/rest/auth_spec.rb#L494)
    * with API_key and basic auth
      * basic/token auth attributes
        * [#using_token_auth? is false](./spec/acceptance/rest/auth_spec.rb#L510)
        * [#using_basic_auth? is true](./spec/acceptance/rest/auth_spec.rb#L514)
  * over json
    * [has immutable options](./spec/acceptance/rest/auth_spec.rb#L38)
    * #request_token
      * [returns the requested token](./spec/acceptance/rest/auth_spec.rb#L46)
      * option :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :capability
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :timestamp
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * option :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L77)
      * with :key_id & :key_secret options
        * [key_id is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L106)
      * with :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L114)
      * without :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L123)
      * with :auth_url option
        * valid
          * and default options
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L171)
          * with params
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L179)
          * with headers
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L187)
          * with POST
            * [requests a token from :auth_url](./spec/acceptance/rest/auth_spec.rb#L195)
        * when response is invalid
          * 500
            * [raises ServerError](./spec/acceptance/rest/auth_spec.rb#L208)
          * XML
            * [raises InvalidResponseBody](./spec/acceptance/rest/auth_spec.rb#L219)
      * with auth_block
        * [calls the block](./spec/acceptance/rest/auth_spec.rb#L237)
        * [uses the token request when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L242)
    * #authorise
      * [updates auth options for subsequent authorise requests such as automatic token renewal](./spec/acceptance/rest/auth_spec.rb#L306)
      * with no previous authorisation
        * [has no current_token](./spec/acceptance/rest/auth_spec.rb#L254)
        * [passes all options to request_token](./spec/acceptance/rest/auth_spec.rb#L258)
        * [returns a valid token](./spec/acceptance/rest/auth_spec.rb#L263)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L267)
        * basic/token auth attributes
          * [#using_token_auth? is true](./spec/acceptance/rest/auth_spec.rb#L274)
          * [#using_basic_auth? is false](./spec/acceptance/rest/auth_spec.rb#L278)
      * with previous authorisation
        * [does not request a token if token is not expired](./spec/acceptance/rest/auth_spec.rb#L290)
        * [requests a new token if token is expired](./spec/acceptance/rest/auth_spec.rb#L295)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L301)
    * #create_token_request
      * [uses the key ID from the client](./spec/acceptance/rest/auth_spec.rb#L319)
      * [uses the default TTL](./spec/acceptance/rest/auth_spec.rb#L323)
      * [uses the default capability](./spec/acceptance/rest/auth_spec.rb#L327)
      * [has a unique nonce](./spec/acceptance/rest/auth_spec.rb#L331)
      * [has a nonce of at least 16 characters](./spec/acceptance/rest/auth_spec.rb#L336)
      * with option :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :capability
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :timestamp
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * with option :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L346)
      * invalid attributes
        * [are ignored](./spec/acceptance/rest/auth_spec.rb#L354)
      * missing key ID and/or secret
        * [should raise an exception if key secret is missing](./spec/acceptance/rest/auth_spec.rb#L364)
        * [should raise an exception if key id is missing](./spec/acceptance/rest/auth_spec.rb#L368)
      * with :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L377)
      * with :timestamp option
        * [uses the provided timestamp](./spec/acceptance/rest/auth_spec.rb#L387)
      * signing
        * [generates a valid HMAC](./spec/acceptance/rest/auth_spec.rb#L404)
    * client with token authentication
      * with token_id argument
        * [authenticates successfully](./spec/acceptance/rest/auth_spec.rb#L427)
        * [disallows publishing on unspecified capability channels](./spec/acceptance/rest/auth_spec.rb#L431)
        * [fails if timestamp is invalid](./spec/acceptance/rest/auth_spec.rb#L439)
        * [cannot be renewed](./spec/acceptance/rest/auth_spec.rb#L447)
      * implicit through client id
        * stubbed
          * [will create a token request](./spec/acceptance/rest/auth_spec.rb#L477)
        * will create a token
          * [before a request is made](./spec/acceptance/rest/auth_spec.rb#L486)
          * [when a message is published](./spec/acceptance/rest/auth_spec.rb#L490)
          * [with capability and TTL defaults](./spec/acceptance/rest/auth_spec.rb#L494)
    * with API_key and basic auth
      * basic/token auth attributes
        * [#using_token_auth? is false](./spec/acceptance/rest/auth_spec.rb#L510)
        * [#using_basic_auth? is true](./spec/acceptance/rest/auth_spec.rb#L514)

### REST
  * protocol
    * transport
      * when protocol is not defined it defaults to :msgpack
        * [uses MsgPack](./spec/acceptance/rest/base_spec.rb#L28)
      * when option {:protocol=>:json} is used
        * [uses JSON](./spec/acceptance/rest/base_spec.rb#L44)
      * when option {:use_binary_protocol=>false} is used
        * [uses JSON](./spec/acceptance/rest/base_spec.rb#L44)
      * when option {:protocol=>:json} is used
        * [uses MsgPack](./spec/acceptance/rest/base_spec.rb#L61)
      * when option {:use_binary_protocol=>false} is used
        * [uses MsgPack](./spec/acceptance/rest/base_spec.rb#L61)
  * over msgpack
    * invalid requests in middleware
      * [should raise an InvalidRequest exception with a valid message](./spec/acceptance/rest/base_spec.rb#L77)
      * server error with JSON response
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L95)
      * server error
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L106)
    * authentication failure
      * when auth#token_renewable?
        * [should automatically reissue a token](./spec/acceptance/rest/base_spec.rb#L144)
      * when NOT auth#token_renewable?
        * [should raise the exception](./spec/acceptance/rest/base_spec.rb#L156)
  * over json
    * invalid requests in middleware
      * [should raise an InvalidRequest exception with a valid message](./spec/acceptance/rest/base_spec.rb#L77)
      * server error with JSON response
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L95)
      * server error
        * [should raise a ServerError exception](./spec/acceptance/rest/base_spec.rb#L106)
    * authentication failure
      * when auth#token_renewable?
        * [should automatically reissue a token](./spec/acceptance/rest/base_spec.rb#L144)
      * when NOT auth#token_renewable?
        * [should raise the exception](./spec/acceptance/rest/base_spec.rb#L156)

### Ably::Rest::Channel
  * over msgpack
    * publishing messages
      * [should publish the message ok](./spec/acceptance/rest/channel_spec.rb#L18)
    * fetching channel history
      * [should return all the history for the channel](./spec/acceptance/rest/channel_spec.rb#L40)
      * [should return messages with unique IDs](./spec/acceptance/rest/channel_spec.rb#L60)
      * [should return paged history](./spec/acceptance/rest/channel_spec.rb#L66)
      * timestamps
        * [should be greater than the time before the messages were published](./spec/acceptance/rest/channel_spec.rb#L53)
    * history options
      * :start
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L125)
      * :end
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L125)
  * over json
    * publishing messages
      * [should publish the message ok](./spec/acceptance/rest/channel_spec.rb#L18)
    * fetching channel history
      * [should return all the history for the channel](./spec/acceptance/rest/channel_spec.rb#L40)
      * [should return messages with unique IDs](./spec/acceptance/rest/channel_spec.rb#L60)
      * [should return paged history](./spec/acceptance/rest/channel_spec.rb#L66)
      * timestamps
        * [should be greater than the time before the messages were published](./spec/acceptance/rest/channel_spec.rb#L53)
    * history options
      * :start
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L125)
      * :end
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/channel_spec.rb#L125)

### Ably::Rest::Channels
  * over msgpack
    * using shortcut method on client
      * behaves like a channel
        * [should access a channel](./spec/acceptance/rest/channels_spec.rb#L14)
        * [should allow options to be set on a channel](./spec/acceptance/rest/channels_spec.rb#L19)
    * using documented .get method on client.channels
      * behaves like a channel
        * [should access a channel](./spec/acceptance/rest/channels_spec.rb#L14)
        * [should allow options to be set on a channel](./spec/acceptance/rest/channels_spec.rb#L19)
    * using undocumented [] method on client.channels
      * behaves like a channel
        * [should access a channel](./spec/acceptance/rest/channels_spec.rb#L14)
        * [should allow options to be set on a channel](./spec/acceptance/rest/channels_spec.rb#L19)
  * over json
    * using shortcut method on client
      * behaves like a channel
        * [should access a channel](./spec/acceptance/rest/channels_spec.rb#L14)
        * [should allow options to be set on a channel](./spec/acceptance/rest/channels_spec.rb#L19)
    * using documented .get method on client.channels
      * behaves like a channel
        * [should access a channel](./spec/acceptance/rest/channels_spec.rb#L14)
        * [should allow options to be set on a channel](./spec/acceptance/rest/channels_spec.rb#L19)
    * using undocumented [] method on client.channels
      * behaves like a channel
        * [should access a channel](./spec/acceptance/rest/channels_spec.rb#L14)
        * [should allow options to be set on a channel](./spec/acceptance/rest/channels_spec.rb#L19)

### Ably::Rest::Client
  * over msgpack
    * #initialize
      * with an auth block
        * [calls the block to get a new token](./spec/acceptance/rest/client_spec.rb#L18)
      * with an auth URL
        * [sends an HTTP request to get a new token](./spec/acceptance/rest/client_spec.rb#L34)
    * token expiry
      * when expired
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L55)
      * token authentication with long expiry token
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L69)
    * connection
      * primary
        * [open timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L85)
        * [request timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L89)
      * fallback
        * [open timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L95)
        * [request timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L99)
    * fallback hosts
      * environment is not production
        * [does not retry with fallback hosts when there is a connection error](./spec/acceptance/rest/client_spec.rb#L132)
      * environment is production
        * when connection times out
          * [tries fallback hosts for CONNECTION_RETRY[:max_retry_attempts]](./spec/acceptance/rest/client_spec.rb#L158)
          * and all request time exeeds CONNECTION_RETRY[:cumulative_request_open_timeout]
            * [stops further attempts to any fallback hosts](./spec/acceptance/rest/client_spec.rb#L173)
        * when connection fails
          * [tries fallback hosts for CONNECTION_RETRY[:max_retry_attempts]](./spec/acceptance/rest/client_spec.rb#L189)
    * with a custom host
      * that does not exist
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L205)
        * and fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L226)
      * that times out
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L241)
        * and fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L254)
  * over json
    * #initialize
      * with an auth block
        * [calls the block to get a new token](./spec/acceptance/rest/client_spec.rb#L18)
      * with an auth URL
        * [sends an HTTP request to get a new token](./spec/acceptance/rest/client_spec.rb#L34)
    * token expiry
      * when expired
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L55)
      * token authentication with long expiry token
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L69)
    * connection
      * primary
        * [open timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L85)
        * [request timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L89)
      * fallback
        * [open timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L95)
        * [request timeout matches configuration](./spec/acceptance/rest/client_spec.rb#L99)
    * fallback hosts
      * environment is not production
        * [does not retry with fallback hosts when there is a connection error](./spec/acceptance/rest/client_spec.rb#L132)
      * environment is production
        * when connection times out
          * [tries fallback hosts for CONNECTION_RETRY[:max_retry_attempts]](./spec/acceptance/rest/client_spec.rb#L158)
          * and all request time exeeds CONNECTION_RETRY[:cumulative_request_open_timeout]
            * [stops further attempts to any fallback hosts](./spec/acceptance/rest/client_spec.rb#L173)
        * when connection fails
          * [tries fallback hosts for CONNECTION_RETRY[:max_retry_attempts]](./spec/acceptance/rest/client_spec.rb#L189)
    * with a custom host
      * that does not exist
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L205)
        * and fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L226)
      * that times out
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L241)
        * and fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L254)

### Ably::Rest Message Encoder
  * with binary transport protocol
    * without encryption
      * with UTF-8 data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L41)
      * with binary data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L52)
      * with JSON data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L63)
    * with encryption
      * with UTF-8 data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L78)
      * with binary data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L89)
      * with JSON data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L100)
  * with text transport protocol
    * without encryption
      * with UTF-8 data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L117)
      * with binary data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L128)
      * with JSON data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L139)
    * with encryption
      * with UTF-8 data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L154)
      * with binary data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L165)
      * with JSON data
        * [does not require an encoding](./spec/acceptance/rest/encoders_spec.rb#L176)

### Ably::Rest Message
  * over msgpack
    * with ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/rest/message_spec.rb#L18)
    * encryption and encoding
      * encoding and decoding encrypted messages
        * with AES-128-CBC
          * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 1 with encrypted encoding cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
        * with AES-256-CBC
          * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 1 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
        * multiple messages
          * [encrypt and decrypt messages](./spec/acceptance/rest/message_spec.rb#L115)
        * sending using protocol msgpack and retrieving with a different protocol
          * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/rest/message_spec.rb#L142)
          * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/rest/message_spec.rb#L142)
          * [delivers a Hash payload to the receiver](./spec/acceptance/rest/message_spec.rb#L142)
        * publishing on an unencrypted channel and retrieving on an encrypted channel
          * [does not attempt to decrypt the message](./spec/acceptance/rest/message_spec.rb#L158)
        * publishing on an encrypted channel and retrieving on an unencrypted channel
          * [delivers the message with encrypted encoding remaining](./spec/acceptance/rest/message_spec.rb#L179)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L185)
        * publishing on an encrypted channel and subscribing with a different algorithm on another client
          * [delivers the message with encrypted encoding remaining](./spec/acceptance/rest/message_spec.rb#L206)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L212)
        * publishing on an encrypted channel and subscribing with a different key on another client
          * [delivers the message with encrypted encoding remaining](./spec/acceptance/rest/message_spec.rb#L233)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L239)
  * over json
    * with ASCII_8BIT message name
      * [is converted into UTF_8](./spec/acceptance/rest/message_spec.rb#L18)
    * encryption and encoding
      * encoding and decoding encrypted messages
        * with AES-128-CBC
          * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 1 with encrypted encoding cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
        * with AES-256-CBC
          * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 1 with encrypted encoding cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
          * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
            * behaves like an Ably encrypter and decrypter
              * publish & subscribe
                * [encrypts message automatically when published](./spec/acceptance/rest/message_spec.rb#L66)
                * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/rest/message_spec.rb#L81)
        * multiple messages
          * [encrypt and decrypt messages](./spec/acceptance/rest/message_spec.rb#L115)
        * sending using protocol json and retrieving with a different protocol
          * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/rest/message_spec.rb#L142)
          * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/rest/message_spec.rb#L142)
          * [delivers a Hash payload to the receiver](./spec/acceptance/rest/message_spec.rb#L142)
        * publishing on an unencrypted channel and retrieving on an encrypted channel
          * [does not attempt to decrypt the message](./spec/acceptance/rest/message_spec.rb#L158)
        * publishing on an encrypted channel and retrieving on an unencrypted channel
          * [delivers the message with encrypted encoding remaining](./spec/acceptance/rest/message_spec.rb#L179)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L185)
        * publishing on an encrypted channel and subscribing with a different algorithm on another client
          * [delivers the message with encrypted encoding remaining](./spec/acceptance/rest/message_spec.rb#L206)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L212)
        * publishing on an encrypted channel and subscribing with a different key on another client
          * [delivers the message with encrypted encoding remaining](./spec/acceptance/rest/message_spec.rb#L233)
          * [logs a Cipher exception](./spec/acceptance/rest/message_spec.rb#L239)

### Ably::Rest::Presence
  * over msgpack
    * #get presence
      * [returns current members on the channel](./spec/acceptance/rest/presence_spec.rb#L25)
      * PENDING: *[with options](./spec/acceptance/rest/presence_spec.rb#L34)*
    * presence #history
      * FAILED: ~~[returns recent presence activity](./spec/acceptance/rest/presence_spec.rb#L41)~~
      * with options
        * forwards
          * FAILED: ~~[returns recent presence activity with options passed to Ably](./spec/acceptance/rest/presence_spec.rb#L57)~~
        * backwards
          * FAILED: ~~[returns recent presence activity with options passed to Ably](./spec/acceptance/rest/presence_spec.rb#L72)~~
    * options
      * :{option}
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L125)
      * :{option}
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L125)
    * decoding
      * valid decodeable content
        * #get
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L182)
        * #history
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L199)
      * invalid data
        * #get
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L230)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L234)
        * #history
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L254)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L258)
  * over json
    * #get presence
      * [returns current members on the channel](./spec/acceptance/rest/presence_spec.rb#L25)
      * PENDING: *[with options](./spec/acceptance/rest/presence_spec.rb#L34)*
    * presence #history
      * FAILED: ~~[returns recent presence activity](./spec/acceptance/rest/presence_spec.rb#L41)~~
      * with options
        * forwards
          * FAILED: ~~[returns recent presence activity with options passed to Ably](./spec/acceptance/rest/presence_spec.rb#L57)~~
        * backwards
          * FAILED: ~~[returns recent presence activity with options passed to Ably](./spec/acceptance/rest/presence_spec.rb#L72)~~
    * options
      * :{option}
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L125)
      * :{option}
        * with milliseconds since epoch
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L115)
        * with Time
          * [are left unchanged](./spec/acceptance/rest/presence_spec.rb#L125)
    * decoding
      * valid decodeable content
        * #get
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L182)
        * #history
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L199)
      * invalid data
        * #get
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L230)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L234)
        * #history
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L254)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L258)

### Ably::Rest::Client Stats
  * over json
    * fetching application stats
      * by minute
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
      * by hour
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
      * by day
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
      * by month
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
  * over msgpack
    * fetching application stats
      * by minute
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
      * by hour
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
      * by day
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)
      * by month
        * [should return all the stats for the application](./spec/acceptance/rest/stats_spec.rb#L44)

### Ably::REST::Client time
  * over msgpack
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/rest/time_spec.rb#L11)
  * over json
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/rest/time_spec.rb#L11)

### Ably::Auth
  * client_id option
    * with nil value
      * [is permitted](./spec/unit/auth_spec.rb#L19)
    * as UTF_8 string
      * [is permitted](./spec/unit/auth_spec.rb#L27)
      * [remains as UTF-8](./spec/unit/auth_spec.rb#L31)
    * as SHIFT_JIS string
      * [gets converted to UTF-8](./spec/unit/auth_spec.rb#L39)
      * [is compatible with original encoding](./spec/unit/auth_spec.rb#L43)
    * as ASCII_8BIT string
      * [gets converted to UTF-8](./spec/unit/auth_spec.rb#L51)
      * [is compatible with original encoding](./spec/unit/auth_spec.rb#L55)
    * as Integer
      * [raises an argument error](./spec/unit/auth_spec.rb#L63)

### Ably::Logger
  * [uses the language provided Logger by default](./spec/unit/logger_spec.rb#L25)
  * with a custom Logger
    * with an invalid interface
      * [raises an exception](./spec/unit/logger_spec.rb#L111)
    * with a valid interface
      * [is used](./spec/unit/logger_spec.rb#L130)

### Ably::Models::ErrorInfo
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
      * with invalid channel_option cipher params
        * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L87)
      * without any configured encryption
        * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L97)
      * with invalid cipher data
        * FAILED: ~~[raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L106)~~
    * with AES-256-CBC
      * message with cipher payload
        * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L122)
        * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L126)
  * #encode
    * with channel set up for AES-128-CBC
      * with encrypted set to true
        * message with string payload
          * [encodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L146)
          * [adds the encoding with utf-8](./spec/unit/models/message_encoders/cipher_spec.rb#L151)
        * message with binary payload
          * [encodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L159)
          * [adds the encoding without utf-8 prefixed](./spec/unit/models/message_encoders/cipher_spec.rb#L164)
          * [returns ASCII_8BIT encoded binary data](./spec/unit/models/message_encoders/cipher_spec.rb#L168)
        * message with json payload
          * [encodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L176)
          * [adds the encoding with utf-8](./spec/unit/models/message_encoders/cipher_spec.rb#L181)
        * message with existing cipher encoding before
          * [leaves message intact as it is already encrypted](./spec/unit/models/message_encoders/cipher_spec.rb#L189)
          * [leaves encoding intact](./spec/unit/models/message_encoders/cipher_spec.rb#L193)
        * with encryption set to to false
          * [leaves message intact as encryption is not enable](./spec/unit/models/message_encoders/cipher_spec.rb#L202)
          * [leaves encoding intact](./spec/unit/models/message_encoders/cipher_spec.rb#L206)
      * channel_option cipher params
        * have invalid key length
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L218)
        * have invalid algorithm
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L225)
        * have missing key
          * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L232)
    * with AES-256-CBC
      * message with cipher payload
        * [decodes cipher](./spec/unit/models/message_encoders/cipher_spec.rb#L249)
        * [strips the encoding](./spec/unit/models/message_encoders/cipher_spec.rb#L254)

### Ably::Models::MessageEncoders::Json
  * #decode
    * message with json payload
      * [decodes json](./spec/unit/models/message_encoders/json_spec.rb#L24)
      * [strips the encoding](./spec/unit/models/message_encoders/json_spec.rb#L28)
    * message with json payload before other payloads
      * [decodes json](./spec/unit/models/message_encoders/json_spec.rb#L36)
      * [strips the encoding](./spec/unit/models/message_encoders/json_spec.rb#L40)
    * message with another payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L48)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L52)
  * #encode
    * message with hash payload
      * [encodes hash payload data as json](./spec/unit/models/message_encoders/json_spec.rb#L66)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L70)
    * already encoded message with hash payload
      * [encodes hash payload data as json](./spec/unit/models/message_encoders/json_spec.rb#L78)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L82)
    * message with Array payload
      * [encodes Array payload data as json](./spec/unit/models/message_encoders/json_spec.rb#L90)
      * [adds the encoding](./spec/unit/models/message_encoders/json_spec.rb#L94)
    * message with UTF-8 payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L102)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L106)
    * message with nil payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L114)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L118)
    * message with no data payload
      * [leaves the message data intact](./spec/unit/models/message_encoders/json_spec.rb#L126)
      * [leaves the encoding intact](./spec/unit/models/message_encoders/json_spec.rb#L130)

### Ably::Models::MessageEncoders::Utf8
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
  * behaves like a model
    * attributes
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
    * [retrieves attribute :timestamp as Time object from ProtocolMessage](./spec/unit/models/message_spec.rb#L20)
  * initialized with
    * :name
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L46)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L50)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L58)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L62)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L70)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L74)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L82)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L90)
    * :client_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L46)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L50)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L58)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L62)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L70)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L74)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L82)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L90)
    * :encoding
      * as UTF_8 string
        * [is permitted](./spec/unit/models/message_spec.rb#L46)
        * [remains as UTF-8](./spec/unit/models/message_spec.rb#L50)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L58)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L62)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/message_spec.rb#L70)
        * [is compatible with original encoding](./spec/unit/models/message_spec.rb#L74)
      * as Integer
        * [raises an argument error](./spec/unit/models/message_spec.rb#L82)
      * as Nil
        * [is permitted](./spec/unit/models/message_spec.rb#L90)

### Ably::Models::PaginatedResource
  * [returns correct length from body](./spec/unit/models/paginated_resource_spec.rb#L30)
  * [supports alias methods for length](./spec/unit/models/paginated_resource_spec.rb#L34)
  * [is Enumerable](./spec/unit/models/paginated_resource_spec.rb#L39)
  * [is iterable](./spec/unit/models/paginated_resource_spec.rb#L43)
  * [provides [] accessor method](./spec/unit/models/paginated_resource_spec.rb#L47)
  * [#first gets the first item in page](./spec/unit/models/paginated_resource_spec.rb#L53)
  * [#last gets the last item in page](./spec/unit/models/paginated_resource_spec.rb#L57)
  * with non paged http response
    * [is the first page](./spec/unit/models/paginated_resource_spec.rb#L161)
    * [is the last page](./spec/unit/models/paginated_resource_spec.rb#L165)
    * [does not support pagination](./spec/unit/models/paginated_resource_spec.rb#L169)
    * [raises an exception when accessing next page](./spec/unit/models/paginated_resource_spec.rb#L173)
    * [raises an exception when accessing first page](./spec/unit/models/paginated_resource_spec.rb#L177)
  * with paged http response
    * [is the first page](./spec/unit/models/paginated_resource_spec.rb#L195)
    * [is not the last page](./spec/unit/models/paginated_resource_spec.rb#L199)
    * [supports pagination](./spec/unit/models/paginated_resource_spec.rb#L203)
    * accessing next page
      * [returns another PaginatedResource](./spec/unit/models/paginated_resource_spec.rb#L231)
      * [retrieves the next page of results](./spec/unit/models/paginated_resource_spec.rb#L235)
      * [is not the first page](./spec/unit/models/paginated_resource_spec.rb#L240)
      * [is the last page](./spec/unit/models/paginated_resource_spec.rb#L244)
      * [raises an exception if trying to access the last page when it is the last page](./spec/unit/models/paginated_resource_spec.rb#L248)
      * and then first page
        * [returns a PaginatedResource](./spec/unit/models/paginated_resource_spec.rb#L259)
        * [retrieves the first page of results](./spec/unit/models/paginated_resource_spec.rb#L263)
        * [is the first page](./spec/unit/models/paginated_resource_spec.rb#L267)

### Ably::Models::PresenceMessage
  * behaves like a model
    * attributes
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
      * #member_id
        * [retrieves attribute :member_id](./spec/shared/model_behaviour.rb#L15)
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
    * [retrieves attribute :timestamp as a Time object from ProtocolMessage](./spec/unit/models/presence_message_spec.rb#L18)
  * initialized with
    * :client_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L60)
        * [remains as UTF-8](./spec/unit/models/presence_message_spec.rb#L64)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L72)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L76)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L84)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L88)
      * as Integer
        * [raises an argument error](./spec/unit/models/presence_message_spec.rb#L96)
      * as Nil
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L104)
    * :member_id
      * as UTF_8 string
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L60)
        * [remains as UTF-8](./spec/unit/models/presence_message_spec.rb#L64)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L72)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L76)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L84)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L88)
      * as Integer
        * [raises an argument error](./spec/unit/models/presence_message_spec.rb#L96)
      * as Nil
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L104)
    * :encoding
      * as UTF_8 string
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L60)
        * [remains as UTF-8](./spec/unit/models/presence_message_spec.rb#L64)
      * as SHIFT_JIS string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L72)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L76)
      * as ASCII_8BIT string
        * [gets converted to UTF-8](./spec/unit/models/presence_message_spec.rb#L84)
        * [is compatible with original encoding](./spec/unit/models/presence_message_spec.rb#L88)
      * as Integer
        * [raises an argument error](./spec/unit/models/presence_message_spec.rb#L96)
      * as Nil
        * [is permitted](./spec/unit/models/presence_message_spec.rb#L104)

### Ably::Models::ProtocolMessage
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
    * #has_connection_serial?
      * without connection_serial
        * [returns false](./spec/unit/models/protocol_message_spec.rb#L141)
      * with connection_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L149)
    * #serial
      * with underlying msg_serial
        * [converts :msg_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L158)
      * with underlying connection_serial
        * [converts :connection_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L166)
      * with underlying connection_serial and msg_serial
        * [prefers connection_serial and converts :connection_serial to an Integer](./spec/unit/models/protocol_message_spec.rb#L174)
    * #has_serial?
      * without msg_serial or connection_serial
        * [returns false](./spec/unit/models/protocol_message_spec.rb#L185)
      * with msg_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L193)
      * with connection_serial
        * [returns true](./spec/unit/models/protocol_message_spec.rb#L201)
    * #error
      * with no error attribute
        * [returns nil](./spec/unit/models/protocol_message_spec.rb#L211)
      * with nil error
        * [returns nil](./spec/unit/models/protocol_message_spec.rb#L219)
      * with error
        * [returns a valid ErrorInfo object](./spec/unit/models/protocol_message_spec.rb#L227)

### Ably::Models::Token
  * behaves like a model
    * attributes
      * #id
        * [retrieves attribute :id](./spec/shared/model_behaviour.rb#L15)
      * #capability
        * [retrieves attribute :capability](./spec/shared/model_behaviour.rb#L15)
      * #client_id
        * [retrieves attribute :client_id](./spec/shared/model_behaviour.rb#L15)
      * #nonce
        * [retrieves attribute :nonce](./spec/shared/model_behaviour.rb#L15)
    * #==
      * [is true when attributes are the same](./spec/shared/model_behaviour.rb#L41)
      * [is false when attributes are not the same](./spec/shared/model_behaviour.rb#L46)
      * [is false when class type differs](./spec/shared/model_behaviour.rb#L50)
    * is immutable
      * [prevents changes](./spec/shared/model_behaviour.rb#L76)
      * [dups options](./spec/shared/model_behaviour.rb#L80)
  * defaults
    * [should default TTL to 1 hour](./spec/unit/models/token_spec.rb#L14)
    * [should default capability to all](./spec/unit/models/token_spec.rb#L18)
    * [should only have defaults for :ttl and :capability](./spec/unit/models/token_spec.rb#L22)
  * attributes
    * #key_id
      * [retrieves attribute :key](./spec/unit/models/token_spec.rb#L32)
    * #issued_at
      * [retrieves attribute :issued_at as Time](./spec/unit/models/token_spec.rb#L42)
    * #expires_at
      * [retrieves attribute :expires as Time](./spec/unit/models/token_spec.rb#L42)
    * #expired?
      * once grace period buffer has passed
        * [is true](./spec/unit/models/token_spec.rb#L55)
      * within grace period buffer
        * [is false](./spec/unit/models/token_spec.rb#L63)
  * ==
    * [is true when attributes are the same](./spec/unit/models/token_spec.rb#L73)
    * [is false when attributes are not the same](./spec/unit/models/token_spec.rb#L78)
    * [is false when class type differs](./spec/unit/models/token_spec.rb#L82)

### Ably::Modules::EventEmitter
  * #trigger event fan out
    * [should #<RSpec::Mocks::Matchers::Receive:0x007fea11606438>](./spec/unit/modules/event_emitter_spec.rb#L18)
    * [#trigger sends only messages to matching event names](./spec/unit/modules/event_emitter_spec.rb#L27)
    * #on subscribe to multiple events
      * [with the same block](./spec/unit/modules/event_emitter_spec.rb#L59)
    * event callback changes within the callback block
      * when new event callbacks are added
        * [is unaffected and processes the prior event callbacks once](./spec/unit/modules/event_emitter_spec.rb#L83)
        * [adds them for the next emitted event](./spec/unit/modules/event_emitter_spec.rb#L89)
      * when callbacks are removed
        * [is unaffected and processes the prior event callbacks once](./spec/unit/modules/event_emitter_spec.rb#L110)
        * [removes them for the next emitted event](./spec/unit/modules/event_emitter_spec.rb#L115)
  * #once
    * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L128)
    * [does not remove other blocks after it is called](./spec/unit/modules/event_emitter_spec.rb#L135)
  * #off
    * with event names as arguments
      * [deletes matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L156)
      * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L161)
      * [continues if the block does not exist](./spec/unit/modules/event_emitter_spec.rb#L166)
    * without any event names
      * [deletes all matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L173)
      * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L178)

### Ably::Modules::StateEmitter
  * [#state returns current state](./spec/unit/modules/state_emitter_spec.rb#L25)
  * [#state= sets current state](./spec/unit/modules/state_emitter_spec.rb#L29)
  * [#change_state sets current state](./spec/unit/modules/state_emitter_spec.rb#L33)
  * #change_state with arguments
    * [passes the arguments through to the triggered callback](./spec/unit/modules/state_emitter_spec.rb#L41)
  * #state?
    * [returns true if state matches](./spec/unit/modules/state_emitter_spec.rb#L52)
    * [returns false if state does not match](./spec/unit/modules/state_emitter_spec.rb#L56)
    * and convenience predicates for states
      * [returns true for #initializing? if state matches](./spec/unit/modules/state_emitter_spec.rb#L61)
      * [returns false for #connecting? if state does not match](./spec/unit/modules/state_emitter_spec.rb#L65)

### Ably::Realtime::Channel
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
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L79)
    * as SHIFT_JIS string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L87)
    * as ASCII_8BIT string
      * [is permitted](./spec/unit/realtime/channel_spec.rb#L95)
    * as Integer
      * [raises an argument error](./spec/unit/realtime/channel_spec.rb#L103)
    * as Nil
      * [raises an argument error](./spec/unit/realtime/channel_spec.rb#L111)
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/channel_spec.rb#L118)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/channel_spec.rb#L124)
  * subscriptions
    * #subscribe
      * [to all events](./spec/unit/realtime/channel_spec.rb#L159)
      * [to specific events](./spec/unit/realtime/channel_spec.rb#L165)
    * #unsubscribe
      * [to all events](./spec/unit/realtime/channel_spec.rb#L181)
      * [to specific events](./spec/unit/realtime/channel_spec.rb#L187)
      * [to specific non-matching events](./spec/unit/realtime/channel_spec.rb#L193)
      * [all callbacks by not providing a callback](./spec/unit/realtime/channel_spec.rb#L199)

### Ably::Realtime::Channels
  * creating channels
    * [#get creates a channel](./spec/unit/realtime/channels_spec.rb#L13)
    * [#get will reuse the channel object](./spec/unit/realtime/channels_spec.rb#L18)
    * [[] creates a channel](./spec/unit/realtime/channels_spec.rb#L24)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/realtime/channels_spec.rb#L31)
    * [calls the block if channel is missing](./spec/unit/realtime/channels_spec.rb#L36)
  * destroying channels
    * [#release detatches and then releases the channel resoures](./spec/unit/realtime/channels_spec.rb#L44)

### Ably::Realtime::Client
  * behaves like a client initializer
    * with invalid arguments
      * empty hash
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L28)
      * nil
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L36)
      * api_key: "invalid"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L44)
      * api_key: "invalid:asdad"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L52)
      * api_key and key_id
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L60)
      * api_key and key_secret
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L68)
      * client_id as only option
        * [requires a valid key](./spec/shared/client_initializer_behaviour.rb#L76)
    * with valid arguments
      * api_key only
        * [connects to the Ably service](./spec/shared/client_initializer_behaviour.rb#L87)
      * key_id and key_secret
        * [constructs an api_key](./spec/shared/client_initializer_behaviour.rb#L95)
      * with a string key instead of options hash
        * [sets the api_key](./spec/shared/client_initializer_behaviour.rb#L103)
        * [sets the key_id](./spec/shared/client_initializer_behaviour.rb#L107)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L111)
      * with token
        * [sets the token_id](./spec/shared/client_initializer_behaviour.rb#L119)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L125)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L132)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L151)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L142)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L146)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L158)
          * [specifies Logger::ERROR log level](./spec/shared/client_initializer_behaviour.rb#L162)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L170)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L188)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L192)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L202)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L207)
  * delegation to the REST Client
    * [passes on the options to the initializer](./spec/unit/realtime/client_spec.rb#L15)
    * for attribute
      * [#environment](./spec/unit/realtime/client_spec.rb#L23)
      * [#use_tls?](./spec/unit/realtime/client_spec.rb#L23)
      * [#log_level](./spec/unit/realtime/client_spec.rb#L23)
      * [#custom_host](./spec/unit/realtime/client_spec.rb#L23)

### Ably::Realtime::Connection
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/connection_spec.rb#L17)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/connection_spec.rb#L23)

### Ably::Realtime::Presence
  * callbacks
    * [are supported for valid STATE events](./spec/unit/realtime/presence_spec.rb#L13)
    * [fail with unacceptable STATE event names](./spec/unit/realtime/presence_spec.rb#L19)
  * subscriptions
    * #subscribe
      * [to all presence state actions](./spec/unit/realtime/presence_spec.rb#L56)
      * [to specific presence state actions](./spec/unit/realtime/presence_spec.rb#L62)
    * #unsubscribe
      * [to all presence state actions](./spec/unit/realtime/presence_spec.rb#L78)
      * [to specific presence state actions](./spec/unit/realtime/presence_spec.rb#L84)
      * [to specific non-matching presence state actions](./spec/unit/realtime/presence_spec.rb#L90)
      * [all callbacks by not providing a callback](./spec/unit/realtime/presence_spec.rb#L96)

### Ably::Realtime
  * [constructor returns an Ably::Realtime::Client](./spec/unit/realtime/realtime_spec.rb#L6)

### Ably::Rest::Channels
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
    * as Nil
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L104)

### Ably::Rest::Channels
  * creating channels
    * [#get creates a channel](./spec/unit/rest/channels_spec.rb#L12)
    * [#get will reuse the channel object](./spec/unit/rest/channels_spec.rb#L17)
    * [[] creates a channel](./spec/unit/rest/channels_spec.rb#L23)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/rest/channels_spec.rb#L30)
    * [calls the block if channel is missing](./spec/unit/rest/channels_spec.rb#L35)
  * destroying channels
    * [#release releases the channel resoures](./spec/unit/rest/channels_spec.rb#L43)

### Ably::Rest::Client
  * behaves like a client initializer
    * with invalid arguments
      * empty hash
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L28)
      * nil
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L36)
      * api_key: "invalid"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L44)
      * api_key: "invalid:asdad"
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L52)
      * api_key and key_id
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L60)
      * api_key and key_secret
        * [raises an exception](./spec/shared/client_initializer_behaviour.rb#L68)
      * client_id as only option
        * [requires a valid key](./spec/shared/client_initializer_behaviour.rb#L76)
    * with valid arguments
      * api_key only
        * [connects to the Ably service](./spec/shared/client_initializer_behaviour.rb#L87)
      * key_id and key_secret
        * [constructs an api_key](./spec/shared/client_initializer_behaviour.rb#L95)
      * with a string key instead of options hash
        * [sets the api_key](./spec/shared/client_initializer_behaviour.rb#L103)
        * [sets the key_id](./spec/shared/client_initializer_behaviour.rb#L107)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L111)
      * with token
        * [sets the token_id](./spec/shared/client_initializer_behaviour.rb#L119)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L125)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L132)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L151)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L142)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L146)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L158)
          * [specifies Logger::ERROR log level](./spec/shared/client_initializer_behaviour.rb#L162)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L170)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L188)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L192)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L202)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L207)
  * TLS
    * disabled
      * [fails when authenticating with basic auth and attempting to send an API key over a non-secure connection](./spec/unit/rest/client_spec.rb#L16)

### Ably::Rest
  * [constructor returns an Ably::Rest::Client](./spec/unit/rest/rest_spec.rb#L7)

### Ably::Util::Crypto
  * defaults
    * [match other client libraries](./spec/unit/util/crypto_spec.rb#L18)
  * encrypts & decrypt
    * [#encrypt encrypts a string](./spec/unit/util/crypto_spec.rb#L28)
    * [#decrypt decrypts a string](./spec/unit/util/crypto_spec.rb#L33)
  * encrypting an empty string
    * [raises an ArgumentError](./spec/unit/util/crypto_spec.rb#L42)
  * using shared client lib fixture data
    * with AES-128-CBC
      * behaves like an Ably encrypter and decrypter
        * text payload
          * [encrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L65)
          * [decrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L69)
    * with AES-256-CBC
      * behaves like an Ably encrypter and decrypter
        * text payload
          * [encrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L65)
          * [decrypts exactly the same binary data as other client libraries](./spec/unit/util/crypto_spec.rb#L69)

### Ably::Util::PubSub
  * event fan out
    * [#publish allows publishing to more than on subscriber](./spec/unit/util/pub_sub_spec.rb#L11)
    * [#publish sends only messages to #subscribe callbacks matching event names](./spec/unit/util/pub_sub_spec.rb#L19)
  * #unsubscribe
    * [deletes matching callbacks](./spec/unit/util/pub_sub_spec.rb#L71)
    * [deletes all callbacks if not block given](./spec/unit/util/pub_sub_spec.rb#L76)
    * [continues if the block does not exist](./spec/unit/util/pub_sub_spec.rb#L81)

-------

## Test summary

* Passing tests: 954
* Pending tests: 22
* Failing tests: 13
