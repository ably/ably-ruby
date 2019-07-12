# encoding: utf-8
require 'spec_helper'
require 'base64'
require 'securerandom'

describe Ably::Rest::Channel, 'messages' do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:default_client_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)         { default_client_options }
    let(:client)                 { Ably::Rest::Client.new(client_options) }
    let(:other_client)           { Ably::Rest::Client.new(client_options) }
    let(:channel)                { client.channel(random_str) }

    context 'publishing with an ASCII_8BIT message name' do
      let(:message_name) { random_str.encode(Encoding::ASCII_8BIT) }

      it 'is converted into UTF_8' do
        channel.publish message_name, 'example'
        message = channel.history.items.first
        expect(message.name.encoding).to eql(Encoding::UTF_8)
        expect(message.name.encode(Encoding::ASCII_8BIT)).to eql(message_name)
      end
    end

    context 'with supported data payload content type' do
      context 'JSON Object (Hash)' do
        let(:data) { { 'Hash' => 'true' } }

        it 'is encoded and decoded to the same hash' do
          channel.publish 'event', data
          expect(channel.history.items.first.data).to eql(data)
        end
      end

      context 'JSON Array' do
        let(:data) { [ nil, true, false, 55, 'string', { 'Hash' => true }, ['array'] ] }

        it 'is encoded and decoded to the same Array' do
          channel.publish 'event', data
          expect(channel.history.items.first.data).to eql(data)
        end
      end

      context 'String' do
        let(:data) { random_str }

        it 'is encoded and decoded to the same Array' do
          channel.publish 'event', data
          expect(channel.history.items.first.data).to eql(data)
        end
      end

      context 'Binary' do
        let(:data) { Base64.encode64(random_str) }

        it 'is encoded and decoded to the same Array' do
          channel.publish 'event', data
          expect(channel.history.items.first.data).to eql(data)
        end
      end
    end

    context 'with supported extra payload content type (#RSL1h, #RSL6a2)' do
      let(:channel) { client.channel("pushenabled:#{random_str}") }

      context 'JSON Object (Hash)' do
        let(:data) { { 'push' => { 'notification' => { 'title' => 'Testing' } } } }

        it 'is encoded and decoded to the same hash' do
          channel.publish 'event', {}, extras: data
          expect(channel.history.items.first.extras).to eql(data)
        end
      end

      context 'JSON Array' do
        let(:data) { { 'push' => { 'data' => { 'key' => [ true, false, 55, nil, 'string', { 'Hash' => true }, ['array'] ] } } } }

        it 'is encoded and decoded to the same deep multi-type object' do
          channel.publish 'event', {}, extras: data
          expect(channel.history.items.first.extras).to eql(data)
        end
      end

      context 'nil' do
        it 'is encoded and decoded to the same Array' do
          channel.publish 'event', {}, extras: nil
          expect(channel.history.items.first.extras).to be_nil
        end
      end
    end

    context 'idempotency (#RSL1k)' do
      let(:id) { random_str }
      let(:name) { 'event' }
      let(:data) { random_str }

      context 'when ID is not included (#RSL1k2)' do
        context 'with Message object' do
          let(:message) { Ably::Models::Message.new(data: data) }

          it 'publishes the same message three times' do
            3.times { channel.publish [message] }
            expect(channel.history.items.length).to eql(3)
          end
        end

        context 'with #publish arguments only' do
          it 'publishes the same message three times' do
            3.times { channel.publish 'event', data }
            expect(channel.history.items.length).to eql(3)
          end
        end
      end

      context 'when ID is included (#RSL1k2, #RSL1k5)' do
        context 'with Message object' do
          let(:message) { Ably::Models::Message.new(id: id, data: data) }

          specify 'three REST publishes result in only one message being published' do
            3.times { channel.publish [message] }
            expect(channel.history.items.length).to eql(1)
            expect(channel.history.items[0].id).to eql(id)
          end
        end

        context 'with #publish arguments only' do
          it 'three REST publishes result in only one message being published' do
            3.times { channel.publish 'event', data, id: id }
            expect(channel.history.items.length).to eql(1)
          end
        end

        specify 'the ID provided is used for the published messages' do
          channel.publish 'event', data, id: id
          expect(channel.history.items[0].id).to eql(id)
        end

        specify 'for multiple messages in one publish operation (#RSL1k3)' do
          message_arr = 3.times.map { Ably::Models::Message.new(id: id, data: data) }
          expect { channel.publish message_arr }.to raise_error do |error|
            expect(error.code).to eql(40031) # Invalid publish request (invalid client-specified id), see https://github.com/ably/ably-common/pull/30
          end
        end

        specify 'for multiple messages in one publish operation with IDs following the required format described in RSL1k1 (#RSL1k3)' do
          message_arr = 3.times.map { |index| Ably::Models::Message.new(id: "#{id}:#{index}", data: data) }
          channel.publish message_arr
          expect(channel.history.items[2].id).to eql("#{id}:0")
          expect(channel.history.items[0].id).to eql("#{id}:2")
          expect(channel.history.items.length).to eql(3)
        end
      end

      specify 'idempotent publishing is disabled by default with 1.1 (#TO3n)' do
        client = Ably::Rest::Client.new(key: api_key, protocol: protocol)
        expect(client.idempotent_rest_publishing).to be_falsey
      end

      specify 'idempotent publishing is enabled by default with 1.2 (#TO3n)' do
        stub_const 'Ably::VERSION', '1.2.0'
        client = Ably::Rest::Client.new(key: api_key, protocol: protocol)
        expect(client.idempotent_rest_publishing).to be_truthy
      end

      context 'when idempotent publishing is enabled in the client library ClientOptions (#TO3n)' do
        let(:client_options) { default_client_options.merge(idempotent_rest_publishing: true, log_level: :error, fallback_hosts: ["#{environment}-realtime.ably.io"]) }

        context 'when there is a network failure triggering an automatic retry (#RSL1k4)' do
          def mock_for_two_publish_failures
            @failed_http_posts = 0
            allow(client).to receive(:can_fallback_to_alternate_ably_host?).and_return(true)
            allow_any_instance_of(Faraday::Connection).to receive(:post) do |*args|
              @failed_http_posts += 1
              if @failed_http_posts == 2
                # Ensure the 3rd requests operates as normal
                allow_any_instance_of(Faraday::Connection).to receive(:post).and_call_original
              end
              raise Faraday::ClientError.new('Fake client error')
            end
          end

          context 'with Message object' do
            let(:message) { Ably::Models::Message.new(data: data) }
            before { mock_for_two_publish_failures }

            specify 'two REST publish retries result in only one message being published' do
              channel.publish [message]
              expect(channel.history.items.length).to eql(1)
              expect(@failed_http_posts).to eql(2)
            end
          end

          context 'with #publish arguments only' do
            before { mock_for_two_publish_failures }

            specify 'two REST publish retries result in only one message being published' do
              channel.publish 'event', data
              expect(channel.history.items.length).to eql(1)
              expect(@failed_http_posts).to eql(2)
            end
          end

          context 'with explicitly provided message ID' do
            let(:id) { random_str }

            before { mock_for_two_publish_failures }

            specify 'two REST publish retries result in only one message being published' do
              channel.publish 'event', data, id: id
              expect(channel.history.items.length).to eql(1)
              expect(channel.history.items[0].id).to eql(id)
              expect(@failed_http_posts).to eql(2)
            end
          end

          specify 'for multiple messages in one publish operation' do
            message_arr = 3.times.map { Ably::Models::Message.new(data: data) }
            3.times { channel.publish message_arr }
            expect(channel.history.items.length).to eql(message_arr.length * 3)
          end
        end

        specify 'the ID is populated with a random ID and serial 0 from this lib (#RSL1k1)' do
          channel.publish 'event'
          expect(channel.history.items[0].id).to match(/^[A-Za-z0-9\+\/]+:0$/)
          base_64_id = channel.history.items[0].id.split(':')[0]
          expect(Base64.decode64(base_64_id).length).to eql(9)
        end

        context 'when publishing a batch of messages' do
          specify 'the ID is populated with a single random ID and sequence of serials from this lib (#RSL1k1)' do
            message = { name: 'event' }
            channel.publish [message, message, message]
            expect(channel.history.items.length).to eql(3)
            expect(channel.history.items[0].id).to match(/^[A-Za-z0-9\+\/]+:2$/)
            expect(channel.history.items[2].id).to match(/^[A-Za-z0-9\+\/]+:0$/)
            base_64_id = channel.history.items[0].id.split(':')[0]
            expect(Base64.decode64(base_64_id).length).to eql(9)
          end
        end
      end
    end

    context 'with unsupported data payload content type' do
      context 'Integer' do
        let(:data) { 1 }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
        end
      end

      context 'Float' do
        let(:data) { 1.1 }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
        end
      end

      context 'Boolean' do
        let(:data) { true }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
        end
      end

      context 'False' do
        let(:data) { false }

        it 'is raises an UnsupportedDataType 40013 exception' do
          expect { channel.publish 'event', data }.to raise_error(Ably::Exceptions::UnsupportedDataType)
        end
      end
    end

    describe 'encryption and encoding' do
      let(:channel_name)      { "persisted:#{random_str}" }
      let(:encrypted_channel) { client.channel(channel_name, cipher: cipher_options) }
      let(:cipher_options)    { { key: Ably::Util::Crypto.generate_random_key } }

      context 'with #publish and #history' do
        shared_examples 'an Ably encrypter and decrypter' do |item, data|
          let(:algorithm)      { data['algorithm'].upcase }
          let(:mode)           { data['mode'].upcase }
          let(:key_length)     { data['keylength'] }
          let(:secret_key)     { Base64.decode64(data['key']) }
          let(:iv)             { Base64.decode64(data['iv']) }

          let(:cipher_options) { { key: secret_key, fixed_iv: iv, algorithm: algorithm, mode: mode, key_length: key_length } }

          let(:encoded)              { item['encoded'] }
          let(:encoded_data)         { encoded['data'] }
          let(:encoded_encoding)     { encoded['encoding'] }
          let(:encoded_data_decoded) do
            if encoded_encoding == 'json'
              JSON.parse(encoded_data)
            elsif encoded_encoding == 'base64'
              Base64.decode64(encoded_data)
            else
              encoded_data
            end
          end

          let(:encrypted)              { item['encrypted'] }
          let(:encrypted_data)         { encrypted['data'] }
          let(:encrypted_encoding)     { encrypted['encoding'] }
          let(:encrypted_data_decoded) do
            if encrypted_encoding.match(%r{/base64$})
              Base64.decode64(encrypted_data)
            else
              encrypted_data
            end
          end

          it 'encrypts message automatically when published (#RTL7d)' do
            expect(client).to receive(:post) do |path, message|
              if protocol == :json
                expect(message['encoding']).to eql(encrypted_encoding)
                expect(Base64.decode64(message['data'])).to eql(encrypted_data_decoded)
              else
                # Messages sent over binary protocol will not have Base64 encoded data
                expect(message['encoding']).to eql(encrypted_encoding.gsub(%r{/base64$}, ''))
                expect(message['data']).to eql(encrypted_data_decoded)
              end
            end.and_return(double('Response', status: 201))

            encrypted_channel.publish 'example', encoded_data_decoded
          end

          it 'sends and retrieves messages that are encrypted & decrypted by the Ably library (#RTL7d)' do
            encrypted_channel.publish 'example', encoded_data_decoded

            message = encrypted_channel.history.items.first
            expect(message.data).to eql(encoded_data_decoded)
            expect(message.encoding).to be_nil
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

        context 'when publishing lots of messages' do
          let(:data) { MessagePack.pack({ 'key' => random_str }) }
          let(:message_count) { 20 }

          it 'encrypts on #publish and decrypts on #history' do
            message_count.times do |index|
              encrypted_channel.publish index.to_s, "#{index}-#{data}"
            end

            messages = encrypted_channel.history.items

            expect(messages.count).to eql(message_count)
            messages.each do |message|
              expect(message.data).to eql("#{message.name}-#{data}")
              expect(message.encoding).to be_nil
            end
          end
        end

        context 'when retrieving #history with a different protocol' do
          let(:other_protocol)       { protocol == :msgpack ? :json : :msgpack }
          let(:other_client)         { Ably::Rest::Client.new(default_client_options.merge(protocol: other_protocol)) }
          let(:other_client_channel) { other_client.channel(channel_name, cipher: cipher_options) }

          before do
            expect(other_client.protocol_binary?).to_not eql(client.protocol_binary?)
          end

          [MessagePack.pack({ 'key' => SecureRandom.hex }), 'ã unicode', { 'key' => SecureRandom.hex }].each do |payload|
            payload_description = "#{payload.class}#{" #{payload.encoding}" if payload.kind_of?(String)}"

            specify "delivers a #{payload_description} payload to the receiver" do
              encrypted_channel.publish 'example', payload

              message = other_client_channel.history.items.first
              expect(message.data).to eql(payload)
              expect(message.encoding).to be_nil
            end
          end
        end

        context 'when publishing on an unencrypted channel and retrieving with #history on an encrypted channel' do
          let(:unencrypted_channel)            { client.channel(channel_name) }
          let(:other_client_encrypted_channel) { other_client.channel(channel_name, cipher: cipher_options) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          it 'does not attempt to decrypt the message' do
            unencrypted_channel.publish 'example', payload

            message = other_client_encrypted_channel.history.items.first
            expect(message.data).to eql(payload)
            expect(message.encoding).to be_nil
          end
        end

        context 'when publishing on an encrypted channel and retrieving with #history on an unencrypted channel' do
          let(:client_options)                   { default_client_options.merge(log_level: :fatal) }
          let(:cipher_options)                   { { key: Ably::Util::Crypto.generate_random_key(256), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel)                { client.channel(channel_name, cipher: cipher_options) }
          let(:other_client_unencrypted_channel) { other_client.channel(channel_name) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          before do
            encrypted_channel.publish 'example', payload
          end

          it 'retrieves the message that remains encrypted with an encrypted encoding attribute (#RTL7e)' do
            message = other_client_unencrypted_channel.history.items.first
            expect(message.data).to_not eql(payload)
            expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
          end

          it 'logs a Cipher exception (#RTL7e)' do
            expect(other_client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Message cannot be decrypted/)
            end
            other_client_unencrypted_channel.history
          end
        end

        context 'publishing on an encrypted channel and retrieving #history with a different algorithm on another client (#RTL7e)' do
          let(:client_options)            { default_client_options.merge(log_level: :fatal) }
          let(:cipher_options_client1)    { { key: Ably::Util::Crypto.generate_random_key(256), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client1) { client.channel(channel_name, cipher: cipher_options_client1) }
          let(:cipher_options_client2)    { { key: Ably::Util::Crypto.generate_random_key(128), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
          let(:encrypted_channel_client2) { other_client.channel(channel_name, cipher: cipher_options_client2) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          before do
            encrypted_channel_client1.publish 'example', payload
          end

          it 'retrieves the message that remains encrypted with an encrypted encoding attribute (#RTL7e)' do
            message = encrypted_channel_client2.history.items.first
            expect(message.data).to_not eql(payload)
            expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
          end

          it 'logs a Cipher exception (#RTL7e)' do
            expect(other_client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Cipher algorithm [\w-]+ does not match/)
            end
            encrypted_channel_client2.history
          end
        end

        context 'publishing on an encrypted channel and subscribing with a different key on another client' do
          let(:client_options)            { default_client_options.merge(log_level: :fatal) }
          let(:cipher_options_client1)    { { key: Ably::Util::Crypto.generate_random_key(256), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client1) { client.channel(channel_name, cipher: cipher_options_client1) }
          let(:cipher_options_client2)    { { key: Ably::Util::Crypto.generate_random_key(256), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
          let(:encrypted_channel_client2) { other_client.channel(channel_name, cipher: cipher_options_client2) }

          let(:payload) { MessagePack.pack({ 'key' => random_str }) }

          before do
            encrypted_channel_client1.publish 'example', payload
          end

          it 'retrieves the message that remains encrypted with an encrypted encoding attribute' do
            message = encrypted_channel_client2.history.items.first
            expect(message.data).to_not eql(payload)
            expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
          end

          it 'logs a Cipher exception' do
            expect(other_client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/CipherError decrypting data/)
            end
            encrypted_channel_client2.history
          end
        end
      end
    end
  end
end
