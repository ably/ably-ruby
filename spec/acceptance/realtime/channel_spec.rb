# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channel, :event_machine do
  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }

    let(:client)       { auto_close Ably::Realtime::Client.new(client_options) }
    let(:connection)   { client.connection }
    let(:channel_name) { random_str }
    let(:payload)      { random_str }
    let(:channel)      { client.channel(channel_name) }
    let(:messages)     { [] }

    let(:sub_client)   { auto_close Ably::Realtime::Client.new(client_options) }
    let(:sub_channel)  { sub_client.channel(channel_name) }

    def disconnect_transport
      connection.transport.unbind
    end

    describe 'initialization' do
      context 'with :auto_connect option set to false on connection' do
        let(:client) do
          auto_close Ably::Realtime::Client.new(default_options.merge(auto_connect: false))
        end

        it 'remains initialized when accessing a channel' do
          client.channel('test')
          EventMachine.add_timer(2) do
            expect(client.connection).to be_initialized
            stop_reactor
          end
        end

        it 'opens a connection implicitly on #attach' do
          client.channel('test').attach do
            expect(client.connection).to be_connected
            stop_reactor
          end
        end
      end
    end

    describe '#attach' do
      context 'when initialized' do
        it 'emits attaching then attached events' do
          channel.once(:attaching) do
            channel.once(:attached) do
              stop_reactor
            end
          end

          channel.attach
        end

        it 'ignores subsequent #attach calls but calls the success callback if provided' do
          channel.once(:attaching) do
            channel.attach
            channel.once(:attached) do
              channel.attach do
                stop_reactor
              end
            end
          end

          channel.attach
        end

        it 'attaches to a channel' do
          channel.attach
          channel.on(:attached) do
            expect(channel.state).to eq(:attached)
            stop_reactor
          end
        end

        it 'attaches to a channel and calls the provided block (#RTL4d)' do
          channel.attach do
            expect(channel.state).to eq(:attached)
            stop_reactor
          end
        end

        it 'sends an ATTACH and waits for an ATTACHED (#RTL4c)' do
          connection.once(:connected) do
            attach_count = 0
            attached_count = 0
            test_complete = false
            client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              next if test_complete
              attached_count += 1 if protocol_message.action == :attached
            end
            client.connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              next if test_complete
              attach_count += 1 if protocol_message.action == :attach
            end
            channel.attach do
              EventMachine.add_timer(1) do
                test_complete = true
                expect(attach_count).to eql(1)
                expect(attached_count).to eql(1)
                stop_reactor
              end
            end
          end
        end

        it 'implicitly attaches the channel (#RTL7c)' do
          expect(channel).to be_initialized
          channel.subscribe { |message| }
          channel.once(:attached) do
            stop_reactor
          end
        end

        context 'when the implicit channel attach fails' do
          let(:allowed_params) do
            { capability: { "*" => ["*"] } }
          end
          let(:not_allowed_params) do
            { capability: { "only_this_channel" => ["*"] } }
          end
          let(:client_options) { default_options.merge(default_token_params: not_allowed_params, use_token_auth: true, log_level: :fatal) }

          it 'registers the listener anyway (#RTL7c)' do
            channel.subscribe do |message|
              stop_reactor
            end
            channel.once(:failed) do
              client.auth.authorize(allowed_params) do
                channel.attach do
                  channel.publish 'foo'
                end
              end
            end
          end
        end
      end

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        expect(channel.attach).to be_a(Ably::Util::SafeDeferrable)
        stop_reactor
      end

      it 'calls the SafeDeferrable callback on success (#RTL4d)' do
        channel.attach.callback do
          expect(channel).to be_a(Ably::Realtime::Channel)
          expect(channel.state).to eq(:attached)
          stop_reactor
        end
      end

      context 'when an ATTACHED acknowledge is not received on the current connection' do
        # As soon as the client sends the ATTACH on a CONNECTED connection
        # simulate a transport failure that triggers the DISCONNECTED state twice
        it 'sends another ATTACH each time the connection becomes connected' do
          attached_messages = []
          client.connection.__outgoing_protocol_msgbus__.on(:protocol_message) do |protocol_message|
            if protocol_message.action == :attach
              attached_messages << protocol_message
              if attached_messages.count < 3
                EventMachine.next_tick do
                  disconnect_transport
                end
              end
            end
          end

          connection.once(:connected) do
            connection.once(:disconnected) do
              expect(attached_messages.count).to eql(1)
              connection.once(:disconnected) do
                expect(attached_messages.count).to eql(2)
                connection.once(:connected) do
                  EventMachine.add_timer(0.1) do
                    expect(attached_messages.count).to eql(3)
                  end
                end
              end
            end
            channel.attach
          end

          channel.once(:attached) do
            EventMachine.add_timer(1) do
              expect(attached_messages.count).to eql(3)
              stop_reactor
            end
          end
        end
      end

      context 'when state is :attached' do
        it 'does nothing (#RTL4a)' do
          channel.attach do
            stopping = false
            client.connection.__outgoing_protocol_msgbus__.once(:protocol_message) do |protocol_message|
              raise "No outgoing messages should be sent as already ATTACHED" unless stopping
            end
            5.times do |index|
              EventMachine.add_timer(0.2 * index) { channel.attach }
            end
            EventMachine.add_timer(1.5) do
              stopping = true
              stop_reactor
            end
          end
        end
      end

      context 'when state is :failed' do
        let(:client_options) { default_options.merge(log_level: :fatal) }

        it 'reattaches and sets the errorReason to nil (#RTL4g)' do
          channel.attach do
            channel.transition_state_machine :failed, reason: RuntimeError.new
            expect(channel).to be_failed
            expect(channel.error_reason).to_not be_nil
            channel.attach do
              expect(channel).to be_attached
              expect(channel.error_reason).to be_nil
              stop_reactor
            end
          end
        end
      end

      context 'when state is :detaching' do
        it 'does the attach operation after the completion of the pending request (#RTL4h)' do
          channel.once(:detaching) do
            channel.once(:detached) do
              channel.once(:attaching) do
                channel.once(:attached) do
                  EventMachine.add_timer(1) do
                    expect(channel).to be_attached
                    stop_reactor
                  end
                end
              end
            end

            channel.attach
          end

          channel.attach do
            channel.detach
          end
        end
      end

      context 'with many connections and many channels on each simultaneously' do
        let(:connection_count)       { 30 }
        let(:channel_count)          { 10 }
        let(:permutation_count)      { connection_count * channel_count }
        let(:channel_connection_ids) { [] }

        it 'attaches all channels', em_timeout: 15 do
          connection_count.times.map do
            auto_close Ably::Realtime::Client.new(default_options)
          end.each do |client|
            channel_count.times.map do |index|
              client.channel("channel-#{index}").attach do
                channel_connection_ids << "#{client.connection.id}:#{index}"
                next unless channel_connection_ids.count == permutation_count

                expect(channel_connection_ids.uniq.count).to eql(permutation_count)
                stop_reactor
              end
            end
          end
        end
      end

      context 'failure as a result of insufficient key permissions' do
        let(:auth_options) do
          default_options.merge(
            key: restricted_api_key,
            log_level: :fatal,
            use_token_auth: true,
            default_token_params: { capability: { "canpublish:foo" => ["*"] } }
          )
        end
        let(:restricted_client) do
          auto_close Ably::Realtime::Client.new(auth_options)
        end
        let(:restricted_channel) { restricted_client.channel("cansubscribe:foo") }

        it 'emits failed event (#RTL4e)' do
          restricted_channel.attach
          restricted_channel.on(:failed) do |connection_state|
            expect(restricted_channel.state).to eq(:failed)
            expect(connection_state.reason.status).to eq(401)
            stop_reactor
          end
        end

        it 'calls the errback of the returned Deferrable (#RTL4d)' do
          restricted_channel.attach.errback do |error|
            expect(restricted_channel.state).to eq(:failed)
            expect(error.status).to eq(401)
            stop_reactor
          end
        end

        it 'updates the error_reason' do
          restricted_channel.attach
          restricted_channel.on(:failed) do
            expect(restricted_channel.error_reason.status).to eq(401)
            stop_reactor
          end
        end

        context 'and subsequent authorisation with suitable permissions' do
          it 'attaches to the channel successfully and resets the channel error_reason' do
            restricted_channel.attach
            restricted_channel.once(:failed) do
              restricted_client.close do
                token_params = { capability: { "cansubscribe:foo" => ["subscribe"] } }
                restricted_client.auth.authorize(token_params) do
                  restricted_channel.once(:attached) do
                    expect(restricted_channel.error_reason).to be_nil
                    stop_reactor
                  end
                  restricted_channel.attach
                end
              end
            end
          end
        end
      end

      context 'with connection state' do
        it 'is initialized (#RTL4i)' do
          expect(connection).to be_initialized
          channel.attach do
            stop_reactor
          end
        end

        it 'is connecting (#RTL4i)' do
          connection.once(:connecting) do
            channel.attach do
              stop_reactor
            end
          end
        end

        it 'is disconnected (#RTL4i)' do
          connection.once(:connected) do
            connection.once(:disconnected) do
              channel.attach do
                stop_reactor
              end
            end
            disconnect_transport
          end
        end
      end
    end

    describe '#detach' do
      context 'when state is :attached' do
        it 'it detaches from a channel (#RTL5d)' do
          channel.attach do
            channel.detach
            channel.on(:detached) do
              expect(channel.state).to eq(:detached)
              stop_reactor
            end
          end
        end

        it 'detaches from a channel and calls the provided block (#RTL5d, #RTL5e)' do
          channel.attach do
            expect(channel.state).to eq(:attached)
            channel.detach do
              expect(channel.state).to eq(:detached)
              stop_reactor
            end
          end
        end

        it 'emits :detaching then :detached events' do
          channel.once(:detaching) do
            channel.once(:detached) do
              stop_reactor
            end
          end

          channel.attach do
            channel.detach
          end
        end

        it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
          channel.attach do
            expect(channel.detach).to be_a(Ably::Util::SafeDeferrable)
            stop_reactor
          end
        end

        it 'calls the Deferrable callback on success' do
          channel.attach do
            channel.detach.callback do
              expect(channel).to be_a(Ably::Realtime::Channel)
              expect(channel.state).to eq(:detached)
              stop_reactor
            end
          end
        end

        context 'and DETACHED message is not received within realtime request timeout' do
          let(:request_timeout) { 2 }
          let(:client_options) { default_options.merge(realtime_request_timeout: request_timeout) }

          it 'fails the deferrable and returns to the previous state (#RTL5f, #RTL5e)' do
            channel.attach do
              # don't process any incoming ProtocolMessages so the channel never becomes detached
              connection.__incoming_protocol_msgbus__.unsubscribe
              detached_requested_at = Time.now.to_i
              channel.detach do
                raise "The detach should not succeed if no incoming protocol messages are processed"
              end.errback do
                expect(channel).to be_attached
                expect(Time.now.to_i - detached_requested_at).to be_within(1).of(request_timeout)
                stop_reactor
              end
            end
          end
        end
      end

      context 'when state is :failed' do
        let(:client_options) { default_options.merge(log_level: :fatal) }

        it 'fails the deferrable (#RTL5b)' do
          channel.attach do
            channel.transition_state_machine :failed, reason: RuntimeError.new
            expect(channel).to be_failed
            channel.detach.errback do |error|
              expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
              stop_reactor
            end
          end
        end
      end

      context 'when state is :attaching' do
        it 'waits for the attach to complete and then moves to detached' do
          connection.once(:connected) do
            channel.once(:attaching) do
              reached_attached = false
              channel.once(:attached) do
                channel.once(:detached) do
                  stop_reactor
                end
              end
              channel.detach
            end
            channel.attach
          end
        end
      end

      context 'when state is :detaching' do
        it 'ignores subsequent #detach calls but calls the callback if provided (#RTL5i)' do
          channel.once(:detaching) do
            channel.once(:detached) do
              channel.detach do
                stop_reactor
              end
            end
            channel.detach
          end

          channel.attach do
            channel.detach
          end
        end
      end

      context 'when state is :suspended' do
        it 'moves the channel state immediately to DETACHED state (#RTL5j)' do
          channel.attach do
            channel.once(:suspended) do
              channel.on do |channel_state_change|
                expect(channel_state_change.current).to eq(:detached)
                expect(channel.state).to eq(:detached)
                EventMachine.add_timer(1) do
                  stop_reactor
                end
              end
              EventMachine.next_tick do
                channel.detach
              end
            end
            channel.transition_state_machine :suspended
          end
        end
      end

      context 'when state is :initialized' do
        it 'does nothing as there is no channel to detach (#RTL5a)' do
          expect(channel).to be_initialized
          channel.detach do
            expect(channel).to be_initialized
            stop_reactor
          end
        end

        it 'returns a valid deferrable' do
          expect(channel).to be_initialized
          channel.detach.callback do
            expect(channel).to be_initialized
            stop_reactor
          end
        end
      end

      context 'when state is :detached' do
        it 'does nothing as the channel is detached (#RTL5a)' do
          channel.attach do
            channel.detach do
              expect(channel).to be_detached
              channel.on do
                raise "Channel state should not change when calling detached if already detached"
              end
              channel.detach do
                EventMachine.add_timer(1) { stop_reactor }
              end
            end
          end
        end
      end

      context 'when connection state is' do
        context 'closing' do
          it 'fails the deferrable (#RTL5b)' do
            connection.once(:connected) do
              channel.attach do
                connection.once(:closing) do
                  channel.detach.errback do |error|
                    expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                    stop_reactor
                  end
                end
                connection.close
              end
            end
          end
        end

        context 'failed and channel is failed' do
          let(:client_options) do
            default_options.merge(log_level: :none)
          end

          it 'fails the deferrable (#RTL5b)' do
            connection.once(:connected) do
              channel.attach do
                connection.once(:failed) do
                  expect(channel).to be_failed
                  channel.detach.errback do |error|
                    expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                    stop_reactor
                  end
                end
                error = Ably::Exceptions::ConnectionFailed.new('forced failure', 500, 50000)
                client.connection.manager.error_received_from_server error
              end
            end
          end
        end

        context 'failed and channel is detached' do
          let(:client_options) do
            default_options.merge(log_level: :none)
          end

          it 'fails the deferrable (#RTL5b)' do
            connection.once(:connected) do
              channel.attach do
                channel.detach do
                  connection.once(:failed) do
                    expect(channel).to be_detached
                    channel.detach.errback do |error|
                      expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                      stop_reactor
                    end
                  end
                  error = Ably::Exceptions::ConnectionFailed.new('forced failure', 500, 50000)
                  client.connection.manager.error_received_from_server error
                end
              end
            end
          end
        end

        context 'initialized' do
          it 'does the detach operation once the connection state is connected (#RTL5h)' do
            expect(connection).to be_initialized
            channel.attach
            channel.detach
            connection.once(:connected) do
              channel.once(:attached) do
                channel.once(:detached) do
                  stop_reactor
                end
              end
            end
          end
        end

        context 'connecting' do
          it 'does the detach operation once the connection state is connected (#RTL5h)' do
            connection.once(:connecting) do
              channel.attach
              channel.detach
              connection.once(:connected) do
                channel.once(:attached) do
                  channel.once(:detached) do
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        context 'disconnected' do
          let(:client_options) do
            default_options.merge(log_level: :fatal)
          end
          it 'does the detach operation once the connection state is connected (#RTL5h)' do
            connection.once(:connected) do
              connection.once(:disconnected) do
                channel.attach
                channel.detach
                connection.once(:connected) do
                  channel.once(:attached) do
                    channel.once(:detached) do
                      stop_reactor
                    end
                  end
                end
              end
              disconnect_transport
            end
          end
        end
      end
    end

    describe 'automatic channel recovery' do
      let(:realtime_request_timeout) { 2 }
      let(:client_options) do
        default_options.merge(realtime_request_timeout: 2, log_level: :fatal)
      end

      context 'when an ATTACH request times out' do
        it 'moves to the SUSPENDED state (#RTL4f)' do
          connection.once(:connected) do
            attach_request_sent_at = Time.now
            channel.attach
            client.connection.__incoming_protocol_msgbus__.unsubscribe
            channel.once(:suspended) do
              expect(attach_request_sent_at.to_i).to be_within(realtime_request_timeout + 1).of(Time.now.to_i)
              stop_reactor
            end
          end
        end
      end

      context 'if a subsequent ATTACHED is received on an ATTACHED channel' do
        it 'ignores the additional ATTACHED if resumed is true (#RTL12)' do
          channel.attach do
            channel.once do |obj|
              fail "No state change expected: #{obj}"
            end
            attached_message = Ably::Models::ProtocolMessage.new(action: 11, channel: channel_name, flags: 4) # ATTACHED with resumed flag
            client.connection.__incoming_protocol_msgbus__.publish :protocol_message, attached_message
            EventMachine.add_timer(1) do
              channel.off
              stop_reactor
            end
          end
        end

        it 'emits an UPDATE only when resumed is true (#RTL12)' do
          channel.attach do
            expect(channel.error_reason).to be_nil
            channel.on(:update) do |state_change|
              expect(state_change.current).to eq(:attached)
              expect(state_change.previous).to eq(:attached)
              expect(state_change.resumed).to be_falsey
              expect(state_change.reason).to be_nil
              expect(channel.error_reason).to be_nil
              stop_reactor
            end
            attached_message = Ably::Models::ProtocolMessage.new(action: 11, channel: channel_name, flags: 0) # No resumed flag
            client.connection.__incoming_protocol_msgbus__.publish :protocol_message, attached_message
          end
        end

        it 'emits an UPDATE when resumed is true and includes the reason error from the ProtocolMessage (#RTL12)' do
          channel.attach do
            expect(channel.error_reason).to be_nil
            channel.on(:update) do |state_change|
              expect(state_change.current).to eq(:attached)
              expect(state_change.previous).to eq(:attached)
              expect(state_change.resumed).to be_falsey
              expect(state_change.reason.code).to eql(50505)
              expect(channel.error_reason.code).to eql(50505)
              stop_reactor
            end
            attached_message = Ably::Models::ProtocolMessage.new(action: 11, channel: channel_name, error: { code: 50505 }, flags: 0) # No resumed flag with error
            client.connection.__incoming_protocol_msgbus__.publish :protocol_message, attached_message
          end
        end
      end

      # skip 'sends an ATTACH protocol message in response to a channel message being received on the attaching channel'
    end

    context '#publish' do
      let(:name)    { random_str }
      let(:data)    { random_str }

      context 'when channel is attached (#RTL6c1)' do
        it 'publishes messages' do
          channel.attach do
            3.times { channel.publish('event', payload) }
          end
          channel.subscribe do |message|
            messages << message if message.data == payload
            stop_reactor if messages.count == 3
          end
        end
      end

      context 'when channel is not attached in state Initializing (#RTL6c1)' do
        it 'publishes messages immediately and does not implicitly attach (#RTL6c1)' do
          sub_channel.attach do
            sub_channel.subscribe do |message|
              messages << message if message.name == 'event'
              if messages.count == 3
                EventMachine.add_timer(1) do
                  expect(channel.state).to eq(:initialized)
                  stop_reactor
                end
              end
            end
            3.times { channel.publish('event', random_str) }
          end
        end
      end

      context 'when channel is Attaching (#RTL6c1)' do
        it 'publishes messages immediately (#RTL6c1)' do
          sub_channel.attach do
            channel.once(:attaching) do
              outgoing_message_count = 0
              client.connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                if protocol_message.action == :message
                  raise "Expected channel state to be attaching when publishing messages, not #{channel.state}" unless channel.attaching?
                  outgoing_message_count += protocol_message.messages.count
                end
              end
              sub_channel.subscribe do |message|
                messages << message if message.name == 'event'
                if messages.count == 3
                  expect(outgoing_message_count).to eql(3)
                  stop_reactor
                end
              end
              3.times { channel.publish('event', random_str) }
            end
            channel.attach
          end
        end
      end

      context 'when channel is Detaching (#RTL6c1)' do
        it 'publishes messages immediately (#RTL6c1)' do
          sub_channel.attach do
            channel.attach do
              channel.once(:detaching) do
                outgoing_message_count = 0
                client.connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                  if protocol_message.action == :message
                    raise "Expected channel state to be attaching when publishing messages, not #{channel.state}" unless channel.detaching?
                    outgoing_message_count += protocol_message.messages.count
                  end
                end
                sub_channel.subscribe do |message|
                  messages << message if message.name == 'event'
                  if messages.count == 3
                    expect(outgoing_message_count).to eql(3)
                    stop_reactor
                  end
                end
                3.times { channel.publish('event', random_str) }
              end
              channel.detach
            end
          end
        end
      end

      context 'when channel is Detached (#RTL6c1)' do
        it 'publishes messages immediately (#RTL6c1)' do
          sub_channel.attach do
            channel.attach
            channel.once(:attached) do
              channel.once(:detached) do
                outgoing_message_count = 0
                client.connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                  if protocol_message.action == :message
                    raise "Expected channel state to be attaching when publishing messages, not #{channel.state}" unless channel.detached?
                    outgoing_message_count += protocol_message.messages.count
                  end
                end
                sub_channel.subscribe do |message|
                  messages << message if message.name == 'event'
                  if messages.count == 3
                    expect(outgoing_message_count).to eql(3)
                    stop_reactor
                  end
                end
                3.times { channel.publish('event', random_str) }
              end
              channel.detach
            end
          end
        end
      end

      context 'with :queue_messages client option set to false (#RTL6c4)' do
        let(:client_options)  { default_options.merge(queue_messages: false) }

        context 'and connection state connected (#RTL6c4)' do
          it 'publishes the message' do
            client.connection.once(:connected) do
              channel.publish('event')
              stop_reactor
            end
          end
        end

        context 'and connection state initialized (#RTL6c4)' do
          it 'fails the deferrable' do
            expect(client.connection).to be_initialized
            channel.publish('event').errback do |error|
              expect(error).to be_a(Ably::Exceptions::MessageQueueingDisabled)
              stop_reactor
            end
          end
        end

        context 'and connection state connecting (#RTL6c4)' do
          it 'fails the deferrable' do
            client.connect
            EventMachine.next_tick do
              expect(client.connection).to be_connecting
              channel.publish('event').errback do |error|
                expect(error).to be_a(Ably::Exceptions::MessageQueueingDisabled)
                stop_reactor
              end
            end
          end
        end

        [:disconnected, :suspended, :closing, :closed].each do |invalid_connection_state|
          context "and connection state #{invalid_connection_state} (#RTL6c4)" do
            let(:client_options)  { default_options.merge(queue_messages: false) }
            it 'fails the deferrable' do
              client.connection.once(:connected) do
                client.connection.once(invalid_connection_state) do
                  expect(client.connection.state).to eq(invalid_connection_state)
                  channel.publish('event').errback do |error|
                    expect(error).to be_a(Ably::Exceptions::MessageQueueingDisabled)
                    stop_reactor
                  end
                end
                if invalid_connection_state == :closed
                  connection.close
                else
                  client.connection.transition_state_machine invalid_connection_state
                end
              end
            end
          end
        end

        context 'and the channel state is failed (#RTL6c4)' do
          let(:client_options)  { default_options.merge(queue_messages: false) }
          it 'fails the deferrable' do
            client.connection.once(:connected) do
              channel.attach
              channel.once(:attached) do
                channel.once(:failed) do
                  channel.publish('event').errback do |error|
                    expect(error).to be_a(Ably::Exceptions::ChannelInactive)
                    stop_reactor
                  end
                end
                channel.transition_state_machine(:failed)
              end
            end
          end
        end
      end

      context 'with name and data arguments' do
        it 'publishes the message and return true indicating success' do
          channel.publish(name, data) do
            channel.history do |page|
              expect(page.items.first.name).to eql(name)
              expect(page.items.first.data).to eql(data)
              stop_reactor
            end
          end
        end

        context 'and additional attributes' do
          let(:client_id) { random_str }

          it 'publishes the message with the attributes and return true indicating success' do
            channel.publish(name, data, client_id: client_id) do
              channel.history do |page|
                expect(page.items.first.client_id).to eql(client_id)
                stop_reactor
              end
            end
          end
        end

        context 'and additional invalid attributes' do
          let(:client_id) { 1 }

          it 'throws an exception' do
            expect { channel.publish([name: 'event', client_id: 1]) }.to raise_error ArgumentError, /client_id must be a String/
            stop_reactor
          end
        end
      end

      context 'with an array of Hash objects with :name and :data attributes' do
        let(:messages) do
          10.times.map do |index|
            { name: index.to_s, data: { "index" => index + 10 } }
          end
        end

        it 'publishes an array of messages in one ProtocolMessage' do
          published = false

          channel.attach do
            client.connection.__outgoing_protocol_msgbus__.once(:protocol_message) do |protocol_message|
              expect(protocol_message.messages.count).to eql(messages.count)
              published = true
            end

            channel.publish(messages).callback do
              channel.history do |page|
                expect(page.items.map(&:name)).to match_array(messages.map { |message| message[:name] })
                expect(page.items.map(&:data)).to match_array(messages.map { |message| message[:data] })
                expect(published).to eql(true)
                stop_reactor
              end
            end
          end
        end
      end

      context 'with an array of Message objects' do
        let(:messages) do
          10.times.map do |index|
            Ably::Models::Message(name: index.to_s, data: { "index" => index + 10 })
          end
        end

        it 'publishes an array of messages in one ProtocolMessage' do
          published = false

          channel.attach do
            client.connection.__outgoing_protocol_msgbus__.once(:protocol_message) do |protocol_message|
              expect(protocol_message.messages.count).to eql(messages.count)
              published = true
            end

            channel.publish(messages).callback do
              channel.history do |page|
                expect(page.items.map(&:name)).to match_array(messages.map { |message| message[:name] })
                expect(page.items.map(&:data)).to match_array(messages.map { |message| message[:data] })
                expect(published).to eql(true)
                stop_reactor
              end
            end
          end
        end

        context 'nil attributes' do
          context 'when name is nil' do
            let(:data) { random_str }

            it 'publishes the message without a name attribute in the payload' do
              published = false

              channel.subscribe do |message|
                expect(message.name).to be_nil
                channel.history do |page|
                  expect(page.items.first.name).to be_nil
                  expect(page.items.first.data).to eql(data)
                  EM.add_timer(0.5) do
                    expect(published).to eql(true)
                    stop_reactor
                  end
                end
              end

              channel.publish(nil, data) do
                published = true
              end
            end
          end

          context 'when data is nil' do
            let(:name) { random_str }

            it 'publishes the message without a data attribute in the payload' do
              published = false

              channel.subscribe do |message|
                expect(message.data).to be_nil
                channel.history do |page|
                  expect(page.items.first.name).to eql(name)
                  expect(page.items.first.data).to be_nil
                  EM.add_timer(0.5) do
                    expect(published).to eql(true)
                    stop_reactor
                  end
                end
              end

              channel.publish(name, nil) do
                published = true
              end
            end
          end

          context 'with neither name or data attributes' do
            let(:name) { random_str }

            it 'publishes the message without any attributes in the payload' do
              channel.publish(nil) do
                channel.history do |page|
                  expect(page.items.first.name).to be_nil
                  expect(page.items.first.data).to be_nil
                  stop_reactor
                end
              end
            end
          end
        end

        context 'with two invalid message out of 12' do
          let(:rest_client)    { Ably::Rest::Client.new(default_options.merge(client_id: 'valid')) }

          let(:invalid_messages) do
            2.times.map do |index|
              Ably::Models::Message(name: index.to_s, data: { "index" => index + 10 }, client_id: 'prohibited')
            end
          end

          context 'before client_id is known (validated)' do
            let(:client_options) { default_options.merge(token: rest_client.auth.request_token.token, log_level: :error) }

            it 'calls the errback once' do
              channel.publish(messages + invalid_messages).tap do |deferrable|
                deferrable.callback do
                  raise 'Publish should have failed'
                end

                deferrable.errback do |error, message|
                  # TODO: Review whether we should fail once or multiple times
                  channel.history do |page|
                    expect(page.items.count).to eql(0)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'when client_id is known (validated)' do
            let(:client_options) { default_options.merge(client_id: 'valid') }

            it 'raises an exception' do
              expect { channel.publish(messages + invalid_messages) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end
        end

        context 'only invalid messages' do
          let(:rest_client)    { Ably::Rest::Client.new(default_options.merge(client_id: 'valid')) }

          let(:invalid_messages) do
            10.times.map do |index|
              Ably::Models::Message(name: index.to_s, data: { "index" => index + 10 }, client_id: 'prohibited')
            end
          end

          context 'before client_id is known (validated)' do
            let(:client_options) { default_options.merge(token: rest_client.auth.request_token.token, log_level: :error) }

            it 'calls the errback once' do
              channel.publish(invalid_messages).tap do |deferrable|
                deferrable.callback do
                  raise 'Publish should have failed'
                end

                deferrable.errback do |error, message|
                  channel.history do |page|
                    expect(page.items.count).to eql(0)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'when client_id is known (validated)' do
            let(:client_options) { default_options.merge(client_id: 'valid') }

            it 'raises an exception' do
              expect { channel.publish(invalid_messages) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end
        end
      end

      context 'with many many messages and many connections simultaneously' do
        let(:connection_count) { 5 }
        let(:messages)         { 5.times.map { |index| { name: "test", data: "message-#{index}" } } }
        let(:published)        { [] }
        let(:channel_name)     { random_str }

        it 'publishes all messages, all success callbacks are called, and a history request confirms all messages were published' do
          connection_count.times.map do
            auto_close Ably::Realtime::Client.new(client_options)
          end.each do |client|
            channel = client.channels.get(channel_name)
            messages.each do |message|
              channel.publish(message.fetch(:name), message.fetch(:data)) do
                published << message
                if published.count == connection_count * messages.count
                  channel.history do |history_page|
                    expect(history_page.items.count).to eql(connection_count * messages.count)
                    stop_reactor
                  end
                end
              end
            end
          end
        end
      end

      context 'with more than allowed messages in a single publish' do
        let(:channel_name) { random_str }

        it 'rejects the publish' do
          messages = (Ably::Realtime::Connection::MAX_PROTOCOL_MESSAGE_BATCH_SIZE + 1).times.map do
            { name: 'foo' }
          end

          channel.publish(messages).errback do |error|
            expect(error).to be_kind_of(Ably::Exceptions::InvalidRequest)
            stop_reactor
          end
        end
      end

      context 'identified clients' do
        context 'when authenticated with a wildcard client_id' do
          let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: '*') }
          let(:client_options)   { default_options.merge(key: nil, token: token) }
          let(:client)           { auto_close Ably::Realtime::Client.new(client_options) }
          let(:channel)          { client.channels.get(channel_name) }

          context 'with a valid client_id in the message' do
            it 'succeeds' do
              channel.publish([name: 'event', client_id: 'validClient']).tap do |deferrable|
                deferrable.errback { raise 'Should have succeeded' }
              end
              channel.subscribe('event') do |message|
                expect(message.client_id).to eql('validClient')
                EM.add_timer(0.5) { stop_reactor }
              end
            end
          end

          context 'with a wildcard client_id in the message' do
            it 'throws an exception' do
              expect { channel.publish([name: 'event', client_id: '*']) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end

          context 'with a non-String client_id in the message' do
            it 'throws an exception' do
              expect { channel.publish([name: 'event', client_id: 1]) }.to raise_error ArgumentError, /client_id must be a String/
              stop_reactor
            end
          end

          context 'with an empty client_id in the message' do
            it 'succeeds and publishes without a client_id' do
              channel.publish([name: 'event', client_id: nil]).tap do |deferrable|
                deferrable.errback { raise 'Should have succeeded' }
              end
              channel.subscribe('event') do |message|
                expect(message.client_id).to be_nil
                EM.add_timer(0.5) { stop_reactor }
              end
            end
          end
        end

        context 'when authenticated with a Token string with an implicit client_id' do
          let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: 'valid').token }
          let(:client_options)   { default_options.merge(key: nil, token: token) }
          let(:client)           { auto_close Ably::Realtime::Client.new(client_options) }
          let(:channel)          { client.channels.get(channel_name) }

          context 'before the client is CONNECTED and the client\'s identity has been obtained' do
            context 'with a valid client_id in the message' do
              it 'succeeds' do
                channel.publish([name: 'event', client_id: 'valid']).tap do |deferrable|
                  deferrable.errback { raise 'Should have succeeded' }
                end
                channel.subscribe('event') do |message|
                  expect(message.client_id).to eql('valid')
                  EM.add_timer(0.5) { stop_reactor }
                end
              end
            end

            context 'with an invalid client_id in the message' do
              let(:client_options)   { default_options.merge(key: nil, token: token, log_level: :error) }
              it 'succeeds in the client library but then fails when delivered to Ably' do
                channel.publish([name: 'event', client_id: 'invalid']).tap do |deferrable|
                  EM.add_timer(0.5) { stop_reactor }
                end
                channel.subscribe('event') do |message|
                  raise 'Message should not have been published'
                end
              end
            end

            context 'with an empty client_id in the message' do
              it 'succeeds and publishes with an implicit client_id' do
                channel.publish([name: 'event', client_id: nil]).tap do |deferrable|
                  deferrable.errback { raise 'Should have succeeded' }
                end
                channel.subscribe('event') do |message|
                  expect(message.client_id).to eql('valid')
                  EM.add_timer(0.5) { stop_reactor }
                end
              end
            end
          end

          context 'after the client is CONNECTED and the client\'s identity is known' do
            context 'with a valid client_id in the message' do
              it 'succeeds' do
                client.connection.once(:connected) do
                  channel.publish([name: 'event', client_id: 'valid']).tap do |deferrable|
                    deferrable.errback { raise 'Should have succeeded' }
                  end
                  channel.subscribe('event') do |message|
                    expect(message.client_id).to eql('valid')
                    EM.add_timer(0.5) { stop_reactor }
                  end
                end
              end
            end

            context 'with an invalid client_id in the message' do
              it 'throws an exception' do
                client.connection.once(:connected) do
                  expect { channel.publish([name: 'event', client_id: 'invalid']) }.to raise_error Ably::Exceptions::IncompatibleClientId
                  stop_reactor
                end
              end
            end

            context 'with an empty client_id in the message' do
              it 'succeeds and publishes with an implicit client_id' do
                client.connection.once(:connected) do
                  channel.publish([name: 'event', client_id: nil]).tap do |deferrable|
                    deferrable.errback { raise 'Should have succeeded' }
                  end
                  channel.subscribe('event') do |message|
                    expect(message.client_id).to eql('valid')
                    EM.add_timer(0.5) { stop_reactor }
                  end
                end
              end
            end
          end
        end

        context 'when authenticated with a valid client_id' do
          let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: 'valid') }
          let(:client_options)   { default_options.merge(key: nil, token: token) }
          let(:client)           { auto_close Ably::Realtime::Client.new(client_options) }
          let(:channel)          { client.channels.get(channel_name) }

          context 'with a valid client_id' do
            it 'succeeds' do
              channel.publish([name: 'event', client_id: 'valid']).tap do |deferrable|
                deferrable.errback { raise 'Should have succeeded' }
              end
              channel.subscribe('event') do |message|
                expect(message.client_id).to eql('valid')
                EM.add_timer(0.5) { stop_reactor }
              end
            end
          end

          context 'with a wildcard client_id in the message' do
            it 'throws an exception' do
              expect { channel.publish([name: 'event', client_id: '*']) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end

          context 'with an invalid client_id in the message' do
            it 'throws an exception' do
              expect { channel.publish([name: 'event', client_id: 'invalid']) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end

          context 'with an empty client_id in the message' do
            it 'succeeds and publishes with an implicit client_id' do
              channel.publish([name: 'event', client_id: nil]).tap do |deferrable|
                deferrable.errback { raise 'Should have succeeded' }
              end
              channel.subscribe('event') do |message|
                expect(message.client_id).to eql('valid')
                EM.add_timer(0.5) { stop_reactor }
              end
            end
          end
        end

        context 'when anonymous and no client_id' do
          let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: nil) }
          let(:client_options)   { default_options.merge(key: nil, token: token) }
          let(:client)           { auto_close Ably::Realtime::Client.new(client_options) }
          let(:channel)          { client.channels.get(channel_name) }

          context 'with a client_id in the message' do
            it 'throws an exception' do
              expect { channel.publish([name: 'event', client_id: 'invalid']) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end

          context 'with a wildcard client_id in the message' do
            it 'throws an exception' do
              expect { channel.publish([name: 'event', client_id: '*']) }.to raise_error Ably::Exceptions::IncompatibleClientId
              stop_reactor
            end
          end

          context 'with an empty client_id in the message' do
            it 'succeeds and publishes with an implicit client_id' do
              channel.publish([name: 'event', client_id: nil]).tap do |deferrable|
                deferrable.errback { raise 'Should have succeeded' }
              end
              channel.subscribe('event') do |message|
                expect(message.client_id).to be_nil
                EM.add_timer(0.5) { stop_reactor }
              end
            end
          end
        end
      end
    end

    describe '#subscribe' do
      context 'with an event argument' do
        it 'subscribes for a single event' do
          channel.subscribe('click') do |message|
            expect(message.data).to eql('data')
            stop_reactor
          end
          channel.publish('click', 'data')
        end
      end

      context 'before attach' do
        it 'receives messages as soon as attached' do
          channel.subscribe('click') do |message|
            expect(channel).to be_attached
            expect(message.data).to eql('data')
            stop_reactor
          end

          channel.publish('click', 'data')

          expect(channel).to be_attaching
        end
      end

      context 'with no event argument' do
        it 'subscribes for all events' do
          channel.subscribe do |message|
            expect(message.data).to eql('data')
            stop_reactor
          end
          channel.publish('click', 'data')
        end
      end

      context 'with a callback that raises an exception' do
        let(:exception) { StandardError.new("Intentional error") }

        it 'logs the error and continues' do
          emitted_exception = false
          expect(client.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/#{exception.message}/)
          end
          channel.subscribe('click') do |message|
            emitted_exception = true
            raise exception
          end
          channel.publish('click', 'data') do
            EventMachine.add_timer(1) do
              expect(emitted_exception).to eql(true)
              stop_reactor
            end
          end
        end
      end

      context 'many times with different event names' do
        it 'filters events accordingly to each callback' do
          click_callback = lambda { |message| messages << message }

          channel.subscribe('click', &click_callback)
          channel.subscribe('move', &click_callback)
          channel.subscribe('press', &click_callback)

          channel.attach do
            channel.publish('click', 'data')
            channel.publish('move', 'data')
            channel.publish('press', 'data') do
              EventMachine.add_timer(2) do
                expect(messages.count).to eql(3)
                stop_reactor
              end
            end
          end
        end
      end
    end

    describe '#unsubscribe' do
      context 'with an event argument' do
        it 'unsubscribes for a single event' do
          channel.subscribe('click') { raise 'Should not have been called' }
          channel.unsubscribe('click')

          channel.publish('click', 'data') do
            EventMachine.add_timer(1) do
              stop_reactor
            end
          end
        end
      end

      context 'with no event argument' do
        it 'unsubscribes for a single event' do
          channel.subscribe { raise 'Should not have been called' }
          channel.unsubscribe

          channel.publish('click', 'data') do
            EventMachine.add_timer(1) do
              stop_reactor
            end
          end
        end
      end
    end

    context 'when connection state changes to' do
      context ':failed' do
        let(:connection_error) { Ably::Exceptions::ConnectionFailed.new('forced failure', 500, 50000) }
        let(:client_options)   { default_options.merge(log_level: :none) }

        def fake_error(error)
          client.connection.manager.error_received_from_server error
        end

        context 'an :attaching channel' do
          it 'transitions state to :failed (#RTL3a)' do
            connection.once(:connected) do
              channel.once(:attaching) do
                channel.on(:failed) do |connection_state_change|
                  error = connection_state_change.reason
                  expect(error).to be_a(Ably::Exceptions::ConnectionFailed)
                  expect(error.code).to eql(50000)
                  stop_reactor
                end
                fake_error connection_error
              end
              channel.attach
            end
          end
        end

        context 'an :attached channel' do
          it 'transitions state to :failed (#RTL3a)' do
            channel.attach do
              channel.on(:failed) do |connection_state_change|
                error = connection_state_change.reason
                expect(error).to be_a(Ably::Exceptions::ConnectionFailed)
                expect(error.code).to eql(50000)
                stop_reactor
              end
              fake_error connection_error
            end
          end

          it 'updates the channel error_reason (#RTL3a)' do
            channel.attach do
              channel.on(:failed) do |connection_state_change|
                error = connection_state_change.reason
                expect(error).to be_a(Ably::Exceptions::ConnectionFailed)
                expect(error.code).to eql(50000)
                stop_reactor
              end
              fake_error connection_error
            end
          end
        end

        context 'a :detached channel' do
          it 'remains in the :detached state (#RTL3a)' do
            channel.attach do
              channel.on(:failed) { raise 'Failed state should not have been reached' }

              channel.detach do
                EventMachine.add_timer(1) do
                  expect(channel).to be_detached
                  stop_reactor
                end

                fake_error connection_error
              end
            end
          end
        end

        context 'a :failed channel' do
          let(:original_error) { RuntimeError.new }

          it 'remains in the :failed state and ignores the failure error (#RTL3a)' do
            channel.attach do
              channel.on(:failed) do
                channel.on(:failed) { raise 'Failed state should not have been reached' }

                EventMachine.add_timer(1) do
                  expect(channel).to be_failed
                  expect(channel.error_reason).to eql(original_error)
                  stop_reactor
                end

                fake_error connection_error
              end

              channel.transition_state_machine :failed, reason: original_error
            end
          end
        end

        context 'a channel ATTACH request' do
          it 'fails the deferrable (#RTL4b)' do
            client.connect do
              client.connection.once(:failed) do
                channel.attach.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                  stop_reactor
                end
              end
              fake_error connection_error
            end
          end
        end
      end

      context ':closed' do
        context 'an :attached channel' do
          it 'transitions state to :detached (#RTL3b)' do
            channel.attach do
              channel.on(:detached) do
                stop_reactor
              end
              client.connection.close
            end
          end
        end

        context 'an :attaching channel (#RTL3b)' do
          it 'transitions state to :detached' do
            channel.on(:attaching) do
              channel.on(:detached) do
                stop_reactor
              end
              client.connection.__incoming_protocol_msgbus__.unsubscribe
              client.connection.close
              closed_message = Ably::Models::ProtocolMessage.new(action: 8) # CLOSED
              client.connection.__incoming_protocol_msgbus__.publish :protocol_message, closed_message
            end
            channel.attach
          end
        end

        context 'a :detached channel' do
          it 'remains in the :detached state (#RTL3b)' do
            channel.attach do
              channel.detach do
                channel.on(:detached) { raise 'Detached state should not have been reached' }

                EventMachine.add_timer(1) do
                  expect(channel).to be_detached
                  stop_reactor
                end

                client.connection.close
              end
            end
          end
        end

        context 'a :failed channel' do
          let(:client_options)   { default_options.merge(log_level: :fatal) }
          let(:original_error) { Ably::Models::ErrorInfo.new(message: 'Error') }

          it 'remains in the :failed state and retains the error_reason (#RTL3b)' do
            channel.attach do
              channel.once(:failed) do
                channel.on(:detached) { raise 'Detached state should not have been reached' }

                EventMachine.add_timer(1) do
                  expect(channel).to be_failed
                  expect(channel.error_reason).to eql(original_error)
                  stop_reactor
                end

                client.connection.close
              end

              channel.transition_state_machine :failed, reason: original_error
            end
          end
        end

        context 'a channel ATTACH request when connection CLOSED' do
          it 'fails the deferrable (#RTL4b)' do
            client.connect do
              client.connection.once(:closed) do
                channel.attach.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                  stop_reactor
                end
              end
              client.close
            end
          end
        end

        context 'a channel ATTACH request when connection CLOSING' do
          it 'fails the deferrable (#RTL4b)' do
            client.connect do
              client.connection.once(:closing) do
                channel.attach.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                  stop_reactor
                end
              end
              client.close
            end
          end
        end
      end

      context ':suspended' do
        context 'an :attaching channel' do
          it 'transitions state to :suspended (#RTL3c)' do
            channel.on(:attaching) do
              channel.on(:suspended) do
                stop_reactor
              end
              client.connection.once_or_if(:connecting) do
                client.connection.transition_state_machine :suspended
              end
            end
            channel.attach
          end
        end

        context 'an :attached channel' do
          it 'transitions state to :suspended (#RTL3c)' do
            channel.attach do
              channel.on(:suspended) do
                stop_reactor
              end
              client.connection.transition_state_machine :suspended
            end
          end

          it 'transitions state automatically to :attaching once the connection is re-established (#RTN15c3)' do
            channel.attach do
              channel.on(:suspended) do
                client.connection.connect
                channel.once(:attached) do
                  stop_reactor
                end
              end
              client.connection.transition_state_machine :suspended
            end
          end
        end

        context 'a :detached channel' do
          it 'remains in the :detached state (#RTL3c)' do
            channel.attach do
              channel.detach do
                channel.on(:detached) { raise 'Detached state should not have been reached' }

                EventMachine.add_timer(1) do
                  expect(channel).to be_detached
                  stop_reactor
                end

                client.connection.transition_state_machine :suspended
              end
            end
          end
        end

        context 'a :failed channel' do
          let(:original_error) { RuntimeError.new }
          let(:client_options) { default_options.merge(log_level: :fatal) }

          it 'remains in the :failed state and retains the error_reason (#RTL3c)' do
            channel.attach do
              channel.once(:failed) do
                channel.on(:detached) { raise 'Detached state should not have been reached' }

                EventMachine.add_timer(1) do
                  expect(channel).to be_failed
                  expect(channel.error_reason).to eql(original_error)
                  stop_reactor
                end

                client.connection.transition_state_machine :suspended
              end

              channel.transition_state_machine :failed, reason: original_error
            end
          end
        end

        context 'a channel ATTACH request when connection SUSPENDED (#RTL4b)' do
          let(:client_options) { default_options.merge(log_level: :fatal) }

          it 'fails the deferrable' do
            client.connect do
              client.connection.once(:suspended) do
                channel.attach.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidStateChange)
                  stop_reactor
                end
              end
              client.connection.transition_state_machine :suspended
            end
          end
        end
      end

      context ':connected' do
        context 'a :suspended channel' do
          it 'is automatically reattached (#RTL3d)' do
            channel.attach do
              channel.once(:suspended) do
                client.connection.connect
                channel.once(:attached) do
                  stop_reactor
                end
              end
              client.connection.transition_state_machine :suspended
            end
          end

          context 'when re-attach attempt fails' do
            let(:client_options) do
              default_options.merge(realtime_request_timeout: 2, log_level: :fatal)
            end

            it 'returns to a suspended state (#RTL3d)' do
              channel.attach do
                channel.once(:attached) do
                  fail "Channel should not have become attached"
                end

                channel.once(:suspended) do
                  client.connection.connect
                  channel.once(:attaching) do
                    # don't process any incoming ProtocolMessages so the connection never opens
                    client.connection.__incoming_protocol_msgbus__.unsubscribe
                    channel.once(:suspended) do |state_change|
                      expect(state_change.reason.code).to eql(90007)
                      stop_reactor
                    end
                  end
                end
                client.connection.transition_state_machine :suspended
              end
            end
          end
        end
      end

      context ':disconnected' do
        context 'with an initialized channel' do
          it 'has no effect on the channel states (#RTL3e)' do
            connection.once(:connected) do
              expect(channel).to be_initialized
              connection.once(:disconnected) do
                expect(channel).to be_initialized
                stop_reactor
              end
              disconnect_transport
            end
          end
        end

        context 'with an attaching channel' do
          it 'has no effect on the channel states (#RTL3e)' do
            connection.once(:connected) do
              channel.once(:attaching) do
                connection.once(:disconnected) do
                  expect(channel).to be_attaching
                  stop_reactor
                end
                disconnect_transport
              end
              channel.attach
            end
          end
        end

        context 'with an attached channel' do
          it 'has no effect on the channel states (#RTL3e)' do
            channel.attach do
              connection.once(:disconnected) do
                expect(channel).to be_attached
                stop_reactor
              end
              disconnect_transport
            end
          end
        end

        context 'with a detached channel' do
          it 'has no effect on the channel states (#RTL3e)' do
            channel.attach do
              channel.detach do
                connection.once(:disconnected) do
                  expect(channel).to be_detached
                  stop_reactor
                end
                disconnect_transport
              end
            end
          end
        end

        context 'with a failed channel' do
          let(:client_options) do
            default_options.merge(
              default_token_params: { capability: { "foo" =>["*"] } },
              use_token_auth: true,
              log_level: :fatal
            )
          end

          it 'has no effect on the channel states (#RTL3e)' do
            channel.once(:failed) do
              connection.once(:disconnected) do
                expect(channel).to be_failed
                stop_reactor
              end
              disconnect_transport
            end
            channel.attach
          end
        end
      end
    end

    describe '#presence' do
      it 'returns a Ably::Realtime::Presence object' do
        expect(channel.presence).to be_a(Ably::Realtime::Presence)
        stop_reactor
      end
    end

    context 'channel state change' do
      it 'emits a ChannelStateChange object' do
        channel.on(:attached) do |channel_state_change|
          expect(channel_state_change).to be_a(Ably::Models::ChannelStateChange)
          stop_reactor
        end
        channel.attach
      end

      context 'ChannelStateChange object' do
        it 'has current state' do
          channel.on(:attached) do |channel_state_change|
            expect(channel_state_change.current).to be_a(Ably::Realtime::Channel::STATE)
            expect(channel_state_change.current).to eq(:attached)
            stop_reactor
          end
          channel.attach
        end

        it 'has a previous state' do
          channel.on(:attached) do |channel_state_change|
            expect(channel_state_change.previous).to be_a(Ably::Realtime::Channel::STATE)
            expect(channel_state_change.previous).to eq(:attaching)
            stop_reactor
          end
          channel.attach
        end

        it 'has the event that generated the state change (#TA5)' do
          channel.on(:attached) do |channel_state_change|
            expect(channel_state_change.event).to be_a(Ably::Realtime::Channel::EVENT)
            expect(channel_state_change.event).to eq(:attached)
            stop_reactor
          end
          channel.attach
        end

        it 'contains a private API protocol_message attribute that is used for special state change events', :api_private do
          channel.on(:attached) do |channel_state_change|
            expect(channel_state_change.protocol_message).to be_a(Ably::Models::ProtocolMessage)
            expect(channel_state_change.reason).to be_nil
            stop_reactor
          end
          channel.attach
        end

        it 'has an empty reason when there is no error' do
          channel.on(:detached) do |channel_state_change|
            expect(channel_state_change.reason).to be_nil
            stop_reactor
          end
          channel.attach do
            channel.detach
          end
        end

        context 'on failure' do
          let(:client_options) { default_options.merge(log_level: :none) }

          it 'has a reason Error object when there is an error on the channel' do
            channel.on(:failed) do |channel_state_change|
              expect(channel_state_change.reason).to be_a(Ably::Exceptions::BaseAblyException)
              stop_reactor
            end
            channel.attach do
              error = Ably::Exceptions::ConnectionFailed.new('forced failure', 500, 50000)
              client.connection.manager.error_received_from_server error
            end
          end
        end

        context '#resume (#RTL2f)' do
          let(:client_options) { default_options.merge(log_level: :fatal) }

          it 'is false when a channel first attaches' do
            channel.attach
            channel.on(:attached) do |channel_state_change|
              expect(channel_state_change.resumed).to be_falsey
              stop_reactor
            end
          end

          it 'is true when a connection is recovered and the channel is attached' do
            channel.attach
            channel.once(:attached) do |channel_state_change|
              connection_id = client.connection.id
              expect(channel_state_change.resumed).to be_falsey

              recover_client = auto_close Ably::Realtime::Client.new(client_options.merge(recover: client.connection.recovery_key))
              recover_client.connection.once(:connected) do
                expect(recover_client.connection.id).to eql(connection_id)
                recover_channel = recover_client.channels.get(channel_name)
                recover_channel.attach
                recover_channel.once(:attached) do |recover_channel_state_change|
                  expect(recover_channel_state_change.resumed).to be_truthy
                  stop_reactor
                end
              end
            end
          end

          it 'is false when a connection fails to recover and the channel is attached' do
            client.connection.once(:connected) do
              recovery_key = client.connection.recovery_key
              client.connection.once(:closed) do
                recover_client = auto_close Ably::Realtime::Client.new(client_options.merge(recover: recovery_key, log_level: :error))
                recover_client.connection.once(:connected) do
                  recover_channel = recover_client.channels.get(channel_name)
                  recover_channel.attach
                  recover_channel.once(:attached) do |recover_channel_state_change|
                    expect(recover_channel_state_change.resumed).to be_falsey
                    stop_reactor
                  end
                end
              end

              client.close
            end
          end

          context 'when a resume fails' do
            let(:client_options) { default_options.merge(log_level: :error) }

            it 'is false when a resume fails to recover and the channel is automatically re-attached' do
              channel.attach do
                connection_id = client.connection.id
                channel.once(:attached) do |channel_state_change|
                  expect(client.connection.id).to_not eql(connection_id)
                  expect(channel_state_change.resumed).to be_falsey
                  stop_reactor
                end
                client.connection.transport.close_connection_after_writing
                client.connection.configure_new '0123456789abcdef', 'wVIsgTHAB1UvXh7z-1991d8586', -1 # force the resume connection key to be invalid
              end
            end
          end
        end
      end

      context 'moves to' do
        %w(suspended failed).each do |channel_state|
          context(channel_state) do
            let(:client) do
              auto_close Ably::Realtime::Client.new(default_options.merge(log_level: :error))
            end

            specify 'all queued messages fail with NACK (#RTL11)' do
              channel.attach do
                # Move to disconnected
                disconnect_transport_proc = lambda do
                  if connection.transport
                    connection.transport.close_connection_after_writing
                  else
                    EventMachine.next_tick { disconnect_transport_proc.call }
                  end
                end
                disconnect_transport_proc.call

                connection.on(:connecting) { disconnect_transport_proc.call }

                connection.once(:disconnected) do
                  channel.publish("foo").errback do |error|
                    stop_reactor
                  end
                  channel.transition_state_machine channel_state.to_sym
                end
              end
            end

            specify 'all published messages awaiting an ACK do nothing (#RTL11a)' do
              connection_been_disconnected = false

              channel.attach
              channel.once(:attached) do
                deferrable = channel.publish("foo")
                deferrable.errback do |error|
                  fail "Message publish should not fail"
                end
                deferrable.callback do |error|
                  EventMachine.add_timer(0.5) do
                    expect(connection_been_disconnected).to be_truthy
                    stop_reactor
                  end
                end

                # Allow 5ms for message to be sent into the socket TCP/IP stack
                EventMachine.add_timer(0.005) do
                  connection.transport.close_connection_after_writing
                  connection.once(:disconnected) do
                    connection_been_disconnected = true
                    channel.transition_state_machine channel_state.to_sym
                  end
                end
              end
            end
          end
        end
      end
    end

    context 'when it receives a server-initiated DETACHED (#RTL13)' do
      let(:detached_action) { 13 }

      context 'and channel is initialized (#RTL13)' do
        it 'does nothing' do
          connection.once(:connected) do
            channel.on { raise 'Channel state should not change' }

            detach_message = Ably::Models::ProtocolMessage.new(action: detached_action, channel: channel_name)
            client.connection.__incoming_protocol_msgbus__.publish :protocol_message, detach_message

            EventMachine.add_timer(1) { stop_reactor }
          end
        end
      end

      context 'and channel is failed' do
        let(:client_options) {
          default_options.merge(
            use_token_auth: true,
            default_token_params: { capability: { "foo" => ["publish"] } },
            log_level: :fatal
          )
        }

        it 'does nothing (#RTL13)' do
          connection.once(:connected) do
            channel.attach
            channel.once(:failed) do
              channel.on { raise 'Channel state should not change' }

              detach_message = Ably::Models::ProtocolMessage.new(action: detached_action, channel: channel_name)
              client.connection.__incoming_protocol_msgbus__.publish :protocol_message, detach_message

              EventMachine.add_timer(1) { stop_reactor }
            end
          end
        end
      end

      context 'and channel is attached' do
        it 'reattaches immediately (#RTL13a)' do
          channel.attach do
            channel.once(:attaching) do |state_change|
              expect(state_change.reason.code).to eql(50505)
              channel.once(:attached) do
                stop_reactor
              end
            end

            detach_message = Ably::Models::ProtocolMessage.new(action: detached_action, channel: channel_name, error: { code: 50505 })
            client.connection.__incoming_protocol_msgbus__.publish :protocol_message, detach_message
          end
        end
      end

      context 'and channel is suspended' do
        it 'reattaches immediately (#RTL13a)' do
          channel.attach do
            channel.once(:suspended) do
              channel.once(:attaching) do |state_change|
                expect(state_change.reason.code).to eql(50505)
                channel.once(:attached) do
                  stop_reactor
                end
              end

              detach_message = Ably::Models::ProtocolMessage.new(action: detached_action, channel: channel_name, error: { code: 50505 })
              client.connection.__incoming_protocol_msgbus__.publish :protocol_message, detach_message
            end

            channel.transition_state_machine! :suspended
          end
        end
      end

      context 'and channel is attaching' do
        let(:client_options) { default_options.merge(channel_retry_timeout: 2, realtime_request_timeout: 1, log_level: :fatal) }

        it 'will move to the SUSPENDED state and then attempt to ATTACH with the ATTACHING state (#RTL13b)' do
          connection.once(:connected) do
            # Prevent any incoming or outgoing ATTACH/ATTACHED message from Ably
            prevent_protocol_messages_proc = lambda do
              if client.connection.transport
                client.connection.transport.__incoming_protocol_msgbus__.unsubscribe
                client.connection.transport.__outgoing_protocol_msgbus__.unsubscribe
              else
                EventMachine.next_tick { prevent_protocol_messages_proc.call }
              end
            end
            prevent_protocol_messages_proc.call
          end

          channel.once(:attaching) do
            attaching_at = Time.now
            # First attaching fails during server-initiated ATTACHED received
            channel.once(:suspended) do |state_change|
              expect(Time.now.to_i - attaching_at.to_i).to be_within(1).of(1)

              suspended_at = Time.now
              # Automatic attach happens at channel_retry_timeout
              channel.once(:attaching) do
                expect(Time.now.to_i - attaching_at.to_i).to be_within(1).of(2)
                channel.once(:suspended) do
                  channel.once(:attaching) do
                    channel.once(:attached) do
                      stop_reactor
                    end
                    # Simulate ATTACHED from Ably
                    attached_message = Ably::Models::ProtocolMessage.new(action: 11, channel: channel_name) # ATTACHED
                    client.connection.__incoming_protocol_msgbus__.publish :protocol_message, attached_message
                  end
                end
              end
            end

            detach_message = Ably::Models::ProtocolMessage.new(action: detached_action, channel: channel_name)
            client.connection.__incoming_protocol_msgbus__.publish :protocol_message, detach_message
          end
          channel.attach
        end
      end
    end

    context 'when it receives an ERROR ProtocolMessage' do
      let(:client_options) { default_options.merge(log_level: :fatal) }

      it 'should transition to the failed state and the error_reason should be set (#RTL14)' do
        channel.attach do
          channel.once(:failed) do |state_change|
            expect(state_change.reason.code).to eql(50505)
            expect(channel.error_reason.code).to eql(50505)
            stop_reactor
          end
          error_message = Ably::Models::ProtocolMessage.new(action: 9, channel: channel_name, error: { code: 50505 }) # ProtocolMessage ERROR type
          client.connection.__incoming_protocol_msgbus__.publish :protocol_message, error_message
        end
      end
    end
  end
end
