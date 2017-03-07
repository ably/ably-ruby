# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Presence, :event_machine do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }

    let(:anonymous_client) { auto_close Ably::Realtime::Client.new(client_options) }
    let(:client_one_id)    { random_str }
    let(:client_one)       { auto_close Ably::Realtime::Client.new(client_options.merge(client_id: client_one_id)) }
    let(:client_two_id)    { random_str }
    let(:client_two)       { auto_close Ably::Realtime::Client.new(client_options.merge(client_id: client_two_id)) }

    let(:wildcard_token)            { Proc.new { Ably::Rest::Client.new(client_options).auth.request_token(client_id: '*') } }
    let(:channel_name)              { "presence-#{random_str(4)}" }
    let(:channel_anonymous_client)  { anonymous_client.channel(channel_name) }
    let(:presence_anonymous_client) { channel_anonymous_client.presence }
    let(:channel_client_one)        { client_one.channel(channel_name) }
    let(:channel_rest_client_one)   { client_one.rest_client.channel(channel_name) }
    let(:presence_client_one)       { channel_client_one.presence }
    let(:channel_client_two)        { client_two.channel(channel_name) }
    let(:presence_client_two)       { channel_client_two.presence }
    let(:data_payload)              { random_str }

    def force_connection_failure(client)
      # Prevent any further SYNC messages coming in on this connection
      client.connection.transport.send(:driver).remove_all_listeners('message')
      client.connection.transport.unbind
    end

    shared_examples_for 'a public presence method' do |method_name, expected_state, args, options = {}|
      let(:client_id) do
        if args.empty?
          random_str
        else
          args
        end
      end

      def setup_test(method_name, args, options)
        if options[:enter_first]
          presence_client_one.subscribe do
            presence_client_one.unsubscribe
            yield
          end
          presence_client_one.public_send(method_name.to_s.gsub(/leave|update/, 'enter'), args)
        else
          yield
        end
      end

      unless expected_state == :left
        it 'raise an exception if the channel is detached' do
          setup_test(method_name, args, options) do
            channel_client_one.attach do
              channel_client_one.transition_state_machine :detaching
              channel_client_one.once(:detached) do
                expect { presence_client_one.public_send(method_name, args) }.to raise_error Ably::Exceptions::InvalidStateChange, /Operation is not allowed when channel is in STATE.detached/i
                stop_reactor
              end
            end
          end
        end

        it 'raise an exception if the channel is failed' do
          setup_test(method_name, args, options) do
            channel_client_one.attach do
              channel_client_one.transition_state_machine :failed
              expect(channel_client_one.state).to eq(:failed)
              expect { presence_client_one.public_send(method_name, args) }.to raise_error Ably::Exceptions::InvalidStateChange, /Operation is not allowed when channel is in STATE.failed/i
              stop_reactor
            end
          end
        end

        it 'implicitly attaches the channel' do
          expect(channel_client_one).to_not be_attached
          presence_client_one.public_send(method_name, args) do
            expect(channel_client_one).to be_attached
            stop_reactor
          end
        end

        context 'when :queue_messages client option is false' do
          let(:client_one) { auto_close Ably::Realtime::Client.new(default_options.merge(queue_messages: false, client_id: client_id)) }

          context 'and connection state initialized' do
            it 'raises an exception' do
              expect { presence_client_one.public_send(method_name, args) }.to raise_error Ably::Exceptions::MessageQueueingDisabled
              expect(client_one.connection).to be_initialized
              stop_reactor
            end
          end

          context 'and connection state connecting' do
            it 'raises an exception' do
              client_one.connect
              EventMachine.next_tick do
                expect { presence_client_one.public_send(method_name, args) }.to raise_error Ably::Exceptions::MessageQueueingDisabled
                expect(client_one.connection).to be_connecting
                stop_reactor
              end
            end
          end

          context 'and connection state disconnected' do
            let(:client_one) { auto_close Ably::Realtime::Client.new(default_options.merge(queue_messages: false, client_id: client_id, :log_level => :error)) }

            it 'raises an exception' do
              client_one.connection.once(:connected) do
                client_one.connection.once(:disconnected) do
                  expect { presence_client_one.public_send(method_name, args) }.to raise_error Ably::Exceptions::MessageQueueingDisabled
                  expect(client_one.connection).to be_disconnected
                  stop_reactor
                end
                client_one.connection.transition_state_machine :disconnected
              end
            end
          end

          context 'and connection state connected' do
            it 'publishes the message' do
              client_one.connection.once(:connected) do
                presence_client_one.public_send(method_name, args)
                stop_reactor
              end
            end
          end
        end
      end

      context 'with supported data payload content type' do
        def register_presence_and_check_data(method_name, data)
          if method_name.to_s.match(/_client/)
            presence_client_one.public_send(method_name, client_id, data)
          else
            presence_client_one.public_send(method_name, data)
          end

          presence_client_one.subscribe do |presence_message|
            expect(presence_message.data).to eql(data)
            stop_reactor
          end
        end

        context 'JSON Object (Hash)' do
          let(:data) { { 'Hash' => 'true' } }

          it 'is encoded and decoded to the same hash' do
            setup_test(method_name, args, options) do
              register_presence_and_check_data method_name, data
            end
          end
        end

        context 'JSON Array' do
          let(:data) { [ nil, true, false, 55, 'string', { 'Hash' => true }, ['array'] ] }

          it 'is encoded and decoded to the same Array' do
            setup_test(method_name, args, options) do
              register_presence_and_check_data method_name, data
            end
          end
        end

        context 'String' do
          let(:data) { random_str }

          it 'is encoded and decoded to the same Array' do
            setup_test(method_name, args, options) do
              register_presence_and_check_data method_name, data
            end
          end
        end

        context 'Binary' do
          let(:data) { Base64.encode64(random_str) }

          it 'is encoded and decoded to the same Array' do
            setup_test(method_name, args, options) do
              register_presence_and_check_data method_name, data
            end
          end
        end
      end

      context 'with unsupported data payload content type' do
        def presence_action(method_name, data)
          if method_name.to_s.match(/_client/)
            presence_client_one.public_send(method_name, client_id, data)
          else
            presence_client_one.public_send(method_name, data)
          end
        end

        context 'Integer' do
          let(:data) { 1 }

          it 'raises an UnsupportedDataType 40011 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end

        context 'Float' do
          let(:data) { 1.1 }

          it 'raises an UnsupportedDataType 40011 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end

        context 'Boolean' do
          let(:data) { true }

          it 'raises an UnsupportedDataType 40011 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end

        context 'False' do
          let(:data) { false }

          it 'raises an UnsupportedDataType 40011 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end
      end

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        setup_test(method_name, args, options) do
          expect(presence_client_one.public_send(method_name, args)).to be_a(Ably::Util::SafeDeferrable)
          stop_reactor
        end
      end

      it 'allows a block to be passed in that is executed upon success' do
        setup_test(method_name, args, options) do
          presence_client_one.public_send(method_name, args) do
            stop_reactor
          end
        end
      end

      it 'calls the Deferrable callback on success' do
        setup_test(method_name, args, options) do
          presence_client_one.public_send(method_name, args).callback do |presence|
            expect(presence).to eql(presence_client_one)
            expect(presence_client_one.state).to eq(expected_state) if expected_state
            stop_reactor
          end
        end
      end

      it 'catches exceptions in the provided method block and logs them to the logger' do
        setup_test(method_name, args, options) do
          expect(presence_client_one.logger).to receive(:error).with(/Intentional exception/) do
            stop_reactor
          end
          presence_client_one.public_send(method_name, args) { raise 'Intentional exception' }
        end
      end

      context 'if connection fails before success' do
        let(:client_options) { default_options.merge(log_level: :none) }

        it 'calls the Deferrable errback if channel is detached' do
          setup_test(method_name, args, options) do
            channel_client_one.attach do
              client_one.connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                # Don't allow any messages to reach the server
                client_one.connection.__outgoing_protocol_msgbus__.unsubscribe
                error_message = Ably::Models::ProtocolMessage.new(action: 9, error: { message: 'force failure' })
                client_one.connection.__incoming_protocol_msgbus__.publish :protocol_message, error_message
              end

              presence_client_one.public_send(method_name, args).tap do |deferrable|
                deferrable.callback { raise 'Should not succeed' }
                deferrable.errback do |error|
                  expect(error).to be_kind_of(Ably::Exceptions::BaseAblyException)
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    shared_examples_for 'a presence on behalf of another client method' do |method_name|
      context ":#{method_name} when authenticated with a wildcard client_id" do
        let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: '*').token }
        let(:client_options)   { default_options.merge(key: nil, token: token) }
        let(:client)           { auto_close Ably::Realtime::Client.new(client_options) }
        let(:presence_channel) { client.channels.get(channel_name).presence }

        context 'and a valid client_id' do
          it 'succeeds' do
            presence_channel.public_send(method_name, 'clientId') do
              EM.add_timer(0.5) { stop_reactor }
            end.tap do |deferrable|
              deferrable.errback { raise 'Should have succeeded' }
            end
          end
        end

        context 'and a wildcard client_id' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, '*') }.to raise_error Ably::Exceptions::IncompatibleClientId
            stop_reactor
          end
        end

        context 'and an empty client_id' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, nil) }.to raise_error Ably::Exceptions::IncompatibleClientId
            stop_reactor
          end
        end
      end

      context ":#{method_name} when authenticated with a valid client_id" do
        let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: 'valid').token }
        let(:client_options)   { default_options.merge(key: nil, token: token) }
        let(:client)           { auto_close Ably::Realtime::Client.new(client_options.merge(log_level: :error)) }
        let(:channel)          { client.channels.get(channel_name) }
        let(:presence_channel) { channel.presence }

        context 'and another invalid client_id' do
          context 'before authentication' do
            it 'allows the operation and then Ably rejects the operation' do
              presence_channel.public_send(method_name, 'invalid').errback do |error|
                expect(error.code).to eql(40012)
                stop_reactor
              end
            end
          end

          context 'after authentication' do
            it 'throws an exception' do
              channel.attach do
                expect { presence_channel.public_send(method_name, 'invalid') }.to raise_error Ably::Exceptions::IncompatibleClientId
                stop_reactor
              end
            end
          end
        end

        context 'and a wildcard client_id' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, '*') }.to raise_error Ably::Exceptions::IncompatibleClientId
            stop_reactor
          end
        end

        context 'and an empty client_id' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, nil) }.to raise_error Ably::Exceptions::IncompatibleClientId
            stop_reactor
          end
        end
      end

      context ":#{method_name} when anonymous and no client_id" do
        let(:token)            { Ably::Rest::Client.new(default_options).auth.request_token(client_id: nil).token }
        let(:client_options)   { default_options.merge(key: nil, token: token) }
        let(:client)           { auto_close Ably::Realtime::Client.new(client_options.merge(log_level: :error)) }
        let(:channel)          { client.channels.get(channel_name) }
        let(:presence_channel) { channel.presence }

        context 'and another invalid client_id' do
          context 'before authentication' do
            it 'allows the operation and then Ably rejects the operation' do
              presence_channel.public_send(method_name, 'invalid').errback do |error|
                expect(error.code).to eql(40012)
                stop_reactor
              end
            end
          end

          context 'after authentication' do
            it 'throws an exception' do
              channel.attach do
                expect { presence_channel.public_send(method_name, 'invalid') }.to raise_error Ably::Exceptions::IncompatibleClientId
                stop_reactor
              end
            end
          end
        end

        context 'and a wildcard client_id' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, '*') }.to raise_error Ably::Exceptions::IncompatibleClientId
            stop_reactor
          end
        end

        context 'and an empty client_id' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, nil) }.to raise_error Ably::Exceptions::IncompatibleClientId
            stop_reactor
          end
        end
      end
    end

    context 'when attached (but not present) on a presence channel with an anonymous client (no client ID)' do
      it 'maintains state as other clients enter and leave the channel' do
        channel_anonymous_client.attach do
          presence_anonymous_client.subscribe(:enter) do |presence_message|
            expect(presence_message.client_id).to eql(client_one.client_id)

            presence_anonymous_client.get do |members|
              expect(members.first.client_id).to eql(client_one.client_id)
              expect(members.first.action).to eq(:enter)

              presence_anonymous_client.subscribe(:leave) do |leave_presence_message|
                expect(leave_presence_message.client_id).to eql(client_one.client_id)

                presence_anonymous_client.get do |members_once_left|
                  expect(members_once_left.count).to eql(0)
                  stop_reactor
                end
              end
            end
          end
        end

        presence_client_one.enter do
          presence_client_one.leave
        end
      end
    end

    context '#members map', api_private: true do
      it 'is available once the channel is created' do
        expect(presence_anonymous_client.members).to_not be_nil
        stop_reactor
      end

      it 'is not synchronised when initially created' do
        expect(presence_anonymous_client.members).to_not be_sync_complete
        stop_reactor
      end

      it 'will emit an :in_sync event when synchronisation is complete' do
        presence_client_one.enter
        presence_client_two.enter

        presence_anonymous_client.members.once(:in_sync) do
          stop_reactor
        end

        channel_anonymous_client.attach
      end

      context 'before server sync complete' do
        it 'behaves like an Enumerable allowing direct access to current members' do
          expect(presence_anonymous_client.members.count).to eql(0)
          expect(presence_anonymous_client.members.map(&:member_key)).to eql([])
          stop_reactor
        end
      end

      context 'once server sync is complete' do
        it 'behaves like an Enumerable allowing direct access to current members' do
          presence_client_one.enter
          presence_client_two.enter

          entered = 0
          presence_client_one.subscribe(:enter) do
            entered += 1
            next unless entered == 2

            presence_anonymous_client.members.once(:in_sync) do
              expect(presence_anonymous_client.members.count).to eql(2)
              member_ids = presence_anonymous_client.members.map(&:member_key)
              expect(member_ids.count).to eql(2)
              expect(member_ids.uniq.count).to eql(2)
              stop_reactor
            end

            channel_anonymous_client.attach
          end
        end
      end
    end

    context '#sync_complete?' do
      context 'when attaching to a channel without any members present' do
        it 'is true and the presence channel is considered synced immediately' do
          channel_anonymous_client.attach do
            expect(channel_anonymous_client.presence).to be_sync_complete
            stop_reactor
          end
        end
      end

      context 'when attaching to a channel with members present' do
        it 'is false and the presence channel will subsequently be synced' do
          presence_client_one.enter
          presence_client_one.subscribe(:enter) do
            presence_client_one.unsubscribe :enter

            channel_anonymous_client.attach do
              expect(channel_anonymous_client.presence).to_not be_sync_complete
              channel_anonymous_client.presence.get(wait_for_sync: true) do
                expect(channel_anonymous_client.presence).to be_sync_complete
                stop_reactor
              end
            end
          end
        end
      end
    end

    context '250 existing (present) members on a channel (3 SYNC pages)' do
      context 'requires at least 3 SYNC ProtocolMessages', em_timeout: 30 do
        let(:enter_expected_count) { 250 }
        let(:present) { [] }
        let(:entered) { [] }
        let(:sync_pages_received) { [] }
        let(:client_one) { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }

        def setup_members_on(presence)
          enter_expected_count.times do |index|
            # 10 messages per second max rate on simulation accounts
            EventMachine.add_timer(index / 10) do
              presence.enter_client("client:#{index}") do |message|
                entered << message
                next unless entered.count == enter_expected_count
                yield
              end
            end
          end
        end

        context 'when a client attaches to the presence channel' do
          it 'emits :present for each member' do
            setup_members_on(presence_client_one) do
              presence_anonymous_client.subscribe(:present) do |present_message|
                expect(present_message.action).to eq(:present)
                present << present_message
                next unless present.count == enter_expected_count

                expect(present.map(&:client_id).uniq.count).to eql(enter_expected_count)
                stop_reactor
              end
            end
          end

          context 'and a member leaves before the SYNC operation is complete' do
            it 'emits :leave immediately as the member leaves' do
              all_client_ids = enter_expected_count.times.map { |id| "client:#{id}" }

              setup_members_on(presence_client_one) do
                leave_member = nil

                presence_anonymous_client.subscribe(:present) do |present_message|
                  present << present_message
                  all_client_ids.delete(present_message.client_id)
                end

                presence_anonymous_client.subscribe(:leave) do |leave_message|
                  expect(leave_message.client_id).to eql(leave_member.client_id)
                  expect(present.count).to be < enter_expected_count
                  EventMachine.add_timer(1) do
                    presence_anonymous_client.unsubscribe
                    stop_reactor
                  end
                end

                anonymous_client.connect do
                  anonymous_client.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    if protocol_message.action == :sync
                      sync_pages_received << protocol_message
                      if sync_pages_received.count == 1
                        leave_action = Ably::Models::PresenceMessage::ACTION.Leave
                        leave_member = Ably::Models::PresenceMessage.new(
                          'id' => "#{client_one.connection.id}-#{all_client_ids.first}:0",
                          'clientId' => all_client_ids.first,
                          'connectionId' => client_one.connection.id,
                          'timestamp' => as_since_epoch(Time.now),
                          'action' => leave_action
                        )
                        presence_anonymous_client.__incoming_msgbus__.publish :presence, leave_member
                      end
                    end
                  end
                end
              end
            end

            it 'ignores presence events with timestamps prior to the current :present event in the MembersMap' do
              started_at = Time.now

              setup_members_on(presence_client_one) do
                leave_member = nil

                presence_anonymous_client.subscribe(:present) do |present_message|
                  present << present_message
                  leave_member = present_message unless leave_member

                  if present.count == enter_expected_count
                    presence_anonymous_client.get do |members|
                      expect(members.find { |member| member.client_id == leave_member.client_id}.action).to eq(:present)
                      EventMachine.add_timer(1) do
                        presence_anonymous_client.unsubscribe
                        stop_reactor
                      end
                    end
                  end
                end

                presence_anonymous_client.subscribe(:leave) do |leave_message|
                  raise 'Leave event should not have been fired because it is out of date'
                end

                anonymous_client.connect do
                  anonymous_client.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    if protocol_message.action == :sync
                      sync_pages_received << protocol_message
                      if sync_pages_received.count == 1
                        leave_action = Ably::Models::PresenceMessage::ACTION.Leave
                        leave_member = Ably::Models::PresenceMessage.new(
                          leave_member.as_json.merge('action' => leave_action, 'timestamp' => as_since_epoch(started_at))
                        )
                        presence_anonymous_client.__incoming_msgbus__.publish :presence, leave_member
                      end
                    end
                  end
                end
              end
            end

            it 'does not emit :present after the :leave event has been emitted, and that member is not included in the list of members via #get with :wait_for_sync' do
              left_client = 10
              left_client_id = "client:#{left_client}"

              setup_members_on(presence_client_one) do
                member_left_emitted = false

                presence_anonymous_client.subscribe(:present) do |present_message|
                  if present_message.client_id == left_client_id
                    raise "Member #{present_message.client_id} should not have been emitted as present"
                  end
                  present << present_message.client_id
                end

                presence_anonymous_client.subscribe(:leave) do |leave_message|
                  if present.include?(leave_message.client_id)
                    raise "Member #{leave_message.client_id} should not have been emitted as present previously"
                  end
                  expect(leave_message.client_id).to eql(left_client_id)
                  member_left_emitted = true
                end

                presence_anonymous_client.get(wait_for_sync: true) do |members|
                  expect(members.count).to eql(enter_expected_count - 1)
                  expect(member_left_emitted).to eql(true)
                  expect(members.map(&:client_id)).to_not include(left_client_id)
                  EventMachine.add_timer(1) do
                    presence_anonymous_client.unsubscribe
                    stop_reactor
                  end
                end

                channel_anonymous_client.attach do
                  leave_action = Ably::Models::PresenceMessage::ACTION.Leave
                  fake_leave_presence_message = Ably::Models::PresenceMessage.new(
                    'id' => "#{client_one.connection.id}-#{left_client_id}:0",
                    'clientId' => left_client_id,
                    'connectionId' => client_one.connection.id,
                    'timestamp' => as_since_epoch(Time.now),
                    'action' => leave_action
                  )
                  # Push out a LEAVE event directly to the Presence object before it's received the :present action via the SYNC ProtocolMessage
                  presence_anonymous_client.__incoming_msgbus__.publish :presence, fake_leave_presence_message
                end
              end
            end
          end

          context '#get' do
            context 'with :wait_for_sync option set to true' do
              it 'waits until sync is complete', em_timeout: 30 do # allow for slow connections and lots of messages
                enter_expected_count.times do |index|
                  EventMachine.add_timer(index / 10) do
                    presence_client_one.enter_client("client:#{index}")
                  end
                end

                presence_client_one.subscribe(:enter) do |message|
                  entered << message
                  next unless entered.count == enter_expected_count

                  presence_anonymous_client.get(wait_for_sync: true) do |members|
                    expect(members.map(&:client_id).uniq.count).to eql(enter_expected_count)
                    expect(members.count).to eql(enter_expected_count)
                    stop_reactor
                  end
                end
              end
            end

            context 'by default' do
              it 'it does not wait for sync', em_timeout: 30 do # allow for slow connections and lots of messages
                enter_expected_count.times do |indx|
                  EventMachine.add_timer(indx / 10) do
                    presence_client_one.enter_client "client:#{indx}"
                  end
                end

                presence_client_one.subscribe(:enter) do |message|
                  entered << message
                  next unless entered.count == enter_expected_count

                  channel_anonymous_client.attach do
                    presence_anonymous_client.get do |members|
                      expect(presence_anonymous_client.members).to_not be_in_sync
                      expect(members.count).to eql(0)
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

    context 'state' do
      context 'once opened' do
        it 'once opened, enters the :left state if the channel detaches' do
          detached = false

          channel_client_one.presence.on(:left) do
            expect(channel_client_one.presence.state).to eq(:left)
            EventMachine.next_tick do
              expect(detached).to eq(true)
              stop_reactor
            end
          end

          channel_client_one.presence.enter do |presence|
            expect(presence.state).to eq(:entered)
            channel_client_one.detach do
              expect(channel_client_one.state).to eq(:detached)
              detached = true
            end
          end
        end
      end
    end

    context '#enter' do
      context 'data attribute' do
        context 'when provided as argument option to #enter' do
          it 'changes to value provided in #leave' do
            leave_callback_called = false

            presence_client_one.enter('stored') do
              expect(presence_client_one.data).to eql('stored')

              presence_client_one.leave do |presence|
                leave_callback_called = true
              end

              presence_client_one.on(:left) do
                expect(presence_client_one.data).to eql(nil)

                EventMachine.next_tick do
                  expect(leave_callback_called).to eql(true)
                  stop_reactor
                end
              end
            end
          end
        end
      end

      context 'message #connection_id' do
        it 'matches the current client connection_id' do
          channel_client_two.attach do
            presence_client_one.enter
          end

          presence_client_two.subscribe do |presence|
            expect(presence.connection_id).to eq(client_one.connection.id)
            stop_reactor
          end
        end
      end

      context 'without necessary capabilities to join presence' do
        let(:restricted_client) do
          auto_close Ably::Realtime::Client.new(default_options.merge(key: restricted_api_key, log_level: :fatal))
        end
        let(:restricted_channel)  { restricted_client.channel("cansubscribe:channel") }
        let(:restricted_presence) { restricted_channel.presence }

        it 'calls the Deferrable errback on capabilities failure' do
          restricted_presence.enter_client('bob').tap do |deferrable|
            deferrable.callback { raise "Should not succeed" }
            deferrable.errback { stop_reactor }
          end
        end
      end

      it_should_behave_like 'a public presence method', :enter, :entered, {}
    end

    context '#update' do
      it 'without previous #enter automatically enters' do
        presence_client_one.update(data_payload) do
          EventMachine.add_timer(1) do
            expect(presence_client_one.state).to eq(:entered)
            stop_reactor
          end
        end
      end

      context 'when ENTERED' do
        it 'has no effect on the state' do
          presence_client_one.enter do
            presence_client_one.once_state_changed { fail 'State should not have changed ' }

            presence_client_one.update(data_payload) do
              EventMachine.add_timer(1) do
                expect(presence_client_one.state).to eq(:entered)
                presence_client_one.off
                stop_reactor
              end
            end
          end
        end
      end

      it 'updates the data if :data argument provided' do
        presence_client_one.enter('prior') do
          presence_client_one.update(data_payload)
        end
        presence_client_one.subscribe(:update) do |message|
          expect(message.data).to eql(data_payload)
          stop_reactor
        end
      end

      it 'updates the data to nil if :data argument is not provided (assumes nil value)' do
        presence_client_one.enter('prior') do
          presence_client_one.update
        end
        presence_client_one.subscribe(:update) do |message|
          expect(message.data).to be_nil
          stop_reactor
        end
      end

      it_should_behave_like 'a public presence method', :update, :entered, {}, enter_first: true
    end

    context '#leave' do
      context ':data option' do
        let(:data) { random_str }
        let(:enter_data) { random_str }

        context 'when set to a string' do
          it 'emits the new data for the leave event' do
            presence_client_one.enter enter_data do
              presence_client_one.leave data
            end

            presence_client_one.subscribe(:leave) do |presence_message|
              expect(presence_message.data).to eql(data)
              stop_reactor
            end
          end
        end

        context 'when set to nil' do
          it 'emits the last value for the data attribute when leaving' do
            presence_client_one.enter enter_data do
              presence_client_one.leave nil
            end

            presence_client_one.subscribe(:leave) do |presence_message|
              expect(presence_message.data).to eql(enter_data)
              stop_reactor
            end
          end
        end

        context 'when not passed as an argument (i.e. nil)' do
          it 'emits the previous value for the data attribute when leaving' do
            presence_client_one.enter enter_data do
              presence_client_one.leave
            end

            presence_client_one.subscribe(:leave) do |presence_message|
              expect(presence_message.data).to eql(enter_data)
              stop_reactor
            end
          end
        end

        context 'and sync is complete' do
          it 'does not cache members that have left' do
            enter_ack = false

            presence_client_one.subscribe(:enter) do
              presence_client_one.unsubscribe :enter

              expect(presence_client_one.members).to be_in_sync
              expect(presence_client_one.members.send(:members).count).to eql(1)
              presence_client_one.leave data
            end

            presence_client_one.enter(enter_data) do
              enter_ack = true
            end

            presence_client_one.subscribe(:leave) do |presence_message|
              presence_client_one.unsubscribe :leave
              expect(presence_message.data).to eql(data)
              expect(presence_client_one.members.send(:members).count).to eql(0)
              expect(enter_ack).to eql(true)
              stop_reactor
            end
          end
        end
      end

      it 'raises an exception if not entered' do
        expect { channel_client_one.presence.leave }.to raise_error(Ably::Exceptions::Standard, /Unable to leave presence channel that is not entered/)
        stop_reactor
      end

      it_should_behave_like 'a public presence method', :leave, :left, {}, enter_first: true
    end

    context ':left event' do
      it 'emits the data defined in enter' do
        channel_client_one.presence.enter('data') do
          channel_client_one.presence.leave
        end

        channel_client_two.presence.subscribe(:leave) do |message|
          expect(message.data).to eql('data')
          stop_reactor
        end
      end

      it 'emits the data defined in update' do
        channel_client_one.presence.enter('something else') do
          channel_client_one.presence.update('data') do
            channel_client_one.presence.leave
          end
        end

        channel_client_two.presence.subscribe(:leave) do |message|
          expect(message.data).to eql('data')
          stop_reactor
        end
      end
    end

    context 'entering/updating/leaving presence state on behalf of another client_id' do
      let(:client_count) { 5 }
      let(:clients)      { [] }
      let(:data)         { random_str }
      let(:client_one)   { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }
      let(:client_two)   { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }

      context '#enter_client' do
        context 'multiple times on the same channel with different client_ids' do
          it "has no affect on the client's presence state and only enters on behalf of the provided client_id" do
            client_count.times do |client_id|
              presence_client_one.enter_client("client:#{client_id}") do
                presence_client_one.on(:entered) { raise 'Should not have entered' }
                next unless client_id == client_count - 1

                EventMachine.add_timer(1) do
                  expect(presence_client_one.state).to eq(:initialized)
                  stop_reactor
                end
              end
            end
          end

          it 'enters a channel and sets the data based on the provided :data option' do
            client_count.times do |client_id|
              presence_client_one.enter_client("client:#{client_id}", data)
            end

            presence_anonymous_client.subscribe(:enter) do |presence|
              expect(presence.data).to eql(data)
              clients << presence
              next unless clients.count == 5

              expect(clients.map(&:client_id).uniq.count).to eql(5)
              stop_reactor
            end
          end
        end

        context 'message #connection_id' do
          let(:client_id) { random_str }

          it 'matches the current client connection_id' do
            channel_client_two.attach do
              presence_client_one.enter_client(client_id)
            end

            presence_client_two.subscribe do |presence|
              expect(presence.client_id).to eq(client_id)
              expect(presence.connection_id).to eq(client_one.connection.id)
              stop_reactor
            end
          end
        end

        context 'without necessary capabilities to enter on behalf of another client' do
          let(:restricted_client) do
            auto_close Ably::Realtime::Client.new(default_options.merge(key: restricted_api_key, log_level: :fatal))
          end
          let(:restricted_channel)  { restricted_client.channel("cansubscribe:channel") }
          let(:restricted_presence) { restricted_channel.presence }

          it 'calls the Deferrable errback on capabilities failure' do
            restricted_presence.enter_client('clientId').tap do |deferrable|
              deferrable.callback { raise "Should not succeed" }
              deferrable.errback { stop_reactor }
            end
          end
        end

        it_should_behave_like 'a public presence method', :enter_client, nil, 'client_id'
        it_should_behave_like 'a presence on behalf of another client method', :enter_client
      end

      context '#update_client' do
        context 'multiple times on the same channel with different client_ids' do
          it 'updates the data attribute for the member when :data option provided' do
            updated_callback_count = 0

            client_count.times do |client_id|
              presence_client_one.enter_client("client:#{client_id}") do
                presence_client_one.update_client("client:#{client_id}", data) do
                  updated_callback_count += 1
                end
              end
            end

            presence_anonymous_client.subscribe(:update) do |presence|
              expect(presence.data).to eql(data)
              clients << presence
              next unless clients.count == 5

              wait_until(proc { updated_callback_count == 5 }) do
                expect(clients.map(&:client_id).uniq.count).to eql(5)
                expect(updated_callback_count).to eql(5)
                stop_reactor
              end
            end
          end

          it 'updates the data attribute to null for the member when :data option is not provided (assumed null)' do
            presence_client_one.enter_client('client_1') do
              presence_client_one.update_client('client_1')
            end

            presence_anonymous_client.subscribe(:update) do |presence|
              expect(presence.client_id).to eql('client_1')
              expect(presence.data).to be_nil
              stop_reactor
            end
          end

          it 'enters if not already entered' do
            updated_callback_count = 0

            client_count.times do |client_id|
              presence_client_one.update_client("client:#{client_id}", data) do
                updated_callback_count += 1
              end
            end

            presence_anonymous_client.subscribe(:enter) do |presence|
              expect(presence.data).to eql(data)
              clients << presence
              next unless clients.count == 5

              wait_until(proc { updated_callback_count == 5 }) do
                expect(clients.map(&:client_id).uniq.count).to eql(5)
                expect(updated_callback_count).to eql(5)
                stop_reactor
              end
            end
          end
        end

        it_should_behave_like 'a public presence method', :update_client, nil, 'client_id'
        it_should_behave_like 'a presence on behalf of another client method', :update_client
      end

      context '#leave_client' do
        context 'leaves a channel' do
          context 'multiple times on the same channel with different client_ids' do
            it 'emits the :leave event for each client_id' do
              left_callback_count = 0

              client_count.times do |client_id|
                presence_client_one.enter_client("client:#{client_id}", random_str) do
                  presence_client_one.leave_client("client:#{client_id}", data) do
                    left_callback_count += 1
                  end
                end
              end

              presence_anonymous_client.subscribe(:leave) do |presence|
                expect(presence.data).to eql(data)
                clients << presence
                next unless clients.count == 5

                wait_until(proc { left_callback_count == 5 }) do
                  expect(clients.map(&:client_id).uniq.count).to eql(5)
                  expect(left_callback_count).to eql(5)
                  stop_reactor
                end
              end
            end

            it 'succeeds if that client_id has not previously entered the channel' do
              left_callback_count = 0

              client_count.times do |client_id|
                presence_client_one.leave_client("client:#{client_id}") do
                  left_callback_count += 1
                end
              end

              presence_anonymous_client.subscribe(:leave) do |presence|
                expect(presence.data).to be_nil
                clients << presence
                next unless clients.count == 5

                wait_until(proc { left_callback_count == 5 }) do
                  expect(clients.map(&:client_id).uniq.count).to eql(5)
                  expect(left_callback_count).to eql(5)
                  stop_reactor
                end
              end
            end
          end

          context 'with a new value in :data option' do
            it 'emits the leave event with the new data value' do
              presence_client_one.enter_client("client:unique", random_str) do
                presence_client_one.leave_client("client:unique", data)
              end

              presence_client_one.subscribe(:leave) do |presence_message|
                expect(presence_message.data).to eql(data)
                stop_reactor
              end
            end
          end

          context 'with a nil value in :data option' do
            it 'emits the leave event with the previous value as a convenience' do
              presence_client_one.enter_client("client:unique", data) do
                presence_client_one.leave_client("client:unique", nil)
              end

              presence_client_one.subscribe(:leave) do |presence_message|
                expect(presence_message.data).to eql(data)
                stop_reactor
              end
            end
          end

          context 'with no :data option' do
            it 'emits the leave event with the previous value as a convenience' do
              presence_client_one.enter_client("client:unique", data) do
                presence_client_one.leave_client("client:unique")
              end

              presence_client_one.subscribe(:leave) do |presence_message|
                expect(presence_message.data).to eql(data)
                stop_reactor
              end
            end
          end
        end

        it_should_behave_like 'a public presence method', :leave_client, nil, 'client_id'
        it_should_behave_like 'a presence on behalf of another client method', :leave_client
      end
    end

    context '#get' do
      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        expect(presence_client_one.get).to be_a(Ably::Util::SafeDeferrable)
        stop_reactor
      end

      it 'calls the Deferrable callback on success' do
        presence_client_one.get.callback do |presence|
          expect(presence).to eq([])
          stop_reactor
        end
      end

      it 'catches exceptions in the provided method block' do
        expect(presence_client_one.logger).to receive(:error).with(/Intentional exception/) do
          stop_reactor
        end
        presence_client_one.get { raise 'Intentional exception' }
      end

      it 'raise an exception if the channel is detached' do
        channel_client_one.attach do
          channel_client_one.transition_state_machine :detaching
          channel_client_one.once(:detached) do
            expect { presence_client_one.get }.to raise_error Ably::Exceptions::InvalidStateChange, /Operation is not allowed when channel is in STATE.detached/i
            stop_reactor
          end
        end
      end

      it 'raise an exception if the channel is failed' do
        channel_client_one.attach do
          channel_client_one.transition_state_machine :failed
          expect(channel_client_one.state).to eq(:failed)
          expect { presence_client_one.get }.to raise_error Ably::Exceptions::InvalidStateChange, /Operation is not allowed when channel is in STATE.failed/i
          stop_reactor
        end
      end

      context 'during a sync', em_timeout: 30 do
        let(:pages)               { 2 }
        let(:members_per_page)    { 100 }
        let(:sync_pages_received) { [] }
        let(:client_one)          { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }
        let(:client_options)      { default_options.merge(log_level: :none) }

        def connect_members_deferrables
          (members_per_page * pages + 1).times.map do |index|
            # rate limit to 10 per second
            EventMachine::DefaultDeferrable.new.tap do |deferrable|
              EventMachine.add_timer(index / 10) do
                presence_client_one.enter_client("client:#{index}").tap do |enter_deferrable|
                  enter_deferrable.callback { |*args| deferrable.succeed *args }
                  enter_deferrable.errback { |*args| deferrable.fail *args }
                end
              end
            end
          end
        end

        context 'when :wait_for_sync is true' do
          it 'fails if the connection fails' do
            when_all(*connect_members_deferrables) do
              channel_client_two.attach do
                client_two.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                  if protocol_message.action == :sync
                    sync_pages_received << protocol_message
                    if sync_pages_received.count == 1
                      error_message = Ably::Models::ProtocolMessage.new(action: 9, error: { message: 'force failure' })
                      client_two.connection.__incoming_protocol_msgbus__.publish :protocol_message, error_message
                    end
                  end
                end
              end

              presence_client_two.get(wait_for_sync: true).tap do |deferrable|
                deferrable.callback { raise 'Get should not succeed' }
                deferrable.errback do |error|
                  stop_reactor
                end
              end
            end
          end

          it 'fails if the channel is detached' do
            when_all(*connect_members_deferrables) do
              channel_client_two.attach do
                client_two.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                  if protocol_message.action == :sync
                    # prevent any more SYNC messages coming through
                    client_two.connection.transport.__incoming_protocol_msgbus__.unsubscribe
                    channel_client_two.transition_state_machine :detaching
                    channel_client_two.transition_state_machine :detached
                  end
                end
              end

              presence_client_two.get(wait_for_sync: true).tap do |deferrable|
                deferrable.callback { raise 'Get should not succeed' }
                deferrable.errback do |error|
                  stop_reactor
                end
              end
            end
          end
        end
      end

      # skip 'it fails if the connection changes to failed state'

      it 'returns the current members on the channel' do
        presence_client_one.enter
        presence_client_one.subscribe(:enter) do
          presence_client_one.unsubscribe :enter
          presence_client_one.get do |members|
            expect(members.count).to eq(1)

            expect(client_one.client_id).to_not be_nil

            this_member = members.first
            expect(this_member.client_id).to eql(client_one.client_id)

            stop_reactor
          end
        end
      end

      it 'filters by connection_id option if provided' do
        presence_client_one.enter do
          presence_client_two.enter
        end

        presence_client_one.subscribe(:enter) do |presence_message|
          # wait until the client_two enter event has been sent to client_one
          next unless presence_message.client_id == client_two.client_id

          presence_client_one.get(connection_id: client_one.connection.id) do |members|
            expect(members.count).to eq(1)
            expect(members.first.connection_id).to eql(client_one.connection.id)

            presence_client_one.get(connection_id: client_two.connection.id) do |members_two|
              expect(members_two.count).to eq(1)
              expect(members_two.first.connection_id).to eql(client_two.connection.id)
              stop_reactor
            end
          end
        end
      end

      it 'filters by client_id option if provided' do
        presence_client_one.enter do
          presence_client_two.enter
        end

        presence_client_one.subscribe(:enter) do |presence_message|
          # wait until the client_two enter event has been sent to client_one
          next unless presence_message.client_id == client_two_id

          presence_client_one.get(client_id: client_one_id) do |members|
            expect(members.count).to eq(1)
            expect(members.first.client_id).to eql(client_one_id)
            expect(members.first.connection_id).to eql(client_one.connection.id)

            presence_client_one.get(client_id: client_two_id) do |members_two|
              expect(members_two.count).to eq(1)
              expect(members_two.first.client_id).to eql(client_two_id)
              expect(members_two.first.connection_id).to eql(client_two.connection.id)
              stop_reactor
            end
          end
        end
      end

      it 'does not wait for SYNC to complete if :wait_for_sync option is false' do
        presence_client_one.enter
        presence_client_one.subscribe(:enter) do
          presence_client_one.unsubscribe :enter

          presence_client_two.get(wait_for_sync: false) do |members|
            expect(members.count).to eql(0)
            stop_reactor
          end
        end
      end

      context 'when a member enters and then leaves' do
        it 'has no members' do
          presence_client_one.enter do
            presence_client_one.leave
          end

          presence_client_one.subscribe(:leave) do
            presence_client_one.get do |members|
              expect(members.count).to eq(0)
              stop_reactor
            end
          end
        end
      end

      context 'with lots of members on different clients' do
        let(:client_one)         { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }
        let(:client_two)         { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }
        let(:members_per_client) { 10 }
        let(:clients_entered)    { Hash.new { |hash, key| hash[key] = 0 } }
        let(:total_members)      { members_per_client * 2 }

        it 'returns a complete list of members on all clients' do
          members_per_client.times do |index|
            presence_client_one.enter_client("client_1:#{index}")
            presence_client_two.enter_client("client_2:#{index}")
          end

          presence_client_one.subscribe(:enter) do
            clients_entered[:client_one] += 1
          end

          presence_client_two.subscribe(:enter) do
            clients_entered[:client_two] += 1
          end

          wait_until(proc { clients_entered[:client_one] + clients_entered[:client_two] == total_members * 2 }) do
            presence_anonymous_client.get(wait_for_sync: true) do |anonymous_members|
              expect(anonymous_members.count).to eq(total_members)
              expect(anonymous_members.map(&:client_id).uniq.count).to eq(total_members)

              presence_client_one.get(wait_for_sync: true) do |client_one_members|
                presence_client_two.get(wait_for_sync: true) do |client_two_members|
                  expect(client_one_members.count).to eq(total_members)
                  expect(client_one_members.count).to eq(client_two_members.count)
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    context '#subscribe' do
      let(:messages) { [] }

      context 'with no arguments' do
        it 'calls the callback for all presence events' do
          when_all(channel_client_one.attach, channel_client_two.attach) do
            presence_client_two.subscribe do |presence_message|
              messages << presence_message
              next unless messages.count == 3

              expect(messages.map(&:action).map(&:to_sym)).to contain_exactly(:enter, :update, :leave)
              stop_reactor
            end

            presence_client_one.enter do
              presence_client_one.update do
                presence_client_one.leave
              end
            end
          end
        end
      end

      context 'with event name' do
        it 'calls the callback for specified presence event' do
          when_all(channel_client_one.attach, channel_client_two.attach) do
            presence_client_two.subscribe(:leave) do |presence_message|
              messages << presence_message
              next unless messages.count == 1

              expect(messages.map(&:action).map(&:to_sym)).to contain_exactly(:leave)
              stop_reactor
            end

            presence_client_one.enter do
              presence_client_one.update do
                presence_client_one.leave
              end
            end
          end
        end
      end

      it 'implicitly attaches' do
        expect(client_one.connection).to be_initialized
        presence_client_one.subscribe { true }
        channel_client_one.on(:attached) do
          expect(client_one.connection).to be_connected
          expect(channel_client_one).to be_attached
          stop_reactor
        end
      end

      context 'with a callback that raises an exception' do
        let(:exception) { StandardError.new("Intentional error") }

        it 'logs the error and continues' do
          emitted_exception = false
          expect(client_one.logger).to receive(:error).with(/#{exception.message}/)
          presence_client_one.subscribe do |presence_message|
            emitted_exception = true
            raise exception
          end
          presence_client_one.enter do
            EventMachine.add_timer(1) do
              expect(emitted_exception).to eql(true)
              stop_reactor
            end
          end
        end
      end
    end

    context '#unsubscribe' do
      context 'with no arguments' do
        it 'removes the callback for all presence events' do
          when_all(channel_client_one.attach, channel_client_two.attach) do
            subscribe_callback = proc { raise 'Should not be called' }
            presence_client_two.subscribe(&subscribe_callback)
            presence_client_two.unsubscribe(&subscribe_callback)

            presence_client_one.enter
            presence_client_one.update
            presence_client_one.leave do
              EventMachine.add_timer(1) do
                stop_reactor
              end
            end
          end
        end
      end

      context 'with event name' do
        it 'removes the callback for specified presence event' do
          when_all(channel_client_one.attach, channel_client_two.attach) do
            subscribe_callback = proc { raise 'Should not be called' }
            presence_client_two.subscribe :leave, &subscribe_callback
            presence_client_two.unsubscribe :leave, &subscribe_callback

            presence_client_one.enter do
              presence_client_one.leave do
                EventMachine.add_timer(1) do
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    context 'REST #get' do
      it 'returns current members' do
        presence_client_one.enter data_payload
        presence_client_one.subscribe(:enter) do
          presence_client_one.unsubscribe :enter

          members_page = channel_rest_client_one.presence.get
          this_member = members_page.items.first

          expect(this_member).to be_a(Ably::Models::PresenceMessage)
          expect(this_member.client_id).to eql(client_one.client_id)
          expect(this_member.data).to eql(data_payload)

          stop_reactor
        end
      end

      it 'returns no members once left' do
        presence_client_one.enter(data_payload) do
          presence_client_one.leave
          presence_client_one.subscribe(:leave) do
            presence_client_one.unsubscribe :leave

            members_page = channel_rest_client_one.presence.get
            expect(members_page.items.count).to eql(0)
            stop_reactor
          end
        end
      end
    end

    context 'client_id with ASCII_8BIT' do
      let(:client_id)   { random_str.encode(Encoding::ASCII_8BIT) }

      context 'in connection set up' do
        let(:client_one)  { auto_close Ably::Realtime::Client.new(default_options.merge(client_id: client_id)) }

        it 'is converted into UTF_8' do
          presence_client_one.enter
          presence_client_one.on(:entered) do |presence|
            expect(presence.client_id.encoding).to eql(Encoding::UTF_8)
            expect(presence.client_id.encode(Encoding::ASCII_8BIT)).to eql(client_id)
            stop_reactor
          end
        end
      end

      context 'in channel options' do
        let(:client_one)  { auto_close Ably::Realtime::Client.new(default_options) }

        it 'is converted into UTF_8' do
          channel_client_one.attach do
            presence_client_one.subscribe(:enter) do |presence|
              expect(presence.client_id.encoding).to eql(Encoding::UTF_8)
              expect(presence.client_id.encode(Encoding::ASCII_8BIT)).to eql(client_id)
              stop_reactor
            end
            presence_anonymous_client.enter_client(client_id)
          end
        end
      end
    end

    context 'encoding and decoding of presence message data' do
      let(:secret_key)              { Ably::Util::Crypto.generate_random_key(256) }
      let(:cipher_options)          { { key: secret_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
      let(:channel_name)            { random_str }
      let(:encrypted_channel)       { client_one.channel(channel_name, cipher: cipher_options) }
      let(:channel_rest_client_one) { client_one.rest_client.channel(channel_name, cipher: cipher_options) }

      let(:crypto)                  { Ably::Util::Crypto.new(cipher_options) }

      let(:data)                    { { 'hash_id' => random_str } }
      let(:data_as_json)            { data.to_json }
      let(:data_as_cipher)          { crypto.encrypt(data.to_json) }

      it 'encrypts presence message data' do
        encrypted_channel.attach do
          encrypted_channel.presence.enter data
        end

        encrypted_channel.presence.__incoming_msgbus__.unsubscribe(:presence) # remove all subscribe callbacks that could decrypt the message
        encrypted_channel.presence.__incoming_msgbus__.subscribe(:presence) do |presence|
          if protocol == :json
            expect(presence['encoding']).to eql('json/utf-8/cipher+aes-256-cbc/base64')
            expect(crypto.decrypt(Base64.decode64(presence['data']))).to eql(data_as_json)
          else
            expect(presence['encoding']).to eql('json/utf-8/cipher+aes-256-cbc')
            expect(crypto.decrypt(presence['data'])).to eql(data_as_json)
          end
          stop_reactor
        end
      end

      context '#subscribe' do
        it 'emits decrypted enter events' do
          encrypted_channel.attach do
            encrypted_channel.presence.enter data
          end

          encrypted_channel.presence.subscribe(:enter) do |presence_message|
            expect(presence_message.encoding).to be_nil
            expect(presence_message.data).to eql(data)
            stop_reactor
          end
        end

        it 'emits decrypted update events' do
          encrypted_channel.attach do
            encrypted_channel.presence.enter('to be updated') do
              encrypted_channel.presence.update data
            end
          end

          encrypted_channel.presence.subscribe(:update) do |presence_message|
            expect(presence_message.encoding).to be_nil
            expect(presence_message.data).to eql(data)
            stop_reactor
          end
        end

        it 'emits previously set data for leave events' do
          encrypted_channel.attach do
            encrypted_channel.presence.enter(data) do
              encrypted_channel.presence.leave
            end
          end

          encrypted_channel.presence.subscribe(:leave) do |presence_message|
            expect(presence_message.encoding).to be_nil
            expect(presence_message.data).to eql(data)
            stop_reactor
          end
        end
      end

      context '#get' do
        it 'returns a list of members with decrypted data' do
          encrypted_channel.presence.enter(data)
          encrypted_channel.presence.subscribe(:enter) do
            encrypted_channel.presence.get do |members|
              member = members.first
              expect(member.encoding).to be_nil
              expect(member.data).to eql(data)
              stop_reactor
            end
          end
        end
      end

      context 'REST #get' do
        it 'returns a list of members with decrypted data' do
          encrypted_channel.presence.enter(data)
          encrypted_channel.presence.subscribe(:enter) do
            member = channel_rest_client_one.presence.get.items.first
            expect(member.encoding).to be_nil
            expect(member.data).to eql(data)
            stop_reactor
          end
        end
      end

      context 'when cipher settings do not match publisher' do
        let(:client_options)                 { default_options.merge(log_level: :fatal) }
        let(:incompatible_cipher_options)    { { key: Ably::Util::Crypto.generate_random_key(128), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
        let(:incompatible_encrypted_channel) { client_two.channel(channel_name, cipher: incompatible_cipher_options) }

        it 'delivers an unencoded presence message left with encoding value' do
          encrypted_channel.presence.enter data

          incompatible_encrypted_channel.presence.subscribe(:enter) do
            incompatible_encrypted_channel.presence.get do |members|
              member = members.first
              expect(member.encoding).to match(/cipher\+aes-256-cbc/)
              expect(member.data).to_not eql(data)
              stop_reactor
            end
          end
        end

        it 'emits an error when cipher does not match and presence data cannot be decoded' do
          incompatible_encrypted_channel.attach do
            incompatible_encrypted_channel.on(:error) do |error|
              expect(error).to be_a(Ably::Exceptions::CipherError)
              expect(error.message).to match(/Cipher algorithm AES-128-CBC does not match/)
              stop_reactor
            end

            encrypted_channel.attach do
              encrypted_channel.presence.enter data
            end
          end
        end
      end
    end

    context 'leaving' do
      specify 'expect :left event once underlying connection is closed' do
        presence_client_one.on(:left) do
          expect(presence_client_one.state).to eq(:left)
          stop_reactor
        end
        presence_client_one.enter do
          client_one.close
        end
      end

      specify 'expect :left event with client data from enter event' do
        presence_client_one.subscribe(:leave) do |message|
          presence_client_one.get(wait_for_sync: true) do |members|
            expect(members.count).to eq(0)
            expect(message.data).to eql(data_payload)
            stop_reactor
          end
        end
        presence_client_one.enter(data_payload) do
          presence_client_one.leave
        end
      end
    end

    context 'connection failure mid-way through a large member sync' do
      let(:members_count) { 250 }
      let(:sync_pages_received) { [] }
      let(:client_options)  { default_options.merge(log_level: :fatal) }

      it 'resumes the SYNC operation', em_timeout: 15 do
        when_all(*members_count.times.map do |index|
          presence_anonymous_client.enter_client("client:#{index}")
        end) do
          channel_client_two.attach do
            client_two.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.action == :sync
                sync_pages_received << protocol_message
                force_connection_failure client_two if sync_pages_received.count == 1
              end
            end
          end

          presence_client_two.get(wait_for_sync: true) do |members|
            expect(members.count).to eql(members_count)
            expect(members.map(&:member_key).uniq.count).to eql(members_count)
            stop_reactor
          end
        end
      end
    end
  end
end
