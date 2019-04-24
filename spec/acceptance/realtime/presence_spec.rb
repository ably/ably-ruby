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

    let(:wildcard_token)            { lambda { |token_params| Ably::Rest::Client.new(client_options).auth.request_token(client_id: '*') } }
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
          acked = false
          received = false
          presence_client_one.public_send(method_name.to_s.gsub(/leave|update/, 'enter'), args) do
            acked = true
            yield if acked & received
          end
          presence_client_one.subscribe do |presence_message|
            expect(presence_message.action).to eq(:enter)
            presence_client_one.unsubscribe
            received = true
            yield if acked & received
          end
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
                presence_client_one.public_send(method_name, args).tap do |deferrable|
                  deferrable.callback { raise 'Get should not succeed' }
                  deferrable.errback do |error|
                    expect(error).to be_a(Ably::Exceptions::InvalidState)
                    expect(error.message).to match(/Operation is not allowed when channel is in STATE.Detached/)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        it 'raise an exception if the channel becomes detached' do
          setup_test(method_name, args, options) do
            channel_client_one.attach do
              channel_client_one.transition_state_machine :detaching
              presence_client_one.public_send(method_name, args).tap do |deferrable|
                deferrable.callback { raise 'Get should not succeed' }
                deferrable.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidState)
                  expect(error.message).to match(/Operation failed as channel transitioned to STATE.Detached/)
                  stop_reactor
                end
              end
            end
          end
        end

        it 'raise an exception if the channel is failed' do
          setup_test(method_name, args, options) do
            channel_client_one.attach do
              channel_client_one.transition_state_machine :failed
              expect(channel_client_one.state).to eq(:failed)
              presence_client_one.public_send(method_name, args).tap do |deferrable|
                deferrable.callback { raise 'Get should not succeed' }
                deferrable.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::InvalidState)
                  expect(error.message).to match(/Operation is not allowed when channel is in STATE.Failed/)
                  stop_reactor
                end
              end
            end
          end
        end

        it 'raise an exception if the channel becomes failed' do
          setup_test(method_name, args, options) do
            channel_client_one.attach do
              presence_client_one.public_send(method_name, args).tap do |deferrable|
                deferrable.callback { raise 'Get should not succeed' }
                deferrable.errback do |error|
                  expect(error).to be_a(Ably::Exceptions::MessageDeliveryFailed)
                  stop_reactor
                end
              end
              channel_client_one.transition_state_machine :failed
              expect(channel_client_one.state).to eq(:failed)
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
            it 'fails the deferrable' do
              presence_client_one.public_send(method_name, args).errback do |error|
                expect(error).to be_a(Ably::Exceptions::MessageQueueingDisabled)
                stop_reactor
              end
              expect(client_one.connection).to be_initialized
            end
          end

          context 'and connection state connecting' do
            it 'fails the deferrable' do
              client_one.connect
              EventMachine.next_tick do
                presence_client_one.public_send(method_name, args).errback do |error|
                  expect(error).to be_a(Ably::Exceptions::MessageQueueingDisabled)
                  stop_reactor
                end
                expect(client_one.connection).to be_connecting
              end
            end
          end

          context 'and connection state disconnected' do
            let(:client_one) { auto_close Ably::Realtime::Client.new(default_options.merge(queue_messages: false, client_id: client_id, :log_level => :error)) }

            it 'fails the deferrable' do
              client_one.connection.once(:connected) do
                client_one.connection.once(:disconnected) do
                  presence_client_one.public_send(method_name, args).errback do |error|
                    expect(error).to be_a(Ably::Exceptions::MessageQueueingDisabled)
                    stop_reactor
                  end
                  expect(client_one.connection).to be_disconnected
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

          it 'raises an UnsupportedDataType 40013 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end

        context 'Float' do
          let(:data) { 1.1 }

          it 'raises an UnsupportedDataType 40013 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end

        context 'Boolean' do
          let(:data) { true }

          it 'raises an UnsupportedDataType 40013 exception' do
            expect { presence_action(method_name, data) }.to raise_error(Ably::Exceptions::UnsupportedDataType)
            stop_reactor
          end
        end

        context 'False' do
          let(:data) { false }

          it 'raises an UnsupportedDataType 40013 exception' do
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
          expect(presence_client_one.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/Intentional exception/)
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

        context 'and a client_id that is not a string type' do
          it 'throws an exception' do
            expect { presence_channel.public_send(method_name, 1) }.to raise_error Ably::Exceptions::IncompatibleClientId
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
      it 'maintains state as other clients enter and leave the channel (#RTP2e)' do
        channel_anonymous_client.attach do
          presence_anonymous_client.subscribe(:enter) do |presence_message|
            expect(presence_message.client_id).to eql(client_one.client_id)

            presence_anonymous_client.get do |members|
              expect(members.first.client_id).to eql(client_one.client_id)
              expect(members.first.action).to eq(:present)

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

    context '#members map / PresenceMap (#RTP2)', api_private: true do
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

      context 'the map is based on the member_key (connection_id & client_id)' do
        # 2 unqiue client_id with client_id "b" being on two connections
        let(:enter_action) { 2 }
        let(:presence_data) do
          [
            { client_id: 'a', connection_id: 'one', id: 'one:0:0', action: enter_action },
            { client_id: 'b', connection_id: 'one', id: 'one:0:1', action: enter_action },
            { client_id: 'a', connection_id: 'one', id: 'one:0:2', action: enter_action },
            { client_id: 'b', connection_id: 'one', id: 'one:0:3', action: enter_action },
            { client_id: 'b', connection_id: 'two', id: 'two:0:4', action: enter_action }
          ]
        end

        it 'ensures uniqueness from this member_key (#RTP2a)' do
          channel_anonymous_client.attach do
            presence_anonymous_client.get do |members|
              expect(members.length).to eql(0)

              ## Fabricate members
              action = Ably::Models::ProtocolMessage::ACTION.Presence
              presence_msg = Ably::Models::ProtocolMessage.new(
                action: action,
                connection_serial: 20,
                channel: channel_name,
                presence: presence_data,
                timestamp: Time.now.to_i * 1000
              )
              anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, presence_msg

              EventMachine.add_timer(0.5) do
                presence_anonymous_client.get do |members|
                  expect(members.length).to eql(3)
                  expect(members.map { |member| member.client_id }.uniq).to contain_exactly('a', 'b')
                  stop_reactor
                end
              end
            end
          end
        end
      end

      context 'newness is compared based on PresenceMessage#id unless synthesized' do
        let(:page_size) { 100 }
        let(:enter_expected_count) { page_size + 1 } # 100 per page, this ensures we have more than one page so that we can test newness during sync
        let(:enter_action) { 2 }
        let(:leave_action) { 3 }
        let(:now) { Time.now.to_i * 1000 }
        let(:entered) { [] }
        let(:client_one) { auto_close Ably::Realtime::Client.new(default_options.merge(auth_callback: wildcard_token)) }

        def setup_members_on(presence)
          enter_expected_count.times do |indx|
            # 10 messages per second max rate on simulation accounts
            rate = indx.to_f / 10
            EventMachine.add_timer(rate) do
              presence.enter_client("client:#{indx}") do |message|
                entered << message
                next unless entered.count == enter_expected_count
                yield
              end
            end
          end
        end

        def allow_sync_fabricate_data_final_sync_and_assert_members
          setup_members_on(presence_client_one) do
            sync_pages_received = []
            anonymous_client.connection.once(:connected) do
              anonymous_client.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                if protocol_message.action == :sync
                  sync_pages_received << protocol_message
                  if sync_pages_received.count == 1
                    action = Ably::Models::ProtocolMessage::ACTION.Presence
                    presence_msg = Ably::Models::ProtocolMessage.new(
                      action: action,
                      connection_serial: anonymous_client.connection.serial + 1,
                      channel: channel_name,
                      presence: presence_data,
                      timestamp: Time.now.to_i * 1000
                    )
                    anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, presence_msg

                    # Now simulate an end to the sync
                    action = Ably::Models::ProtocolMessage::ACTION.Sync
                    sync_msg = Ably::Models::ProtocolMessage.new(
                      action: action,
                      connection_serial: anonymous_client.connection.serial + 2,
                      channel: channel_name,
                      channel_serial: 'validserialprefix:', # with no part after the `:` this indicates the end to the SYNC
                      presence: [],
                      timestamp: Time.now.to_i * 1000
                    )
                    anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, sync_msg

                    # Stop the next SYNC arriving
                    anonymous_client.connection.__incoming_protocol_msgbus__.unsubscribe
                  end
                end
              end

              presence_anonymous_client.get do |members|
                expect(members.length).to eql(page_size + 2)
                expect(members.find { |member| member.client_id == 'a' }).to be_nil
                expect(members.find { |member| member.client_id == 'b' }.timestamp.to_i).to eql(now / 1000)
                expect(members.find { |member| member.client_id == 'c' }.timestamp.to_i).to eql(now / 1000)
                stop_reactor
              end
            end
          end
        end

        context 'when presence messages are synthesized' do
          let(:presence_data) do
            [
              { client_id: 'a', connection_id: 'one', id: 'one:0:0', action: enter_action, timestamp: now },            # first messages from client, second fabricated
              { client_id: 'a', connection_id: 'one', id: 'fabricated:0:1', action: leave_action, timestamp: now + 1 }, # leave after enter based on timestamp
              { client_id: 'b', connection_id: 'one', id: 'one:0:2', action: enter_action, timestamp: now },            # first messages from client, second fabricated
              { client_id: 'b', connection_id: 'one', id: 'fabricated:0:3', action: leave_action, timestamp: now - 1 }, # leave before enter based on timestamp
              { client_id: 'c', connection_id: 'one', id: 'fabricated:0:4', action: enter_action, timestamp: now },     # both messages fabricated
              { client_id: 'c', connection_id: 'one', id: 'fabricated:0:5', action: leave_action, timestamp: now - 1 }  # leave before enter based on timestamp
            ]
          end

          it 'compares based on timestamp if either has a connectionId not part of the presence message id (#RTP2b1)' do
            allow_sync_fabricate_data_final_sync_and_assert_members
          end
        end

        context 'when presence messages are not synthesized (events sent from clients)' do
          let(:presence_data) do
            [
              { client_id: 'a', connection_id: 'one', id: 'one:0:0', action: enter_action, timestamp: now },      # first messages from client
              { client_id: 'a', connection_id: 'one', id: 'one:1:0', action: leave_action, timestamp: now - 1 },  # leave after enter based on msgSerial part of ID
              { client_id: 'b', connection_id: 'one', id: 'one:2:2', action: enter_action, timestamp: now },      # first messages from client
              { client_id: 'b', connection_id: 'one', id: 'one:2:1', action: leave_action, timestamp: now + 1 },  # leave before enter based on index part of ID
              { client_id: 'c', connection_id: 'one', id: 'one:4:4', action: enter_action, timestamp: now },      # first messages from client
              { client_id: 'c', connection_id: 'one', id: 'one:3:5', action: leave_action, timestamp: now + 1 }   # leave before enter based on msgSerial part of ID
            ]
          end

          it 'compares based on timestamp if either has a connectionId not part of the presence message id (#RTP2b2)' do
            allow_sync_fabricate_data_final_sync_and_assert_members
          end
        end
      end
    end

    context '#sync_complete? and SYNC flags (#RTP1)' do
      context 'when attaching to a channel without any members present' do
        it 'sync_complete? is true, there is no presence flag, and the presence channel is considered synced immediately (#RTP1)' do
          flag_checked = false

          anonymous_client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
            if protocol_message.action == :attached
              flag_checked = true
              expect(protocol_message.has_presence_flag?).to eql(false)
            end
          end

          channel_anonymous_client.attach do
            expect(channel_anonymous_client.presence).to be_sync_complete
            EventMachine.next_tick do
              expect(flag_checked).to eql(true)
              stop_reactor
            end
          end
        end
      end

      context 'when attaching to a channel with members present' do
        it 'sync_complete? is false, there is a presence flag, and the presence channel is subsequently synced (#RTP1)' do
          flag_checked = false

          anonymous_client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
            if protocol_message.action == :attached
              flag_checked = true
              expect(protocol_message.has_presence_flag?).to eql(true)
            end
          end

          presence_client_one.enter
          presence_client_one.subscribe(:enter) do
            presence_client_one.unsubscribe :enter

            channel_anonymous_client.attach do
              expect(channel_anonymous_client.presence).to_not be_sync_complete
              channel_anonymous_client.presence.get do
                expect(channel_anonymous_client.presence).to be_sync_complete
                EventMachine.next_tick do
                  expect(flag_checked).to eql(true)
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    context '101 existing (present) members on a channel (2 SYNC pages)' do
      context 'requiring at least 2 SYNC ProtocolMessages', em_timeout: 40 do
        let(:enter_expected_count) { 101 }
        let(:present) { [] }
        let(:entered) { [] }
        let(:sync_pages_received) { [] }
        let(:client_one) { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }

        def setup_members_on(presence)
          enter_expected_count.times do |indx|
            # 10 messages per second max rate on simulation accounts
            rate = indx.to_f / 10
            EventMachine.add_timer(rate) do
              presence.enter_client("client:#{indx}") do |message|
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

          context 'and a member enters before the SYNC operation is complete' do
            let(:enter_client_id) { random_str }

            it 'emits a :enter immediately and the member is :present once the sync is complete (#RTP2g)' do
              setup_members_on(presence_client_one) do
                member_entered = false

                anonymous_client.connect do
                  presence_anonymous_client.subscribe(:enter) do |member|
                    expect(member.client_id).to eql(enter_client_id)
                    member_entered = true
                  end

                  presence_anonymous_client.get do |members|
                    expect(members.find { |member| member.client_id == enter_client_id }.action).to eq(:present)
                    stop_reactor
                  end

                  anonymous_client.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    if protocol_message.action == :sync
                      sync_pages_received << protocol_message
                      if sync_pages_received.count == 1
                        enter_action = Ably::Models::PresenceMessage::ACTION.Enter
                        enter_member = Ably::Models::PresenceMessage.new(
                          'id' => "#{client_one.connection.id}:#{random_str}:0",
                          'clientId' => enter_client_id,
                          'connectionId' => client_one.connection.id,
                          'timestamp' => as_since_epoch(Time.now),
                          'action' => enter_action
                        )
                        presence_anonymous_client.__incoming_msgbus__.publish :presence, enter_member
                      end
                    end
                  end
                end
              end
            end
          end

          context 'and a member leaves before the SYNC operation is complete' do
            it 'emits :leave immediately as the member leaves and cleans up the ABSENT member after (#RTP2f, #RTP2g)' do
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

                  # Hacky accessing a private method, but absent members are intentionally not exposed to any public APIs
                  expect(presence_anonymous_client.members.send(:absent_members).length).to eql(1)

                  presence_anonymous_client.members.once(:in_sync) do
                    # Check that members count is exact indicating the members with LEAVE action after sync are removed
                    expect(presence_anonymous_client).to be_sync_complete
                    expect(presence_anonymous_client.members.length).to eql(enter_expected_count - 1)
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
                          'id' => "#{client_one.connection.id}:#{all_client_ids.first}:0",
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

            it 'ignores presence events with timestamps / identifiers prior to the current :present event in the MembersMap (#RTP2c)' do
              started_at = Time.now

              setup_members_on(presence_client_one) do
                leave_member = nil

                presence_anonymous_client.subscribe(:present) do |present_message|
                  present << present_message

                  if present.count == enter_expected_count
                    presence_anonymous_client.get do |members|
                      member = members.find { |member| member.client_id == leave_member.client_id}
                      expect(member).to_not be_nil
                      expect(member.action).to eq(:present)
                      EventMachine.add_timer(1) do
                        presence_anonymous_client.unsubscribe
                        stop_reactor
                      end
                    end
                  end
                end

                presence_anonymous_client.subscribe(:leave) do |leave_message|
                  raise "Leave event for #{leave_message} should not have been fired because it is out of date"
                end

                anonymous_client.connect do
                  anonymous_client.connection.transport.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
                    if protocol_message.action == :sync
                      sync_pages_received << protocol_message
                      if sync_pages_received.count == 1
                        first_member = protocol_message.presence[0] # get the first member in the SYNC set
                        leave_action = Ably::Models::PresenceMessage::ACTION.Leave
                        leave_member = Ably::Models::PresenceMessage.new(
                          first_member.as_json.merge('action' => leave_action, 'timestamp' => as_since_epoch(started_at))
                        )
                        # After the SYNC has started, no inject that member has having left with a timestamp before the sync
                        presence_anonymous_client.__incoming_msgbus__.publish :presence, leave_member
                      end
                    end
                  end
                end
              end
            end

            it 'does not emit :present after the :leave event has been emitted, and that member is not included in the list of members via #get (#RTP2f)' do
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

                presence_anonymous_client.get do |members|
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
                    'id' => "#{client_one.connection.id}:#{left_client_id}:0",
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
            context 'by default' do
              it 'waits until sync is complete (#RTP11c1)', em_timeout: 30 do # allow for slow connections and lots of messages
                enter_expected_count.times do |indx|
                  EventMachine.add_timer(indx / 10) do
                    presence_client_one.enter_client "client:#{indx}"
                  end
                end

                presence_client_one.subscribe(:enter) do |message|
                  entered << message
                  next unless entered.count == enter_expected_count

                  presence_anonymous_client.get do |members|
                    expect(members.map(&:client_id).uniq.count).to eql(enter_expected_count)
                    expect(members.count).to eql(enter_expected_count)
                    stop_reactor
                  end
                end
              end
            end

            context 'with :wait_for_sync option set to false (#RTP11c1)' do
              it 'it does not wait for sync', em_timeout: 30 do # allow for slow connections and lots of messages
                enter_expected_count.times do |indx|
                  EventMachine.add_timer(indx / 10) do
                    presence_client_one.enter_client "client:#{indx}"
                    presence_client_one.subscribe(:enter) do |message|
                      entered << message
                      next unless entered.count == enter_expected_count

                      channel_anonymous_client.attach do
                        presence_anonymous_client.get(wait_for_sync: false) do |members|
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
            presence_client_two.subscribe do |presence|
              expect(presence.connection_id).to eq(client_one.connection.id)
              stop_reactor
            end

            presence_client_one.enter
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
        channel_client_one.attach do
          presence_client_one.enter('prior') do
            presence_client_one.update(data_payload)
          end
          presence_client_one.subscribe(:update) do |message|
            expect(message.data).to eql(data_payload)
            stop_reactor
          end
        end
      end

      it 'updates the data to nil if :data argument is not provided (assumes nil value)' do
        channel_client_one.attach do
          presence_client_one.enter('prior') do
            presence_client_one.update
          end
          presence_client_one.subscribe(:update) do |message|
            expect(message.data).to be_nil
            stop_reactor
          end
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
            channel_client_one.attach do
              presence_client_one.enter enter_data do
                presence_client_one.leave data
              end

              presence_client_one.subscribe(:leave) do |presence_message|
                expect(presence_message.data).to eql(data)
                stop_reactor
              end
            end
          end
        end

        context 'when set to nil' do
          it 'emits the last value for the data attribute when leaving' do
            channel_client_one.attach do
              presence_client_one.enter enter_data do
                presence_client_one.leave nil
              end

              presence_client_one.subscribe(:leave) do |presence_message|
                expect(presence_message.data).to eql(enter_data)
                stop_reactor
              end
            end
          end
        end

        context 'when not passed as an argument (i.e. nil)' do
          it 'emits the previous value for the data attribute when leaving' do
            channel_client_one.attach do
              presence_client_one.enter enter_data do
                presence_client_one.leave
              end

              presence_client_one.subscribe(:leave) do |presence_message|
                expect(presence_message.data).to eql(enter_data)
                stop_reactor
              end
            end
          end
        end

        context 'and sync is complete' do
          it 'does not cache members that have left' do
            enter_ack = false

            channel_client_one.attach do
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
      end

      it 'succeeds and does not emit an event (#RTP10d)' do
        channel_client_one.attach do
          channel_client_one.presence.leave do
            # allow enough time for leave event to (not) fire
            EventMachine.add_timer(2) do
              stop_reactor
            end
          end
          channel_client_one.subscribe(:leave) do
            raise "No leave event should fire"
          end
        end
      end

      it_should_behave_like 'a public presence method', :leave, :left, {}, enter_first: true
    end

    context ':left event' do
      it 'emits the data defined in enter' do
        channel_client_two.attach do
          channel_client_one.presence.enter('data') do
            channel_client_one.presence.leave
          end

          channel_client_two.presence.subscribe(:leave) do |message|
            expect(message.data).to eql('data')
            stop_reactor
          end
        end
      end

      it 'emits the data defined in update' do
        channel_client_two.attach do
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
            channel_anonymous_client.attach do
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
        end

        context 'message #connection_id' do
          let(:client_id) { random_str }

          it 'matches the current client connection_id' do
            channel_client_two.attach do
              presence_client_one.enter_client(client_id)

              presence_client_two.subscribe do |presence|
                expect(presence.client_id).to eq(client_id)
                expect(presence.connection_id).to eq(client_one.connection.id)
                stop_reactor
              end
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

            channel_anonymous_client.attach do
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

                wait_until(lambda { updated_callback_count == 5 }) do
                  expect(clients.map(&:client_id).uniq.count).to eql(5)
                  expect(updated_callback_count).to eql(5)
                  stop_reactor
                end
              end
            end
          end

          it 'updates the data attribute to null for the member when :data option is not provided (assumed null)' do
            channel_anonymous_client.attach do
              presence_client_one.enter_client('client_1') do
                presence_client_one.update_client('client_1')
              end

              presence_anonymous_client.subscribe(:update) do |presence|
                expect(presence.client_id).to eql('client_1')
                expect(presence.data).to be_nil
                stop_reactor
              end
            end
          end

          it 'enters if not already entered' do
            updated_callback_count = 0

            channel_anonymous_client.attach do
              client_count.times do |client_id|
                presence_client_one.update_client("client:#{client_id}", data) do
                  updated_callback_count += 1
                end
              end

              presence_anonymous_client.subscribe(:enter) do |presence|
                expect(presence.data).to eql(data)
                clients << presence
                next unless clients.count == 5

                wait_until(lambda { updated_callback_count == 5 }) do
                  expect(clients.map(&:client_id).uniq.count).to eql(5)
                  expect(updated_callback_count).to eql(5)
                  stop_reactor
                end
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

              channel_anonymous_client.attach do
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

                  wait_until(lambda { left_callback_count == 5 }) do
                    expect(clients.map(&:client_id).uniq.count).to eql(5)
                    expect(left_callback_count).to eql(5)
                    stop_reactor
                  end
                end
              end
            end

            it 'succeeds if that client_id has not previously entered the channel' do
              left_callback_count = 0

              channel_anonymous_client.attach do
                client_count.times do |client_id|
                  presence_client_one.leave_client("client:#{client_id}") do
                    left_callback_count += 1
                  end
                end

                presence_anonymous_client.subscribe(:leave) do |presence|
                  expect(presence.data).to be_nil
                  clients << presence
                  next unless clients.count == 5

                  wait_until(lambda { left_callback_count == 5 }) do
                    expect(clients.map(&:client_id).uniq.count).to eql(5)
                    expect(left_callback_count).to eql(5)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'with a new value in :data option' do
            it 'emits the leave event with the new data value' do
              channel_client_one.attach do
                presence_client_one.enter_client("client:unique", random_str) do
                  presence_client_one.leave_client("client:unique", data)
                end

                presence_client_one.subscribe(:leave) do |presence_message|
                  expect(presence_message.data).to eql(data)
                  stop_reactor
                end
              end
            end
          end

          context 'with a nil value in :data option' do
            it 'emits the leave event with the previous value as a convenience' do
              channel_client_one.attach do
                presence_client_one.enter_client("client:unique", data) do
                  presence_client_one.leave_client("client:unique", nil)
                end

                presence_client_one.subscribe(:leave) do |presence_message|
                  expect(presence_message.data).to eql(data)
                  stop_reactor
                end
              end
            end
          end

          context 'with no :data option' do
            it 'emits the leave event with the previous value as a convenience' do
              channel_client_one.attach do
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
        expect(presence_client_one.logger).to receive(:error) do |*args, &block|
          expect(args.concat([block ? block.call : nil]).join(',')).to match(/Intentional exception/)
          stop_reactor
        end
        presence_client_one.get { raise 'Intentional exception' }
      end

      it 'implicitly attaches the channel (#RTP11b)' do
        expect(channel_client_one).to be_initialized
        presence_client_one.get do |members|
          expect(channel_client_one).to be_attached
          stop_reactor
        end
      end

      context 'when the channel is SUSPENDED' do
        context 'with wait_for_sync: true' do
          it 'results in an error with @code@ @91005@ and a @message@ stating that the presence state is out of sync (#RTP11d)' do
            presence_client_one.enter do
              channel_client_one.transition_state_machine! :suspended
              presence_client_one.get(wait_for_sync: true).errback do |error|
                expect(error.code).to eql(91005)
                expect(error.message).to match(/presence state is out of sync/i)
                stop_reactor
              end
            end
          end
        end

        context 'with wait_for_sync: false' do
          it 'returns the current PresenceMap and does not wait for the channel to change to the ATTACHED state (#RTP11d)' do
            presence_client_one.enter do
              channel_client_one.transition_state_machine! :suspended
              presence_client_one.get(wait_for_sync: false) do |members|
                expect(channel_client_one).to be_suspended
                stop_reactor
              end
            end
          end
        end
      end

      it 'fails if the connection is DETACHED (#RTP11b)' do
        channel_client_one.attach do
          channel_client_one.detach do
            presence_client_one.get.tap do |deferrable|
              deferrable.callback { raise 'Get should not succeed' }
              deferrable.errback do |error|
                expect(error).to be_a(Ably::Exceptions::InvalidState)
                expect(error.message).to match(/Operation is not allowed when channel is in STATE.Detached/)
                stop_reactor
              end
            end
          end
        end
      end

      it 'fails if the connection is FAILED (#RTP11b)' do
        channel_client_one.attach do
          channel_client_one.transition_state_machine :failed
          expect(channel_client_one.state).to eq(:failed)
          presence_client_one.get.tap do |deferrable|
            deferrable.callback { raise 'Get should not succeed' }
            deferrable.errback do |error|
              expect(error).to be_a(Ably::Exceptions::InvalidState)
              expect(error.message).to match(/Operation is not allowed when channel is in STATE.Failed/)
              stop_reactor
            end
          end
        end
      end

      context 'during a sync', em_timeout: 30 do
        let(:pages)               { 2 }
        let(:members_per_page)    { 100 }
        let(:sync_pages_received) { [] }
        let(:client_one)          { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: wildcard_token)) }
        let(:client_options)      { default_options.merge(log_level: :none) }

        def connect_members_deferrables
          (members_per_page * pages + 1).times.map do |mem_index|
            # rate limit to 10 per second
            EventMachine::DefaultDeferrable.new.tap do |deferrable|
              EventMachine.add_timer(mem_index/10) do
                presence_client_one.enter_client("client:#{mem_index}").tap do |enter_deferrable|
                  enter_deferrable.callback { |*args| deferrable.succeed *args }
                  enter_deferrable.errback { |*args| deferrable.fail *args }
                end
              end
            end
          end
        end

        context 'when :wait_for_sync is true' do
          it 'fails if the connection becomes FAILED (#RTP11b)' do
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

          it 'fails if the channel becomes detached (#RTP11b)' do
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

      it 'returns the current members on the channel (#RTP11a)' do
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

      it 'filters by connection_id option if provided (#RTP11c3)' do
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

      it 'filters by client_id option if provided (#RTP11c2)' do
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

      it 'does not wait for SYNC to complete if :wait_for_sync option is false (#RTP11c1)' do
        presence_client_one.enter
        presence_client_one.subscribe(:enter) do
          presence_client_one.unsubscribe :enter

          presence_client_two.get(wait_for_sync: false) do |members|
            expect(members.count).to eql(0)
            stop_reactor
          end
        end
      end

      it 'returns the list of members and waits for SYNC to complete by default (#RTP11a)' do
        presence_client_one.enter
        presence_client_one.subscribe(:enter) do
          presence_client_one.unsubscribe :enter

          presence_client_two.get do |members|
            expect(members.count).to eql(1)
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

      context 'when a member enters and the presence map is updated' do
        it 'adds the member as being :present (#RTP2d)' do
          presence_client_one.enter
          presence_client_one.subscribe(:enter) do
            presence_client_one.unsubscribe :enter

            presence_client_one.get do |members|
              expect(members.count).to eq(1)
              expect(members.first.action).to eq(:present)
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
          members_per_client.times do |indx|
            presence_client_one.enter_client("client_1:#{indx}")
            presence_client_two.enter_client("client_2:#{indx}")
          end

          presence_client_one.subscribe(:enter) do
            clients_entered[:client_one] += 1
          end

          presence_client_two.subscribe(:enter) do
            clients_entered[:client_two] += 1
          end

          wait_until(lambda { clients_entered[:client_one] + clients_entered[:client_two] == total_members * 2 }) do
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
          expect(client_one.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/#{exception.message}/)
          end
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
            subscribe_callback = lambda { raise 'Should not be called' }
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
            subscribe_callback = lambda { raise 'Should not be called' }
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
            expect(client_two.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Cipher algorithm AES-128-CBC does not match/)
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
      let(:members_count) { 201 }
      let(:sync_pages_received) { [] }
      let(:client_options)  { default_options.merge(log_level: :fatal) }

      it 'resumes the SYNC operation (#RTP3)', em_timeout: 15 do
        when_all(*members_count.times.map do |indx|
          presence_anonymous_client.enter_client("client:#{indx}")
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

    context 'server-initiated sync' do
      context 'with multiple SYNC pages' do
        let(:present_action) { 1 }
        let(:leave_action) { 3 }
        let(:presence_sync_1) do
          [
            { client_id: 'a', connection_id: 'one', id: 'one:0:0', action: present_action },
            { client_id: 'b', connection_id: 'one', id: 'one:0:1', action: present_action }
          ]
        end
        let(:presence_sync_2) do
          [
            { client_id: 'a', connection_id: 'one', id: 'one:1:0', action: leave_action }
          ]
        end

        it 'is initiated with a SYNC message and completed with a later SYNC message with no cursor value part of the channelSerial (#RTP18a, #RTP18b) ', em_timeout: 15 do
          presence_anonymous_client.get do |members|
            expect(members.length).to eql(0)
            expect(presence_anonymous_client).to be_sync_complete

            presence_anonymous_client.subscribe(:present) do
              expect(presence_anonymous_client).to_not be_sync_complete
              presence_anonymous_client.get do |members|
                expect(presence_anonymous_client).to be_sync_complete
                expect(members.length).to eql(1)
                expect(members.first.client_id).to eql('b')
                stop_reactor
              end
            end

            ## Fabricate server-initiated SYNC in two parts
            action = Ably::Models::ProtocolMessage::ACTION.Sync
            sync_message = Ably::Models::ProtocolMessage.new(
              action: action,
              connection_serial: 10,
              channel_serial: 'sequenceid:cursor',
              channel: channel_name,
              presence: presence_sync_1,
              timestamp: Time.now.to_i * 1000
            )
            anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, sync_message

            sync_message = Ably::Models::ProtocolMessage.new(
              action: action,
              connection_serial: 11,
              channel_serial: 'sequenceid:', # indicates SYNC is complete
              channel: channel_name,
              presence: presence_sync_2,
              timestamp: Time.now.to_i * 1000
            )
            anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, sync_message
          end
        end
      end

      context 'with a single SYNC page' do
        let(:present_action) { 1 }
        let(:leave_action) { 3 }
        let(:presence_sync) do
          [
            { client_id: 'a', connection_id: 'one', id: 'one:0:0', action: present_action },
            { client_id: 'b', connection_id: 'one', id: 'one:0:1', action: present_action },
            { client_id: 'a', connection_id: 'one', id: 'one:1:0', action: leave_action }
          ]
        end

        it 'is initiated and completed with a single SYNC message (and no channelSerial) (#RTP18a, #RTP18c) ', em_timeout: 15 do
          presence_anonymous_client.get do |members|
            expect(members.length).to eql(0)
            expect(presence_anonymous_client).to be_sync_complete

            presence_anonymous_client.subscribe(:present) do
              expect(presence_anonymous_client).to_not be_sync_complete
              presence_anonymous_client.get do |members|
                expect(presence_anonymous_client).to be_sync_complete
                expect(members.length).to eql(1)
                expect(members.first.client_id).to eql('b')
                stop_reactor
              end
            end

            ## Fabricate server-initiated SYNC in two parts
            action = Ably::Models::ProtocolMessage::ACTION.Sync
            sync_message = Ably::Models::ProtocolMessage.new(
              action: action,
              connection_serial: 10,
              channel: channel_name,
              presence: presence_sync,
              timestamp: Time.now.to_i * 1000
            )
            anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, sync_message
          end
        end
      end

      context 'when members exist in the PresenceMap before a SYNC completes' do
        let(:enter_action) { Ably::Models::PresenceMessage::ACTION.Enter.to_i }
        let(:present_action) { Ably::Models::PresenceMessage::ACTION.Present.to_i }
        let(:presence_sync_protocol_message) do
          [
            { client_id: 'a', connection_id: 'one', id: 'one:0:0', action: present_action },
            { client_id: 'b', connection_id: 'one', id: 'one:0:1', action: present_action }
          ]
        end
        let(:presence_enter_message) do
          Ably::Models::PresenceMessage.new(
            'id' => "#{random_str}:#{random_str}:0",
            'clientId' => random_str,
            'connectionId' => random_str,
            'timestamp' => as_since_epoch(Time.now),
            'action' => enter_action
          )
        end

        it 'removes the members that are no longer present (#RTP19)', em_timeout: 15 do
          presence_anonymous_client.get do |members|
            expect(members.length).to eql(0)

            # Now inject a fake member into the PresenceMap by faking the receive of a Presence message from Ably into the Presence object
            presence_anonymous_client.__incoming_msgbus__.publish :presence, presence_enter_message

            EventMachine.next_tick do
              presence_anonymous_client.get do |members|
                expect(members.length).to eql(1)
                expect(members.first.client_id).to eql(presence_enter_message.client_id)

                presence_events = []
                presence_anonymous_client.subscribe do |presence_message|
                  presence_events << [presence_message.client_id, presence_message.action.to_sym]
                  if presence_message.action == :leave
                    expect(presence_message.id).to be_nil
                    expect(presence_message.timestamp.to_f * 1000).to be_within(200).of(Time.now.to_f * 1000)
                  end
                end

                ## Fabricate server-initiated SYNC in two parts
                action = Ably::Models::ProtocolMessage::ACTION.Sync
                sync_message = Ably::Models::ProtocolMessage.new(
                  action: action,
                  connection_serial: 10,
                  channel: channel_name,
                  presence: presence_sync_protocol_message,
                  timestamp: Time.now.to_i * 1000
                )
                anonymous_client.connection.__incoming_protocol_msgbus__.publish :protocol_message, sync_message

                EventMachine.next_tick do
                  presence_anonymous_client.get do |members|
                    expect(members.length).to eql(2)
                    expect(members.find { |member| member.client_id == presence_enter_message.client_id}).to be_nil
                    expect(presence_events).to contain_exactly(
                      ['a', :present],
                      ['b', :present],
                      [presence_enter_message.client_id, :leave]
                    )
                    stop_reactor
                  end
                end
              end
            end
          end
        end
      end
    end

    context 'when the client does not have presence subscribe privileges but is present on the channel' do
      let(:present_only_capability) do
        { channel_name => ["presence"] }
      end
      let(:present_only_callback) { lambda { |token_params| Ably::Rest::Client.new(client_options).auth.request_token(client_id: '*', capability: present_only_capability) } }
      let(:client_one) { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: present_only_callback)) }

      it 'receives presence updates for all presence events generated by the current connection and the presence map is kept up to date (#RTP17a)' do
        enter_client_ids = []
        presence_client_one.subscribe(:enter) do |presence_message|
          enter_client_ids << presence_message.client_id
        end

        leave_client_ids = []
        presence_client_one.subscribe(:leave) do |presence_message|
          leave_client_ids << presence_message.client_id
        end

        presence_client_one.enter_client 'bob' do
          presence_client_one.enter_client 'sarah'
        end

        entered_count = 0
        presence_client_one.subscribe(:enter) do
          entered_count += 1
          next unless entered_count == 2

          presence_client_one.unsubscribe :enter
          presence_client_one.get do |members|
            EventMachine.add_timer(1) do
              expect(members.map(&:client_id)).to contain_exactly('bob', 'sarah')
              expect(enter_client_ids).to contain_exactly('bob', 'sarah')

              presence_client_one.leave_client 'bob' do
                presence_client_one.leave_client 'sarah'
              end

              leave_count = 0
              presence_client_one.subscribe(:leave) do
                leave_count += 1
                next unless leave_count == 2

                presence_client_one.get do |members|
                  expect(members.length).to eql(0)
                  expect(leave_client_ids).to contain_exactly('bob', 'sarah')
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    context "local PresenceMap for presence members entered by this client" do
      it "maintains a copy of the member map for any member that shares this connection's connection ID (#RTP17)" do
        presence_client_one.enter do
          presence_client_two.enter
        end

        entered_count = 0
        presence_client_one.subscribe(:enter) do
          entered_count += 1
          next unless entered_count == 2
          channel_anonymous_client.attach do
            channel_anonymous_client.presence.get do |members|
              expect(channel_anonymous_client.presence.members.local_members).to be_empty
              expect(presence_client_one.members.local_members.length).to eql(1)
              expect(presence_client_one.members.local_members.values.first.connection_id).to eql(client_one.connection.id)
              expect(presence_client_two.members.local_members.values.first.connection_id).to eql(client_two.connection.id)
              presence_client_two.leave
              presence_client_two.subscribe(:leave) do
                expect(presence_client_two.members.local_members).to be_empty
                stop_reactor
              end
            end
          end
        end
      end

      context 'when a channel becomes attached again' do
        let(:attached_action) { Ably::Models::ProtocolMessage::ACTION.Attached.to_i }
        let(:sync_action) { Ably::Models::ProtocolMessage::ACTION.Sync.to_i }
        let(:presence_action) { Ably::Models::ProtocolMessage::ACTION.Presence.to_i }
        let(:present_action) { Ably::Models::PresenceMessage::ACTION.Present.to_i }
        let(:resume_flag) { 4 }
        let(:presence_flag) { 1 }

        def fabricate_incoming_protocol_message(protocol_message)
          client_one.connection.__incoming_protocol_msgbus__.publish :protocol_message, protocol_message
        end

        # Prevents any messages from the WebSocket transport being sent / received
        # Connection protocol message subscriptions are still active, but nothing reaches or comes from the WebSocket transport
        def cripple_websocket_transport
          client_one.connection.transport.__incoming_protocol_msgbus__.unsubscribe
          client_one.connection.transport.__outgoing_protocol_msgbus__.unsubscribe
        end

        context 'and the resume flag is true' do
          context 'and the presence flag is false' do
            it 'does not send any presence events as the PresenceMap is in sync (#RTP5c1)' do
              presence_client_one.enter
              presence_client_one.subscribe(:enter) do
                presence_client_one.unsubscribe :enter

                client_one.connection.transport.__outgoing_protocol_msgbus__.subscribe do |message|
                  raise "No presence state updates to Ably are expected. Message sent: #{message.to_json}" if client_one.connection.connected?
                end

                cripple_websocket_transport

                fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                  action: attached_action,
                  channel: channel_name,
                  flags: resume_flag
                )

                EventMachine.add_timer(1) do
                  presence_client_one.get do |members|
                    expect(members.length).to eql(1)
                    expect(presence_client_one.members.local_members.length).to eql(1)
                    stop_reactor
                  end
                end
              end
            end
          end

          context 'and the presence flag is true' do
            context 'and following the SYNC all local MemberMap members are present in the PresenceMap' do
              it 'does nothing as MemberMap is in sync (#RTP5c2)' do
                presence_client_one.enter
                presence_client_one.subscribe(:enter) do
                  presence_client_one.unsubscribe :enter

                  expect(presence_client_one.members.length).to eql(1)
                  expect(presence_client_one.members.local_members.length).to eql(1)

                  presence_client_one.members.once(:in_sync) do
                    presence_client_one.get do |members|
                      expect(members.length).to eql(1)
                      expect(presence_client_one.members.local_members.length).to eql(1)
                      stop_reactor
                    end
                  end

                  client_one.connection.transport.__outgoing_protocol_msgbus__.subscribe do |message|
                    raise "No presence state updates to Ably are expected. Message sent: #{message.to_json}" if client_one.connection.connected?
                  end

                  cripple_websocket_transport

                  fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                    action: attached_action,
                    channel: channel_name,
                    flags: resume_flag + presence_flag
                  )

                  fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                    action: sync_action,
                    channel: channel_name,
                    presence: presence_client_one.members.map(&:shallow_clone).map(&:as_json),
                    channelSerial: nil # no further SYNC messages expected
                  )
                end
              end
            end

            context 'and following the SYNC a local MemberMap member is not present in the PresenceMap' do
              it 're-enters the missing members automatically (#RTP5c2)' do
                sync_check_completed = false

                presence_client_one.enter
                presence_client_one.subscribe(:enter) do
                  presence_client_one.unsubscribe :enter

                  expect(presence_client_one.members.length).to eql(1)
                  expect(presence_client_one.members.local_members.length).to eql(1)

                  client_one.connection.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |message|
                    next if message.action == :close # ignore finalization of connection

                    expect(message.action).to eq(:presence)
                    presence_message = message.presence.first
                    expect(presence_message.action).to eq(:enter)
                    expect(presence_message.client_id).to eq(client_one.auth.client_id)

                    presence_client_one.subscribe(:enter) do |message|
                      expect(message.connection_id).to eql(client_one.connection.id)
                      expect(message.client_id).to eq(client_one.auth.client_id)

                      EventMachine.next_tick do
                        expect(presence_client_one.members.length).to eql(2)
                        expect(presence_client_one.members.local_members.length).to eql(1)
                        expect(sync_check_completed).to be_truthy
                        stop_reactor
                      end
                    end

                    # Fabricate Ably sending back the Enter PresenceMessage to the client a short while after
                    # ensuring the PresenceMap for a short period does not have this member as to be expected in reality
                    EventMachine.add_timer(0.2) do
                      connection_id = random_str
                      fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                        action: presence_action,
                        channel: channel_name,
                        connectionId: client_one.connection.id,
                        connectionSerial: 50,
                        timestamp: as_since_epoch(Time.now),
                        presence: [presence_message.shallow_clone(id: "#{client_one.connection.id}:0:0", timestamp: as_since_epoch(Time.now)).as_json]
                      )
                    end
                  end

                  presence_client_one.members.once(:in_sync) do
                    # For a brief period, the client will have re-entered the missing members from the local_members
                    # but the enter from Ably will have not been received, so at this point the local_members will be empty
                    presence_client_one.get do |members|
                      expect(members.length).to eql(1)
                      expect(members.first.connection_id).to_not eql(client_one.connection.id)
                      expect(presence_client_one.members.local_members.length).to eql(0)
                      sync_check_completed = true
                    end
                  end

                  cripple_websocket_transport

                  fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                    action: attached_action,
                    channel: channel_name,
                    flags: resume_flag + presence_flag
                  )

                  # Complete the SYNC but without the member who was entered by this client
                  connection_id = random_str
                  fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                    action: sync_action,
                    channel: channel_name,
                    timestamp: as_since_epoch(Time.now),
                    presence: [{ id: "#{connection_id}:0:0", action: present_action, connection_id: connection_id, client_id: random_str }],
                    chanenlSerial: nil # no further SYNC messages expected
                  )
                end
              end
            end
          end
        end

        context 'and the resume flag is false' do
          context 'and the presence flag is false' do
            let(:member_data) { random_str }

            it 'immediately resends all local presence members (#RTP5c2, #RTP19a)' do
              in_sync_confirmed_no_local_members = false
              local_member_leave_event_fired = false

              presence_client_one.enter(member_data)
              presence_client_one.subscribe(:enter) do
                presence_client_one.unsubscribe :enter

                presence_client_one.subscribe(:leave) do |message|
                  # The local member will leave the PresenceMap due to the ATTACHED without Presence
                  local_member_leave_event_fired = true
                end

                # Local members re-entered automatically appear as updates due to the
                # fabricated ATTACHED message sent and the members already being present
                presence_client_one.subscribe(:update) do |message|
                  expect(local_member_leave_event_fired).to be_truthy
                  expect(message.data).to eq(member_data)
                  expect(message.client_id).to eq(client_one.auth.client_id)
                  EventMachine.next_tick do
                    expect(presence_client_one.members.length).to eql(1)
                    expect(presence_client_one.members.local_members.length).to eql(1)
                    expect(in_sync_confirmed_no_local_members).to be_truthy
                    stop_reactor
                  end
                end

                presence_client_one.members.once(:in_sync) do
                  # Immediately after SYNC (no sync actually occurred, but this event fires immediately after a channel SYNCs or is not expecting to SYNC)
                  expect(presence_client_one.members.length).to eql(0)
                  expect(presence_client_one.members.local_members.length).to eql(0)
                  in_sync_confirmed_no_local_members = true
                end

                # ATTACHED ProtocolMessage with no presence flag will clear the presence set immediately, #RTP19a
                fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                  action: attached_action,
                  channel: channel_name,
                  flags: 0 # no resume or presence flag
                )
              end
            end
          end
        end

        context 'when re-entering a client automatically, if the re-enter fails for any reason' do
          let(:client_one_options) do
            client_options.merge(client_id: client_one_id, log_level: :error)
          end
          let(:client_one) { auto_close Ably::Realtime::Client.new(client_one_options) }

          it 'should emit an ErrorInfo with error code 91004 (#RTP5c3)' do
            presence_client_one.enter

            # Wait for client to be entered
            presence_client_one.subscribe(:enter) do
              # Local member should not be re-entered as the request to re-enter will timeout
              presence_client_one.subscribe(:update) do |message|
                raise "Unexpected update, this should not happen as the re-enter fails"
              end

              channel_client_one.on(:update) do |channel_state_change|
                next if channel_state_change.reason.nil? # first update is generated by the fabricated ATTACHED

                expect(channel_state_change.reason.code).to eql(91004)
                expect(channel_state_change.reason.message).to match(/#{client_one_id}/)
                expect(channel_state_change.reason.message).to match(/Fabricated/) # fabricated message
                expect(channel_state_change.reason.message).to match(/2345/) # fabricated error code
                stop_reactor
              end

              cripple_websocket_transport

              client_one.connection.__outgoing_protocol_msgbus__.subscribe do |protocol_message|
                if protocol_message.action == :presence
                  # Fabricate a NACK for the re-enter message
                  EventMachine.add_timer(0.1) do
                    fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                      action: Ably::Models::ProtocolMessage::ACTION.Nack.to_i ,
                      channel: channel_name,
                      count: 1,
                      msg_serial: protocol_message.message_serial,
                      error: {
                        message: 'Fabricated',
                        code: 2345
                      }
                    )
                  end
                end
              end

              # ATTACHED ProtocolMessage with no presence flag will clear the presence set immediately, #RTP19a
              fabricate_incoming_protocol_message Ably::Models::ProtocolMessage.new(
                action: attached_action,
                channel: channel_name,
                flags: 0 # no resume or presence flag
              )
            end
          end
        end
      end
    end

    context 'channel state side effects' do
      context 'channel transitions to the FAILED state' do
        let(:anonymous_client) { auto_close Ably::Realtime::Client.new(client_options.merge(log_level: :fatal)) }
        let(:client_one)       { auto_close Ably::Realtime::Client.new(client_options.merge(client_id: client_one_id, log_level: :fatal)) }

        it 'clears the PresenceMap and local member map copy and does not emit any presence events (#RTP5a)' do
          presence_client_one.enter
          presence_client_one.subscribe(:enter) do
            presence_client_one.unsubscribe :enter

            channel_anonymous_client.attach do
              presence_anonymous_client.get do |members|
                expect(members.count).to eq(1)

                presence_anonymous_client.subscribe { raise 'No presence events should be emitted' }
                channel_anonymous_client.transition_state_machine! :failed, reason: RuntimeError.new
                expect(presence_anonymous_client.members.length).to eq(0)
                expect(channel_anonymous_client).to be_failed
                presence_anonymous_client.unsubscribe # prevent events being sent to the channel from Ably as it is unaware it's FAILED

                expect(presence_client_one.members.local_members.count).to eq(1)
                channel_client_one.transition_state_machine! :failed
                expect(channel_client_one).to be_failed
                expect(presence_client_one.members.local_members.count).to eq(0)
                stop_reactor
              end
            end
          end
        end
      end

      context 'channel transitions to the DETACHED state' do
        it 'clears the PresenceMap and local member map copy and does not emit any presence events (#RTP5a)' do
          presence_client_one.enter
          presence_client_one.subscribe(:enter) do
            presence_client_one.unsubscribe :enter

            channel_anonymous_client.attach do
              presence_anonymous_client.get do |members|
                expect(members.count).to eq(1)

                presence_anonymous_client.subscribe { raise 'No presence events should be emitted' }
                channel_anonymous_client.detach do
                  expect(presence_anonymous_client.members.length).to eq(0)
                  expect(channel_anonymous_client).to be_detached

                  expect(presence_client_one.members.local_members.count).to eq(1)
                  channel_client_one.detach do
                    expect(presence_client_one.members.local_members.count).to eq(0)
                    stop_reactor
                  end
                end
              end
            end
          end
        end
      end

      context 'channel transitions to the SUSPENDED state' do
        let(:auth_callback) do
          lambda do |token_params|
            # Pause to allow presence updates to occur whilst disconnected
            sleep 1
            Ably::Rest::Client.new(client_options).auth.request_token
          end
        end
        let(:anonymous_client) { auto_close Ably::Realtime::Client.new(client_options.merge(auth_callback: auth_callback)) }

        it 'maintains the PresenceMap and only publishes presence event changes since the last attached state (#RTP5f)' do
          presence_client_one.enter do
            presence_client_two.enter
          end

          entered_count = 0
          presence_client_one.subscribe(:enter) do
            entered_count += 1
            next unless entered_count == 2

            presence_client_one.unsubscribe :enter
            channel_anonymous_client.attach do
              presence_anonymous_client.get do |members|
                expect(members.count).to eq(2)

                received_events = []
                presence_anonymous_client.subscribe do |presence_message|
                  expect(presence_message.action).to eq(:leave)
                  expect(presence_message.client_id).to eql(client_one_id)
                  received_events << [:leave, presence_message.client_id]
                end

                # Kill the connection triggering an automatic reconnect and reattach of the channel that is about to put into the suspended state
                anonymous_client.connection.transport.close_connection_after_writing

                # Prevent the same connection resuming, we want a new connection and the channel SYNC to be sent
                anonymous_client.connection.reset_resume_info

                anonymous_client.connection.once(:disconnected) do
                  # Move to the SUSPENDED state and check presence map intact
                  channel_anonymous_client.transition_state_machine! :suspended

                  # Change the presence map state on that channel by getting one member to leave whilst the connection for anonymous client is diconnected
                  presence_client_one.leave

                  # Whilst SUSPENDED and DISCONNECTED, a get of the PresenceMap should still reveal two members
                  presence_anonymous_client.get(wait_for_sync: false) do |members|
                    expect(members.count).to eq(2)

                    channel_anonymous_client.once(:attached) do
                      presence_anonymous_client.get do |members|
                        expect(members.count).to eq(1)
                        EventMachine.add_timer(0.5) do
                          expect(received_events).to contain_exactly([:leave, client_one_id])
                          presence_anonymous_client.unsubscribe
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
    end
  end
end
