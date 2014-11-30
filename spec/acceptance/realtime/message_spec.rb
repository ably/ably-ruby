require 'spec_helper'
require 'securerandom'

describe 'Ably::Realtime::Channel Messages' do
  include RSpec::EventMachine

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) { options.merge(api_key: api_key, environment: environment, protocol: protocol) }
      let(:client) do
        Ably::Realtime::Client.new(default_options)
      end
      let(:channel) { client.channel(channel_name) }

      let(:other_client) do
        Ably::Realtime::Client.new(default_options)
      end
      let(:other_client_channel) { other_client.channel(channel_name) }

      let(:channel_name) { 'subscribe_send_text' }
      let(:options) { { :protocol => :json } }
      let(:payload) { 'Test message (subscribe_send_text)' }

      it 'sends a string message' do
        run_reactor do
          channel.attach
          channel.on(:attached) do
            channel.publish('test_event', payload) do |message|
              expect(message.data).to eql(payload)
              stop_reactor
            end
          end
        end
      end

      it 'sends a single message with an echo on another connection' do
        run_reactor do
          other_client_channel.attach do
            channel.publish 'test_event', payload
            other_client_channel.subscribe('test_event') do |message|
              expect(message.data).to eql(payload)
              stop_reactor
            end
          end
        end
      end

      context 'with echo_messages => false' do
        let(:no_echo_client) do
          Ably::Realtime::Client.new(default_options.merge(echo_messages: false))
        end
        let(:no_echo_channel) { no_echo_client.channel(channel_name) }

        it 'sends a single message without a reply yet the messages is echoed on another normal connection' do
          run_reactor(10) do
            channel.attach do |echo_channel|
              no_echo_channel.attach do
                no_echo_channel.publish 'test_event', payload

                no_echo_channel.subscribe('test_event') do |message|
                  fail "Message should not have been echoed back"
                end

                echo_channel.subscribe('test_event') do |message|
                  expect(message.data).to eql(payload)
                  EventMachine.add_timer(1) do
                    stop_reactor
                  end
                end
              end
            end
          end
        end
      end

      context 'with multiple messages' do
        let(:send_count) { 15 }
        let(:expected_echos) { send_count * 2 }
        let(:channel_name) { SecureRandom.hex }
        let(:echos) do
          { client: 0, other: 0 }
        end
        let(:callbacks) do
          { client: 0, other: 0 }
        end

        it 'sends and receives the messages on both opened connections and calls the callbacks (expects twice number of messages due to local echos)' do
          run_reactor(8) do
            check_message_and_callback_counts = Proc.new do
              if echos[:client] == expected_echos && echos[:other] == expected_echos
                # Wait for message backlog to clear
                EventMachine.add_timer(0.5) do
                  expect(echos[:client]).to eql(expected_echos)
                  expect(echos[:other]).to eql(expected_echos)

                  expect(callbacks[:client]).to eql(send_count)
                  expect(callbacks[:other]).to eql(send_count)

                  EventMachine.stop
                end
              end
            end

            published = false
            attach_callback = Proc.new do
              next if published

              if channel.attached? && other_client_channel.attached?
                send_count.times do |index|
                  channel.publish('test_event', "#{index}: #{payload}") do
                    callbacks[:client] += 1
                  end
                  other_client_channel.publish('test_event', "#{index}: #{payload}") do
                    callbacks[:other] += 1
                  end
                end

                published = true
              end
            end

            channel.subscribe('test_event') do |message|
              echos[:client] += 1
              check_message_and_callback_counts.call
            end
            other_client_channel.subscribe('test_event') do |message|
              echos[:other] += 1
              check_message_and_callback_counts.call
            end

            channel.attach &attach_callback
            other_client_channel.attach &attach_callback
          end
        end
      end

      context 'without suitable publishing permissions' do
        let(:restricted_client) do
          Ably::Realtime::Client.new(options.merge(api_key: restricted_api_key, environment: environment, protocol: protocol))
        end
        let(:restricted_channel) { restricted_client.channel("cansubscribe:example") }
        let(:payload) { 'Test message without permission to publish' }

        it 'calls the error callback' do
          run_reactor do
            restricted_channel.attach
            restricted_channel.on(:attached) do
              deferrable = restricted_channel.publish('test_event', payload)
              deferrable.errback do |message, error|
                expect(message.data).to eql(payload)
                expect(error.status).to eql(401)
                stop_reactor
              end
              deferrable.callback do |message|
                fail 'Success callback should not have been called'
                stop_reactor
              end
            end
          end
        end
      end
    end
  end
end
