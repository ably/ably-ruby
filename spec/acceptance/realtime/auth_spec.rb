# encoding: utf-8
require 'spec_helper'

# Very high level test coverage of the Realtime::Auth object which is just an async
# wrapper around the Ably::Auth object
#
describe Ably::Realtime::Auth, :event_machine do
  def disconnect_transport(connection)
    if connection.transport
      connection.transport.close_connection_after_writing
    else
      EventMachine.next_tick { disconnect_transport connection }
    end
  end

  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }
    let(:client)          { auto_close Ably::Realtime::Client.new(client_options) }
    let(:auth)            { client.auth }

    context 'with basic auth' do
      context '#authentication_security_requirements_met?' do
        before do
          expect(client.use_tls?).to eql(true)
        end

        it 'returns true' do
          expect(auth.authentication_security_requirements_met?).to eql(true)
          stop_reactor
        end
      end

      context '#key' do
        it 'contains the API key' do
          expect(auth.key).to eql(api_key)
          stop_reactor
        end
      end

      context '#key_name' do
        it 'contains the API key name' do
          expect(auth.key_name).to eql(key_name)
          stop_reactor
        end
      end

      context '#key_secret' do
        it 'contains the API key secret' do
          expect(auth.key_secret).to eql(key_secret)
          stop_reactor
        end
      end

      context '#using_basic_auth?' do
        it 'is true when using Basic Auth' do
          expect(auth).to be_using_basic_auth
          stop_reactor
        end
      end

      context '#using_token_auth?' do
        it 'is false when using Basic Auth' do
          expect(auth).to_not be_using_token_auth
          stop_reactor
        end
      end
    end

    context 'with token auth' do
      let(:client_id)      { random_str }
      let(:client_options) { default_options.merge(client_id: client_id) }

      context '#client_id' do
        it 'contains the ClientOptions client ID' do
          expect(auth.client_id).to eql(client_id)
          stop_reactor
        end
      end

      context '#current_token_details' do
        it 'contains the current token after auth' do
          expect(auth.current_token_details).to be_nil
          auth.authorize do
            expect(auth.current_token_details).to be_a(Ably::Models::TokenDetails)
            stop_reactor
          end
        end
      end

      context '#token_renewable?' do
        it 'is true when an API key exists' do
          expect(auth).to be_token_renewable
          stop_reactor
        end
      end

      context '#options (auth_options)' do
        let(:token_str) { auth.request_token_sync.token }
        let(:auth_url) { "https://echo.ably.io/?type=text" }
        let(:auth_params) { { :body => token_str } }
        let(:client_options) { default_options.merge(auto_connect: false) }

        it 'contains the configured auth options' do
          auth.authorize({}, auth_url: auth_url, auth_params: auth_params) do
            expect(auth.options[:auth_url]).to eql(auth_url)
            stop_reactor
          end
        end
      end

      context '#token_params' do
        let(:custom_ttl) { 33 }

        it 'contains the configured auth options' do
          auth.authorize(ttl: custom_ttl) do
            expect(auth.token_params[:ttl]).to eql(custom_ttl)
            stop_reactor
          end
        end
      end

      context '#using_basic_auth?' do
        it 'is false when using Token Auth' do
          auth.authorize do
            expect(auth).to_not be_using_basic_auth
            stop_reactor
          end
        end
      end

      context '#using_token_auth?' do
        it 'is true when using Token Auth' do
          auth.authorize do
            expect(auth).to be_using_token_auth
            stop_reactor
          end
        end
      end
    end

    context 'methods' do
      let(:custom_ttl)       { 33 }
      let(:custom_client_id) { random_str }

      context '#create_token_request' do
        it 'returns a token request asynchronously' do
          auth.create_token_request(ttl: custom_ttl) do |token_request|
            expect(token_request).to be_a(Ably::Models::TokenRequest)
            expect(token_request.ttl).to eql(custom_ttl)
            stop_reactor
          end
        end
      end

      context '#create_token_request_async' do
        it 'returns a token request synchronously' do
          auth.create_token_request_sync(ttl: custom_ttl).tap do |token_request|
            expect(token_request).to be_a(Ably::Models::TokenRequest)
            expect(token_request.ttl).to eql(custom_ttl)
            stop_reactor
          end
        end
      end

      context '#request_token' do
        it 'returns a token asynchronously' do
          auth.request_token(client_id: custom_client_id, ttl: custom_ttl) do |token_details|
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.expires.to_i).to be_within(3).of(Time.now.to_i + custom_ttl)
            expect(token_details.client_id).to eql(custom_client_id)
            stop_reactor
          end
        end
      end

      context '#request_token_async' do
        it 'returns a token synchronously' do
          auth.request_token_sync(ttl: custom_ttl, client_id: custom_client_id).tap do |token_details|
            expect(token_details).to be_a(Ably::Models::TokenDetails)
            expect(token_details.expires.to_i).to be_within(3).of(Time.now.to_i + custom_ttl)
            expect(token_details.client_id).to eql(custom_client_id)
            stop_reactor
          end
        end
      end

      context '#authorize' do
        context 'with token auth' do
          let(:client_options) { default_options.merge(use_token_auth: true) }

          it 'returns a token asynchronously' do
            auth.authorize(ttl: custom_ttl, client_id: custom_client_id) do |token_details|
              expect(token_details).to be_a(Ably::Models::TokenDetails)
              expect(token_details.expires.to_i).to be_within(3).of(Time.now.to_i + custom_ttl)
              expect(token_details.client_id).to eql(custom_client_id)
              stop_reactor
            end
          end
        end

        context 'with auth_callback blocking' do
          let(:rest_auth_client) { Ably::Rest::Client.new(default_options.merge(key: api_key)) }
          let(:client_options)   { default_options.merge(auth_callback: auth_callback) }
          let(:pause)            { 5 }

          context 'with a slow auth callback response' do
            let(:auth_callback) do
              lambda do |token_params|
                sleep pause
                rest_auth_client.auth.request_token
              end
            end

            it 'asynchronously authenticates' do
              timers_called = 0
              block = lambda do
                timers_called += 1
                EventMachine.add_timer(0.5, &block)
              end
              block.call
              client.connect
              client.connection.on(:connected) do
                expect(timers_called).to be >= (pause-1) / 0.5
                stop_reactor
              end
            end
          end
        end

        context 'when implicitly called, with an explicit ClientOptions client_id' do
          let(:client_id)        { random_str }
          let(:client_options)   { default_options.merge(auth_callback: lambda { |token_params| auth_token_object }, client_id: client_id, log_level: :none) }
          let(:rest_auth_client) { Ably::Rest::Client.new(default_options.merge(key: api_key, client_id: 'invalid')) }

          context 'and an incompatible client_id in a TokenDetails object passed to the auth callback' do
            let(:auth_token_object) { rest_auth_client.auth.request_token }

            it 'rejects a TokenDetails object with an incompatible client_id and fails with an exception' do
              client.connect
              client.connection.on(:failed) do |state_change|
                expect(state_change.reason).to be_a(Ably::Exceptions::AuthenticationFailed)
                expect(state_change.reason.code).to eql(40012)
                EventMachine.add_timer(0.1) do
                  expect(client.connection).to be_failed
                  stop_reactor
                end
              end
            end
          end

          context 'and an incompatible client_id in a TokenRequest object passed to the auth callback and fails with an exception' do
            let(:auth_token_object) { rest_auth_client.auth.create_token_request }

            it 'rejects a TokenRequests object with an incompatible client_id and fails with an exception' do
              client.connect
              client.connection.on(:failed) do |state_change|
                expect(state_change.reason).to be_a(Ably::Exceptions::AuthenticationFailed)
                expect(state_change.reason.code).to eql(40012)
                EventMachine.add_timer(0.1) do
                  expect(client.connection).to be_failed
                  stop_reactor
                end
              end
            end
          end
        end

        context 'when explicitly called, with an explicit ClientOptions client_id' do
          let(:auth_proc) do
            lambda do |token_params|
              if !@requested
                @requested = true
                valid_auth_token
              else
                invalid_auth_token
              end
            end
          end

          let(:client_id)          { random_str }
          let(:client_options)     { default_options.merge(auth_callback: auth_proc, client_id: client_id, log_level: :none) }
          let(:valid_auth_token)   { Ably::Rest::Client.new(default_options.merge(key: api_key, client_id: client_id)).auth.request_token }
          let(:invalid_auth_token) { Ably::Rest::Client.new(default_options.merge(key: api_key, client_id: 'invalid')).auth.request_token }

          context 'and an incompatible client_id in a TokenDetails object passed to the auth callback' do
            it 'rejects a TokenDetails object with an incompatible client_id and fails with an exception' do
              client.connection.once(:connected) do
                client.auth.authorize({})
                client.connection.on(:failed) do |state_change|
                  expect(state_change.reason).to be_a(Ably::Exceptions::IncompatibleClientId)
                  expect(state_change.reason.code).to eql(40012)
                  EventMachine.add_timer(0.1) do
                    expect(client.connection).to be_failed
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        context 'when already authenticated with a valid token' do
          let(:rest_client)      { Ably::Rest::Client.new(default_options) }
          let(:client_publisher) { auto_close Ably::Realtime::Client.new(default_options) }
          let(:basic_capability) { JSON.dump("foo" => ["subscribe"]) }
          let(:basic_token_cb)   { lambda do |token_params|
            rest_client.auth.create_token_request({ capability: basic_capability })
          end }
          let(:upgraded_capability) { JSON.dump({ "foo" => ["subscribe", "publish"] }) }
          let(:upgraded_token_cb)   { lambda do |token_params|
            rest_client.auth.create_token_request({ capability: upgraded_capability })
          end }
          let(:identified_token_cb) { lambda do |token_params|
            rest_client.auth.create_token_request({ client_id: 'bob' })
          end }
          let(:downgraded_capability) { JSON.dump({ "bar" => ["subscribe"] }) }
          let(:downgraded_token_cb)   { lambda do |token_params|
            rest_client.auth.create_token_request({ capability: downgraded_capability })
          end }

          let(:client_options) { default_options.merge(auth_callback: basic_token_cb) }
          let(:connection) { client.connection }

          context 'when INITIALIZED' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb, auto_connect: false) }

            it 'obtains a token and connects to Ably (#RTC8c, #RTC8b1)' do
              has_connected = false
              EventMachine.add_timer(0.2) do
                expect(client.connection).to be_initialized
                connection.once(:connected) do
                  expect(client.auth.client_id).to_not be_nil
                  has_connected = true
                end
                client.auth.authorize(nil, auth_callback: identified_token_cb) do |token|
                  expect(token.client_id).to eql('bob')
                  EventMachine.add_timer(0.25) do
                    expect(has_connected).to be_truthy
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'when CONNECTING' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb) }

            it 'aborts the current connection process, obtains a token, and connects to Ably again (#RTC8b)' do
              connected_count = 0
              connection.once(:connecting) do
                connection.once(:connected) { connected_count += 1 }

                client.auth.authorize(nil, auth_callback: identified_token_cb) do |token|
                  expect(token.client_id).to eql('bob')
                  EventMachine.add_timer(0.25) do
                    expect(connected_count).to eql(1)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'when FAILED' do
            let(:client_options) { default_options.merge(token: 'this.token:is.invalid', log_level: :none) }

            it 'obtains a token and connects to Ably (#RTC8c, #RTC8b1)' do
              has_connected = false
              connection.once(:failed) do
                client.connection.once(:connected) do
                  has_connected = true
                end
                client.auth.authorize(nil, auth_callback: basic_token_cb) do
                  EventMachine.add_timer(0.25) do
                    expect(has_connected).to be_truthy
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'when CLOSED' do
            it 'obtains a token and connects to Ably (#RTC8c, #RTC8b1, #RTC8a3)' do
              has_connected = false
              connection.once(:connected) do
                connection.once(:closed) do
                  client.connection.once(:connected) do
                    has_connected = true
                  end
                  client.auth.authorize(nil, auth_callback: basic_token_cb) do
                    EventMachine.add_timer(0.25) do
                      expect(has_connected).to be_truthy
                      stop_reactor
                    end
                  end
                end
                connection.close
              end
            end
          end

          context 'when in the CONNECTED state' do
            context 'with a valid token in the AUTH ProtocolMessage sent' do
              let(:client_options) { default_options.merge(use_token_auth: true) }

              it 'obtains a new token (that upgrades from anonymous to identified) and upgrades the connection after receiving an updated CONNECTED ProtocolMessage (#RTC8a, #RTC8a3)' do
                skip "This capability to upgrade from anonymous to identified is not yet implemented, see https://github.com/ably/wiki/issues/182"

                client.connection.once(:connected) do
                  existing_token = client.auth.current_token_details
                  expect(client.connection.details.client_id).to be_nil
                  auth_sent = false
                  has_updated = false
                  new_connected_message_received = false

                  client.connection.once(:disconnected) { raise "Should not disconnnect during auth process"}
                  client.connection.once(:update) do
                    expect(auth_sent).to be_truthy
                    expect(new_connected_message_received).to be_truthy
                    expect(existing_token).to_not eql(client.auth.current_token_details)
                    expect(client.auth.client_id).to_not be_nil
                    expect(client.connection.details.client_id).to_not be_nil
                    has_updated = true
                  end

                  connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    auth_sent = true if protocol_message.action == :auth
                  end
                  connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    new_connected_message_received = true if protocol_message.action == :connected
                  end

                  client.auth.authorize(nil, auth_callback: identified_token_cb) do
                    EventMachine.add_timer(0.25) do
                      expect(has_updated).to be_truthy
                      stop_reactor
                    end
                  end
                end
              end

              it 'obtains a new token (as anonymous user before & after) and upgrades the connection after receiving an updated CONNECTED ProtocolMessage (#RTC8a, #RTC8a3)' do
                client.connection.once(:connected) do
                  existing_token = client.auth.current_token_details
                  auth_sent = false
                  has_updated = false
                  new_connected_message_received = false

                  client.connection.once(:disconnected) { raise "Should not disconnnect during auth process"}
                  client.connection.once(:update) do
                    EventMachine.next_tick do
                      expect(auth_sent).to be_truthy
                      expect(new_connected_message_received).to be_truthy
                      expect(existing_token).to_not eql(client.auth.current_token_details)
                      has_updated = true
                    end
                  end

                  connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    auth_sent = true if protocol_message.action == :auth
                  end
                  connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    new_connected_message_received = true if protocol_message.action == :connected
                  end

                  client.auth.authorize do
                    EventMachine.add_timer(0.25) do
                      expect(has_updated).to be_truthy
                      stop_reactor
                    end
                  end
                end
              end
            end
          end

          context 'when DISCONNECTED' do
            it 'obtains a token, upgrades from anonymous to identified, and connects to Ably immediately (#RTC8c, #RTC8b1)' do
              skip "This capability to upgrade from anonymous to identified is not yet implemented, see https://github.com/ably/wiki/issues/182"

              disconnected_waiting = false
              has_connected = false

              connection.once(:connected) do
                expect(client.auth.client_id).to be_nil

                connection.on(:disconnected) do |connection_state_change|
                  # Once we detect the connection will remain DISCONNECTED for 15s, then we can call authorize
                  # else we can't be sure authorize was responsible for the reconnect
                  if connection_state_change.retry_in > 1
                    disconnected_waiting = true

                    client.connection.once(:connected) do
                      expect(client.auth.client_id).to_not be_nil
                      has_connected = true
                    end

                    client.auth.authorize(nil, auth_callback: identified_token_cb) do
                      EventMachine.add_timer(0.25) do
                        expect(has_connected).to be_truthy
                        stop_reactor
                      end
                    end
                  end
                end

                connection.on(:connecting) do
                  disconnect_transport connection unless disconnected_waiting
                end
                disconnect_transport connection
              end
            end

            it 'obtains a similar anonymous token and connects to Ably immediately (#RTC8c, #RTC8b1)' do
              disconnected_waiting = false
              has_connected = false

              connection.once(:connected) do
                expect(client.auth.client_id).to be_nil

                connection.on(:disconnected) do |connection_state_change|
                  # Once we detect the connection will remain DISCONNECTED for 15s, then we can call authorize
                  # else we can't be sure authorize was responsible for the reconnect
                  if connection_state_change.retry_in > 1
                    disconnected_waiting = true

                    client.connection.once(:connected) do
                      expect(client.auth.client_id).to be_nil
                      has_connected = true
                    end

                    client.auth.authorize do
                      EventMachine.add_timer(0.25) do
                        expect(has_connected).to be_truthy
                        stop_reactor
                      end
                    end
                  end
                end

                connection.on(:connecting) do
                  disconnect_transport connection unless disconnected_waiting
                end
                disconnect_transport connection
              end
            end
          end

          context 'when SUSPENDED' do
            let(:client_options) do
              default_options.merge(
                disconnected_retry_timeout: 0.1,
                max_connection_state_ttl: 0.3,
                use_token_auth: true
              )
            end

            it 'obtains a token and connects to Ably immediately (#RTC8c, #RTC8b1)' do
              been_suspended = false
              has_connected = false

              connection.once(:connected) do
                connection.on(:suspended) do |connection_state_change|
                  been_suspended = true

                  client.connection.once(:connected) do
                    has_connected = true
                  end

                  client.auth.authorize do
                    EventMachine.add_timer(0.25) do
                      expect(has_connected).to be_truthy
                      stop_reactor
                    end
                  end
                end

                connection.on(:connecting) do
                  disconnect_transport connection unless been_suspended
                end
                disconnect_transport connection
              end
            end
          end

          context 'when client is identified' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb, log_level: :none) }

            let(:basic_token_cb)   { lambda do |token_params|
              rest_client.auth.create_token_request({ client_id: 'mike', capability: basic_capability })
            end }

            it 'transitions the connection state to FAILED if the client_id changes (#RSA15c, #RTC8a2)' do
              client.connection.once(:connected) do
                client.auth.authorize(nil, auth_callback: identified_token_cb)
                client.connection.once(:failed) do
                  expect(client.connection.error_reason.message).to match(/incompatible.*clientId/i)
                  expect(client.connection.error_reason.code).to eql(40012)
                  stop_reactor
                end
              end
            end
          end

          context 'when auth fails' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb, log_level: :none) }
            let!(:token_string) { client.rest_client.auth.request_token.token }

            it 'transitions the connection state to the FAILED state (#RSA15c, #RTC8a2, #RTC8a3)' do
              connection_failed = false

              client.connection.once(:connected) do
                client.auth.authorize(nil, auth_callback: lambda { |token_params| "#{app_id}.invalid.token.will.cause.failure" }).tap do |deferrable|
                  deferrable.errback do |error|
                    EventMachine.add_timer(0.2) do
                      expect(connection_failed).to eql(true)
                      expect(error.message).to match(/invalid.*accessToken/i)
                      expect(error.code).to eql(40005)
                      stop_reactor
                    end
                  end
                  deferrable.callback { raise "Authorize should not succed" }
                end
              end

              client.connection.once(:failed) do
                expect(client.connection.error_reason.message).to match(/invalid.*accessToken/i)
                expect(client.connection.error_reason.code).to eql(40005)
                connection_failed = true
              end
            end
          end

          context 'when the authCallback fails' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb, log_level: :none) }

            it 'calls the error callback of authorize and leaves the connection intact (#RSA4c3)' do
              client.connection.once(:connected) do
                client.auth.authorize(nil, auth_callback: lambda { |token_params| raise 'Exception raised' }).errback do |error|
                  EventMachine.add_timer(0.2) do
                    expect(connection).to be_connected
                    expect(error.message).to match(/Exception raised/i)
                    stop_reactor
                  end
                end
                client.connection.once(:failed) do
                  raise "Connection should not fail"
                end
              end
            end
          end

          context 'when upgrading capabilities' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb, log_level: :error) }

            it 'is allowed (#RTC8a1)' do
              client.connection.once(:connected) do
                client.connection.once(:disconnected) { raise 'Upgrade does not require a disconnect' }

                channel = client.channels.get('foo')
                channel.attach do
                  channel.publish('not-allowed').errback do |error|
                    expect(error.code).to eql(40160)
                    expect(error.message).to match(/permission denied/)

                    client.auth.authorize(nil, auth_callback: upgraded_token_cb)
                    client.connection.once(:update) do
                      expect(client.connection.error_reason).to be_nil
                      channel.subscribe('now-allowed') do |message|
                        stop_reactor
                      end
                      channel.publish 'now-allowed'
                    end
                  end
                end
              end
            end
          end

          context 'when downgrading capabilities (#RTC8a1)' do
            let(:client_options) { default_options.merge(auth_callback: basic_token_cb, log_level: :none) }

            it 'is allowed and channels are detached' do
              client.connection.once(:connected) do
                client.connection.once(:disconnected) { raise 'Upgrade does not require a disconnect' }

                channel = client.channels.get('foo')
                channel.attach do
                  client.auth.authorize(nil, auth_callback: downgraded_token_cb)
                  channel.once(:failed) do
                    expect(channel.error_reason.code).to eql(40160)
                    expect(channel.error_reason.message).to match(/Channel denied access/)
                    stop_reactor
                  end
                end
              end
            end
          end

          it 'ensures message delivery continuity whilst upgrading (#RTC8a1)' do
            received_messages = []
            subscriber_channel = client.channels.get('foo')
            publisher_channel  = client_publisher.channels.get('foo')
            subscriber_channel.attach do
              client.connection.once(:disconnected) { raise 'Upgrade does not require a disconnect' }

              subscriber_channel.subscribe do |message|
                received_messages << message
              end
              publisher_channel.attach do
                publisher_channel.publish('foo') do
                  EventMachine.add_timer(2) do
                    expect(received_messages.length).to eql(1)

                    client.connection.once(:update) do
                      EventMachine.add_timer(2) do
                        expect(received_messages.length).to eql(2)
                        stop_reactor
                      end
                    end

                    client.auth.authorize(nil)

                    publisher_channel.publish('bar')
                  end
                end
              end
            end
          end
        end
      end

      context '#authorize_async' do
        it 'returns a token synchronously' do
          auth.authorize_sync(ttl: custom_ttl, client_id: custom_client_id).tap do |token_details|
            expect(auth.authorize_sync).to be_a(Ably::Models::TokenDetails)
            expect(token_details.expires.to_i).to be_within(3).of(Time.now.to_i + custom_ttl)
            expect(token_details.client_id).to eql(custom_client_id)
            stop_reactor
          end
        end
      end
    end

    context 'server initiated AUTH ProtocolMessage' do
      before do
        stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0 # allow token to be used even if about to expire
        stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0) # Ensure tokens issued expire immediately after issue
      end

      context 'when received' do
        # Ably will send AUTH 30 seconds before expiry
        let(:client_options) { default_options.merge(use_token_auth: :true, default_token_params: { ttl: 33 }) }

        it 'should immediately start a new authentication process (#RTN22)' do
          client.connection.once(:connected) do
            original_token = auth.current_token_details
            received_auth = false

            client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              received_auth = true if protocol_message.action == :auth
            end

            client.connection.once(:update) do
              expect(received_auth).to be_truthy
              expect(original_token).to_not eql(auth.current_token_details)
              stop_reactor
            end
          end
        end
      end

      context 'when not received' do
        # Ably in all environments other than production will send AUTH 5 seconds before expiry, so
        # set TTL to 5s so that the window for Realtime to send has passed
        let(:client_options) { default_options.merge(use_token_auth: :true, default_token_params: { ttl: 5 }) }

        it 'should expect the connection to be disconnected by the server but should resume automatically (#RTN22a)' do
          client.connection.once(:connected) do
            original_token = auth.current_token_details
            original_conn_id = client.connection.id
            received_auth = false

            client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              received_auth = true if protocol_message.action == :auth
            end

            client.connection.once(:disconnected) do |state_change|
              expect(state_change.reason.code).to eql(40142)

              client.connection.once(:connected) do
                expect(received_auth).to be_falsey
                expect(original_token).to_not eql(auth.current_token_details)
                expect(original_conn_id).to eql(client.connection.id)
                stop_reactor
              end
            end
          end
        end
      end
    end

    context '#auth_params' do
      it 'returns the auth params asynchronously' do
        auth.auth_params do |auth_params|
          expect(auth_params).to be_a(Hash)
          stop_reactor
        end
      end
    end

    context '#auth_params_sync' do
      it 'returns the auth params synchronously' do
        expect(auth.auth_params_sync).to be_a(Hash)
        stop_reactor
      end
    end

    context '#auth_header' do
      it 'returns an auth header asynchronously' do
        auth.auth_header do |auth_header|
          expect(auth_header).to be_a(String)
          stop_reactor
        end
      end
    end

    context '#auth_header_sync' do
      it 'returns an auth header synchronously' do
        expect(auth.auth_header_sync).to be_a(String)
        stop_reactor
      end
    end

    describe '#client_id_validated?' do
      let(:auth) { Ably::Rest::Client.new(default_options.merge(key: api_key)).auth }

      context 'when using basic auth' do
        let(:client_options) { default_options.merge(key: api_key) }

        context 'before connected' do
          it 'is false as basic auth users do not have an identity' do
            expect(client.auth).to_not be_client_id_validated
            stop_reactor
          end
        end

        context 'once connected' do
          it 'is true' do
            client.connection.once(:connected) do
              expect(client.auth).to be_client_id_validated
              stop_reactor
            end
          end

          it 'contains a validated wildcard client_id' do
            client.connection.once(:connected) do
              expect(client.auth.client_id).to eql('*')
              stop_reactor
            end
          end
        end
      end

      context 'when using a token string' do
        context 'with a valid client_id' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: 'present').token) }

          context 'before connected' do
            it 'is false as identification is not possible from an opaque token string' do
              expect(client.auth).to_not be_client_id_validated
              stop_reactor
            end

            specify '#client_id is nil' do
              expect(client.auth.client_id).to be_nil
              stop_reactor
            end
          end

          context 'once connected' do
            it 'is true' do
              client.connection.once(:connected) do
                expect(client.auth).to be_client_id_validated
                stop_reactor
              end
            end

            specify '#client_id is populated' do
              client.connection.once(:connected) do
                expect(client.auth.client_id).to eql('present')
                stop_reactor
              end
            end
          end
        end

        context 'with no client_id (anonymous)' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: nil).token) }

          context 'before connected' do
            it 'is false as identification is not possible from an opaque token string' do
              expect(client.auth).to_not be_client_id_validated
              stop_reactor
            end
          end

          context 'once connected' do
            it 'is true' do
              client.connection.once(:connected) do
                expect(client.auth).to be_client_id_validated
                stop_reactor
              end
            end
          end
        end

        context 'with a wildcard client_id (anonymous)' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: '*').token) }

          context 'before connected' do
            it 'is false as identification is not possible from an opaque token string' do
              expect(client.auth).to_not be_client_id_validated
              stop_reactor
            end
          end

          context 'once connected' do
            it 'is true' do
              client.connection.once(:connected) do
                expect(client.auth).to be_client_id_validated
                stop_reactor
              end
            end
          end
        end
      end

      context 'when using a token' do
        context 'with a client_id' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: 'present')) }

          it 'is true' do
            expect(client.auth).to be_client_id_validated
            stop_reactor
          end

          context 'once connected' do
            it 'is true' do
              client.connection.once(:connected) do
                expect(client.auth).to be_client_id_validated
                stop_reactor
              end
            end
          end
        end

        context 'with no client_id (anonymous)' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: nil)) }

          it 'is true' do
            expect(client.auth).to be_client_id_validated
            stop_reactor
          end

          context 'once connected' do
            it 'is true' do
              client.connection.once(:connected) do
                expect(client.auth).to be_client_id_validated
                stop_reactor
              end
            end
          end
        end

        context 'with a wildcard client_id (anonymous)' do
          let(:client_options) { default_options.merge(token: auth.request_token(client_id: '*')) }

          it 'is true' do
            expect(client.auth).to be_client_id_validated
            stop_reactor
          end

          context 'once connected' do
            it 'is true' do
              client.connection.once(:connected) do
                expect(client.auth).to be_client_id_validated
                stop_reactor
              end
            end
          end
        end
      end

      context 'when using a token request with a client_id' do
        let(:client_options) { default_options.merge(token: auth.create_token_request(client_id: 'present')) }

        it 'is not true as identification is not confirmed until authenticated' do
          expect(client.auth).to_not be_client_id_validated
          stop_reactor
        end

        context 'once connected' do
          it 'is true as identification is completed following CONNECTED ProtocolMessage' do
            client.channel('test').publish('a') do
              expect(client.auth).to be_client_id_validated
              stop_reactor
            end
          end
        end
      end
    end

    context 'deprecated #authorise', :prevent_log_stubbing do
      let(:client_options)  { default_options.merge(key: api_key, logger: custom_logger_object, use_token_auth: true) }
      let(:custom_logger_object) { TestLogger.new }

      it 'logs a deprecation warning (#RSA10l)' do
        client.auth.authorise
        expect(custom_logger_object.logs.find { |severity, message| message.match(/authorise.*deprecated/i)} ).to_not be_nil
        stop_reactor
      end

      it 'returns a valid token (#RSA10l)' do
        client.auth.authorise do |response|
          expect(response).to be_a(Ably::Models::TokenDetails)
          stop_reactor
        end
      end
    end

    context 'when using JWT' do
      let(:auth_url) { 'https://echo.ably.io/createJWT' }
      let(:auth_params) { { keyName: key_name, keySecret: key_secret } }
      let(:channel_name) { "test_JWT_#{random_str}" }
      let(:message_name) { 'message_JWT' }

      # RSA8g
      context 'when using auth_url' do
        let(:client_options) { default_options.merge(auth_url: auth_url, auth_params: auth_params) }

        context 'when credentials are valid' do
          it 'client successfully fetches a channel and publishes a message' do
            channel = client.channels.get(channel_name)
            channel.subscribe do |message|
              expect(message.name).to eql(message_name)
              stop_reactor
            end
            channel.publish message_name
          end
        end

        context 'when credentials are wrong' do
          let(:auth_params) { { keyName: key_name, keySecret: 'invalid' } }

          it 'disconnected includes and invalid signature message' do
            client.connection.once(:disconnected) do |state_change|
              expect(state_change.reason.message.match(/invalid signature/i)).to_not be_nil
              expect(state_change.reason.code).to eql(40144)
              stop_reactor
            end
            client.connect
          end
        end

        context 'when token is expired' do
          let(:token_duration) { 5 }
          let(:auth_params) { { keyName: key_name, keySecret: key_secret, expiresIn: token_duration } }
          it 'receives a 40142 error from the server' do
            client.connection.once(:connected) do
              client.connection.once(:disconnected) do |state_change|
                expect(state_change.reason).to be_a(Ably::Models::ErrorInfo)
                expect(state_change.reason.message).to match(/(expire)/i)
                expect(state_change.reason.code).to eql(40142)
                stop_reactor
              end
            end
          end
        end
      end

      # RSA8g
      context 'when using auth_callback' do
        let(:token_callback) do
          lambda do |token_params|
            Ably::Rest::Client.new(default_options).auth.request_token({}, { auth_url: auth_url, auth_params: auth_params }).token
          end
        end
        let(:client_options) { default_options.merge(auth_callback: token_callback) }
        WebMock.allow_net_connect!
        WebMock.disable!
        context 'when credentials are valid' do

          it 'authentication succeeds and client can post a message' do
            channel = client.channels.get(channel_name)
            channel.subscribe do |message|
              expect(message.name).to eql(message_name)
              stop_reactor
            end
            channel.publish(message_name) do
              # assert_requested :get, Addressable::Template.new("#{auth_url}{?keyName,keySecret}")
            end
          end
        end

        context 'when credentials are invalid' do
          let(:auth_params) { { keyName: key_name, keySecret: 'invalid' } }

          it 'authentication fails and reason for disconnection is invalid signature' do
            client.connection.once(:disconnected) do |state_change|
              expect(state_change.reason.message.match(/invalid signature/i)).to_not be_nil
              expect(state_change.reason.code).to eql(40144)
              stop_reactor
            end
            client.connect
          end
        end
      end

      context 'when the client is initialized with ClientOptions and the token is a JWT token' do
        let(:client_options) { { token: token, environment: environment, protocol: protocol } }

        context 'when credentials are valid' do
          let(:token) { Faraday.get("#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}").body }

          it 'posts successfully to a channel' do
            channel = client.channels.get(channel_name)
            channel.subscribe do |message|
              expect(message.name).to eql(message_name)
              stop_reactor
            end
            channel.publish(message_name)
          end
        end

        context 'when credentials are invalid' do
          let(:key_secret) { 'invalid' }
          let(:token) { Faraday.get("#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}").body }
          let(:client_options) { { token: token, environment: environment, protocol: protocol, log_level: :none } }

          it 'fails with an invalid signature error' do
            client.connection.once(:disconnected) do |state_change|
              expect(state_change.reason.message.match(/invalid signature/i)).to_not be_nil
              expect(state_change.reason.code).to eql(40144)
              stop_reactor
            end
            client.connect
          end
        end
      end

      context 'when JWT token expires' do
        before do
          stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0 # allow token to be used even if about to expire
          stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0) # Ensure tokens issued expire immediately after issue
        end
        let(:token_callback) do
          lambda do |token_params|
            # Ably in all environments other than production will send AUTH 5 seconds before expiry, so
            # we generate a JWT that expires in 5s so that the window for Realtime to send has passed
            tokenResponse = Faraday.get "#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}&expiresIn=5"
            tokenResponse.body
          end
        end
        let(:client_options) { default_options.merge(use_token_auth: true, auth_callback: token_callback) }

        # RTC8a
        it 'client disconnects, a new token is requested via auth_callback and the client gets reconnected' do
          client.connection.once(:connected) do
            original_token = auth.current_token_details
            original_conn_id = client.connection.id

            client.connection.once(:disconnected) do |state_change|
              expect(state_change.reason.code).to eql(40142)

              client.connection.once(:connected) do
                expect(original_token).to_not eql(auth.current_token_details)
                expect(original_conn_id).to eql(client.connection.id)
                stop_reactor
              end
            end
          end
        end

        context 'and an AUTH procol message is received' do
          let(:token_callback) do
            lambda do |token_params|
              # Ably in all environments other than local will send AUTH 30 seconds before expiry
              # We set the TTL to 35s so there's room to receive an AUTH protocol message
              tokenResponse = Faraday.get "#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}&expiresIn=35"
              tokenResponse.body
            end
          end

          # RTC8a, RTC8a4
          it 'client reauths correctly without going through a disconnection' do
            client.connection.once(:connected) do
              original_token = client.auth.current_token_details
              received_auth = false

              client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                received_auth = true if protocol_message.action == :auth
              end

              client.connection.once(:update) do
                expect(received_auth).to be_truthy
                expect(original_token).to_not eql(client.auth.current_token_details)
                stop_reactor
              end
            end
          end
        end
      end

      context 'when the JWT token request includes a client_id' do
        let(:client_id) { random_str }
        let(:auth_callback) do
          lambda do |token_params|
            Faraday.get("#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}&client_id=#{client_id}").body
          end
        end
        let(:client_options) { default_options.merge(auth_callback: auth_callback) }

        it 'the client_id is the same that was specified in the auth_callback that generated the JWT token' do
          client.connection.once(:connected) do
            expect(client.auth.client_id).to eql(client_id)
            stop_reactor
          end
        end
      end

      context 'when the JWT token request includes a subscribe-only capability' do
        let(:channel_with_publish_permissions) { "test_JWT_with_publish_#{random_str}" }
        let(:basic_capability) { JSON.dump(channel_name => ['subscribe'], channel_with_publish_permissions => ['publish']) }
        let(:auth_callback) do
          lambda do |token_params|
            Faraday.get("#{auth_url}?keyName=#{key_name}&keySecret=#{key_secret}&capability=#{URI.escape(basic_capability)}").body
          end
        end
        let(:client_options) { default_options.merge(auth_callback: auth_callback, log_level: :error) }

        it 'client fails to publish to a channel with subscribe-only capability and publishes successfully on a channel with permissions' do
          client.connection.once(:connected) do
            forbidden_channel = client.channels.get(channel_name)
            allowed_channel = client.channels.get(channel_with_publish_permissions)
            forbidden_channel.publish('not-allowed').errback do |error|
              expect(error.code).to eql(40160)
              expect(error.message).to match(/permission denied/)

              allowed_channel.publish(message_name) do |message|
                expect(message.name).to eql(message_name)
                stop_reactor
              end
            end
          end
        end
      end
    end
  end
end
