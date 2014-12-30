# encoding: utf-8
require 'spec_helper'
require 'base64'
require 'json'
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
      let(:options)      { { :protocol => :json } }
      let(:payload)      { 'Test message (subscribe_send_text)' }

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

      context 'with ASCII_8BIT message name' do
        let(:message_name) { random_str.encode(Encoding::ASCII_8BIT) }
        it 'is converted into UTF_8' do
          run_reactor do
            channel.attach do
              channel.publish message_name, payload
            end
            channel.subscribe do |message|
              expect(message.name.encoding).to eql(Encoding::UTF_8)
              expect(message.name.encode(Encoding::ASCII_8BIT)).to eql(message_name)
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
        let(:send_count)     { 15 }
        let(:expected_echos) { send_count * 2 }
        let(:channel_name)   { random_str }
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

                  stop_reactor
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
        let(:payload)            { 'Test message without permission to publish' }

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

      context 'encoding and decoding encrypted messages' do
        shared_examples 'an Ably encrypter and decrypter' do |item, data|
          let(:algorithm)      { data['algorithm'].upcase }
          let(:mode)           { data['mode'].upcase }
          let(:key_length)     { data['keylength'] }
          let(:secret_key)     { Base64.decode64(data['key']) }
          let(:iv)             { Base64.decode64(data['iv']) }

          let(:cipher_options) { { key: secret_key, iv: iv, algorithm: algorithm, mode: mode, key_length: key_length } }

          context 'publish & subscribe' do
            let(:encoded)          { item['encoded'] }
            let(:encoded_data)     { encoded['data'] }
            let(:encoded_encoding) { encoded['encoding'] }
            let(:encoded_data_decoded) do
              if encoded_encoding == 'json'
                JSON.parse(encoded_data)
              elsif encoded_encoding == 'base64'
                Base64.decode64(encoded_data)
              else
                encoded_data
              end
            end

            let(:encrypted)          { item['encrypted'] }
            let(:encrypted_data)     { encrypted['data'] }
            let(:encrypted_encoding) { encrypted['encoding'] }
            let(:encrypted_data_decoded) do
              if encrypted_encoding.match(%r{/base64$})
                Base64.decode64(encrypted_data)
              else
                encrypted_data
              end
            end

            let(:encrypted_channel) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

            it 'encrypts message automatically when published' do
              run_reactor do
                encrypted_channel.__incoming_msgbus__.unsubscribe # remove all subscribe callbacks that could decrypt the message

                encrypted_channel.__incoming_msgbus__.subscribe(:message) do |message|
                  if protocol == :json
                    expect(message['encoding']).to eql(encrypted_encoding)
                    expect(message['data']).to eql(encrypted_data)
                  else
                    # Messages received over binary protocol will not have Base64 encoded data
                    expect(message['encoding']).to eql(encrypted_encoding.gsub(%r{/base64$}, ''))
                    expect(message['data']).to eql(encrypted_data_decoded)
                  end
                  stop_reactor
                end

                encrypted_channel.publish 'example', encoded_data_decoded
              end
            end

            it 'sends and receives messages that are encrypted & decrypted by the Ably library' do
              run_reactor do
                encrypted_channel.publish 'example', encoded_data_decoded
                encrypted_channel.subscribe do |message|
                  expect(message.data).to eql(encoded_data_decoded)
                  expect(message.encoding).to be_nil
                  stop_reactor
                end
              end
            end
          end
        end

        resources_root = File.expand_path('../../../resources', __FILE__)

        def self.add_tests_for_data(data)
          data['items'].each_with_index do |item, index|
            context "item #{index} with encrypted encoding #{item['encrypted']['encoding']}" do
              it_behaves_like 'an Ably encrypter and decrypter', item, data
            end
          end
        end

        context 'with AES-128-CBC' do
          data = JSON.parse(File.read(File.join(resources_root, 'crypto-data-128.json')))
          add_tests_for_data data
        end

        context 'with AES-256-CBC' do
          data = JSON.parse(File.read(File.join(resources_root, 'crypto-data-256.json')))
          add_tests_for_data data
        end

        context 'multiple sends from one client to another' do
          let(:cipher_options)            { { key: random_str(32) } }
          let(:encrypted_channel_client1) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }
          let(:encrypted_channel_client2) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

          let(:data) { MessagePack.pack({ 'key' => random_str }) }
          let(:message_count) { 50 }

          it 'encrypt and decrypt messages' do
            messages_received = {
              decrypted: 0,
              encrypted: 0
            }

            run_reactor do
              encrypted_channel_client2.attach do
                encrypted_channel_client2.subscribe do |message|
                  expect(message.data).to eql("#{message.name}-#{data}")
                  expect(message.encoding).to be_nil
                  messages_received[:decrypted] += 1
                  stop_reactor if messages_received[:decrypted] == message_count
                end

                encrypted_channel_client1.__incoming_msgbus__.subscribe(:message) do |message|
                  expect(message['encoding']).to match(/cipher\+/)
                  messages_received[:encrypted] += 1
                end
              end

              message_count.times do |index|
                encrypted_channel_client2.publish index.to_s, "#{index}-#{data}"
              end
            end
          end
        end

        context "sending using protocol #{protocol} and subscribing with a different protocol" do
          let(:other_protocol) { protocol == :msgpack ? :json : :msgpack }
          let(:other_client) do
            Ably::Realtime::Client.new(default_options.merge(protocol: other_protocol))
          end

          let(:cipher_options)            { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client1) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }
          let(:encrypted_channel_client2) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

          before do
            expect(other_client.protocol_binary?).to_not eql(client.protocol_binary?)
          end

          [MessagePack.pack({ 'key' => SecureRandom.hex }), 'ã unicode', { 'key' => SecureRandom.hex }].each do |payload|
            payload_description = "#{payload.class}#{" #{payload.encoding}" if payload.kind_of?(String)}"

            specify "delivers a #{payload_description} payload to the receiver" do
              run_reactor do
                encrypted_channel_client1.publish 'example', payload
                encrypted_channel_client2.subscribe do |message|
                  expect(message.data).to eql(payload)
                  expect(message.encoding).to be_nil
                  stop_reactor
                end
              end
            end
          end
        end

        context 'publishing on an unencrypted channel and subscribing on an encrypted channel with another client' do
          let(:cipher_options)              { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:unencrypted_channel_client1) { client.channel(channel_name) }
          let(:encrypted_channel_client2)   { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          it 'does not attempt to decrypt the message' do
            run_reactor do
              unencrypted_channel_client1.publish 'example', payload
              encrypted_channel_client2.subscribe do |message|
                expect(message.data).to eql(payload)
                expect(message.encoding).to be_nil
                stop_reactor
              end
            end
          end
        end

        context 'publishing on an encrypted channel and subscribing on an unencrypted channel with another client' do
          let(:cipher_options)              { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client1)   { client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }
          let(:unencrypted_channel_client2) { other_client.channel(channel_name) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          it 'delivers the message but still encrypted' do
            run_reactor do
              encrypted_channel_client1.publish 'example', payload
              unencrypted_channel_client2.subscribe do |message|
                expect(message.data).to_not eql(payload)
                expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
                stop_reactor
              end
            end
          end

          it 'triggers a Cipher error on the channel' do
            run_reactor do
              unencrypted_channel_client2.attach do
                encrypted_channel_client1.publish 'example', payload
                unencrypted_channel_client2.on(:error) do |error|
                  expect(error).to be_a(Ably::Exceptions::CipherError)
                  expect(error.code).to eql(92001)
                  expect(error.message).to match(/Message cannot be decrypted/)
                  stop_reactor
                end
              end
            end
          end
        end

        context 'publishing on an encrypted channel and subscribing with a different algorithm on another client' do
          let(:cipher_options_client1)    { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client1) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client1) }
          let(:cipher_options_client2)    { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
          let(:encrypted_channel_client2) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client2) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          it 'delivers the message but still encrypted' do
            run_reactor do
              encrypted_channel_client1.publish 'example', payload
              encrypted_channel_client2.subscribe do |message|
                expect(message.data).to_not eql(payload)
                expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
                stop_reactor
              end
            end
          end

          it 'triggers a Cipher error on the channel' do
            run_reactor do
              encrypted_channel_client2.attach do
                encrypted_channel_client1.publish 'example', payload
                encrypted_channel_client2.on(:error) do |error|
                  expect(error).to be_a(Ably::Exceptions::CipherError)
                  expect(error.code).to eql(92002)
                  expect(error.message).to match(/Cipher algorithm [\w\d-]+ does not match/)
                  stop_reactor
                end
              end
            end
          end
        end

        context 'publishing on an encrypted channel and subscribing with a different key on another client' do
          let(:cipher_options_client1)    { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client1) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client1) }
          let(:cipher_options_client2)    { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client2) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client2) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          it 'delivers the message but still encrypted' do
            run_reactor do
              encrypted_channel_client1.publish 'example', payload
              encrypted_channel_client2.subscribe do |message|
                expect(message.data).to_not eql(payload)
                expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
                stop_reactor
              end
            end
          end

          it 'triggers a Cipher error on the channel' do
            run_reactor do
              encrypted_channel_client2.attach do
                encrypted_channel_client1.publish 'example', payload
                encrypted_channel_client2.on(:error) do |error|
                  expect(error).to be_a(Ably::Exceptions::CipherError)
                  expect(error.code).to eql(92003)
                  expect(error.message).to match(/CipherError decrypting data/)
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
