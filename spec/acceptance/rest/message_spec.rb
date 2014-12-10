# encoding: utf-8

require 'spec_helper'
require 'securerandom'

describe 'Ably::Rest Message' do
  include Ably::Modules::Conversions

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:default_client_options) { { api_key: api_key, environment: environment, protocol: protocol } }
      let(:client)                 { Ably::Rest::Client.new(default_client_options) }
      let(:other_client)           { Ably::Rest::Client.new(default_client_options) }

      describe 'encryption and encoding' do
        let(:channel_name)      { "persisted:#{SecureRandom.hex(4)}" }
        let(:cipher_options)    { { key: SecureRandom.hex(32) } }
        let(:encrypted_channel) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

        context 'encoding and decoding encrypted messages' do
          shared_examples 'an Ably encrypter and decrypter' do |item, data|
            let(:algorithm)      { data['algorithm'].upcase }
            let(:mode)           { data['mode'].upcase }
            let(:key_length)     { data['keylength'] }
            let(:secret_key)     { Base64.decode64(data['key']) }
            let(:iv)             { Base64.decode64(data['iv']) }

            let(:cipher_options) { { key: secret_key, iv: iv, algorithm: algorithm, mode: mode, key_length: key_length } }

            context 'publish & subscribe' do
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

              it 'encrypts message automatically when published' do
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

              it 'sends and receives messages that are encrypted & decrypted by the Ably library' do
                encrypted_channel.publish 'example', encoded_data_decoded

                message = encrypted_channel.history.first
                expect(message.data).to eql(encoded_data_decoded)
                expect(message.encoding).to be_nil
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

          context 'multiple messages' do
            let(:data) { MessagePack.pack({ 'key' => SecureRandom.hex }) }
            let(:message_count) { 20 }

            it 'encrypt and decrypt messages' do
              message_count.times do |index|
                encrypted_channel.publish index.to_s, "#{index}-#{data}"
              end

              messages = encrypted_channel.history

              expect(messages.count).to eql(message_count)
              messages.each do |message|
                expect(message.data).to eql("#{message.name}-#{data}")
                expect(message.encoding).to be_nil
              end
            end
          end

          context "sending using protocol #{protocol} and retrieving with a different protocol" do
            let(:other_protocol)       { protocol == :msgpack ? :json : :msgpack }
            let(:other_client)         { Ably::Rest::Client.new(default_client_options.merge(protocol: other_protocol)) }
            let(:other_client_channel) {  other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

            before do
              expect(other_client.protocol_binary?).to_not eql(client.protocol_binary?)
            end

            [MessagePack.pack({ 'key' => SecureRandom.hex }), 'ã unicode', { 'key' => SecureRandom.hex }].each do |payload|
              payload_description = "#{payload.class}#{" #{payload.encoding}" if payload.kind_of?(String)}"

              specify "delivers a #{payload_description} payload to the receiver" do
                encrypted_channel.publish 'example', payload

                message = other_client_channel.history.first
                expect(message.data).to eql(payload)
                expect(message.encoding).to be_nil
              end
            end
          end

          context 'publishing on an unencrypted channel and retrieving on an encrypted channel' do
            let(:unencrypted_channel)            { client.channel(channel_name) }
            let(:other_client_encrypted_channel) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

            let(:payload) { MessagePack.pack({ 'key' => SecureRandom.hex }) }

            it 'does not attempt to decrypt the message' do
              unencrypted_channel.publish 'example', payload

              message = other_client_encrypted_channel.history.first
              expect(message.data).to eql(payload)
              expect(message.encoding).to be_nil
            end
          end

          context 'publishing on an encrypted channel and retrieving on an unencrypted channel' do
            let(:encrypted_channel)                { client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }
            let(:other_client_unencrypted_channel) { other_client.channel(channel_name) }

            let(:payload) { MessagePack.pack({ 'key' => SecureRandom.hex }) }

            skip 'delivers the message but still encrypted' do
              # TODO: Decide if we should raise an exception or allow the message through
              encrypted_channel.publish 'example', payload

              message = other_client_unencrypted_channel.history.first
              expect(message.data).to_not eql(payload)
              expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
            end

            it 'triggers a Cipher exception' do
              encrypted_channel.publish 'example', payload
              expect { other_client_unencrypted_channel.history }.to raise_error Ably::Exceptions::CipherError, /Message cannot be decrypted/
            end
          end

          context 'publishing on an encrypted channel and subscribing with a different algorithm on another client' do
            let(:cipher_options_client1)    { { key: SecureRandom.hex(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
            let(:encrypted_channel_client1) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client1) }
            let(:cipher_options_client2)    { { key: SecureRandom.hex(32), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
            let(:encrypted_channel_client2) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client2) }

            let(:payload) { MessagePack.pack({ 'key' => SecureRandom.hex }) }

            skip 'delivers the message but still encrypted' do
              # TODO: Decide if we should raise an exception or allow the message through
              encrypted_channel.publish 'example', payload

              message = other_client_unencrypted_channel.history.first
              expect(message.data).to_not eql(payload)
              expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
            end

            it 'triggers a Cipher exception' do
              encrypted_channel_client1.publish 'example', payload
              expect { encrypted_channel_client2.history }.to raise_error Ably::Exceptions::CipherError, /Cipher algorithm [\w\d-]+ does not match/
            end
          end

          context 'publishing on an encrypted channel and subscribing with a different key on another client' do
            let(:cipher_options_client1)    { { key: SecureRandom.hex(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
            let(:encrypted_channel_client1) { client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client1) }
            let(:cipher_options_client2)    { { key: SecureRandom.hex(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
            let(:encrypted_channel_client2) { other_client.channel(channel_name, encrypted: true, cipher_params: cipher_options_client2) }

            let(:payload) { MessagePack.pack({ 'key' => SecureRandom.hex }) }

            skip 'delivers the message but still encrypted' do
              # TODO: Decide if we should raise an exception or allow the message through
              encrypted_channel.publish 'example', payload

              message = other_client_unencrypted_channel.history.first
              expect(message.data).to_not eql(payload)
              expect(message.encoding).to match(/^cipher\+aes-256-cbc/)
            end

            it 'triggers a Cipher exception' do
              encrypted_channel_client1.publish 'example', payload
              expect { encrypted_channel_client2.history }.to raise_error Ably::Exceptions::CipherError, /CipherError decrypting data/
            end
          end
        end
      end
    end
  end
end
