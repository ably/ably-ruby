# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channel do
  include RSpec::EventMachine

  [:json].each do |protocol| #:msgpack,
    context "over #{protocol}" do
      let(:default_options) { { api_key: api_key, environment: environment, protocol: protocol } }
      let(:client_options)  { default_options }

      let(:client)       { Ably::Realtime::Client.new(client_options) }
      let(:channel_name) { random_str }
      let(:payload)      { random_str }
      let(:channel)      { client.channel(channel_name) }
      let(:messages)     { [] }

      context 'connection with connect_automatically option set to false' do
        let(:client) do
          Ably::Realtime::Client.new(default_options.merge(connect_automatically: false))
        end

        it 'remains initialized when accessing a channel' do
          run_reactor do
            client.channel('test')
            EventMachine.add_timer(2) do
              expect(client.connection).to be_initialized
              stop_reactor
            end
          end
        end

        it 'opens implicitly if attaching to a channel' do
          run_reactor do
            client.channel('test').attach do
              expect(client.connection).to be_connected
              stop_reactor
            end
          end
        end

        it 'opens implicitly if accessing the presence object' do
          run_reactor do
            client.channel('test').tap do |channel|
              channel.on(:attached) do
                expect(client.connection).to be_connected
                stop_reactor
              end
              channel.presence
            end
          end
        end
      end

      context 'when :failed' do
        let(:client_options) { default_options.merge(log_level: :fatal) }

        specify '#attach reattaches' do
          run_reactor do
            channel.attach do
              channel.transition_state_machine :failed, RuntimeError.new
              expect(channel).to be_failed
              channel.attach do
                expect(channel).to be_attached
                stop_reactor
              end
            end
          end
        end

        specify '#detach raises an exception' do
          run_reactor do
            channel.attach do
              channel.transition_state_machine :failed, RuntimeError.new
              expect(channel).to be_failed
              expect { channel.detach }.to raise_error Ably::Exceptions::StateChangeError
              stop_reactor
            end
          end
        end
      end

      context 'when :attaching' do
        it 'emits attaching then attached events' do
          run_reactor do
            channel.once(:attaching) do
              channel.once(:attached) do
                stop_reactor
              end
            end

            channel.attach
          end
        end

        specify '#detach moves straight to detaching and skips attached' do
          run_reactor do
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

        it 'ignores subsequent #attach calls but calls the callback if provided' do
          run_reactor do
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
        end
      end

      context 'when :detaching' do
        it 'emits detaching then detached events' do
          run_reactor do
            channel.once(:detaching) do
              channel.once(:detached) do
                stop_reactor
              end
            end

            channel.attach do
              channel.detach
            end
          end
        end

        specify '#attach moves straight to attaching and skips detached' do
          run_reactor do
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

        it 'ignores subsequent #detach calls but calls the callback if provided' do
          run_reactor do
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
      end

      it 'attaches to a channel' do
        run_reactor do
          channel.attach
          channel.on(:attached) do
            expect(channel.state).to eq(:attached)
            stop_reactor
          end
        end
      end

      it 'attaches to a channel with a block' do
        run_reactor do
          channel.attach do
            expect(channel.state).to eq(:attached)
            stop_reactor
          end
        end
      end

      it 'detaches from a channel with a block' do
        run_reactor do
          channel.attach do |chan|
            chan.detach do |detached_chan|
              expect(detached_chan.state).to eq(:detached)
              stop_reactor
            end
          end
        end
      end

      it 'publishes 3 messages once attached' do
        run_reactor do
          channel.attach do
            3.times { channel.publish('event', payload) }
          end
          channel.subscribe do |message|
            messages << message if message.data == payload
            stop_reactor if messages.length == 3
          end
        end

        expect(messages.count).to eql(3)
      end

      it 'publishes 3 messages from queue before attached' do
        run_reactor do
          3.times { channel.publish('event', random_str) }
          channel.subscribe do |message|
            messages << message if message.name == 'event'
            stop_reactor if messages.length == 3
          end
        end

        expect(messages.count).to eql(3)
      end

      it 'publishes 3 messages from queue before attached in a single protocol message' do
        run_reactor do
          3.times { channel.publish('event', random_str) }
          channel.subscribe do |message|
            messages << message if message.name == 'event'
            stop_reactor if messages.length == 3
          end
        end

        # All 3 messages should be batched into a single Protocol Message by the client library
        # message.id = "{protocol_message.id}:{protocol_message_index}"

        # Check that all messages share the same message_serial
        message_id = messages.map { |msg| msg.id.split(':')[0] }
        expect(message_id.uniq.count).to eql(1)

        # Check that all messages use message index 0,1,2
        message_indexes = messages.map { |msg| msg.id.split(':')[1] }
        expect(message_indexes).to include("0", "1", "2")
      end

      it 'subscribes and unsubscribes' do
        run_reactor do
          channel.subscribe('click') do |message|
            messages << message
          end
          channel.attach do
            channel.unsubscribe('click')
            channel.publish('click', 'data')
            EventMachine.add_timer(2) do
              stop_reactor
              expect(messages.length).to eql(0)
            end
          end
        end
      end

      it 'subscribes and unsubscribes from multiple channels' do
        run_reactor do
          click_callback = proc { |message| messages << message }

          channel.subscribe('click', &click_callback)
          channel.subscribe('move', &click_callback)
          channel.subscribe('press', &click_callback)

          channel.attach do
            channel.unsubscribe('click')
            channel.unsubscribe('move', &click_callback)
            channel.unsubscribe('press') { this_callback_is_not_subscribed_so_ignored }

            channel.publish('click', 'data')
            channel.publish('move', 'data')
            channel.publish('press', 'data')

            EventMachine.add_timer(2) do
              stop_reactor
              # Only the press subscribe callback should still be subscribed
              expect(messages.length).to eql(1)
            end
          end
        end
      end

      it 'opens many connections and then many channels simultaneously' do
        run_reactor(15) do
          count         = 25
          connected_ids = []
          member_ids    = []

          clients = count.times.map do
            Ably::Realtime::Client.new(default_options)
          end

          channels_opened = 0
          open_channels_on_clients = Proc.new do
            5.times.each do |channel|
              clients.each do |client|
                client.channel("channel-#{channel}").attach do
                  channels_opened += 1
                  if channels_opened == clients.count * 5
                    expect(channels_opened).to eql(clients.count * 5)
                    stop_reactor
                  end
                end
              end
            end
          end

          clients.each do |client|
            client.connection.on(:connected) do
              connected_ids << client.connection.id
              member_ids    << client.connection.member_id

              if connected_ids.count == 25
                expect(connected_ids.uniq.count).to eql(25)
                expect(member_ids.uniq.count).to eql(25)
                open_channels_on_clients.call
              end
            end
          end
        end
      end

      it 'opens many connections and attaches to channels before connected' do
        run_reactor(15) do
          count, connected_ids = 25, []

          clients = count.times.map do
            Ably::Realtime::Client.new(default_options)
          end

          channels_opened = 0

          clients.each do |client|
            5.times.each do |channel|
              client.channel("channel-#{channel}").attach do
                channels_opened += 1
                if channels_opened == clients.count * 5
                  expect(channels_opened).to eql(clients.count * 5)
                  stop_reactor
                end
              end
            end
          end
        end
      end

      context 'attach failure' do
        let(:restricted_client) do
          Ably::Realtime::Client.new(default_options.merge(api_key: restricted_api_key, log_level: :fatal))
        end
        let(:restricted_channel) { restricted_client.channel("cannot_subscribe") }

        it 'triggers failed event' do
          run_reactor do
            restricted_channel.attach
            restricted_channel.on(:failed) do |error|
              expect(restricted_channel.state).to eq(:failed)
              expect(error.status).to eq(401)
              stop_reactor
            end
          end
        end

        it 'triggers an error event' do
          run_reactor do
            restricted_channel.attach
            restricted_channel.on(:error) do |error|
              expect(restricted_channel.state).to eq(:failed)
              expect(error.status).to eq(401)
              stop_reactor
            end
          end
        end

        it 'updates the error_reason' do
          run_reactor do
            restricted_channel.attach
            restricted_channel.on(:failed) do
              expect(restricted_channel.error_reason.status).to eq(401)
              stop_reactor
            end
          end
        end
      end

      describe 'when connection' do
        context 'fails' do
          let(:connection_error) { Ably::Exceptions::ConnectionError.new('forced failure', 500, 50000) }
          let(:client_options)   { default_options.merge(log_level: :none) }

          context 'a attached channel' do
            it 'transitions state to :failed' do
              run_reactor do
                channel.attach do
                  channel.on(:failed) do |error|
                    expect(error).to eql(connection_error)
                    stop_reactor
                  end

                  client.connection.manager.error_received_from_server connection_error
                end
              end
            end

            it 'triggers an error event for the channel' do
              run_reactor do
                channel.attach do
                  channel.on(:error) do |error|
                    expect(error).to eql(connection_error)
                    stop_reactor
                  end

                  client.connection.manager.error_received_from_server connection_error
                end
              end
            end

            it 'updates the error_reason' do
              run_reactor do
                channel.attach do
                  channel.on(:failed) do |error|
                    expect(channel.error_reason).to eql(connection_error)
                    stop_reactor
                  end

                  client.connection.manager.error_received_from_server connection_error
                end
              end
            end
          end

          context 'a detached channel' do
            it 'remains in the same state' do
              run_reactor do
                channel.attach do
                  channel.on(:failed) { raise 'Failed state should not have been reached' }
                  channel.on(:error)  { raise 'Error should not have been emitted' }

                  channel.detach do
                    EventMachine.add_timer(1) do
                      expect(channel).to be_detached
                      stop_reactor
                    end

                    client.connection.manager.error_received_from_server connection_error
                  end
                end
              end
            end
          end

          context 'a failed channel' do
            let(:original_error) { RuntimeError.new }

            it 'remains in the same state' do
              run_reactor do
                channel.attach do
                  channel.on(:error) do
                    channel.on(:failed) { raise 'Failed state should not have been reached' }
                    channel.on(:error)  { raise 'Error should not have been emitted' }

                    EventMachine.add_timer(1) do
                      expect(channel).to be_failed
                      expect(channel.error_reason).to eql(original_error)
                      stop_reactor
                    end

                    client.connection.manager.error_received_from_server connection_error
                  end

                  channel.transition_state_machine :failed, original_error
                end
              end
            end
          end
        end

        context 'closes' do
          context 'a attached channel' do
            it 'transitions state to :detached' do
              run_reactor do
                channel.attach do
                  channel.on(:detached) do
                    stop_reactor
                  end

                  client.connection.close
                end
              end
            end
          end

          context 'a detached channel' do
            it 'remains in the same state' do
              run_reactor do
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
          end

          context 'failed channel' do
            let(:original_error) { RuntimeError.new }
            let(:client_options)   { default_options.merge(log_level: :fatal) }

            it 'remains in the same state' do
              run_reactor do
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

                  channel.transition_state_machine :failed, original_error
                end
              end
            end
          end
        end
      end
    end
  end
end


