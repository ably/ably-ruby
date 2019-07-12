# encoding: utf-8
require 'spec_helper'
require 'base64'
require 'json'
require 'securerandom'

describe 'Ably::Realtime::Channel Message', :event_machine do
  vary_by_protocol do
    let(:default_options) { options.merge(key: api_key, environment: environment, protocol: protocol) }
    let(:client_options)  { default_options }
    let(:client) do
      auto_close Ably::Realtime::Client.new(client_options)
    end
    let(:channel) { client.channel(channel_name) }

    let(:other_client) do
      auto_close Ably::Realtime::Client.new(client_options)
    end
    let(:other_client_channel) { other_client.channel(channel_name) }

    let(:channel_name) { "subscribe_send_text-#{random_str}" }
    let(:options)      { { :protocol => :json } }
    let(:payload)      { 'Test message (subscribe_send_text)' }

    it 'sends a String data payload' do
      channel.attach
      channel.on(:attached) do
        channel.publish('test_event', payload) do |message|
          expect(message.data).to eql(payload)
          stop_reactor
        end
      end
    end

    context 'with supported data payload content type' do
      def publish_and_check_data(data)
        channel.attach
        channel.publish 'event', data
        channel.subscribe do |message|
          expect(message.data).to eql(data)
          stop_reactor
        end
      end

      context 'JSON Object (Hash)' do
        let(:data) { { 'Hash' => 'true' } }

        it 'is encoded and decoded to the same hash' do
          publish_and_check_data data
        end
      end

      context 'JSON Array' do
        let(:data) { [ nil, true, false, 55, 'string', { 'Hash' => true }, ['array'] ] }

        it 'is encoded and decoded to the same Array' do
          publish_and_check_data data
        end
      end

      context 'String' do
        let(:data) { random_str }

        it 'is encoded and decoded to the same Array' do
          publish_and_check_data data
        end
      end

      context 'Binary' do
        let(:data) { Base64.encode64(random_str) }

        it 'is encoded and decoded to the same Array' do
          publish_and_check_data data
        end
      end
    end

    context 'with supported extra payload content type (#RTL6h, #RSL6a2)' do
      let(:channel) { client.channel("pushenabled:#{random_str}") }

      def publish_and_check_extras(extras)
        channel.attach
        channel.publish 'event', {}, extras: extras
        channel.subscribe do |message|
          expect(message.extras).to eql(extras)
          stop_reactor
        end
      end

      context 'JSON Object (Hash)' do
        let(:data) { { 'push' => { 'notification' => { 'title' => 'Testing' } } } }

        it 'is encoded and decoded to the same hash' do
          publish_and_check_extras data
        end
      end

      context 'JSON Array' do
        let(:data) { { 'push' => { 'data' => { 'key' => [ true, false, 55, nil, 'string', { 'Hash' => true }, ['array'] ] } } } }

        it 'is encoded and decoded to the same Array' do
          publish_and_check_extras data
        end
      end

      context 'nil' do
        it 'is encoded and decoded to the same Array' do
          channel.publish 'event', {}, extras: nil
          publish_and_check_extras nil
        end
      end
    end

    context 'with unsupported data payload content type' do
      context 'Integer' do
        let(:data) { 1 }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
          stop_reactor
        end
      end

      context 'Float' do
        let(:data) { 1.1 }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
          stop_reactor
        end
      end

      context 'Boolean' do
        let(:data) { true }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
          stop_reactor
        end
      end

      context 'False' do
        let(:data) { false }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
          stop_reactor
        end
      end
    end

    context 'with ASCII_8BIT message name' do
      let(:message_name) { random_str.encode(Encoding::ASCII_8BIT) }
      it 'is converted into UTF_8' do
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

    context 'when the message publisher has a client_id' do
      let(:client_id) { random_str }
      let(:client_options)  { default_options.merge(client_id: client_id) }

      it 'contains a #client_id attribute' do
        when_all(channel.attach, other_client_channel.attach) do
          other_client_channel.subscribe('event') do |message|
            expect(message.client_id).to eql(client_id)
            stop_reactor
          end
          channel.publish('event', payload)
        end
      end
    end

    describe '#connection_id attribute' do
      context 'over realtime' do
        it 'matches the sender connection#id' do
          when_all(channel.attach, other_client_channel.attach) do
            other_client_channel.subscribe('event') do |message|
              expect(message.connection_id).to eql(client.connection.id)
              stop_reactor
            end
            channel.publish('event', payload)
          end
        end
      end

      context 'when retrieved over REST' do
        it 'matches the sender connection#id' do
          channel.publish('event', payload) do
            channel.history do |page|
              expect(page.items.first.connection_id).to eql(client.connection.id)
              stop_reactor
            end
          end
        end
      end
    end

    describe 'local echo when published' do
      it 'is enabled by default' do
        channel.attach do
          channel.publish 'test_event', payload
          channel.subscribe('test_event') do |message|
            expect(message.data).to eql(payload)
            stop_reactor
          end
        end
      end

      context 'with :echo_messages option set to false' do
        let(:no_echo_client) do
          auto_close Ably::Realtime::Client.new(default_options.merge(echo_messages: false))
        end
        let(:no_echo_channel) { no_echo_client.channel(channel_name) }

        let(:rest_client) do
          Ably::Rest::Client.new(default_options)
        end

        it 'will not echo messages to the client but will still broadcast messages to other connected clients', em_timeout: 10 do
          channel.attach do |echo_channel|
            no_echo_channel.attach do
              no_echo_channel.publish 'test_event', payload

              no_echo_channel.subscribe('test_event') do |message|
                fail "Message should not have been echoed back"
              end

              echo_channel.subscribe('test_event') do |message|
                expect(message.data).to eql(payload)
                EventMachine.add_timer(1.5) do
                  stop_reactor
                end
              end
            end
          end
        end

        it 'will not echo messages to the client from other REST clients publishing using that connection_key', em_timeout: 10 do
          no_echo_channel.attach do
            no_echo_channel.subscribe('test_event') do |message|
              fail "Message should not have been echoed back"
            end

            rest_client.channel(channel_name).publish('test_event', nil, connection_key: no_echo_client.connection.key)
            EventMachine.add_timer(1.5) do
              stop_reactor
            end
          end
        end

        it 'will echo messages with a valid connection_id to the client from other REST clients publishing using that connection_key', em_timeout: 10 do
          channel.attach do
            channel.subscribe('test_event') do |message|
              expect(message.connection_id).to eql(client.connection.id)
            end

            rest_client.channel(channel_name).publish('test_event', nil, connection_key: client.connection.key)
            EventMachine.add_timer(1.5) do
              stop_reactor
            end
          end
        end
      end
    end

    context 'publishing lots of messages across two connections' do
      let(:send_count)     { 30 }
      let(:expected_echos) { send_count * 2 }
      let(:channel_name)   { random_str }
      let(:echos) do
        { client: 0, other: 0 }
      end
      let(:callbacks) do
        { client: 0, other: 0 }
      end

      it 'sends and receives the messages on both opened connections and calls the success callbacks for each message published', em_timeout: 10 do
        check_message_and_callback_counts = lambda do
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

        channel.subscribe('test_event') do |message|
          echos[:client] += 1
          check_message_and_callback_counts.call
        end
        other_client_channel.subscribe('test_event') do |message|
          echos[:other] += 1
          check_message_and_callback_counts.call
        end

        when_all(channel.attach, other_client_channel.attach) do
          send_count.times do |index|
            channel.publish('test_event', "#{index}: #{payload}") do
              callbacks[:client] += 1
            end
            other_client_channel.publish('test_event', "#{index}: #{payload}") do
              callbacks[:other] += 1
            end
          end
        end
      end
    end

    context 'without suitable publishing permissions' do
      let(:restricted_client) do
        auto_close Ably::Realtime::Client.new(options.merge(key: restricted_api_key, environment: environment, protocol: protocol, :log_level => :error))
      end
      let(:restricted_channel) { restricted_client.channel("cansubscribe:example") }
      let(:payload)            { 'Test message without permission to publish' }

      it 'calls the error callback' do
        restricted_channel.attach do
          deferrable = restricted_channel.publish('test_event', payload)
          deferrable.errback do |error|
            expect(error.status).to eql(401)
            stop_reactor
          end
          deferrable.callback do |message|
            fail 'Success callback should not have been called'
          end
        end
      end
    end

    context 'server incorrectly resends a message that was already received by the client library' do
      let(:messages_received) { [] }
      let(:connection)        { client.connection }
      let(:client_options)    { default_options.merge(log_level: :fatal) }

      it 'discards the message and logs it as an error to the channel' do
        first_message_protocol_message = nil
        connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
          first_message_protocol_message ||= protocol_message unless protocol_message.messages.empty?
        end

        channel.attach do
          channel.subscribe do |message|
            messages_received << message
            if messages_received.count == 2
              # simulate a duplicate protocol message being received
              EventMachine.next_tick do
                connection.__incoming_protocol_msgbus__.publish :protocol_message, first_message_protocol_message
              end
            end
          end
          2.times { |i| EventMachine.add_timer(i.to_f / 5) { channel.publish('event', 'data') } }

          expect(client.logger).to receive(:error) do |*args, &block|
            expect(args.concat([block ? block.call : nil]).join(',')).to match(/duplicate/)

            EventMachine.add_timer(0.5) do
              expect(messages_received.count).to eql(2)
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

        let(:cipher_options) { { key: secret_key, fixed_iv: iv, algorithm: algorithm, mode: mode, key_length: key_length } }

        context 'with #publish and #subscribe' do
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

          let(:encrypted_channel) { client.channel(channel_name, cipher: cipher_options) }

          it 'encrypts message automatically before they are pushed to the server (#RTL7d)' do
            encrypted_channel.attach do
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

          it 'sends and receives messages that are encrypted & decrypted by the Ably library (#RTL7d)' do
            encrypted_channel.subscribe do |message|
              expect(message.data).to eql(encoded_data_decoded)
              expect(message.encoding).to be_nil
              stop_reactor
            end
            encrypted_channel.publish 'example', encoded_data_decoded
          end
        end
      end

      resources_root = File.expand_path('../../../../lib/submodules/ably-common/test-resources', __FILE__)

      def self.add_tests_for_data(data)
        data['items'].each_with_index do |item, index|
          context "item #{index} with encrypted encoding #{item['encrypted']['encoding']}" do
            it_behaves_like 'an Ably encrypter and decrypter', item, data
          end
        end
      end

      context 'with AES-128-CBC using crypto-data-128.json fixtures (#RTL7d)' do
        data = JSON.parse(File.read(File.join(resources_root, 'crypto-data-128.json')))
        add_tests_for_data data
      end

      context 'with AES-256-CBC using crypto-data-256.json fixtures (#RTL7d)' do
        data = JSON.parse(File.read(File.join(resources_root, 'crypto-data-256.json')))
        add_tests_for_data data
      end

      context 'with multiple sends from one client to another' do
        let(:cipher_options)            { { key: Ably::Util::Crypto.generate_random_key } }
        let(:encrypted_channel_client1) { client.channel(channel_name, cipher: cipher_options) }
        let(:encrypted_channel_client2) { other_client.channel(channel_name, cipher: cipher_options) }

        let(:data) { { 'key' => random_str } }
        let(:message_count) { 50 }

        it 'encrypts and decrypts all messages' do
          messages_received = []

          encrypted_channel_client1.attach do
            encrypted_channel_client1.subscribe do |message|
              expect(message.data).to eql(MessagePack.pack(data.merge(index: message.name.to_i)))
              expect(message.encoding).to be_nil
              messages_received << message
              stop_reactor if messages_received.count == message_count
            end

            message_count.times do |index|
              encrypted_channel_client2.publish index.to_s, MessagePack.pack(data.merge(index: index))
            end
          end
        end

        it 'receives raw messages with the correct encoding' do
          encrypted_channel_client1.attach do
            client.connection.__incoming_protocol_msgbus__.unsubscribe # remove all listeners
            client.connection.__incoming_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.action == Ably::Models::ProtocolMessage::ACTION.Message
                protocol_message.messages.each do |message|
                  expect(message['encoding']).to match(/cipher\+/)
                end
                stop_reactor
              end
            end

            encrypted_channel_client2.publish 'name', MessagePack.pack('data')
          end
        end
      end

      context 'subscribing with a different transport protocol' do
        let(:other_protocol) { protocol == :msgpack ? :json : :msgpack }
        let(:other_client) do
          auto_close Ably::Realtime::Client.new(default_options.merge(protocol: other_protocol))
        end

        let(:cipher_options)            { { key: Ably::Util::Crypto.generate_random_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:encrypted_channel_client1) { client.channel(channel_name, cipher: cipher_options) }
        let(:encrypted_channel_client2) { other_client.channel(channel_name, cipher: cipher_options) }

        before do
          expect(other_client.protocol_binary?).to_not eql(client.protocol_binary?)
        end

        [MessagePack.pack({ 'key' => SecureRandom.hex }), 'ã unicode', { 'key' => SecureRandom.hex }].each do |payload|
          payload_description = "#{payload.class}#{" #{payload.encoding}" if payload.kind_of?(String)}"

          it "delivers a #{payload_description} payload to the receiver" do
            encrypted_channel_client2.attach do
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
        let(:client_options)              { default_options.merge(log_level: :fatal) }
        let(:cipher_options)              { { key: Ably::Util::Crypto.generate_random_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:unencrypted_channel_client1) { client.channel(channel_name) }
        let(:encrypted_channel_client2)   { other_client.channel(channel_name, cipher: cipher_options) }

        let(:payload) { MessagePack.pack({ 'key' => random_str }) }

        it 'does not attempt to decrypt the message' do
          unencrypted_channel_client1.publish 'example', payload
          encrypted_channel_client2.subscribe do |message|
            expect(message.data).to eql(payload)
            expect(message.encoding).to be_nil
            stop_reactor
          end
        end
      end

      context 'publishing on an encrypted channel and subscribing on an unencrypted channel with another client' do
        let(:client_options)              { default_options.merge(log_level: :fatal) }
        let(:cipher_options)              { { key: Ably::Util::Crypto.generate_random_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:encrypted_channel_client1)   { client.channel(channel_name, cipher: Ably::Util::Crypto.get_default_params(cipher_options)) }
        let(:unencrypted_channel_client2) { other_client.channel(channel_name) }

        let(:payload) { MessagePack.pack({ 'key' => random_str }) }

        it 'delivers the message but still encrypted with a value in the #encoding attribute (#RTL7e)' do
          unencrypted_channel_client2.attach do
            encrypted_channel_client1.publish 'example', payload
            unencrypted_channel_client2.subscribe do |message|
              expect(message.data).to_not eql(payload)
              expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
              stop_reactor
            end
          end
        end

        it 'logs a Cipher error (#RTL7e)' do
          unencrypted_channel_client2.attach do
            expect(other_client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Message cannot be decrypted/)
              stop_reactor
            end
            encrypted_channel_client1.publish 'example', payload
          end
        end
      end

      context 'publishing on an encrypted channel and subscribing with a different algorithm on another client' do
        let(:client_options)              { default_options.merge(log_level: :fatal) }
        let(:cipher_options_client1)    { { key: Ably::Util::Crypto.generate_random_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:encrypted_channel_client1) { client.channel(channel_name, cipher: Ably::Util::Crypto.get_default_params(cipher_options_client1)) }
        let(:cipher_options_client2)    { { key: Ably::Util::Crypto.generate_random_key(128), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
        let(:encrypted_channel_client2) { other_client.channel(channel_name, cipher: Ably::Util::Crypto.get_default_params(cipher_options_client2)) }

        let(:payload) { MessagePack.pack({ 'key' => random_str }) }

        it 'delivers the message but still encrypted with the cipher detials in the #encoding attribute (#RTL7e)' do
          encrypted_channel_client1.publish 'example', payload
          encrypted_channel_client2.subscribe do |message|
            expect(message.data).to_not eql(payload)
            expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
            stop_reactor
          end
        end

        it 'emits a Cipher error on the channel (#RTL7e)' do
          encrypted_channel_client2.attach do
            encrypted_channel_client1.publish 'example', payload
            expect(other_client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Cipher algorithm [\w-]+ does not match/)
              stop_reactor
            end
          end
        end
      end

      context 'publishing on an encrypted channel and subscribing with a different key on another client' do
        let(:client_options)              { default_options.merge(log_level: :fatal) }
        let(:cipher_options_client1)    { { key: Ably::Util::Crypto.generate_random_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:encrypted_channel_client1) { client.channel(channel_name, cipher: cipher_options_client1) }
        let(:cipher_options_client2)    { { key: Ably::Util::Crypto.generate_random_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:encrypted_channel_client2) { other_client.channel(channel_name, cipher: cipher_options_client2) }

        let(:payload) { MessagePack.pack({ 'key' => random_str }) }

        it 'delivers the message but still encrypted with the cipher details in the #encoding attribute' do
          encrypted_channel_client2.attach do
            encrypted_channel_client1.publish 'example', payload
            encrypted_channel_client2.subscribe do |message|
              expect(message.data).to_not eql(payload)
              expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
              stop_reactor
            end
          end
        end

        it 'emits a Cipher error on the channel' do
          encrypted_channel_client2.attach do
            encrypted_channel_client1.publish 'example', payload
            expect(other_client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/CipherError decrypting data/)
              stop_reactor
            end
          end
        end
      end
    end

    describe 'when message is published, the connection disconnects before the ACK is received, and the connection is resumed' do
      let(:event_name)     { random_str }
      let(:message_state)  { [] }
      let(:connection)     { client.connection }
      let(:client_options) { default_options.merge(:log_level => :fatal) }
      let(:msgs_received)  { [] }

      it 'publishes the message again, later receives the ACK and only one message is ever received from Ably' do
        on_reconnected = lambda do |*args|
          expect(message_state).to be_empty
          EventMachine.add_timer(2) do
            expect(message_state).to contain_exactly(:delivered)
            expect(msgs_received.length).to eql(1)
            stop_reactor
          end
        end

        connection.once(:connected) do
          connection.transport.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
            if protocol_message.messages.find { |message| message.name == event_name }
              EventMachine.add_timer(0.001) do
                connection.transport.unbind # trigger failure
                expect(message_state).to be_empty
                connection.once :connected, &on_reconnected
              end
            end
          end
        end

        channel.publish(event_name).tap do |deferrable|
          deferrable.callback { message_state << :delivered }
          deferrable.errback do
            raise 'Message delivery should not fail'
          end
        end

        channel.subscribe do |message|
          msgs_received << message
        end
      end
    end

    describe 'when message is published, the connection disconnects before the ACK is received' do
      let(:connection) { client.connection }
      let(:event_name) { random_str }

      describe 'the connection is not resumed' do
        let(:client_options) { default_options.merge(:log_level => :fatal) }

        it 'calls the errback for all messages' do
          connection.once(:connected) do
            connection.transport.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.messages.find { |message| message.name == event_name }
                EventMachine.add_timer(0.0001) do
                  connection.transport.unbind # trigger failure
                  connection.configure_new '0123456789abcdef', 'wVIsgTHAB1UvXh7z-1991d8586', -1 # force the resume connection key to be invalid
                end
              end
            end
          end

          channel.publish(event_name).tap do |deferrable|
            deferrable.callback do
              raise 'Message delivery should not happen'
            end
            deferrable.errback do
              stop_reactor
            end
          end
        end
      end

      describe 'the connection becomes suspended' do
        let(:client_options) { default_options.merge(:log_level => :fatal) }

        it 'calls the errback for all messages' do
          connection.once(:connected) do
            connection.transport.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.messages.find { |message| message.name == event_name }
                EventMachine.add_timer(0.0001) do
                  connection.transition_state_machine :suspended
                  stub_const 'Ably::FALLBACK_HOSTS', []
                  allow(client).to receive(:endpoint).and_return(URI::Generic.build(scheme: 'wss', host: 'does.not.exist.com'))
                end
              end
            end
          end

          channel.publish(event_name).tap do |deferrable|
            deferrable.callback do
              raise 'Message delivery should not happen'
            end
            deferrable.errback do
              stop_reactor
            end
          end
        end
      end

      describe 'the connection becomes failed' do
        let(:client_options) { default_options.merge(:log_level => :none) }

        it 'calls the errback for all messages' do
          connection.once(:connected) do
            connection.transport.__outgoing_protocol_msgbus__.subscribe(:protocol_message) do |protocol_message|
              if protocol_message.messages.find { |message| message.name == event_name }
                EventMachine.add_timer(0.001) do
                  connection.transition_state_machine :failed, reason: RuntimeError.new
                end
              end
            end
          end

          channel.publish(event_name).tap do |deferrable|
            deferrable.callback do
              raise 'Message delivery should not happen'
            end
            deferrable.errback do
              stop_reactor
            end
          end
        end
      end
    end
  end

  context 'message encoding interoperability' do
    let(:client_options)  { { key: api_key, environment: environment, protocol: :json } }
    let(:channel_name) { "subscribe_send_text-#{random_str}" }

    fixtures_path = File.expand_path('../../../../lib/submodules/ably-common/test-resources/messages-encoding.json', __FILE__)

    context 'over a JSON transport' do
      let(:realtime_client) do
        auto_close Ably::Realtime::Client.new(client_options)
      end
      let(:rest_client) do
        Ably::Rest::Client.new(client_options)
      end
      let(:realtime_channel) { realtime_client.channels.get(channel_name) }

      JSON.parse(File.read(fixtures_path))['messages'].each do |encoding_spec|
        context "when decoding #{encoding_spec['expectedType']}" do
          it 'ensures that client libraries have compatible encoding and decoding using common fixtures' do
            realtime_channel.attach do
              realtime_channel.subscribe do |message|
                if encoding_spec['expectedHexValue']
                  expect(message.data.unpack('H*').first).to eql(encoding_spec['expectedHexValue'])
                else
                  expect(message.data).to eql(encoding_spec['expectedValue'])
                end
                stop_reactor
              end

              raw_message = { "data" => encoding_spec['data'], "encoding" => encoding_spec['encoding'] }
              rest_client.post("/channels/#{channel_name}/messages", JSON.dump(raw_message))
            end
          end
        end

        context "when encoding #{encoding_spec['expectedType']}" do
          it 'ensures that client libraries have compatible encoding and decoding using common fixtures' do
            data = if encoding_spec['expectedHexValue']
              encoding_spec['expectedHexValue'].scan(/../).map { |x| x.hex }.pack('c*')
            else
              encoding_spec['expectedValue']
            end

            realtime_channel.publish("event", data) do
              response = rest_client.get("/channels/#{channel_name}/messages")
              message = response.body[0]
              expect(message['encoding']).to eql(encoding_spec['encoding'])
              if message['encoding'] == 'json'
                expect(JSON.parse(encoding_spec['data'])).to eql(JSON.parse(message['data']))
              else
                expect(encoding_spec['data']).to eql(message['data'])
              end
              stop_reactor
            end
          end
        end
      end
    end

    context 'over a MsgPack transport' do
      JSON.parse(File.read(fixtures_path))['messages'].each do |encoding_spec|
        context "when publishing a #{encoding_spec['expectedType']} using JSON protocol" do
          let(:rest_publish_client) do
            Ably::Rest::Client.new(client_options.merge(protocol: :json))
          end
          let(:realtime_subscribe_client) do
            Ably::Realtime::Client.new(client_options.merge(protocol: :msgpack))
          end
          let(:realtime_subscribe_channel) { realtime_subscribe_client.channels.get(channel_name) }

          it 'receives the message over MsgPack and the data matches' do
            expect(realtime_subscribe_client).to be_protocol_binary

            realtime_subscribe_channel.attach do
              realtime_subscribe_channel.subscribe do |message|
                if encoding_spec['expectedHexValue']
                  expect(message.data.unpack('H*').first).to eql(encoding_spec['expectedHexValue'])
                else
                  expect(message.data).to eql(encoding_spec['expectedValue'])
                end
                stop_reactor
              end

              raw_message = { "data" => encoding_spec['data'], "encoding" => encoding_spec['encoding'] }
              rest_publish_client.post("/channels/#{channel_name}/messages", JSON.dump(raw_message))
            end
          end
        end

        context "when retrieving a #{encoding_spec['expectedType']} using JSON protocol" do
          let(:rest_publish_client) do
            Ably::Rest::Client.new(client_options.merge(protocol: :msgpack))
          end
          let(:rest_retrieve_client) do
            Ably::Rest::Client.new(client_options.merge(protocol: :json))
          end
          let(:rest_publish_channel) { rest_publish_client.channels.get(channel_name) }

          it 'is compatible with a publishes using MsgPack' do
            expect(rest_publish_client).to be_protocol_binary

            data = if encoding_spec['expectedHexValue']
              encoding_spec['expectedHexValue'].scan(/../).map { |x| x.hex }.pack('c*')
            else
              encoding_spec['expectedValue']
            end
            rest_publish_channel.publish "event", data

            response = rest_retrieve_client.get("/channels/#{channel_name}/messages")
            message = response.body[0]
            expect(message['encoding']).to eql(encoding_spec['encoding'])
            expect(encoding_spec['data']).to eql(message['data'])
            stop_reactor
          end
        end
      end
    end
  end
end
