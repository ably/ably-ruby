# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Connection, 'failures', :event_machine do
  let(:connection) { client.connection }

  vary_by_protocol do
    let(:default_options) do
      { key: api_key, environment: environment, protocol: protocol }
    end

    let(:client_options) { default_options }
    let(:client) do
      auto_close Ably::Realtime::Client.new(client_options)
    end
    let(:rest_client) do
      Ably::Rest::Client.new(default_options)
    end

    context 'authentication failure' do
      let(:client_options) do
        default_options.merge(key: invalid_key, log_level: :none)
      end

      context 'when API key is invalid' do
        context 'with invalid app part of the key' do
          let(:invalid_key) { 'not_an_app.invalid_key_name:invalid_key_value' }

          it 'enters the failed state and returns a not found error' do
            connection.on(:failed) do |connection_state_change|
              error = connection_state_change.reason
              expect(connection.state).to eq(:failed)
              # TODO: Check error type is an InvalidToken exception
              expect(error.status).to eq(404)
              expect(error.code).to eq(40400) # not found
              stop_reactor
            end
          end
        end

        context 'with invalid key name part of the key' do
          let(:invalid_key) { "#{app_id}.invalid_key_name:invalid_key_value" }

          it 'enters the failed state and returns an authorization error' do
            connection.on(:failed) do |connection_state_change|
              error = connection_state_change.reason
              expect(connection.state).to eq(:failed)
              # TODO: Check error type is a TokenNotFound exception
              expect(error.status).to eq(401)
              expect(error.code).to eq(40400) # not found
              stop_reactor
            end
          end
        end
      end

      context 'with auth_url' do
        context 'opening a new connection' do
          context 'request fails due to network failure' do
            let(:client_options) { default_options.reject { |k, v| k == :key }.merge(auth_url: "http://#{random_str}.domain.will.never.resolve.to/path", log_level: :fatal) }

            specify 'the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)' do
              states = Hash.new { |hash, key| hash[key] = [] }

              connection.once(:connected) { raise "Connection can never move to connected because of auth failures" }

              connection.on do |connection_state|
                states[connection_state.current.to_sym] << Time.now
                if states[:disconnected].count == 2 && connection_state.current == :disconnected
                  expect(connection.error_reason).to be_a(Ably::Exceptions::ConnectionError)
                  expect(connection.error_reason.message).to match(/auth_url/)
                  EventMachine.add_timer(2) do
                    expect(states.keys).to include(:connecting, :disconnected)
                    expect(states[:connecting].count).to eql(2)
                    expect(states[:connected].count).to eql(0)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'request fails due to invalid content', :webmock do
            let(:auth_endpoint) { "http://#{random_str}.domain.will.never.resolve.to/authenticate" }
            let(:client_options) { default_options.reject { |k, v| k == :key }.merge(auth_url: auth_endpoint, log_level: :fatal) }

            before do
               stub_request(:get, auth_endpoint).
                 to_return(:status => 200, :body => "", :headers => { "Content-type" => "text/html" })
            end

            specify 'the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)' do
              states = Hash.new { |hash, key| hash[key] = [] }

              connection.once(:connected) { raise "Connection can never move to connected because of auth failures" }

              connection.on do |connection_state|
                states[connection_state.current.to_sym] << Time.now
                if states[:disconnected].count == 2 && connection_state.current == :disconnected
                  expect(connection.error_reason).to be_a(Ably::Exceptions::ConnectionError)
                  expect(connection.error_reason.message).to match(/auth_url/)
                  expect(connection.error_reason.message).to match(/Content Type.*not supported/)
                  EventMachine.add_timer(2) do
                    expect(states.keys).to include(:connecting, :disconnected)
                    expect(states[:connecting].count).to eql(2)
                    expect(states[:connected].count).to eql(0)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'request fails due to slow response and subsequent timeout', :webmock, em_timeout: (Ably::Rest::Client::HTTP_DEFAULTS.fetch(:request_timeout) + 5) * 2 do
            let(:auth_url) { "http://#{random_str}.domain.will.be.stubbed/path" }
            let(:client_options) { default_options.reject { |k, v| k == :key }.merge(auth_url: auth_url, log_level: :fatal) }

            # Timeout +5 seconds, beyond default allowed timeout
            before do
              stub_request(:get, auth_url).
                to_return do |request|
                  sleep Ably::Rest::Client::HTTP_DEFAULTS.fetch(:request_timeout) + 5
                  { status: [500, "Internal Server Error"] }
                end
            end

            specify 'the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)' do
              states = Hash.new { |hash, key| hash[key] = [] }

              connection.once(:connected) { raise "Connection can never move to connected because of auth failures" }

              connection.on do |connection_state|
                states[connection_state.current.to_sym] << Time.now
                if states[:disconnected].count == 2 && connection_state.current == :disconnected
                  expect(connection.error_reason).to be_a(Ably::Exceptions::ConnectionError)
                  expect(connection.error_reason.message).to match(/auth_url/)
                  EventMachine.add_timer(2) do
                    expect(states.keys).to include(:connecting, :disconnected)
                    expect(states[:connecting].count).to eql(2)
                    expect(states[:connected].count).to eql(0)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'request fails once due to slow response but succeeds the second time' do
            let(:auth_url) { "http://#{random_str}.domain.will.be.stubbed/path" }
            let(:client_options) { default_options.reject { |k, v| k == :key }.merge(auth_url: auth_url, log_level: :fatal) }

            # Timeout +5 seconds, beyond default allowed timeout
            before do
              token_response = Ably::Rest::Client.new(default_options).auth.request_token
              WebMock.enable!

              stub_request(:get, auth_url).
                to_return do |request|
                  sleep Ably::Rest::Client::HTTP_DEFAULTS.fetch(:request_timeout)
                  { status: [500, "Internal Server Error"] }
                end.then.
                to_return(:status => 201, :body => token_response.to_json, :headers => { 'Content-Type' => 'application/json' })
            end

            specify 'the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)' do
              states = Hash.new { |hash, key| hash[key] = [] }

              connection.once(:connected) do
                expect(states[:disconnected].count).to eql(1)
                expect(states[:connecting].count).to eql(2)
                stop_reactor
              end

              connection.on do |connection_state|
                states[connection_state.current.to_sym] << Time.now
              end
            end
          end
        end

        context 'existing CONNECTED connection' do
          context 'authorize request failure leaves connection in existing condition' do
            let(:auth_options) { { auth_url: "http://#{random_str}.domain.will.never.resolve.to/path" } }
            let(:client_options) { default_options.merge(use_token_auth: true, log_level: :fatal) }

            specify 'the connection remains in the CONNECTED state and authorize fails (#RSA4c, #RSA4c1, #RSA4c3)' do
              connection.once(:connected) do
                connection.on { raise "State should not change and should stay connected" }

                client.auth.authorize(nil, auth_options).tap do |deferrable|
                  deferrable.callback { raise "Authorize should not succeed" }
                  deferrable.errback do |err|
                    expect(err).to be_a(Ably::Exceptions::ConnectionError)
                    expect(err.message).to match(/auth_url/)

                    EventMachine.add_timer(1) do
                      expect(connection).to be_connected
                      connection.off
                      stop_reactor
                    end
                  end
                end
              end
            end
          end
        end
      end

      context 'with auth_callback' do
        context 'opening a new connection' do
          context 'when callback fails due to an exception' do
            let(:client_options) { default_options.reject { |k, v| k == :key }.merge(auth_callback: lambda { |token_params| raise "Cannot issue token" }, log_level: :fatal) }

            it 'the connection moves to the disconnected state and tries again, returning again to the disconnected state (#RSA4c, #RSA4c1, #RSA4c2)' do
              states = Hash.new { |hash, key| hash[key] = [] }

              connection.once(:connected) { raise "Connection can never move to connected because of auth failures" }

              connection.on do |connection_state|
                states[connection_state.current.to_sym] << Time.now
                if states[:disconnected].count == 2 && connection_state.current == :disconnected
                  expect(connection.error_reason).to be_a(Ably::Exceptions::ConnectionError)
                  expect(connection.error_reason.message).to match(/auth_callback/)
                  EventMachine.add_timer(2) do
                    expect(states.keys).to include(:connecting, :disconnected)
                    expect(states[:connecting].count).to eql(2)
                    expect(states[:connected].count).to eql(0)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'existing CONNECTED connection' do
            context 'when callback fails due to the request taking longer than realtime_request_timeout' do
              let(:request_timeout) { 3 }
              let(:client_options) { default_options.merge(
                realtime_request_timeout: request_timeout,
                use_token_auth: true,
                log_level: :fatal)
              }
              let(:auth_options) { { auth_callback: lambda { |token_params| sleep 10 }, } }

              it 'the authorization request fails as configured in the realtime_request_timeout (#RSA4c, #RSA4c1, #RSA4c3)' do
                connection.once(:connected) do
                  connection.on { raise "State should not change and should stay connected" }

                  client.auth.authorize(nil, auth_options).tap do |deferrable|
                    deferrable.callback { raise "Authorize should not succeed" }
                    deferrable.errback do |err|
                      expect(err).to be_a(Ably::Exceptions::ConnectionError)
                      expect(err.message).to match(/auth_callback/)

                      EventMachine.add_timer(1) do
                        expect(connection).to be_connected
                        connection.off
                        stop_reactor
                      end
                    end
                  end
                end
              end
            end
          end
        end
      end
    end

    context 'automatic connection retry' do
      context 'with invalid WebSocket host' do
        let(:retry_every_for_tests)       { 0.2 }
        let(:max_time_in_state_for_tests) { 0.6 }

        let(:client_failure_options) do
          default_options.merge(
            log_level: :none,
            disconnected_retry_timeout: retry_every_for_tests,
            suspended_retry_timeout:    retry_every_for_tests,
            max_connection_state_ttl:   max_time_in_state_for_tests
          )
        end

        # retry immediately after failure, then one retry every :retry_every_for_tests
        let(:expected_retry_attempts) { 1 + (max_time_in_state_for_tests / retry_every_for_tests).round }
        let(:state_changes)           { Hash.new { |hash, key| hash[key] = 0 } }
        let(:timer)                   { Hash.new }

        let(:client_options) do
          client_failure_options.merge(realtime_host: 'non.existent.host')
        end

        def count_state_changes
          EventMachine.next_tick do
            %w(connecting disconnected failed suspended).each do |state|
              connection.on(state.to_sym) { state_changes[state.to_sym] += 1 }
            end
          end
        end

        def start_timer
          timer[:start] = Time.now
        end

        def time_passed
          Time.now.to_f - timer[:start].to_f
        end

        context 'when disconnected' do
          it 'enters the suspended state after multiple attempts to connect' do
            connection.on(:failed) { raise 'Connection should not have reached :failed state yet' }

            count_state_changes && start_timer

            connection.once(:suspended) do
              expect(connection.state).to eq(:suspended)

              expect(state_changes[:connecting]).to   eql(expected_retry_attempts + 1) # allow for initial connecting attempt
              expect(state_changes[:disconnected]).to eql(expected_retry_attempts)

              expect(time_passed).to be > max_time_in_state_for_tests
              stop_reactor
            end
          end

          context 'for the first time' do
            let(:client_options) do
              default_options.merge(realtime_host: 'non.existent.host', disconnected_retry_timeout: 2, log_level: :error)
            end

            it 'reattempts connection immediately and then waits disconnected_retry_timeout for a subsequent attempt' do
              expect(connection.defaults[:disconnected_retry_timeout]).to eql(2)
              connection.once(:disconnected) do
                started_at = Time.now.to_f
                connection.once(:disconnected) do
                  expect(Time.now.to_f - started_at).to be < 1
                  started_at = Time.now.to_f
                  connection.once(:disconnected) do
                    expect(Time.now.to_f - started_at).to be > 2
                    stop_reactor
                  end
                end
              end
            end
          end

          describe '#close' do
            it 'transitions connection state to :closed' do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }
              connection.on(:failed)    { raise 'Connection should not have reached :failed state yet' }

              connection.once(:disconnected) do
                expect(connection.state).to eq(:disconnected)

                connection.on(:closed) do
                  expect(connection.state).to eq(:closed)
                  stop_reactor
                end

                connection.close
              end
            end
          end
        end

        context 'when connection state is :suspended' do
          it 'stays in the suspended state after any number of reconnection attempts' do
            connection.on(:connected) { raise 'Connection should not have reached :connected state' }

            connection.once(:suspended) do
              count_state_changes && start_timer

              EventMachine.add_timer((retry_every_for_tests + 0.1) * 10) do
                expect(connection.state).to eq(:suspended)

                expect(state_changes[:connecting]).to   be >= 10
                expect(state_changes[:suspended]).to    be >= 10
                expect(state_changes[:disconnected]).to eql(0)

                stop_reactor
              end
            end
          end

          context 'for the first time' do
            let(:client_options) do
              default_options.merge(suspended_retry_timeout: 2, max_connection_state_ttl: 0, log_level: :error)
            end

            it 'waits suspended_retry_timeout before attempting to reconnect' do
              expect(client.connection.defaults[:suspended_retry_timeout]).to eql(2)
              connection.once(:connected) do
                connection.transition_state_machine :suspended
                allow(connection).to receive(:current_host).and_return('does.not.exist.com')

                started_at = Time.now.to_f
                connection.once(:connecting) do
                  expect(Time.now.to_f - started_at).to be > 1.75
                  started_at = Time.now.to_f
                  connection.once(:connecting) do
                    expect(Time.now.to_f - started_at).to be > 1.75
                    connection.once(:suspended) do
                      stop_reactor
                    end
                  end
                end
              end
            end
          end

          describe '#close' do
            it 'transitions connection state to :closed' do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }

              connection.once(:suspended) do
                expect(connection.state).to eq(:suspended)

                connection.on(:closed) do
                  expect(connection.state).to eq(:closed)
                  stop_reactor
                end

                connection.close
              end
            end
          end
        end

        context 'when connection state is :failed' do
          describe '#close' do
            it 'will not transition state to :close and fails with an InvalidStateChange exception' do
              connection.on(:connected) { raise 'Connection should not have reached :connected state' }

              connection.once(:suspended) do
                connection.transition_state_machine :failed
              end

              connection.once(:failed) do
                expect(connection.state).to eq(:failed)
                connection.close.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                  expect(error.message).to match(/Unable to transition from failed => closing/)
                  stop_reactor
                end
              end
            end
          end
        end

        context '#error_reason' do
          [:disconnected, :suspended, :failed].each do |state|
            it "contains the error when state is #{state}" do
              connection.on(state) do |connection_state_change|
                error = connection_state_change.reason
                expect(connection.error_reason).to eq(error)
                expect(connection.error_reason.code).to eql(80000)
                stop_reactor
              end

              connection.once(:suspended) do |connection_state_change|
                connection.transition_state_machine :failed, reason: connection_state_change.reason
              end
            end
          end

          it 'is reset to nil when :connected' do
            connection.once(:disconnected) do |error|
              # stub the host so that the connection connects
              allow(connection).to receive(:determine_host).and_yield(TestApp.instance.realtime_host)
              connection.once(:connected) do
                expect(connection.error_reason).to be_nil
                stop_reactor
              end
            end
          end

          it 'is reset to nil when :closed' do
            connection.once(:disconnected) do |error|
              connection.close do
                expect(connection.error_reason).to be_nil
                stop_reactor
              end
            end
          end
        end
      end

      describe '#connect' do
        let(:timeout) { 1.5 }

        let(:client_options) do
          default_options.merge(
            log_level: :none,
            realtime_request_timeout: timeout,
          )
        end

        before do
          connection.on(:connected) { raise "Connection should not open in this test as CONNECTED ProtocolMessage is never received" }

          connection.once(:connecting) do
            # don't process any incoming ProtocolMessages so the connection never opens
            connection.__incoming_protocol_msgbus__.unsubscribe
          end
        end

        context 'connection opening times out' do
          it 'attempts to reconnect' do
            started_at = Time.now

            connection.once(:disconnected) do
              expect(Time.now.to_f - started_at.to_f).to be > timeout
              connection.once(:connecting) do
                stop_reactor
              end
            end

            connection.connect
          end

          context 'when retry intervals are stubbed to attempt reconnection quickly' do
            let(:client_options) do
              default_options.merge(
                log_level: :error,
                disconnected_retry_timeout: 0.1,
                suspended_retry_timeout:    0.1,
                max_connection_state_ttl:   0.2,
                realtime_host:              'non.existent.host'
              )
            end

            it 'never calls the provided success block', em_timeout: 10 do
              connection.connect do
                raise 'success block should not have been called'
              end

              connection.once(:suspended) do
                connection.once(:suspended) do
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    context 'connection resume' do
      let(:channel_name) { random_str }
      let(:channel) { client.channel(channel_name) }
      let(:publishing_client) do
        auto_close Ably::Realtime::Client.new(client_options)
      end
      let(:publishing_client_channel) { publishing_client.channel(channel_name) }
      let(:client_options) { default_options.merge(log_level: :none) }

      def fail_if_suspended_or_failed
        connection.on(:suspended) { raise 'Connection should not have reached :suspended state' }
        connection.on(:failed)    { raise 'Connection should not have reached :failed state' }
      end

      context 'when DISCONNECTED ProtocolMessage received from the server' do
        it 'reconnects automatically and immediately' do
          fail_if_suspended_or_failed

          connection.once(:connected) do
            connection.once(:disconnected) do
              disconnected_at = Time.now.to_f
              connection.once(:connecting) do
                expect(Time.now.to_f).to be_within(0.25).of(disconnected_at)
                connection.once(:connected) do
                  state_history = connection.state_history.map { |transition| transition[:state].to_sym }
                  expect(state_history).to eql([:connecting, :connected, :disconnected, :connecting, :connected])
                  stop_reactor
                end
              end
            end
            protocol_message = Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Disconnected.to_i)
            connection.__incoming_protocol_msgbus__.publish :protocol_message, protocol_message
          end
        end

        context 'connection state freshness is monitored' do
          it 'resumes connections when disconnected within the connection_state_ttl period (#RTN15g)' do
            connection.once(:connected) do
              connection_id = connection.id
              reconnected_with_resume = false

              # Make sure the next connect has the resume param
              allow(EventMachine).to receive(:connect).and_wrap_original do |original, *args, &block|
                url = args[4]
                uri = URI.parse(url)
                expect(CGI::parse(uri.query)['resume'][0]).to_not be_empty
                reconnected_with_resume = true
                original.call(*args, &block)
              end

              connection.once(:disconnected) do
                disconnected_at = Time.now

                connection.once(:connecting) do
                  expect(Time.now.to_f - disconnected_at.to_f).to be < connection.connection_state_ttl
                  connection.once(:connected) do |state_change|
                    expect(connection.id).to eql(connection_id)
                    expect(reconnected_with_resume).to be_truthy
                    stop_reactor
                  end
                end
              end

              connection.transport.unbind
            end
          end

          context 'when connection_state_ttl period has passed since being disconnected' do
            let(:client_options) do
              default_options.merge(
                disconnected_retry_timeout: 4,
                suspended_retry_timeout:    8,
                max_connection_state_ttl:   2,
              )
            end

            it 'clears the local connection state and uses a new connection when the connection_state_ttl period has passed (#RTN15g)' do
              connection.once(:connected) do
                connection_id = connection.id
                resumed_with_clean_connection = false

                connection.once(:disconnected) do
                  disconnected_at = Time.now

                  connection.once(:connecting) do
                    connection.once(:disconnected) do
                      # Make sure the next connect does not have the resume param
                      allow(EventMachine).to receive(:connect).and_wrap_original do |original, *args, &block|
                        url = args[4]
                        uri = URI.parse(url)
                        expect(CGI::parse(uri.query)['resume']).to be_empty
                        resumed_with_clean_connection = true
                        original.call(*args, &block)
                      end

                      allow(connection.details).to receive(:max_idle_interval).and_return(0)
                      connection.__incoming_protocol_msgbus__.plugin_listeners

                      connection.once(:connecting) do
                        expect(Time.now.to_f - disconnected_at.to_f).to be > connection.connection_state_ttl
                        connection.once(:connected) do |state_change|
                          expect(connection.id).to_not eql(connection_id)
                          expect(resumed_with_clean_connection).to be_truthy
                          stop_reactor
                        end
                      end
                    end

                    # Disconnect the transport and trigger a new disconnected state
                    wait_until(lambda { connection.transport }) do
                      connection.transport.unbind
                    end
                  end

                  connection.__incoming_protocol_msgbus__.unplug_listeners
                end

                connection.transport.unbind
              end
            end
          end

          context 'when connection_state_ttl period has passed since last activity on the connection' do
            let(:client_options) do
              default_options.merge(
                max_connection_state_ttl: 2,
              )
            end

            it 'does not clear the local connection state when the connection_state_ttl period has passed since last activity, but the idle timeout has not passed (#RTN15g1, #RTN15g2)' do
              expect(connection.connection_state_ttl).to eql(client_options.fetch(:max_connection_state_ttl))

              connection.once(:connected) do
                connection_id = connection.id
                resumed_connection = false

                connection.once(:disconnected) do
                  disconnected_at = Time.now

                  allow(connection).to receive(:time_since_connection_confirmed_alive?).and_return(connection.connection_state_ttl + 1)

                  # Make sure the next connect does not have the resume param
                  allow(EventMachine).to receive(:connect).and_wrap_original do |original, *args, &block|
                    url = args[4]
                    uri = URI.parse(url)
                    expect(CGI::parse(uri.query)['resume']).to_not be_empty
                    resumed_connection = true
                    original.call(*args, &block)
                  end

                  connection.once(:connecting) do
                    connection.once(:connected) do |state_change|
                      expect(connection.id).to eql(connection_id)
                      expect(resumed_connection).to be_truthy
                      stop_reactor
                    end
                  end
                end

                connection.transport.unbind
              end
            end

            it 'clears the local connection state and uses a new connection when the connection_state_ttl + max_idle_interval period has passed since last activity (#RTN15g1, #RTN15g2)' do
              expect(connection.connection_state_ttl).to eql(client_options.fetch(:max_connection_state_ttl))

              connection.once(:connected) do
                connection_id = connection.id
                resumed_with_clean_connection = false

                connection.once(:disconnected) do
                  disconnected_at = Time.now

                  pseudo_time_passed = connection.connection_state_ttl + connection.details.max_idle_interval + 1
                  allow(connection).to receive(:time_since_connection_confirmed_alive?).and_return(pseudo_time_passed)

                  # Make sure the next connect does not have the resume param
                  allow(EventMachine).to receive(:connect).and_wrap_original do |original, *args, &block|
                    url = args[4]
                    uri = URI.parse(url)
                    expect(CGI::parse(uri.query)['resume']).to be_empty
                    resumed_with_clean_connection = true
                    original.call(*args, &block)
                  end

                  connection.once(:connecting) do
                    connection.once(:connected) do |state_change|
                      expect(connection.id).to_not eql(connection_id)
                      expect(resumed_with_clean_connection).to be_truthy
                      stop_reactor
                    end
                  end
                end

                connection.transport.unbind
              end
            end

            it 'still reattaches the channels automatically following a new connection being established (#RTN15g2)' do
              connection.once(:connected) do
                connection_id = connection.id
                resumed_with_clean_connection = false
                channel_emitted_an_attached = false

                channel.attach do
                  channel.once(:attached) do |channel_state_change|
                    expect(channel_state_change.resumed).to be_falsey
                    channel_emitted_an_attached = true
                  end

                  connection.once(:disconnected) do
                    disconnected_at = Time.now

                    pseudo_time_passed = connection.connection_state_ttl + connection.details.max_idle_interval + 1
                    allow(connection).to receive(:time_since_connection_confirmed_alive?).and_return(pseudo_time_passed)

                    # Make sure the next connect does not have the resume param
                    allow(EventMachine).to receive(:connect).and_wrap_original do |original, *args, &block|
                      url = args[4]
                      uri = URI.parse(url)
                      expect(CGI::parse(uri.query)['resume']).to be_empty
                      resumed_with_clean_connection = true
                      original.call(*args, &block)
                    end

                    connection.once(:connecting) do
                      connection.once(:connected) do |state_change|
                        expect(connection.id).to_not eql(connection_id)
                        expect(resumed_with_clean_connection).to be_truthy

                        wait_until(lambda { channel.attached? }) do
                          expect(channel_emitted_an_attached).to be_truthy
                          stop_reactor
                        end
                      end
                    end
                  end

                  connection.transport.unbind
                end
              end
            end
          end
        end

        context 'and subsequently fails to reconnect' do
          let(:retry_every) { 1.5 }

          let(:client_options) do
            default_options.merge(
              log_level: :none,
              disconnected_retry_timeout: retry_every,
              suspended_retry_timeout:    retry_every,
              max_connection_state_ttl:   60
            )
          end

          it "retries every #{Ably::Realtime::Connection::DEFAULTS.fetch(:disconnected_retry_timeout)} seconds" do
            fail_if_suspended_or_failed

            stubbed_first_attempt = false

            connection.once(:connected) do
              connection.once(:disconnected) do
                connection.once(:connecting) do
                  connection.once(:disconnected) do
                    disconnected_at = Time.now.to_f
                    connection.once(:connecting) do
                      expect(Time.now.to_f - disconnected_at).to be > retry_every
                      state_history = connection.state_history.map { |transition| transition[:state].to_sym }
                      expect(state_history).to eql([:connecting, :connected, :disconnected, :connecting, :disconnected, :connecting])

                      # allow one more recoonect when reactor stopped
                      expect(connection.manager).to receive(:reconnect_transport)
                      stop_reactor
                    end
                  end

                  # When reconnect called simply open the transport and close immediately
                  expect(connection.manager).to receive(:reconnect_transport) do
                    next if stubbed_first_attempt

                    connection.manager.setup_transport do
                      EventMachine.next_tick do
                        connection.transport.unbind
                        stubbed_first_attempt = true
                      end
                    end
                  end
                end
              end

              protocol_message = Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Disconnected.to_i)
              connection.__incoming_protocol_msgbus__.publish :protocol_message, protocol_message
            end
          end
        end
      end

      context 'when websocket transport is abruptly disconnected' do
        it 'reconnects automatically' do
          fail_if_suspended_or_failed

          connection.once(:connected) do
            connection.once(:disconnected) do
              connection.once(:connected) do
                state_history = connection.state_history.map { |transition| transition[:state].to_sym }
                expect(state_history).to eql([:connecting, :connected, :disconnected, :connecting, :connected])
                stop_reactor
              end
            end
            connection.transport.close_connection_after_writing
          end
        end

        context 'hosts used' do
          it 'reconnects with the default host' do
            fail_if_suspended_or_failed

            connection.once(:connected) do
              connection.once(:disconnected) do
                hosts = []
                expect(connection).to receive(:create_transport).once.and_wrap_original do |original_method, *args, &block|
                  hosts << args[0]
                  original_method.call(*args, &block)
                end
                connection.once(:connected) do
                  host = "#{"#{environment}-" if environment && environment.to_s != 'production'}#{Ably::Realtime::Client::DOMAIN}"
                  expect(hosts.first).to eql(host)
                  expect(hosts.length).to eql(1)
                  stop_reactor
                end
              end
              connection.transport.close_connection_after_writing
            end
          end
        end
      end

      context 'after successfully reconnecting and resuming' do
        it 'retains connection_id and updates the connection_key (#RTN15e, #RTN16d)' do
          connection.once(:connected) do
            previous_connection_id = connection.id
            connection.transport.close_connection_after_writing

            expect(connection).to receive(:configure_new).with(previous_connection_id, anything, anything).and_call_original

            connection.once(:connected) do
              expect(connection.key).to_not be_nil
              expect(connection.id).to eql(previous_connection_id)
              stop_reactor
            end
          end
        end

        it 'includes the error received in the connection state change from Ably but leaves the channels attached' do
          channel.attach do
            connection.transport.close_connection_after_writing

            connection.once(:connecting) do
              connection.__incoming_protocol_msgbus__.unsubscribe
              connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                allow(protocol_message).to receive(:error).and_return(Ably::Exceptions::Standard.new('Injected error'))
              end
              # Create a new message dispatcher that subscribes to ProtocolMessages after the previous subscription allowing us
              # to modify the ProtocolMessage
              Ably::Realtime::Client::IncomingMessageDispatcher.new(client, connection)
            end

            connection.once(:connected) do |connection_state_change|
              EM.add_timer(0.5) do
                expect(connection_state_change.reason).to be_a(Ably::Exceptions::Standard)
                expect(connection_state_change.reason.message).to match(/Injected error/)
                expect(connection.error_reason).to be_a(Ably::Exceptions::Standard)
                expect(channel).to be_attached
                stop_reactor
              end
            end
          end
        end

        it 'retains channel subscription state' do
          channel.subscribe('event') do |message|
            expect(message.data).to eql('message')
            stop_reactor
          end

          channel.attach do
            publishing_client_channel.attach do
              connection.transport.close_connection_after_writing

              connection.once(:connected) do
                publishing_client_channel.publish 'event', 'message'
              end
            end
          end
        end

        it 'executes the resume callback', api_private: true do
          channel.attach do
            connection.transport.close_connection_after_writing
            connection.on_resume do
              expect(connection).to be_connected
              stop_reactor
            end
          end
        end

        context 'when messages were published whilst the client was disconnected' do
          it 'receives the messages published whilst offline' do
            messages_received = false

            channel.subscribe('event') do |message|
              expect(message.data).to eql('message')
              messages_received = true
            end

            channel.attach do
              publishing_client_channel.attach do
                connection.transport.unsafe_off # remove all event handlers that detect socket connection state has changed
                connection.transport.close_connection_after_writing

                publishing_client_channel.publish('event', 'message') do
                  EventMachine.add_timer(1) do
                    expect(messages_received).to eql(false)
                    # simulate connection dropped to re-establish web socket
                    connection.transition_state_machine :disconnected
                  end
                end

                # subsequent connection will receive message sent whilst disconnected
                connection.once(:connected) do
                  EventMachine.add_timer(1) do
                    expect(messages_received).to eql(true)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        it 'retains the client_msg_serial (#RTN15c2, #RTN15c3)' do
          last_message = nil
          channel = client.channels.get("foo")

          channel.attach do
            connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.action == :message
                last_message = protocol_message
              end
            end

            channel.publish("first") do
              expect(last_message.message_serial).to eql(0)
              channel.publish("second") do
                expect(last_message.message_serial).to eql(1)
                connection.once(:connected) do
                  channel.publish("first on resumed connection") do
                    # Message serial reset after failed resume
                    expect(last_message.message_serial).to eql(2)
                    stop_reactor
                  end
                end

                # simulate connection dropped to re-establish web socket
                connection.transition_state_machine :disconnected
              end
            end
          end
        end
      end

      context 'when failing to resume' do
        context 'because the connection_key is not or no longer valid' do
          let(:channel) { client.channel(random_str) }

          def kill_connection_transport_and_prevent_valid_resume
            connection.transport.close_connection_after_writing
            connection.configure_new '0123456789abcdef', 'wVIsgTHAB1UvXh7z-1991d8586', -1 # force the resume connection key to be invalid
          end

          it 'updates the connection_id and connection_key' do
            connection.once(:connected) do
              previous_connection_id  = connection.id
              previous_connection_key = connection.key

              connection.once(:connected) do
                expect(connection.key).to_not eql(previous_connection_key)
                expect(connection.id).to_not eql(previous_connection_id)
                stop_reactor
              end

              kill_connection_transport_and_prevent_valid_resume
            end
          end

          it 'issue a reattach for all attached channels and fail all message awaiting an ACK (#RTN15c3)' do
            channel_count = 10
            channels = channel_count.times.map { |index| client.channel("channel-#{index}") }
            when_all(*channels.map(&:attach)) do
              attached_channels = []
              reattaching_channels = []
              attach_protocol_messages = []
              failed_messages = []

              channels.each do |channel|
                channel.publish("foo").errback do
                  failed_messages << channel
                end
                channel.on(:attaching) do |channel_state_change|
                  error = channel_state_change.reason
                  expect(error.message).to match(/Unable to recover connection/i)
                  reattaching_channels << channel
                end
                channel.on(:attached) do
                  attached_channels << channel
                  next unless attached_channels.count == channel_count
                  expect(reattaching_channels.count).to eql(channel_count)
                  expect(failed_messages.count).to eql(channel_count)
                  expect(attach_protocol_messages.uniq).to match(channels.map(&:name))
                  stop_reactor
                end
              end

              connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                if protocol_message.action == :attach
                  attach_protocol_messages << protocol_message.channel
                end
              end

              kill_connection_transport_and_prevent_valid_resume
            end
          end

          it 'issue a reattach for all attaching channels and fail all queued messages (#RTN15c3)' do
            channel_count = 10
            channels = channel_count.times.map { |index| client.channel("channel-#{index}") }

            channels.map(&:attach)

            attached_channels = []
            attach_protocol_messages = []
            failed_messages = []

            channels.each do |channel|
              channel.publish("foo").errback do
                failed_messages << channel
              end

              channel.on(:attached) do |state_change|
                attached_channels << channel
                expect(state_change).to_not be_resumed
                next unless attached_channels.count == channel_count
                expect(failed_messages.count).to eql(channel_count)
                expect(attach_protocol_messages.uniq).to match(channels.map(&:name))
                stop_reactor
              end
            end

            connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.action == :attach
                attach_protocol_messages << protocol_message.channel
              end
            end

            client.connection.once(:connected) do
              kill_connection_transport_and_prevent_valid_resume
            end
          end

          it 'issue a attach for all suspended channels (#RTN15c3)' do
            channel_count = 10
            channels = channel_count.times.map { |index| client.channel("channel-#{index}") }

            when_all(*channels.map(&:attach)) do
              # Force all channels into a suspended state
              channels.map do |channel|
                channel.transition_state_machine! :suspended
                expect(channel).to be_suspended
              end

              attached_channels = []
              reattaching_channels = []
              attach_protocol_messages = []

              channels.each do |channel|
                channel.on(:attaching) do
                  reattaching_channels << channel
                end
                channel.on(:attached) do
                  attached_channels << channel
                  next unless attached_channels.count == channel_count
                  expect(reattaching_channels.count).to eql(channel_count)
                  expect(attach_protocol_messages.uniq).to match(channels.map(&:name))
                  stop_reactor
                end
              end

              connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                if protocol_message.action == :attach
                  attach_protocol_messages << protocol_message.channel
                end
              end

              kill_connection_transport_and_prevent_valid_resume
            end
          end

          it 'sets the error reason on each channel' do
            channel.attach do
              channel.on(:attaching) do |state_change|
                expect(state_change.reason.message).to match(/Unable to recover connection/i)
                expect(state_change.reason.code).to eql(80008)
                expect(channel.error_reason.code).to eql(80008)

                channel.on(:attached) do |state_change|
                  stop_reactor
                end
              end
              kill_connection_transport_and_prevent_valid_resume
            end
          end

          it 'continues to use the client_msg_serial (#RTN15c3)' do
            last_message = nil
            channel = client.channels.get("foo")

            connection.once(:connected) do
              connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                if protocol_message.action == :message
                  last_message = protocol_message
                end
              end

              channel.publish("first") do
                expect(last_message.message_serial).to eql(0)
                channel.publish("second") do
                  expect(last_message.message_serial).to eql(1)
                  connection.once(:connected) do
                    channel.publish("first on new connection") do
                      # Message serial reset after failed resume
                      expect(last_message.message_serial).to eql(2)
                      stop_reactor
                    end
                  end

                  kill_connection_transport_and_prevent_valid_resume
                end
              end
            end
          end
        end

        context 'as the DISCONNECTED window to resume has passed' do
          let(:channel) { client.channel(random_str) }

          def kill_connection_transport_and_prevent_valid_resume
            connection.transport.close_connection_after_writing
          end

          it 'starts a new connection automatically and does not try and resume' do
            connection.once(:connected) do
              previous_connection_id  = connection.id
              previous_connection_key = connection.key

              connection.once(:connected) do
                expect(connection.key).to_not eql(previous_connection_key)
                expect(connection.id).to_not eql(previous_connection_id)
                stop_reactor
              end

              # Wait until next tick before stubbing otherwise liveness test may
              # record the stubbed last contact time as the future time
              EventMachine.next_tick do
                five_minutes_time = Time.now + 5 * 60
                allow(Time).to receive(:now) { five_minutes_time }

                kill_connection_transport_and_prevent_valid_resume
              end
            end
          end
        end
      end

      context 'when an ERROR protocol message is received' do
        %w(connecting connected).each do |state|
          state = state.to_sym
          context "whilst #{state}" do
            context 'with a token error code in the range 40140 <= code < 40150 (#RTN14b)' do
              let(:client_options) { default_options.merge(use_token_auth: true) }

              it 'triggers a re-authentication' do
                connection.once(state) do
                  current_token = client.auth.current_token_details

                  error_message = Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Error.to_i, error: { code: 40140 })
                  connection.__incoming_protocol_msgbus__.publish :protocol_message, error_message

                  connection.once(:connected) do
                    expect(client.auth.current_token_details).to_not eql(current_token)
                    stop_reactor
                  end
                end
              end
            end

            context 'with an error code indicating an error other than a token failure (#RTN14g, #RTN15i)' do
              it 'causes the connection to fail' do
                connection.once(state) do
                  connection.once(:failed) do
                    stop_reactor
                  end

                  error_message = Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Error.to_i, error: { code: 50000 })
                  connection.__incoming_protocol_msgbus__.publish :protocol_message, error_message
                end
              end
            end

            context 'with no error code indicating an error other than a token failure (#RTN14g, #RTN15i)' do
              it 'causes the connection to fail' do
                connection.once(state) do
                  connection.once(:failed) do
                    stop_reactor
                  end

                  error_message = Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Error.to_i)
                  connection.__incoming_protocol_msgbus__.publish :protocol_message, error_message
                end
              end
            end
          end
        end
      end

      context "whilst resuming" do
        context "with a token error code in the region 40140 <= code < 40150 (#{}RTN15c5)" do
          before do
            stub_const 'Ably::Models::TokenDetails::TOKEN_EXPIRY_BUFFER', 0 # allow token to be used even if about to expire
            stub_const 'Ably::Auth::TOKEN_DEFAULTS', Ably::Auth::TOKEN_DEFAULTS.merge(renew_token_buffer: 0) # Ensure tokens issued expire immediately after issue
          end

          let!(:four_second_token) {
            rest_client.auth.request_token(ttl: 4).token
          }

          let!(:normal_token) {
            rest_client.auth.request_token.token
          }

          let(:client_options) do
            default_options.merge(auth_callback: lambda do |token_params|
              @auth_requests ||= 0
              @auth_requests += 1

              case @auth_requests
              when 1
                four_second_token
              when 2
                normal_token
              end
            end)
          end

          it 'triggers a re-authentication and then resumes the connection' do
            connection.once(:connected) do
              connection_id = connection.id

              connecting_attempts = 0
              connection.on(:connecting) { connecting_attempts += 1 }

              connection.once(:connected) do
                expect(@auth_requests).to eql(2) # initial + reconnect fails due to expiry & then obtains new token
                expect(connecting_attempts).to eql(2) # reconnect with failed token, then reconnect with successful token
                expect(connection.id).to eql(connection_id)
                stop_reactor
              end

              # Prevent token expired DISCONNECTED arriving on the transport
              # Instead we want to let the client lib catch a transport closed event
              # Then attempt to reconnect with an expired token
              connection.transport.__incoming_protocol_msgbus__.unsubscribe

              EventMachine.next_tick do
                # Lock the EventMachine for 4 seconds until the token has expired
                sleep 5

                # Simulate an abrupt disconnection which will in turn resume but with an expired token
                connection.transport.close_connection_after_writing
              end
            end
          end
        end
      end

      context 'with any other error (#RTN15c4)' do
        it 'moves the connection to the failed state' do
          channel = client.channels.get("foo")
          channel.attach do
            connection.once(:failed) do |state_change|
              expect(state_change.reason.code).to eql(40400)
              expect(connection.error_reason.code).to eql(40400)
              expect(channel).to be_failed
              expect(channel.error_reason.code).to eql(40400)
              stop_reactor
            end

            allow(client.rest_client.auth).to receive(:key).and_return("invalid.key:secret")

            # Simulate an abrupt disconnection which will in turn resume with an invalid key
            connection.transport.close_connection_after_writing
          end
        end
      end
    end

    describe 'fallback host feature' do
      let(:retry_every_for_tests)       { 0.2  }
      let(:max_time_in_state_for_tests) { 0.59 }

      let(:timeout_options) do
        default_options.merge(
          environment:                :production,
          log_level:                  :none,
          disconnected_retry_timeout: retry_every_for_tests,
          suspended_retry_timeout:    retry_every_for_tests,
          max_connection_state_ttl:   max_time_in_state_for_tests
        )
      end

      # Retry immediately and then wait retry_every before every subsequent attempt
      let(:expected_retry_attempts)    { 1 + (max_time_in_state_for_tests / retry_every_for_tests).round }

      let(:retry_count_for_one_state)  { 1 + expected_retry_attempts } # initial connect then disconnected
      let(:retry_count_for_all_states) { 1 + expected_retry_attempts + 1 } # initial connection, disconnected & then one suspended attempt

      context 'with custom realtime websocket host option' do
        let(:expected_host) { 'this.host.does.not.exist' }
        let(:client_options) { timeout_options.merge(realtime_host: expected_host) }

        it 'never uses a fallback host' do
          expect(connection).to receive(:create_transport).exactly(retry_count_for_all_states).times do |host|
            expect(host).to eql(expected_host)
            raise EventMachine::ConnectionError
          end

          connection.once(:suspended) do
            connection.once(:suspended) do
              stop_reactor
            end
          end
        end
      end

      context 'with custom realtime websocket port option' do
        let(:custom_port) { 666}
        let(:client_options) { timeout_options.merge(tls_port: custom_port) }

        it 'never uses a fallback host' do
          expect(connection).to receive(:create_transport).exactly(retry_count_for_all_states).times do |host, port|
            expect(port).to eql(custom_port)
            raise EventMachine::ConnectionError
          end

          connection.once(:suspended) do
            connection.once(:suspended) do
              stop_reactor
            end
          end
        end
      end

      context 'with non-production environment' do
        let(:environment)    { 'sandbox' }
        let(:expected_host)  { "#{environment}-#{Ably::Realtime::Client::DOMAIN}" }
        let(:client_options) { timeout_options.merge(environment: environment) }

        it 'does not use a fallback host by default' do
          expect(connection).to receive(:create_transport).exactly(retry_count_for_all_states).times do |host|
            expect(host).to eql(expected_host)
            raise EventMachine::ConnectionError
          end

          connection.once(:suspended) do
            connection.once(:suspended) do
              stop_reactor
            end
          end
        end

        context ':fallback_hosts_use_default is true' do
          let(:max_time_in_state_for_tests) { 4 }
          let(:fallback_hosts_used) { Array.new }
          let(:client_options) { timeout_options.merge(environment: environment, fallback_hosts_use_default: true) }

          it 'uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k7)' do
            request = 0
            allow(connection).to receive(:create_transport) do |host|
              if request == 0
                expect(host).to eql(expected_host)
              else
                fallback_hosts_used << host
              end
              request += 1
              raise EventMachine::ConnectionError
            end

            connection.once(:suspended) do
              expect(fallback_hosts_used.uniq).to match_array(Ably::FALLBACK_HOSTS + [expected_host])
              stop_reactor
            end
          end

          it 'does not use a fallback host if the connection connects on the default host and then later becomes disconnected', em_timeout: 25 do
            request = 0

            allow(connection).to receive(:create_transport).and_wrap_original do |wrapped_proc, host, *args, &block|
              expect(host).to eql(expected_host)
              request += 1
              wrapped_proc.call(host, *args, &block)
            end

            connection.on(:connected) do
              if request <= 2
                EventMachine.add_timer(3) do
                  # Force a disconnect
                  connection.transport.unbind
                end
              else
                stop_reactor
              end
            end
          end
        end

        context ':fallback_hosts array is provided' do
          let(:max_time_in_state_for_tests) { 4 }
          let(:fallback_hosts) { %w(a.foo.com b.foo.com) }
          let(:fallback_hosts_used) { Array.new }
          let(:client_options) { timeout_options.merge(environment: environment, fallback_hosts: fallback_hosts) }

          it 'uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k6)' do
            request = 0
            allow(connection).to receive(:create_transport) do |host|
              if request == 0
                expect(host).to eql(expected_host)
              else
                fallback_hosts_used << host
              end
              request += 1
              raise EventMachine::ConnectionError
            end

            connection.once(:suspended) do
              expect(fallback_hosts_used.uniq).to match_array(fallback_hosts + [expected_host])
              stop_reactor
            end
          end
        end
      end

      context 'with production environment' do
        let(:custom_hosts)   { %w(A.ably-realtime.com B.ably-realtime.com) }
        before do
          stub_const 'Ably::FALLBACK_HOSTS', custom_hosts
        end

        let(:expected_host)  { Ably::Realtime::Client::DOMAIN }
        let(:client_options) { timeout_options.merge(environment: nil) }

        let(:fallback_hosts_used) { Array.new }

        context 'when the Internet is down' do
          before do
            allow(connection).to receive(:internet_up?).and_yield(false)
          end

          it 'never uses a fallback host' do
            expect(connection).to receive(:create_transport).exactly(retry_count_for_all_states).times do |host|
              expect(host).to eql(expected_host)
              raise EventMachine::ConnectionError
            end

            connection.once(:suspended) do
              connection.once(:suspended) do
                stop_reactor
              end
            end
          end
        end

        context 'when the Internet is up' do
          before do
            allow(connection).to receive(:internet_up?).and_yield(true)
            @suspended = 0
          end

          context 'and default options' do
            let(:max_time_in_state_for_tests) { 2 } # allow time for 3 attempts, 2 configured fallbacks + primary host

            it 'uses a fallback host + the original host once on every subsequent disconnected attempt until suspended' do
              request = 0
              expect(connection).to receive(:create_transport).exactly(retry_count_for_one_state).times do |host|
                if request == 0
                  expect(host).to eql(expected_host)
                else
                  fallback_hosts_used << host
                end
                request += 1
                raise EventMachine::ConnectionError
              end

              connection.once(:suspended) do
                fallback_hosts_used.pop # remove suspended attempt host
                expect(fallback_hosts_used.uniq).to match_array(custom_hosts + [expected_host])
                stop_reactor
              end
            end

            it 'uses the primary host when suspended, and then every fallback host and the primary host again on every subsequent suspended attempt' do
              request = 0
              expect(connection).to receive(:create_transport).at_least(:once) do |host|
                if request == 0 || request == expected_retry_attempts + 1
                  expect(host).to eql(expected_host)
                else
                  expect(custom_hosts + [expected_host]).to include(host)
                  fallback_hosts_used << host if @suspended > 0
                end
                request += 1
                raise EventMachine::ConnectionError
              end

              connection.on(:suspended) do
                @suspended += 1

                if @suspended > 4
                  expect(fallback_hosts_used.uniq).to match_array(custom_hosts + [expected_host])
                  stop_reactor
                end
              end
            end

            it 'uses the correct host name for the WebSocket requests to the fallback hosts' do
              request = 0
              expect(connection).to receive(:create_transport).at_least(:once) do |host, port, uri|
                if request == 0 || request == expected_retry_attempts + 1
                  expect(uri.hostname).to eql(expected_host)
                else
                  expect(custom_hosts + [expected_host]).to include(uri.hostname)
                  fallback_hosts_used << host if @suspended > 0
                end
                request += 1
                raise EventMachine::ConnectionError
              end

              connection.on(:suspended) do
                @suspended += 1

                if @suspended > 4
                  expect(fallback_hosts_used.uniq).to match_array(custom_hosts + [expected_host])
                  stop_reactor
                end
              end
            end
          end

          context ':fallback_hosts array is provided by an empty array' do
            let(:max_time_in_state_for_tests) { 3 }
            let(:fallback_hosts) { [] }
            let(:hosts_used) { Array.new }
            let(:client_options) { timeout_options.merge(environment: 'production', fallback_hosts: fallback_hosts) }

            it 'uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k6)' do
              allow(connection).to receive(:create_transport) do |host|
                hosts_used << host
                raise EventMachine::ConnectionError
              end

              connection.once(:suspended) do
                expect(hosts_used.uniq.length).to eql(1)
                expect(hosts_used.uniq.first).to eql(expected_host)
                stop_reactor
              end
            end
          end

          context ':fallback_hosts array is provided' do
            let(:max_time_in_state_for_tests) { 3 }
            let(:fallback_hosts) { %w(a.foo.com b.foo.com) }
            let(:fallback_hosts_used) { Array.new }
            let(:client_options) { timeout_options.merge(environment: 'production', fallback_hosts: fallback_hosts) }

            it 'uses a fallback host on every subsequent disconnected attempt until suspended (#RTN17b, #TO3k6)' do
              request = 0
              allow(connection).to receive(:create_transport) do |host|
                if request == 0
                  expect(host).to eql(expected_host)
                else
                  fallback_hosts_used << host
                end
                request += 1
                raise EventMachine::ConnectionError
              end

              connection.once(:suspended) do
                expect(fallback_hosts_used.uniq).to match_array(fallback_hosts + [expected_host])
                stop_reactor
              end
            end
          end
        end
      end
    end
  end
end
