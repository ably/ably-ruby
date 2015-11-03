# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channel, :event_machine do
  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }

    let(:client)       { auto_close Ably::Realtime::Client.new(client_options) }
    let(:channel_name) { random_str }
    let(:payload)      { random_str }
    let(:channel)      { client.channel(channel_name) }
    let(:messages)     { [] }

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

      it 'attaches to a channel and calls the provided block' do
        channel.attach do
          expect(channel.state).to eq(:attached)
          stop_reactor
        end
      end

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        expect(channel.attach).to be_a(Ably::Util::SafeDeferrable)
        stop_reactor
      end

      it 'calls the SafeDeferrable callback on success' do
        channel.attach.callback do
          expect(channel).to be_a(Ably::Realtime::Channel)
          expect(channel.state).to eq(:attached)
          stop_reactor
        end
      end

      context 'when state is :failed' do
        let(:client_options) { default_options.merge(log_level: :fatal) }

        it 'reattaches' do
          channel.attach do
            channel.transition_state_machine :failed, reason: RuntimeError.new
            expect(channel).to be_failed
            channel.attach do
              expect(channel).to be_attached
              stop_reactor
            end
          end
        end
      end

      context 'when state is :detaching' do
        it 'moves straight to attaching and skips detached' do
          channel.once(:detaching) do
            channel.once(:detached) { raise 'Detach should not have been reached' }

            channel.once(:attaching) do
              channel.once(:attached) do
                channel.off
                stop_reactor
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
        let(:restricted_client) do
          auto_close Ably::Realtime::Client.new(default_options.merge(key: restricted_api_key, log_level: :fatal))
        end
        let(:restricted_channel) { restricted_client.channel("cannot_subscribe") }

        it 'emits failed event' do
          restricted_channel.attach
          restricted_channel.on(:failed) do |connection_state|
            expect(restricted_channel.state).to eq(:failed)
            expect(connection_state.reason.status).to eq(401)
            stop_reactor
          end
        end

        it 'calls the errback of the returned Deferrable' do
          restricted_channel.attach.errback do |error|
            expect(restricted_channel.state).to eq(:failed)
            expect(error.status).to eq(401)
            stop_reactor
          end
        end

        it 'emits an error event' do
          restricted_channel.attach
          restricted_channel.on(:error) do |error|
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
                # A direct call to #authorise is synchronous
                restricted_client.auth.authorise({}, key: api_key)

                restricted_client.connect do
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
    end

    describe '#detach' do
      it 'detaches from a channel' do
        channel.attach do
          channel.detach
          channel.on(:detached) do
            expect(channel.state).to eq(:detached)
            stop_reactor
          end
        end
      end

      it 'detaches from a channel and calls the provided block' do
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

      context 'when state is :failed' do
        let(:client_options) { default_options.merge(log_level: :fatal) }

        it 'raises an exception' do
          channel.attach do
            channel.transition_state_machine :failed, reason: RuntimeError.new
            expect(channel).to be_failed
            expect { channel.detach }.to raise_error Ably::Exceptions::InvalidStateChange
            stop_reactor
          end
        end
      end

      context 'when state is :attaching' do
        it 'moves straight to :detaching state and skips :attached' do
          channel.once(:attaching) do
            channel.once(:attached) { raise 'Attached should never be reached' }

            channel.once(:detaching) do
              channel.once(:detached) do
                stop_reactor
              end
            end

            channel.detach
          end

          channel.attach
        end
      end

      context 'when state is :detaching' do
        it 'ignores subsequent #detach calls but calls the callback if provided' do
          channel.once(:detaching) do
            channel.detach
            channel.once(:detached) do
              channel.detach do
                stop_reactor
              end
            end
          end

          channel.attach do
            channel.detach
          end
        end
      end

      context 'when state is :initialized' do
        it 'does nothing as there is no channel to detach' do
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
    end

    describe 'channel recovery in :attaching state' do
      context 'the transport is disconnected before the ATTACHED protocol message is received' do
        skip 'attach times out and fails if not ATTACHED protocol message received'
        skip 'channel is ATTACHED if ATTACHED protocol message is later received'
        skip 'sends an ATTACH protocol message in response to a channel message being received on the attaching channel'
      end
    end

    context '#publish' do
      let(:name)    { random_str }
      let(:data)    { random_str }

      context 'when attached' do
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

      context 'when not yet attached' do
        it 'publishes queued messages once attached' do
          3.times { channel.publish('event', random_str) }
          channel.subscribe do |message|
            messages << message if message.name == 'event'
            stop_reactor if messages.count == 3
          end
        end

        it 'publishes queued messages within a single protocol message' do
          3.times { channel.publish('event', random_str) }
          channel.subscribe do |message|
            messages << message if message.name == 'event'
            next unless messages.length == 3

            # All 3 messages should be batched into a single Protocol Message by the client library
            # message.id = "{protocol_message.id}:{protocol_message_index}"
            # Check that all messages share the same protocol_message.id
            message_id = messages.map { |msg| msg.id.split(':')[0] }
            expect(message_id.uniq.count).to eql(1)

            # Check that messages use index 0,1,2 in the ID
            message_indexes = messages.map { |msg| msg.id.split(':')[1] }
            expect(message_indexes).to include("0", "1", "2")
            stop_reactor
          end
        end

        context 'with :queue_messages client option set to false' do
          let(:client_options)  { default_options.merge(queue_messages: false) }

          context 'and connection state initialized' do
            it 'raises an exception' do
              expect { channel.publish('event') }.to raise_error Ably::Exceptions::MessageQueueingDisabled
              expect(client.connection).to be_initialized
              stop_reactor
            end
          end

          context 'and connection state connecting' do
            it 'raises an exception' do
              client.connect
              EventMachine.next_tick do
                expect { channel.publish('event') }.to raise_error Ably::Exceptions::MessageQueueingDisabled
                expect(client.connection).to be_connecting
                stop_reactor
              end
            end
          end

          context 'and connection state disconnected' do
            let(:client_options)  { default_options.merge(queue_messages: false, :log_level => :error ) }
            it 'raises an exception' do
              client.connection.once(:connected) do
                client.connection.once(:disconnected) do
                  expect { channel.publish('event') }.to raise_error Ably::Exceptions::MessageQueueingDisabled
                  expect(client.connection).to be_disconnected
                  stop_reactor
                end
                client.connection.transition_state_machine :disconnected
              end
            end
          end

          context 'and connection state connected' do
            it 'publishes the message' do
              client.connection.once(:connected) do
                channel.publish('event')
                stop_reactor
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

        context 'with two invalid message out of 12' do
          let(:client_options) { default_options.merge(client_id: 'valid') }
          let(:invalid_messages) do
            2.times.map do |index|
              Ably::Models::Message(name: index.to_s, data: { "index" => index + 10 }, client_id: 'prohibited')
            end
          end

          it 'calls the errback once' do
            skip 'Waiting for issue #256 to be resolved'
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

        context 'only invalid messages' do
          let(:client_options) { default_options.merge(client_id: 'valid') }
          let(:invalid_messages) do
            10.times.map do |index|
              Ably::Models::Message(name: index.to_s, data: { "index" => index + 10 }, client_id: 'prohibited')
            end
          end

          it 'calls the errback once' do
            skip 'Waiting for issue #256 to be resolved'
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

      context 'many times with different event names' do
        it 'filters events accordingly to each callback' do
          click_callback = proc { |message| messages << message }

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

        context 'an :attached channel' do
          it 'transitions state to :failed' do
            channel.attach do
              channel.on(:failed) do |connection_state_change|
                error = connection_state_change.reason
                expect(error).to be_a(Ably::Exceptions::ConnectionFailed)
                expect(error.code).to eql(80002)
                stop_reactor
              end
              fake_error connection_error
            end
          end

          it 'emits an error event on the channel' do
            channel.attach do
              channel.on(:error) do |error|
                expect(error).to be_a(Ably::Exceptions::ConnectionFailed)
                expect(error.code).to eql(80002)
                stop_reactor
              end
              fake_error connection_error
            end
          end

          it 'updates the channel error_reason' do
            channel.attach do
              channel.on(:failed) do |connection_state_change|
                error = connection_state_change.reason
                expect(error).to be_a(Ably::Exceptions::ConnectionFailed)
                expect(error.code).to eql(80002)
                stop_reactor
              end
              fake_error connection_error
            end
          end
        end

        context 'a :detached channel' do
          it 'remains in the :detached state' do
            channel.attach do
              channel.on(:failed) { raise 'Failed state should not have been reached' }
              channel.on(:error)  { raise 'Error should not have been emitted' }

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

          it 'remains in the :failed state and ignores the failure error' do
            channel.attach do
              channel.on(:error) do
                channel.on(:failed) { raise 'Failed state should not have been reached' }
                channel.on(:error)  { raise 'Error should not have been emitted' }

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
          it 'raises an exception' do
            client.connect do
              client.connection.once(:failed) do
                expect { channel.attach }.to raise_error Ably::Exceptions::InvalidStateChange
                stop_reactor
              end
              fake_error connection_error
            end
          end
        end
      end

      context ':closed' do
        context 'an :attached channel' do
          it 'transitions state to :detached' do
            channel.attach do
              channel.on(:detached) do
                stop_reactor
              end
              client.connection.close
            end
          end
        end

        context 'a :detached channel' do
          it 'remains in the :detached state' do
            channel.attach do
              channel.detach do
                channel.on(:detached) { raise 'Detached state should not have been reached' }
                channel.on(:error)    { raise 'Error should not have been emitted' }

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

          it 'remains in the :failed state and retains the error_reason' do
            channel.attach do
              channel.once(:error) do
                channel.on(:detached) { raise 'Detached state should not have been reached' }
                channel.on(:error)    { raise 'Error should not have been emitted' }

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
          it 'raises an exception' do
            client.connect do
              client.connection.once(:closed) do
                expect { channel.attach }.to raise_error Ably::Exceptions::InvalidStateChange
                stop_reactor
              end
              client.close
            end
          end
        end

        context 'a channel ATTACH request when connection CLOSING' do
          it 'raises an exception' do
            client.connect do
              client.connection.once(:closing) do
                expect { channel.attach }.to raise_error Ably::Exceptions::InvalidStateChange
                stop_reactor
              end
              client.close
            end
          end
        end
      end

      context ':suspended' do
        context 'an :attached channel' do
          let(:client_options) { default_options.merge(log_level: :fatal) }

          it 'transitions state to :detached' do
            channel.attach do
              channel.on(:detached) do
                stop_reactor
              end
              client.connection.transition_state_machine :suspended
            end
          end
        end

        context 'a :detached channel' do
          it 'remains in the :detached state' do
            channel.attach do
              channel.detach do
                channel.on(:detached) { raise 'Detached state should not have been reached' }
                channel.on(:error)    { raise 'Error should not have been emitted' }

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

          it 'remains in the :failed state and retains the error_reason' do
            channel.attach do
              channel.once(:error) do
                channel.on(:detached) { raise 'Detached state should not have been reached' }
                channel.on(:error)    { raise 'Error should not have been emitted' }

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

        context 'a channel ATTACH request when connection SUSPENDED' do
          let(:client_options) { default_options.merge(log_level: :fatal) }

          it 'raises an exception' do
            client.connect do
              client.connection.once(:suspended) do
                expect { channel.attach }.to raise_error Ably::Exceptions::InvalidStateChange
                stop_reactor
              end
              client.connection.transition_state_machine :suspended
            end
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
            expect(channel_state_change.current).to eq(:attached)
            stop_reactor
          end
          channel.attach
        end

        it 'has a previous state' do
          channel.on(:attached) do |channel_state_change|
            expect(channel_state_change.previous).to eq(:attaching)
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
      end
    end
  end
end
