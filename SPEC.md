# Ably Realtime & REST Client Library 0.8.2 Specification

### Ably::Realtime::Channel#history
_(see [spec/acceptance/realtime/channel_history_spec.rb](./spec/acceptance/realtime/channel_history_spec.rb))_
  * using JSON and MsgPack protocol
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
      * [raises an exception unless state is attached](./spec/acceptance/realtime/channel_history_spec.rb#L199)
      * and two pages of messages
        * [retrieves two pages of messages before channel was attached](./spec/acceptance/realtime/channel_history_spec.rb#L175)

### Ably::Realtime::Channel
_(see [spec/acceptance/realtime/channel_spec.rb](./spec/acceptance/realtime/channel_spec.rb))_
  * using JSON and MsgPack protocol
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
      * [emits :detaching then :detached events](./spec/acceptance/realtime/channel_spec.rb#L231)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/channel_spec.rb#L243)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/channel_spec.rb#L250)
      * when state is :failed
        * [raises an exception](./spec/acceptance/realtime/channel_spec.rb#L263)
      * when state is :attaching
        * [moves straight to :detaching state and skips :attached](./spec/acceptance/realtime/channel_spec.rb#L274)
      * when state is :detaching
        * [ignores subsequent #detach calls but calls the callback if provided](./spec/acceptance/realtime/channel_spec.rb#L292)
    * channel recovery in :attaching state
      * the transport is disconnected before the ATTACHED protocol message is received
        * PENDING: *[attach times out and fails if not ATTACHED protocol message received](./spec/acceptance/realtime/channel_spec.rb#L311)*
        * PENDING: *[channel is ATTACHED if ATTACHED protocol message is later received](./spec/acceptance/realtime/channel_spec.rb#L312)*
        * PENDING: *[sends an ATTACH protocol message in response to a channel message being received on the attaching channel](./spec/acceptance/realtime/channel_spec.rb#L313)*
    * #publish
      * when attached
        * [publishes messages](./spec/acceptance/realtime/channel_spec.rb#L319)
      * when not yet attached
        * [publishes queued messages once attached](./spec/acceptance/realtime/channel_spec.rb#L331)
        * [publishes queued messages within a single protocol message](./spec/acceptance/realtime/channel_spec.rb#L339)
    * #subscribe
      * with an event argument
        * [subscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L362)
      * with no event argument
        * [subscribes for all events](./spec/acceptance/realtime/channel_spec.rb#L372)
      * many times with different event names
        * [filters events accordingly to each callback](./spec/acceptance/realtime/channel_spec.rb#L382)
    * #unsubscribe
      * with an event argument
        * [unsubscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L405)
      * with no event argument
        * [unsubscribes for a single event](./spec/acceptance/realtime/channel_spec.rb#L418)
    * when connection state changes to
      * :failed
        * an :attached channel
          * [transitions state to :failed](./spec/acceptance/realtime/channel_spec.rb#L441)
          * [emits an error event on the channel](./spec/acceptance/realtime/channel_spec.rb#L451)
          * [updates the channel error_reason](./spec/acceptance/realtime/channel_spec.rb#L461)
        * a :detached channel
          * [remains in the :detached state](./spec/acceptance/realtime/channel_spec.rb#L473)
        * a :failed channel
          * [remains in the :failed state and ignores the failure error](./spec/acceptance/realtime/channel_spec.rb#L493)
      * :closed
        * an :attached channel
          * [transitions state to :detached](./spec/acceptance/realtime/channel_spec.rb#L516)
        * a :detached channel
          * [remains in the :detached state](./spec/acceptance/realtime/channel_spec.rb#L527)
        * a :failed channel
          * [remains in the :failed state and retains the error_reason](./spec/acceptance/realtime/channel_spec.rb#L548)

### Ably::Realtime::Client
_(see [spec/acceptance/realtime/client_spec.rb](./spec/acceptance/realtime/client_spec.rb))_
  * using JSON and MsgPack protocol
    * initialization
      * basic auth
        * [is enabled by default with a provided :key option](./spec/acceptance/realtime/client_spec.rb#L18)
        * :tls option
          * set to false to forec a plain-text connection
            * [fails to connect because a private key cannot be sent over a non-secure connection](./spec/acceptance/realtime/client_spec.rb#L31)
      * token auth
        * with TLS enabled
          * and a pre-generated Token provided with the :token option
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L51)
          * with valid :key and :use_token_auth option set to true
            * [automatically authorises on connect and generates a token](./spec/acceptance/realtime/client_spec.rb#L64)
          * with client_id
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L77)
        * with TLS disabled
          * and a pre-generated Token provided with the :token option
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L51)
          * with valid :key and :use_token_auth option set to true
            * [automatically authorises on connect and generates a token](./spec/acceptance/realtime/client_spec.rb#L64)
          * with client_id
            * [connects using token auth](./spec/acceptance/realtime/client_spec.rb#L77)
        * with a Proc for the :auth_callback option
          * [calls the Proc](./spec/acceptance/realtime/client_spec.rb#L102)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/realtime/client_spec.rb#L109)

### Ably::Realtime::Connection failures
_(see [spec/acceptance/realtime/connection_failures_spec.rb](./spec/acceptance/realtime/connection_failures_spec.rb))_
  * using JSON and MsgPack protocol
    * authentication failure
      * when API key is invalid
        * with invalid app part of the key
          * [enters the failed state and returns a not found error](./spec/acceptance/realtime/connection_failures_spec.rb#L26)
        * with invalid key name part of the key
          * [enters the failed state and returns an authorization error](./spec/acceptance/realtime/connection_failures_spec.rb#L40)
    * automatic connection retry
      * with invalid WebSocket host
        * when disconnected
          * [enters the suspended state after multiple attempts to connect](./spec/acceptance/realtime/connection_failures_spec.rb#L95)
          * #close
            * [transitions connection state to :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L112)
        * when connection state is :suspended
          * [enters the failed state after multiple attempts if the max_time_in_state is set](./spec/acceptance/realtime/connection_failures_spec.rb#L131)
          * #close
            * [transitions connection state to :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L151)
        * when connection state is :failed
          * #close
            * [will not transition state to :close and raises a StateChangeError exception](./spec/acceptance/realtime/connection_failures_spec.rb#L170)
        * #error_reason
          * [contains the error when state is disconnected](./spec/acceptance/realtime/connection_failures_spec.rb#L184)
          * [contains the error when state is suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L184)
          * [contains the error when state is failed](./spec/acceptance/realtime/connection_failures_spec.rb#L184)
          * [is reset to nil when :connected](./spec/acceptance/realtime/connection_failures_spec.rb#L193)
          * [is reset to nil when :closed](./spec/acceptance/realtime/connection_failures_spec.rb#L204)
      * #connect
        * connection opening times out
          * [attempts to reconnect](./spec/acceptance/realtime/connection_failures_spec.rb#L231)
          * [calls the errback of the returned Deferrable object when first connection attempt fails](./spec/acceptance/realtime/connection_failures_spec.rb#L244)
          * when retry intervals are stubbed to attempt reconnection quickly
            * [never calls the provided success block](./spec/acceptance/realtime/connection_failures_spec.rb#L263)
    * connection resume
      * when DISCONNECTED ProtocolMessage received from the server
        * [reconnects automatically and immediately](./spec/acceptance/realtime/connection_failures_spec.rb#L292)
        * and subsequently fails to reconnect
          * [retries every 15 seconds](./spec/acceptance/realtime/connection_failures_spec.rb#L322)
      * when websocket transport is closed
        * [reconnects automatically](./spec/acceptance/realtime/connection_failures_spec.rb#L365)
      * after successfully reconnecting and resuming
        * [retains connection_id and connection_key](./spec/acceptance/realtime/connection_failures_spec.rb#L382)
        * [retains channel subscription state](./spec/acceptance/realtime/connection_failures_spec.rb#L399)
        * when messages were published whilst the client was disconnected
          * [receives the messages published whilst offline](./spec/acceptance/realtime/connection_failures_spec.rb#L429)
      * when failing to resume
        * because the connection_key is not or no longer valid
          * [updates the connection_id and connection_key](./spec/acceptance/realtime/connection_failures_spec.rb#L470)
          * [detaches all channels](./spec/acceptance/realtime/connection_failures_spec.rb#L485)
          * [emits an error on the channel and sets the error reason](./spec/acceptance/realtime/connection_failures_spec.rb#L503)
    * fallback host feature
      * with custom realtime websocket host option
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L542)
      * with non-production environment
        * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L559)
      * with production environment
        * when the Internet is down
          * [never uses a fallback host](./spec/acceptance/realtime/connection_failures_spec.rb#L587)
        * when the Internet is up
          * [uses a fallback host on every subsequent disconnected attempt until suspended](./spec/acceptance/realtime/connection_failures_spec.rb#L604)
          * [uses the primary host when suspended, and a fallback host on every subsequent suspended attempt](./spec/acceptance/realtime/connection_failures_spec.rb#L623)

### Ably::Realtime::Connection
_(see [spec/acceptance/realtime/connection_spec.rb](./spec/acceptance/realtime/connection_spec.rb))_
  * using JSON and MsgPack protocol
    * intialization
      * [connects automatically](./spec/acceptance/realtime/connection_spec.rb#L23)
      * with :auto_connect option set to false
        * [does not connect automatically](./spec/acceptance/realtime/connection_spec.rb#L35)
        * [connects when method #connect is called](./spec/acceptance/realtime/connection_spec.rb#L43)
      * with token auth
        * for renewable tokens
          * that are valid for the duration of the test
            * with valid pre authorised token expiring in the future
              * [uses the existing token created by Auth](./spec/acceptance/realtime/connection_spec.rb#L61)
            * with implicit authorisation
              * [uses the token created by the implicit authorisation](./spec/acceptance/realtime/connection_spec.rb#L73)
          * that expire
            * opening a new connection
              * with recently expired token
                * [renews the token on connect](./spec/acceptance/realtime/connection_spec.rb#L94)
              * with immediately expiring token
                * [renews the token on connect, and only makes one subsequent attempt to obtain a new token](./spec/acceptance/realtime/connection_spec.rb#L108)
                * [uses the primary host for subsequent connection and auth requests](./spec/acceptance/realtime/connection_spec.rb#L118)
            * when connected with a valid non-expired token
              * that then expires following the connection being opened
                * PENDING: *[retains connection state](./spec/acceptance/realtime/connection_spec.rb#L166)*
                * PENDING: *[changes state to failed if a new token cannot be issued](./spec/acceptance/realtime/connection_spec.rb#L167)*
                * the server
                  * [disconnects the client, and the client automatically renews the token and then reconnects](./spec/acceptance/realtime/connection_spec.rb#L145)
        * for non-renewable tokens
          * that are expired
            * opening a new connection
              * [transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L182)
            * when connected
              * PENDING: *[transitions state to failed](./spec/acceptance/realtime/connection_spec.rb#L195)*
    * initialization state changes
      * with implicit #connect
        * [are emitted in order](./spec/acceptance/realtime/connection_spec.rb#L222)
      * with explicit #connect
        * [are emitted in order](./spec/acceptance/realtime/connection_spec.rb#L228)
    * #connect
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/connection_spec.rb#L236)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/connection_spec.rb#L241)
      * when already connected
        * [does nothing and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L250)
      * once connected
        * connection#id
          * [is a string](./spec/acceptance/realtime/connection_spec.rb#L267)
          * [is unique from the connection#key](./spec/acceptance/realtime/connection_spec.rb#L274)
          * [is unique for every connection](./spec/acceptance/realtime/connection_spec.rb#L281)
        * connection#key
          * [is a string](./spec/acceptance/realtime/connection_spec.rb#L290)
          * [is unique from the connection#id](./spec/acceptance/realtime/connection_spec.rb#L297)
          * [is unique for every connection](./spec/acceptance/realtime/connection_spec.rb#L304)
      * following a previous connection being opened and closed
        * [reconnects and is provided with a new connection ID and connection key from the server](./spec/acceptance/realtime/connection_spec.rb#L314)
    * #serial connection serial
      * [is set to -1 when a new connection is opened](./spec/acceptance/realtime/connection_spec.rb#L334)
      * [is set to 0 when a message sent ACK is received](./spec/acceptance/realtime/connection_spec.rb#L356)
      * [is set to 1 when the second message sent ACK is received](./spec/acceptance/realtime/connection_spec.rb#L363)
      * when a message is sent but the ACK has not yet been received
        * [the sent message msgSerial is 0 but the connection serial remains at -1](./spec/acceptance/realtime/connection_spec.rb#L343)
    * #close
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/connection_spec.rb#L374)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/connection_spec.rb#L381)
      * when already closed
        * [does nothing and no further state changes are emitted](./spec/acceptance/realtime/connection_spec.rb#L392)
      * when connection state is
        * :initialized
          * [changes the connection state to :closing and then immediately :closed without sending a ProtocolMessage CLOSE](./spec/acceptance/realtime/connection_spec.rb#L420)
        * :connected
          * [changes the connection state to :closing and waits for the server to confirm connection is :closed with a ProtocolMessage](./spec/acceptance/realtime/connection_spec.rb#L438)
          * with an unresponsive connection
            * [force closes the connection when a :closed ProtocolMessage response is not received](./spec/acceptance/realtime/connection_spec.rb#L468)
    * #ping
      * [echoes a heart beat](./spec/acceptance/realtime/connection_spec.rb#L491)
      * when not connected
        * [raises an exception](./spec/acceptance/realtime/connection_spec.rb#L501)
      * with a success block that raises an exception
        * [catches the exception and logs the error](./spec/acceptance/realtime/connection_spec.rb#L508)
    * recovery
      * #recovery_key
        * [is composed of connection key and serial that is kept up to date with each message ACK received](./spec/acceptance/realtime/connection_spec.rb#L545)
        * [is available when connection is in one of the states: connecting, connected, disconnected, suspended, failed](./spec/acceptance/realtime/connection_spec.rb#L568)
        * [is nil when connection is explicitly CLOSED](./spec/acceptance/realtime/connection_spec.rb#L592)
      * opening a new connection using a recently disconnected connection's #recovery_key
        * connection#id and connection#key after recovery
          * [remains the same](./spec/acceptance/realtime/connection_spec.rb#L606)
        * when messages have been sent whilst the old connection is disconnected
          * the new connection
            * [recovers server-side queued messages](./spec/acceptance/realtime/connection_spec.rb#L647)
      * with :recover option
        * with invalid syntax
          * [raises an exception](./spec/acceptance/realtime/connection_spec.rb#L672)
        * with invalid formatted value sent to server
          * [emits a fatal error on the connection object, sets the #error_reason and disconnects](./spec/acceptance/realtime/connection_spec.rb#L681)
        * with expired (missing) value sent to server
          * [emits an error on the connection object, sets the #error_reason, yet will connect anyway](./spec/acceptance/realtime/connection_spec.rb#L696)
    * with many connections simultaneously
      * [opens each with a unique connection#id and connection#key](./spec/acceptance/realtime/connection_spec.rb#L715)
    * when a state transition is unsupported
      * [emits a StateChangeError](./spec/acceptance/realtime/connection_spec.rb#L735)
    * protocol failure
      * receiving an invalid ProtocolMessage
        * [emits an error on the connection and logs a fatal error message](./spec/acceptance/realtime/connection_spec.rb#L751)
    * undocumented method
      * #internet_up?
        * [returns a Deferrable](./spec/acceptance/realtime/connection_spec.rb#L767)
        * internet up URL protocol
          * when using TLS for the connection
            * [uses TLS for the Internet check to https://internet-up.ably-realtime.com/is-the-internet-up.txt](./spec/acceptance/realtime/connection_spec.rb#L778)
          * when using a non-secured connection
            * [uses TLS for the Internet check to http://internet-up.ably-realtime.com/is-the-internet-up.txt](./spec/acceptance/realtime/connection_spec.rb#L788)
        * when the Internet is up
          * [calls the block with true](./spec/acceptance/realtime/connection_spec.rb#L797)
          * [calls the success callback of the Deferrable](./spec/acceptance/realtime/connection_spec.rb#L804)
        * when the Internet is down
          * [calls the block with false](./spec/acceptance/realtime/connection_spec.rb#L816)
          * [calls the failure callback of the Deferrable](./spec/acceptance/realtime/connection_spec.rb#L823)

### Ably::Realtime::Channel Message
_(see [spec/acceptance/realtime/message_spec.rb](./spec/acceptance/realtime/message_spec.rb))_
  * using JSON and MsgPack protocol
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
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/message_spec.rb#L82)
      * Float
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/message_spec.rb#L91)
      * Boolean
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/message_spec.rb#L100)
      * False
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/message_spec.rb#L109)
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
        * [will not echo messages to the client but will still broadcast messages to other connected clients](./spec/acceptance/realtime/message_spec.rb#L187)
    * publishing lots of messages across two connections
      * [sends and receives the messages on both opened connections and calls the success callbacks for each message published](./spec/acceptance/realtime/message_spec.rb#L219)
    * without suitable publishing permissions
      * [calls the error callback](./spec/acceptance/realtime/message_spec.rb#L264)
    * server incorrectly resends a message that was already received by the client library
      * [discards the message and logs it as an error to the channel](./spec/acceptance/realtime/message_spec.rb#L284)
    * encoding and decoding encrypted messages
      * with AES-128-CBC using crypto-data-128.json fixtures
        * item 0 with encrypted encoding utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
        * item 1 with encrypted encoding cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-128-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
      * with AES-256-CBC using crypto-data-256.json fixtures
        * item 0 with encrypted encoding utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
        * item 1 with encrypted encoding cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
        * item 2 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
        * item 3 with encrypted encoding json/utf-8/cipher+aes-256-cbc/base64
          * behaves like an Ably encrypter and decrypter
            * with #publish and #subscribe
              * [encrypts message automatically before they are pushed to the server](./spec/acceptance/realtime/message_spec.rb#L348)
              * [sends and receives messages that are encrypted & decrypted by the Ably library](./spec/acceptance/realtime/message_spec.rb#L366)
      * with multiple sends from one client to another
        * [encrypts and decrypts all messages](./spec/acceptance/realtime/message_spec.rb#L405)
      * subscribing with a different transport protocol
        * [delivers a String ASCII-8BIT payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L448)
        * [delivers a String UTF-8 payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L448)
        * [delivers a Hash payload to the receiver](./spec/acceptance/realtime/message_spec.rb#L448)
      * publishing on an unencrypted channel and subscribing on an encrypted channel with another client
        * [does not attempt to decrypt the message](./spec/acceptance/realtime/message_spec.rb#L467)
      * publishing on an encrypted channel and subscribing on an unencrypted channel with another client
        * [delivers the message but still encrypted with a value in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L485)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L494)
      * publishing on an encrypted channel and subscribing with a different algorithm on another client
        * [delivers the message but still encrypted with the cipher detials in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L516)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L525)
      * publishing on an encrypted channel and subscribing with a different key on another client
        * [delivers the message but still encrypted with the cipher details in the #encoding attribute](./spec/acceptance/realtime/message_spec.rb#L547)
        * [emits a Cipher error on the channel](./spec/acceptance/realtime/message_spec.rb#L558)

### Ably::Realtime::Presence history
_(see [spec/acceptance/realtime/presence_history_spec.rb](./spec/acceptance/realtime/presence_history_spec.rb))_
  * using JSON and MsgPack protocol
    * [provides up to the moment presence history](./spec/acceptance/realtime/presence_history_spec.rb#L21)
    * [ensures REST presence history message IDs match ProtocolMessage wrapped message and connection IDs via Realtime](./spec/acceptance/realtime/presence_history_spec.rb#L41)
    * with option until_attach: true
      * [retrieves all presence messages before channel was attached](./spec/acceptance/realtime/presence_history_spec.rb#L60)
      * [raises an exception unless state is attached](./spec/acceptance/realtime/presence_history_spec.rb#L92)
      * and two pages of messages
        * [retrieves two pages of messages before channel was attached](./spec/acceptance/realtime/presence_history_spec.rb#L73)

### Ably::Realtime::Presence
_(see [spec/acceptance/realtime/presence_spec.rb](./spec/acceptance/realtime/presence_spec.rb))_
  * using JSON and MsgPack protocol
    * when attached (but not present) on a presence channel with an anonymous client (no client ID)
      * [maintains state as other clients enter and leave the channel](./spec/acceptance/realtime/presence_spec.rb#L219)
    * #sync_complete?
      * when attaching to a channel without any members present
        * [is true and the presence channel is considered synced immediately](./spec/acceptance/realtime/presence_spec.rb#L295)
      * when attaching to a channel with members present
        * [is false and the presence channel will subsequently be synced](./spec/acceptance/realtime/presence_spec.rb#L304)
    * 250 existing (present) members on a channel (3 SYNC pages)
      * requires at least 3 SYNC ProtocolMessages
        * when a client attaches to the presence channel
          * [emits :present for each member](./spec/acceptance/realtime/presence_spec.rb#L336)
          * and a member leaves before the SYNC operation is complete
            * [emits :leave immediately as the member leaves](./spec/acceptance/realtime/presence_spec.rb#L350)
            * [ignores presence events with timestamps prior to the current :present event in the MembersMap](./spec/acceptance/realtime/presence_spec.rb#L388)
            * [does not emit :present after the :leave event has been emitted, and that member is not included in the list of members via #get with :wait_for_sync](./spec/acceptance/realtime/presence_spec.rb#L427)
          * #get
            * with :wait_for_sync option set to true
              * [waits until sync is complete](./spec/acceptance/realtime/presence_spec.rb#L474)
            * by default
              * [it does not wait for sync](./spec/acceptance/realtime/presence_spec.rb#L491)
    * state
      * once opened
        * [once opened, enters the :left state if the channel detaches](./spec/acceptance/realtime/presence_spec.rb#L515)
    * #enter
      * [allows client_id to be set on enter for anonymous clients](./spec/acceptance/realtime/presence_spec.rb#L538)
      * [raises an exception if client_id is not set](./spec/acceptance/realtime/presence_spec.rb#L585)
      * data attribute
        * when provided as argument option to #enter
          * [remains intact following #leave](./spec/acceptance/realtime/presence_spec.rb#L549)
      * message #connection_id
        * [matches the current client connection_id](./spec/acceptance/realtime/presence_spec.rb#L573)
      * without necessary capabilities to join presence
        * [calls the Deferrable errback on capabilities failure](./spec/acceptance/realtime/presence_spec.rb#L597)
      * it should behave like a public presence method
        * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L44)
        * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L44)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L157)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L164)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L174)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L73)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L83)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L93)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L103)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L123)
          * Float
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L132)
          * Boolean
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L141)
          * False
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L150)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L195)
    * #update
      * [without previous #enter automatically enters](./spec/acceptance/realtime/presence_spec.rb#L609)
      * [updates the data if :data argument provided](./spec/acceptance/realtime/presence_spec.rb#L634)
      * [updates the data to nil if :data argument is not provided (assumes nil value)](./spec/acceptance/realtime/presence_spec.rb#L644)
      * when ENTERED
        * [has no effect on the state](./spec/acceptance/realtime/presence_spec.rb#L619)
      * it should behave like a public presence method
        * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L44)
        * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L44)
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L157)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L164)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L174)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L73)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L83)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L93)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L103)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L123)
          * Float
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L132)
          * Boolean
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L141)
          * False
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L150)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L195)
    * #leave
      * [raises an exception if not entered](./spec/acceptance/realtime/presence_spec.rb#L718)
      * :data option
        * when set to a string
          * [emits the new data for the leave event](./spec/acceptance/realtime/presence_spec.rb#L663)
        * when set to nil
          * [emits a nil value for the data attribute when leaving](./spec/acceptance/realtime/presence_spec.rb#L676)
        * when not passed as an argument
          * [emits the previously defined value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L689)
        * and sync is complete
          * [does not cache members that have left](./spec/acceptance/realtime/presence_spec.rb#L702)
      * it should behave like a public presence method
        * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L157)
        * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L164)
        * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L174)
        * with supported data payload content type
          * JSON Object (Hash)
            * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L73)
          * JSON Array
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L83)
          * String
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L93)
          * Binary
            * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L103)
        * with unsupported data payload content type
          * Integer
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L123)
          * Float
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L132)
          * Boolean
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L141)
          * False
            * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L150)
        * if connection fails before success
          * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L195)
    * :left event
      * [emits the data defined in enter](./spec/acceptance/realtime/presence_spec.rb#L727)
      * [emits the data defined in update](./spec/acceptance/realtime/presence_spec.rb#L738)
    * entering/updating/leaving presence state on behalf of another client_id
      * #enter_client
        * multiple times on the same channel with different client_ids
          * [has no affect on the client's presence state and only enters on behalf of the provided client_id](./spec/acceptance/realtime/presence_spec.rb#L759)
          * [enters a channel and sets the data based on the provided :data option](./spec/acceptance/realtime/presence_spec.rb#L773)
        * message #connection_id
          * [matches the current client connection_id](./spec/acceptance/realtime/presence_spec.rb#L792)
        * it should behave like a public presence method
          * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L44)
          * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L44)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L157)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L164)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L174)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L73)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L83)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L93)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L103)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L123)
            * Float
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L132)
            * Boolean
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L141)
            * False
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L150)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L195)
        * without necessary capabilities to enter on behalf of another client
          * [calls the Deferrable errback on capabilities failure](./spec/acceptance/realtime/presence_spec.rb#L814)
      * #update_client
        * multiple times on the same channel with different client_ids
          * [updates the data attribute for the member when :data option provided](./spec/acceptance/realtime/presence_spec.rb#L825)
          * [updates the data attribute to null for the member when :data option is not provided (assumed null)](./spec/acceptance/realtime/presence_spec.rb#L849)
          * [enters if not already entered](./spec/acceptance/realtime/presence_spec.rb#L861)
        * it should behave like a public presence method
          * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L44)
          * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L44)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L157)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L164)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L174)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L73)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L83)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L93)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L103)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L123)
            * Float
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L132)
            * Boolean
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L141)
            * False
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L150)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L195)
      * #leave_client
        * leaves a channel
          * multiple times on the same channel with different client_ids
            * [emits the :leave event for each client_id](./spec/acceptance/realtime/presence_spec.rb#L890)
            * [succeeds if that client_id has not previously entered the channel](./spec/acceptance/realtime/presence_spec.rb#L914)
          * with a new value in :data option
            * [emits the leave event with the new data value](./spec/acceptance/realtime/presence_spec.rb#L938)
          * with a nil value in :data option
            * [emits the leave event with the previous value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L951)
          * with no :data option
            * [emits the leave event with the previous value as a convenience](./spec/acceptance/realtime/presence_spec.rb#L964)
        * it should behave like a public presence method
          * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L44)
          * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L44)
          * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L157)
          * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L164)
          * [catches exceptions in the provided method block and logs them to the logger](./spec/acceptance/realtime/presence_spec.rb#L174)
          * with supported data payload content type
            * JSON Object (Hash)
              * [is encoded and decoded to the same hash](./spec/acceptance/realtime/presence_spec.rb#L73)
            * JSON Array
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L83)
            * String
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L93)
            * Binary
              * [is encoded and decoded to the same Array](./spec/acceptance/realtime/presence_spec.rb#L103)
          * with unsupported data payload content type
            * Integer
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L123)
            * Float
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L132)
            * Boolean
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L141)
            * False
              * [raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/realtime/presence_spec.rb#L150)
          * if connection fails before success
            * [calls the Deferrable errback if channel is detached](./spec/acceptance/realtime/presence_spec.rb#L195)
    * #get
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/presence_spec.rb#L982)
      * [calls the Deferrable callback on success](./spec/acceptance/realtime/presence_spec.rb#L987)
      * [catches exceptions in the provided method block](./spec/acceptance/realtime/presence_spec.rb#L994)
      * [raise an exception if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L1002)
      * [raise an exception if the channel is failed](./spec/acceptance/realtime/presence_spec.rb#L1002)
      * [returns the current members on the channel](./spec/acceptance/realtime/presence_spec.rb#L1079)
      * [filters by connection_id option if provided](./spec/acceptance/realtime/presence_spec.rb#L1094)
      * [filters by client_id option if provided](./spec/acceptance/realtime/presence_spec.rb#L1116)
      * [does not wait for SYNC to complete if :wait_for_sync option is false](./spec/acceptance/realtime/presence_spec.rb#L1140)
      * during a sync
        * when :wait_for_sync is true
          * [fails if the connection fails](./spec/acceptance/realtime/presence_spec.rb#L1033)
          * [fails if the channel is detached](./spec/acceptance/realtime/presence_spec.rb#L1053)
      * when a member enters and then leaves
        * [has no members](./spec/acceptance/realtime/presence_spec.rb#L1150)
      * with lots of members on different clients
        * [returns a complete list of members on all clients](./spec/acceptance/realtime/presence_spec.rb#L1167)
    * #subscribe
      * with no arguments
        * [calls the callback for all presence events](./spec/acceptance/realtime/presence_spec.rb#L1203)
    * #unsubscribe
      * with no arguments
        * [removes the callback for all presence events](./spec/acceptance/realtime/presence_spec.rb#L1225)
    * REST #get
      * [returns current members](./spec/acceptance/realtime/presence_spec.rb#L1244)
      * [returns no members once left](./spec/acceptance/realtime/presence_spec.rb#L1257)
    * client_id with ASCII_8BIT
      * in connection set up
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L1274)
      * in channel options
        * [is converted into UTF_8](./spec/acceptance/realtime/presence_spec.rb#L1287)
    * encoding and decoding of presence message data
      * [encrypts presence message data](./spec/acceptance/realtime/presence_spec.rb#L1311)
      * #subscribe
        * [emits decrypted enter events](./spec/acceptance/realtime/presence_spec.rb#L1330)
        * [emits decrypted update events](./spec/acceptance/realtime/presence_spec.rb#L1342)
        * [emits previously set data for leave events](./spec/acceptance/realtime/presence_spec.rb#L1356)
      * #get
        * [returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L1372)
      * REST #get
        * [returns a list of members with decrypted data](./spec/acceptance/realtime/presence_spec.rb#L1385)
      * when cipher settings do not match publisher
        * [delivers an unencoded presence message left with encoding value](./spec/acceptance/realtime/presence_spec.rb#L1400)
        * [emits an error when cipher does not match and presence data cannot be decoded](./spec/acceptance/realtime/presence_spec.rb#L1413)
    * leaving
      * [expect :left event once underlying connection is closed](./spec/acceptance/realtime/presence_spec.rb#L1430)
      * [expect :left event with client data from enter event](./spec/acceptance/realtime/presence_spec.rb#L1440)
    * connection failure mid-way through a large member sync
      * [resumes the SYNC operation](./spec/acceptance/realtime/presence_spec.rb#L1458)

### Ably::Realtime::Client#stats
_(see [spec/acceptance/realtime/stats_spec.rb](./spec/acceptance/realtime/stats_spec.rb))_
  * using JSON and MsgPack protocol
    * fetching stats
      * [should return a PaginatedResult](./spec/acceptance/realtime/stats_spec.rb#L10)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/stats_spec.rb#L17)

### Ably::Realtime::Client#time
_(see [spec/acceptance/realtime/time_spec.rb](./spec/acceptance/realtime/time_spec.rb))_
  * using JSON and MsgPack protocol
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/realtime/time_spec.rb#L10)
      * [returns a SafeDeferrable that catches exceptions in callbacks and logs them](./spec/acceptance/realtime/time_spec.rb#L19)

### Ably::Auth
_(see [spec/acceptance/rest/auth_spec.rb](./spec/acceptance/rest/auth_spec.rb))_
  * using JSON and MsgPack protocol
    * [has immutable options](./spec/acceptance/rest/auth_spec.rb#L54)
    * #request_token
      * [returns a valid requested token in the expected format with valid issued and expires attributes](./spec/acceptance/rest/auth_spec.rb#L69)
      * with option :client_id
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L101)
      * with option :capability
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L101)
      * with option :nonce
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L101)
      * with option :timestamp
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L101)
      * with option :ttl
        * [overrides default and uses camelCase notation for attributes](./spec/acceptance/rest/auth_spec.rb#L101)
      * with :key option
        * [key_name is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L130)
      * with :key_name & :key_secret options
        * [key_name is used in request and signing uses key_secret](./spec/acceptance/rest/auth_spec.rb#L159)
      * with :query_time option
        * [queries the server for the time](./spec/acceptance/rest/auth_spec.rb#L167)
      * without :query_time option
        * [does not query the server for the time](./spec/acceptance/rest/auth_spec.rb#L176)
      * with :auth_url option
        * when response from :auth_url is a valid token request
          * [requests a token from :auth_url using an HTTP GET request](./spec/acceptance/rest/auth_spec.rb#L224)
          * [returns a valid token generated from the token request](./spec/acceptance/rest/auth_spec.rb#L229)
          * with :query_params
            * [requests a token from :auth_url with the :query_params](./spec/acceptance/rest/auth_spec.rb#L236)
          * with :headers
            * [requests a token from :auth_url with the HTTP headers set](./spec/acceptance/rest/auth_spec.rb#L244)
          * with POST
            * [requests a token from :auth_url using an HTTP POST instead of the default GET](./spec/acceptance/rest/auth_spec.rb#L252)
        * when response from :auth_url is a token details object
          * [returns TokenDetails created from the token JSON](./spec/acceptance/rest/auth_spec.rb#L277)
        * when response from :auth_url is text/plain content type and a token string
          * [returns TokenDetails created from the token JSON](./spec/acceptance/rest/auth_spec.rb#L294)
        * when response is invalid
          * 500
            * [raises ServerError](./spec/acceptance/rest/auth_spec.rb#L307)
          * XML
            * [raises InvalidResponseBody](./spec/acceptance/rest/auth_spec.rb#L318)
      * with a Proc for the :auth_callback option
        * that returns a TokenRequest
          * [calls the Proc when authenticating to obtain the request token](./spec/acceptance/rest/auth_spec.rb#L337)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L342)
        * that returns a TokenDetails JSON object
          * [calls the Proc when authenticating to obtain the request token](./spec/acceptance/rest/auth_spec.rb#L371)
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L376)
        * that returns a TokenDetails object
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L397)
        * that returns a Token string
          * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L413)
      * with client_id
        * [returns a token with the client_id](./spec/acceptance/rest/auth_spec.rb#L445)
    * before #authorise has been called
      * [has no current_token_details](./spec/acceptance/rest/auth_spec.rb#L452)
    * #authorise
      * [updates the persisted auth options that are then used for subsequent authorise requests](./spec/acceptance/rest/auth_spec.rb#L499)
      * when called for the first time since the client has been instantiated
        * [passes all options to #request_token](./spec/acceptance/rest/auth_spec.rb#L463)
        * [returns a valid token](./spec/acceptance/rest/auth_spec.rb#L468)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L472)
      * with previous authorisation
        * [does not request a token if current_token_details has not expired](./spec/acceptance/rest/auth_spec.rb#L483)
        * [requests a new token if token is expired](./spec/acceptance/rest/auth_spec.rb#L488)
        * [issues a new token if option :force => true](./spec/acceptance/rest/auth_spec.rb#L494)
      * with a Proc for the :auth_callback option
        * [calls the Proc](./spec/acceptance/rest/auth_spec.rb#L515)
        * [uses the token request returned from the callback when requesting a new token](./spec/acceptance/rest/auth_spec.rb#L519)
        * for every subsequent #request_token
          * without a :auth_callback Proc
            * [calls the originally provided block](./spec/acceptance/rest/auth_spec.rb#L525)
          * with a provided block
            * [does not call the originally provided Proc and calls the new #request_token :auth_callback Proc](./spec/acceptance/rest/auth_spec.rb#L532)
    * #create_token_request
      * [uses the key name from the client](./spec/acceptance/rest/auth_spec.rb#L548)
      * [uses the default TTL](./spec/acceptance/rest/auth_spec.rb#L552)
      * [uses the default capability](./spec/acceptance/rest/auth_spec.rb#L556)
      * the nonce
        * [is unique for every request](./spec/acceptance/rest/auth_spec.rb#L561)
        * [is at least 16 characters](./spec/acceptance/rest/auth_spec.rb#L566)
      * with option :ttl
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L577)
      * with option :nonce
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L577)
      * with option :client_id
        * [overrides default](./spec/acceptance/rest/auth_spec.rb#L577)
      * with additional invalid attributes
        * [are ignored](./spec/acceptance/rest/auth_spec.rb#L585)
      * when required fields are missing
        * [should raise an exception if key secret is missing](./spec/acceptance/rest/auth_spec.rb#L596)
        * [should raise an exception if key name is missing](./spec/acceptance/rest/auth_spec.rb#L600)
      * with :query_time option
        * [queries the server for the timestamp](./spec/acceptance/rest/auth_spec.rb#L609)
      * with :timestamp option
        * [uses the provided timestamp in the token request](./spec/acceptance/rest/auth_spec.rb#L619)
      * signing
        * [generates a valid HMAC](./spec/acceptance/rest/auth_spec.rb#L641)
    * using token authentication
      * with :token option
        * [authenticates successfully using the provided :token](./spec/acceptance/rest/auth_spec.rb#L664)
        * [disallows publishing on unspecified capability channels](./spec/acceptance/rest/auth_spec.rb#L668)
        * [fails if timestamp is invalid](./spec/acceptance/rest/auth_spec.rb#L676)
        * [cannot be renewed automatically](./spec/acceptance/rest/auth_spec.rb#L684)
      * when implicit as a result of using :client id
        * and requests to the Ably server are mocked
          * [will send a token request to the server](./spec/acceptance/rest/auth_spec.rb#L712)
        * a token is created
          * [before a request is made](./spec/acceptance/rest/auth_spec.rb#L721)
          * [when a message is published](./spec/acceptance/rest/auth_spec.rb#L725)
          * [with capability and TTL defaults](./spec/acceptance/rest/auth_spec.rb#L729)
    * when using an :key and basic auth
      * [#using_token_auth? is false](./spec/acceptance/rest/auth_spec.rb#L744)
      * [#key attribute contains the key string](./spec/acceptance/rest/auth_spec.rb#L748)
      * [#using_basic_auth? is true](./spec/acceptance/rest/auth_spec.rb#L752)

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
  * using JSON and MsgPack protocol
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
        * [should raise an InvalidToken exception](./spec/acceptance/rest/base_spec.rb#L158)

### Ably::Rest::Channel
_(see [spec/acceptance/rest/channel_spec.rb](./spec/acceptance/rest/channel_spec.rb))_
  * using JSON and MsgPack protocol
    * #publish
      * FAILED: ~~[should publish the message and return true indicating success](./spec/acceptance/rest/channel_spec.rb#L17)~~
    * #history
      * [should return the current message history for the channel](./spec/acceptance/rest/channel_spec.rb#L39)
      * [should return paged history using the PaginatedResult model](./spec/acceptance/rest/channel_spec.rb#L67)
      * message timestamps
        * [should all be after the messages were published](./spec/acceptance/rest/channel_spec.rb#L52)
      * message IDs
        * [should be unique](./spec/acceptance/rest/channel_spec.rb#L60)
    * #history option
      * :start
        * with milliseconds since epoch value
          * [uses this value in the history request](./spec/acceptance/rest/channel_spec.rb#L123)
        * with a Time object value
          * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/channel_spec.rb#L133)
      * :end
        * with milliseconds since epoch value
          * [uses this value in the history request](./spec/acceptance/rest/channel_spec.rb#L123)
        * with a Time object value
          * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/channel_spec.rb#L133)

### Ably::Rest::Channels
_(see [spec/acceptance/rest/channels_spec.rb](./spec/acceptance/rest/channels_spec.rb))_
  * using JSON and MsgPack protocol
    * using shortcut method #channel on the client object
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)
    * using #get method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)
    * using undocumented array accessor [] method on client#channels
      * behaves like a channel
        * [returns a channel object](./spec/acceptance/rest/channels_spec.rb#L6)
        * [returns channel object and passes the provided options](./spec/acceptance/rest/channels_spec.rb#L11)

### Ably::Rest::Client
_(see [spec/acceptance/rest/client_spec.rb](./spec/acceptance/rest/client_spec.rb))_
  * using JSON and MsgPack protocol
    * #initialize
      * with a :auth_callback Proc
        * [calls the auth Proc to get a new token](./spec/acceptance/rest/client_spec.rb#L20)
      * with an auth URL
        * [sends an HTTP request to the provided URL to get a new token](./spec/acceptance/rest/client_spec.rb#L34)
    * using tokens
      * when expired
        * [creates a new token automatically when the old token expires](./spec/acceptance/rest/client_spec.rb#L58)
      * when token has not expired
        * [reuses the existing token for every request](./spec/acceptance/rest/client_spec.rb#L72)
    * connection transport
      * for default host
        * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L88)
        * [is configured to timeout connection requests in 15 seconds](./spec/acceptance/rest/client_spec.rb#L92)
      * for the fallback hosts
        * [is configured to timeout connection opening in 4 seconds](./spec/acceptance/rest/client_spec.rb#L98)
        * [is configured to timeout connection requests in 15 seconds](./spec/acceptance/rest/client_spec.rb#L102)
    * fallback hosts
      * configured
        * [should make connection attempts to A.ably-realtime.com, B.ably-realtime.com, C.ably-realtime.com, D.ably-realtime.com, E.ably-realtime.com](./spec/acceptance/rest/client_spec.rb#L115)
      * when environment is NOT production
        * [does not retry failed requests with fallback hosts when there is a connection error](./spec/acceptance/rest/client_spec.rb#L132)
      * when environment is production
        * and connection times out
          * [tries fallback hosts 3 times](./spec/acceptance/rest/client_spec.rb#L172)
          * and the total request time exeeds 10 seconds
            * [makes no further attempts to any fallback hosts](./spec/acceptance/rest/client_spec.rb#L187)
        * and connection fails
          * [tries fallback hosts 3 times](./spec/acceptance/rest/client_spec.rb#L203)
    * with a custom host
      * that does not exist
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L219)
        * fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L240)
      * that times out
        * [fails immediately and raises a Faraday Error](./spec/acceptance/rest/client_spec.rb#L255)
        * fallback hosts
          * [are never used](./spec/acceptance/rest/client_spec.rb#L268)

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
  * using JSON and MsgPack protocol
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
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/rest/message_spec.rb#L68)
      * Float
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/rest/message_spec.rb#L76)
      * Boolean
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/rest/message_spec.rb#L84)
      * False
        * [is raises an UnsupportedDataTypeError 40011 exception](./spec/acceptance/rest/message_spec.rb#L92)
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
  * using JSON and MsgPack protocol
    * tested against presence fixture data set up in test app
      * #get
        * [returns current members on the channel with their action set to :present](./spec/acceptance/rest/presence_spec.rb#L41)
        * with :limit option
          * [returns a paged response limiting number of members per page](./spec/acceptance/rest/presence_spec.rb#L55)
      * #history
        * [returns recent presence activity](./spec/acceptance/rest/presence_spec.rb#L69)
        * with options
          * direction: :forwards
            * [returns recent presence activity forwards with most recent history last](./spec/acceptance/rest/presence_spec.rb#L85)
          * direction: :backwards
            * [returns recent presence activity backwards with most recent history first](./spec/acceptance/rest/presence_spec.rb#L100)
    * #history
      * with time range options
        * :start
          * with milliseconds since epoch value
            * [uses this value in the history request](./spec/acceptance/rest/presence_spec.rb#L152)
          * with Time object value
            * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/presence_spec.rb#L162)
        * :end
          * with milliseconds since epoch value
            * [uses this value in the history request](./spec/acceptance/rest/presence_spec.rb#L152)
          * with Time object value
            * [converts the value to milliseconds since epoch in the hisotry request](./spec/acceptance/rest/presence_spec.rb#L162)
    * decoding
      * with encoded fixture data
        * #history
          * [decodes encoded and encryped presence fixture data automatically](./spec/acceptance/rest/presence_spec.rb#L182)
        * #get
          * [decodes encoded and encryped presence fixture data automatically](./spec/acceptance/rest/presence_spec.rb#L189)
    * decoding permutations using mocked #history
      * valid decodeable content
        * #get
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L245)
        * #history
          * [automaticaly decodes presence messages](./spec/acceptance/rest/presence_spec.rb#L262)
      * invalid data
        * #get
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L293)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L297)
        * #history
          * [returns the messages still encoded](./spec/acceptance/rest/presence_spec.rb#L317)
          * [logs a cipher error](./spec/acceptance/rest/presence_spec.rb#L321)

### Ably::Rest::Client#stats
_(see [spec/acceptance/rest/stats_spec.rb](./spec/acceptance/rest/stats_spec.rb))_
  * using JSON and MsgPack protocol
    * fetching application stats
      * by minute
        * with :from set to last interval and :limit set to 1
          * [retrieves only one stat](./spec/acceptance/rest/stats_spec.rb#L50)
          * [returns zero value for any missing metrics](./spec/acceptance/rest/stats_spec.rb#L54)
          * [returns all aggregated message data](./spec/acceptance/rest/stats_spec.rb#L59)
          * [returns inbound realtime all data](./spec/acceptance/rest/stats_spec.rb#L64)
          * [returns inbound realtime message data](./spec/acceptance/rest/stats_spec.rb#L69)
          * [returns outbound realtime all data](./spec/acceptance/rest/stats_spec.rb#L74)
          * [returns persisted presence all data](./spec/acceptance/rest/stats_spec.rb#L79)
          * [returns connections all data](./spec/acceptance/rest/stats_spec.rb#L84)
          * [returns channels all data](./spec/acceptance/rest/stats_spec.rb#L89)
          * [returns api_requests data](./spec/acceptance/rest/stats_spec.rb#L94)
          * [returns token_requests data](./spec/acceptance/rest/stats_spec.rb#L99)
          * [returns stat objects with #interval_granularity equal to :minute](./spec/acceptance/rest/stats_spec.rb#L104)
          * [returns stat objects with #interval_id matching :start](./spec/acceptance/rest/stats_spec.rb#L108)
          * [returns stat objects with #interval_time matching :start Time](./spec/acceptance/rest/stats_spec.rb#L112)
        * with :start set to first interval, :limit set to 1 and direction :forwards
          * [returns the first interval stats as stats are provided forwards from :start](./spec/acceptance/rest/stats_spec.rb#L122)
          * [returns 3 pages of stats](./spec/acceptance/rest/stats_spec.rb#L126)
        * with :end set to last interval, :limit set to 1 and direction :backwards
          * [returns the 3rd interval stats first as stats are provided backwards from :end](./spec/acceptance/rest/stats_spec.rb#L139)
          * [returns 3 pages of stats](./spec/acceptance/rest/stats_spec.rb#L143)
      * by hour
        * [should aggregate the stats for that period](./spec/acceptance/rest/stats_spec.rb#L167)
      * by day
        * [should aggregate the stats for that period](./spec/acceptance/rest/stats_spec.rb#L167)
      * by month
        * [should aggregate the stats for that period](./spec/acceptance/rest/stats_spec.rb#L167)

### Ably::Rest::Client#time
_(see [spec/acceptance/rest/time_spec.rb](./spec/acceptance/rest/time_spec.rb))_
  * using JSON and MsgPack protocol
    * fetching the service time
      * [should return the service time as a Time object](./spec/acceptance/rest/time_spec.rb#L10)

### Ably::Auth
_(see [spec/unit/auth_spec.rb](./spec/unit/auth_spec.rb))_
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
  * defaults
    * [should default TTL to 1 hour](./spec/unit/auth_spec.rb#L73)
    * [should default capability to all](./spec/unit/auth_spec.rb#L77)
    * [should only have defaults for :ttl and :capability](./spec/unit/auth_spec.rb#L81)

### Ably::Logger
_(see [spec/unit/logger_spec.rb](./spec/unit/logger_spec.rb))_
  * [uses the language provided Logger by default](./spec/unit/logger_spec.rb#L15)
  * with a custom Logger
    * with an invalid interface
      * [raises an exception](./spec/unit/logger_spec.rb#L116)
    * with a valid interface
      * [is used](./spec/unit/logger_spec.rb#L135)

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
      * with invalid channel_option cipher params
        * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L87)
      * without any configured encryption
        * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L97)
      * with invalid cipher data
        * [raise an exception](./spec/unit/models/message_encoders/cipher_spec.rb#L106)
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
_(see [spec/unit/models/message_encoders/json_spec.rb](./spec/unit/models/message_encoders/json_spec.rb))_
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
    * [is the first page](./spec/unit/models/paginated_result_spec.rb#L172)
    * [is the last page](./spec/unit/models/paginated_result_spec.rb#L176)
    * [does not have next page](./spec/unit/models/paginated_result_spec.rb#L180)
    * [does not support pagination](./spec/unit/models/paginated_result_spec.rb#L184)
    * [returns nil when accessing next page](./spec/unit/models/paginated_result_spec.rb#L188)
    * [returns nil when accessing first page](./spec/unit/models/paginated_result_spec.rb#L192)
  * with paged http response
    * [is the first page](./spec/unit/models/paginated_result_spec.rb#L210)
    * [has next page](./spec/unit/models/paginated_result_spec.rb#L214)
    * [is not the last page](./spec/unit/models/paginated_result_spec.rb#L218)
    * [supports pagination](./spec/unit/models/paginated_result_spec.rb#L222)
    * accessing next page
      * [returns another PaginatedResult](./spec/unit/models/paginated_result_spec.rb#L250)
      * [retrieves the next page of results](./spec/unit/models/paginated_result_spec.rb#L254)
      * [is not the first page](./spec/unit/models/paginated_result_spec.rb#L259)
      * [does not have a next page](./spec/unit/models/paginated_result_spec.rb#L263)
      * [is the last page](./spec/unit/models/paginated_result_spec.rb#L267)
      * [returns nil when trying to access the last page when it is the last page](./spec/unit/models/paginated_result_spec.rb#L271)
      * and then first page
        * [returns a PaginatedResult](./spec/unit/models/paginated_result_spec.rb#L282)
        * [retrieves the first page of results](./spec/unit/models/paginated_result_spec.rb#L286)
        * [is the first page](./spec/unit/models/paginated_result_spec.rb#L290)

### Ably::Models::PresenceMessage
_(see [spec/unit/models/presence_message_spec.rb](./spec/unit/models/presence_message_spec.rb))_
  * behaves like a model
    * attributes
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
    * #issued with :issued option as milliseconds in constructor
      * [retrieves attribute :issued as Time](./spec/unit/models/token_details_spec.rb#L31)
    * #issued with :issued option as a Time in constructor
      * [retrieves attribute :issued as Time](./spec/unit/models/token_details_spec.rb#L40)
    * #issued when converted to JSON
      * [is in milliseconds](./spec/unit/models/token_details_spec.rb#L49)
    * #expires with :expires option as milliseconds in constructor
      * [retrieves attribute :expires as Time](./spec/unit/models/token_details_spec.rb#L31)
    * #expires with :expires option as a Time in constructor
      * [retrieves attribute :expires as Time](./spec/unit/models/token_details_spec.rb#L40)
    * #expires when converted to JSON
      * [is in milliseconds](./spec/unit/models/token_details_spec.rb#L49)
    * #expired?
      * once grace period buffer has passed
        * [is true](./spec/unit/models/token_details_spec.rb#L61)
      * within grace period buffer
        * [is false](./spec/unit/models/token_details_spec.rb#L69)
  * ==
    * [is true when attributes are the same](./spec/unit/models/token_details_spec.rb#L79)
    * [is false when attributes are not the same](./spec/unit/models/token_details_spec.rb#L84)
    * [is false when class type differs](./spec/unit/models/token_details_spec.rb#L88)

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
    * [should emit an event for any number of subscribers](./spec/unit/modules/event_emitter_spec.rb#L19)
    * [sends only messages to matching event names](./spec/unit/modules/event_emitter_spec.rb#L28)
    * #on subscribe to multiple events
      * [with the same block](./spec/unit/modules/event_emitter_spec.rb#L60)
    * event callback changes within the callback block
      * when new event callbacks are added
        * [is unaffected and processes the prior event callbacks once](./spec/unit/modules/event_emitter_spec.rb#L84)
        * [adds them for the next emitted event](./spec/unit/modules/event_emitter_spec.rb#L90)
      * when callbacks are removed
        * [is unaffected and processes the prior event callbacks once](./spec/unit/modules/event_emitter_spec.rb#L111)
        * [removes them for the next emitted event](./spec/unit/modules/event_emitter_spec.rb#L116)
  * #on
    * [calls the block every time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L129)
    * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L136)
  * #once
    * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L158)
    * [does not remove other blocks after it is called](./spec/unit/modules/event_emitter_spec.rb#L165)
    * [catches exceptions in the provided block, logs the error and continues](./spec/unit/modules/event_emitter_spec.rb#L173)
  * #unsafe_once
    * [calls the block the first time an event is emitted only](./spec/unit/modules/event_emitter_spec.rb#L181)
    * [does not catch exceptions in provided blocks](./spec/unit/modules/event_emitter_spec.rb#L188)
  * #off
    * with event names as arguments
      * [deletes matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L206)
      * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L211)
      * [continues if the block does not exist](./spec/unit/modules/event_emitter_spec.rb#L216)
    * without any event names
      * [deletes all matching callbacks](./spec/unit/modules/event_emitter_spec.rb#L223)
      * [deletes all callbacks if not block given](./spec/unit/modules/event_emitter_spec.rb#L228)

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
      * [without a block raises an invalid ArgumentError](./spec/unit/realtime/channel_spec.rb#L162)
      * [with no event name specified subscribes the provided block to all events](./spec/unit/realtime/channel_spec.rb#L166)
      * [with a single event name subscribes that block to matching events](./spec/unit/realtime/channel_spec.rb#L172)
      * [with a multiple event name arguments subscribes that block to all of those event names](./spec/unit/realtime/channel_spec.rb#L179)
      * [with a multiple duplicate event name arguments subscribes that block to all of those unique event names once](./spec/unit/realtime/channel_spec.rb#L191)
    * #unsubscribe
      * [with no event name specified unsubscribes that block from all events](./spec/unit/realtime/channel_spec.rb#L206)
      * [with a single event name argument unsubscribes the provided block with the matching event name](./spec/unit/realtime/channel_spec.rb#L212)
      * [with multiple event name arguments unsubscribes each of those matching event names with the provided block](./spec/unit/realtime/channel_spec.rb#L218)
      * [with a non-matching event name argument has no effect](./spec/unit/realtime/channel_spec.rb#L224)
      * [with no block argument unsubscribes all blocks for the event name argument](./spec/unit/realtime/channel_spec.rb#L230)

### Ably::Realtime::Channels
_(see [spec/unit/realtime/channels_spec.rb](./spec/unit/realtime/channels_spec.rb))_
  * creating channels
    * [#get creates a channel](./spec/unit/realtime/channels_spec.rb#L13)
    * [#get will reuse the channel object](./spec/unit/realtime/channels_spec.rb#L18)
    * [[] creates a channel](./spec/unit/realtime/channels_spec.rb#L24)
  * #fetch
    * [retrieves a channel if it exists](./spec/unit/realtime/channels_spec.rb#L31)
    * [calls the block if channel is missing](./spec/unit/realtime/channels_spec.rb#L36)
  * destroying channels
    * [#release detaches and then releases the channel resources](./spec/unit/realtime/channels_spec.rb#L44)
  * is Enumerable
    * [allows enumeration](./spec/unit/realtime/channels_spec.rb#L61)
    * [provides #length](./spec/unit/realtime/channels_spec.rb#L77)
    * #each
      * [returns an enumerator](./spec/unit/realtime/channels_spec.rb#L66)
      * [yields each channel](./spec/unit/realtime/channels_spec.rb#L70)

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
      * with a string key instead of options hash
        * [sets the key](./spec/shared/client_initializer_behaviour.rb#L103)
        * [sets the key_name](./spec/shared/client_initializer_behaviour.rb#L107)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L111)
      * with a string token key instead of options hash
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L119)
      * with token
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L127)
      * with token_details
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L135)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L141)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L148)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L167)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L158)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L162)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L174)
          * [specifies Logger::ERROR log level](./spec/shared/client_initializer_behaviour.rb#L178)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L186)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L204)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L208)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L218)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L223)
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
    * as Nil
      * [raises an argument error](./spec/unit/rest/channel_spec.rb#L104)

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
      * with a string key instead of options hash
        * [sets the key](./spec/shared/client_initializer_behaviour.rb#L103)
        * [sets the key_name](./spec/shared/client_initializer_behaviour.rb#L107)
        * [sets the key_secret](./spec/shared/client_initializer_behaviour.rb#L111)
      * with a string token key instead of options hash
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L119)
      * with token
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L127)
      * with token_details
        * [sets the token](./spec/shared/client_initializer_behaviour.rb#L135)
      * endpoint
        * [defaults to production](./spec/shared/client_initializer_behaviour.rb#L141)
        * with environment option
          * [uses an alternate endpoint](./spec/shared/client_initializer_behaviour.rb#L148)
      * tls
        * [defaults to TLS](./spec/shared/client_initializer_behaviour.rb#L167)
        * set to false
          * [uses plain text](./spec/shared/client_initializer_behaviour.rb#L158)
          * [uses HTTP](./spec/shared/client_initializer_behaviour.rb#L162)
      * logger
        * default
          * [uses Ruby Logger](./spec/shared/client_initializer_behaviour.rb#L174)
          * [specifies Logger::ERROR log level](./spec/shared/client_initializer_behaviour.rb#L178)
        * with log_level :none
          * [silences all logging with a NilLogger](./spec/shared/client_initializer_behaviour.rb#L186)
        * with custom logger and log_level
          * [uses the custom logger](./spec/shared/client_initializer_behaviour.rb#L204)
          * [sets the custom log level](./spec/shared/client_initializer_behaviour.rb#L208)
    * delegators
      * [delegates :client_id to .auth](./spec/shared/client_initializer_behaviour.rb#L218)
      * [delegates :auth_options to .auth](./spec/shared/client_initializer_behaviour.rb#L223)
  * initializer options
    * TLS
      * disabled
        * [fails for any operation with basic auth and attempting to send an API key over a non-secure connection](./spec/unit/rest/client_spec.rb#L17)
    * :use_token_auth
      * set to false
        * with an key with :tls => false
          * [fails for any operation with basic auth and attempting to send an API key over a non-secure connection](./spec/unit/rest/client_spec.rb#L28)
        * without an key
          * [fails as an key is required if not using token auth](./spec/unit/rest/client_spec.rb#L36)
      * set to true
        * without an key or token
          * [fails as an key is required to issue tokens](./spec/unit/rest/client_spec.rb#L46)

### Ably::Rest
_(see [spec/unit/rest/rest_spec.rb](./spec/unit/rest/rest_spec.rb))_
  * [constructor returns an Ably::Rest::Client](./spec/unit/rest/rest_spec.rb#L7)

### Ably::Util::Crypto
_(see [spec/unit/util/crypto_spec.rb](./spec/unit/util/crypto_spec.rb))_
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

  * Passing tests: 1092
  * Pending tests: 6
  * Failing tests: 0
