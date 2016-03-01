require 'spec_helper'
require 'ably/models/message_encoders/cipher'
require 'msgpack'

describe Ably::Models::MessageEncoders::Cipher do
  let(:secret_key)          { Ably::Util::Crypto.generate_random_key(128) }
  let(:crypto_options)      { { key: secret_key, algorithm: 'AES', mode: 'CBC', key_length: 128 } }
  let(:crypto)              { Ably::Util::Crypto.new(cipher_params) }

  let(:decoded_data)        { random_str(32) }
  let(:cipher_data)         { crypto.encrypt(decoded_data) }

  let(:binary_data)         { MessagePack.pack(decoded_data) }
  let(:binary_cipher_data)  { crypto.encrypt(binary_data) }

  let(:client)              { instance_double('Ably::Realtime::Client') }

  subject { Ably::Models::MessageEncoders::Cipher.new(client) }

  context '#decode' do
    context 'with channel set up for AES-128-CBC' do
      let(:cipher_params) { crypto_options }

      context 'valid cipher data' do
        before do
          subject.decode message, { cipher: cipher_params }
        end

        context 'message with cipher payload' do
          let(:message) { { data: cipher_data, encoding: 'cipher+aes-128-cbc' } }

          it 'decodes cipher' do
            expect(message[:data]).to eql(decoded_data)
          end

          it 'strips the encoding' do
            expect(message[:encoding]).to be_nil
          end
        end

        context 'message with cipher payload before other payloads' do
          let(:message) { { data: cipher_data, encoding: 'utf-8/cipher+aes-128-cbc' } }

          it 'decodes cipher' do
            expect(message[:data]).to eql(decoded_data)
          end

          it 'strips the encoding' do
            expect(message[:encoding]).to eql('utf-8')
          end
        end

        context 'message with binary payload' do
          let(:message) { { data: binary_cipher_data, encoding: 'base64/cipher+aes-128-cbc' } }

          it 'decodes cipher' do
            expect(message[:data]).to eql(binary_data)
          end

          it 'strips the encoding' do
            expect(message[:encoding]).to eql('base64')
          end

          it 'returns ASCII_8BIT encoded binary data' do
            expect(message[:data].encoding).to eql(Encoding::ASCII_8BIT)
          end
        end

        context 'message with another payload' do
          let(:message) { { data: decoded_data, encoding: 'utf-8' } }

          it 'leaves the message data intact' do
            expect(message[:data]).to eql(decoded_data)
          end

          it 'leaves the encoding intact' do
            expect(message[:encoding]).to eql('utf-8')
          end
        end
      end

      context '256 bit key' do
        let(:secret_key) { Ably::Util::Crypto.generate_random_key(256) }

        context 'with invalid channel_option cipher params' do
          let(:message) { { data: decoded_data, encoding: 'cipher+aes-128-cbc' } }
          let(:cipher_params) { crypto_options.merge(key_length: 256) }
          let(:decode_method) { subject.decode message, { cipher: cipher_params } }

          it 'raise an exception' do
            expect { decode_method }.to raise_error Ably::Exceptions::CipherError, /Cipher algorithm [\w-]+ does not match message cipher algorithm of AES-128-CBC/
          end
        end

        context 'without any configured encryption' do
          let(:message) { { data: decoded_data, encoding: 'cipher+aes-128-cbc' } }
          let(:cipher_params) { crypto_options.merge(key_length: 256) }
          let(:decode_method) { subject.decode message, {} }

          it 'raise an exception' do
            expect { decode_method }.to raise_error Ably::Exceptions::CipherError, /Message cannot be decrypted as the channel is not set up for encryption & decryption/
          end
        end
      end

      context 'with invalid cipher data' do
        let(:message) { { data: decoded_data, encoding: 'cipher+aes-128-cbc' } }
        let(:decode_method) { subject.decode(message, { cipher: cipher_params }) }

        it 'raise an exception' do
          expect { decode_method }.to raise_error Ably::Exceptions::CipherError, /CipherError decrypting data/
        end
      end
    end

    context 'with AES-256-CBC' do
      let(:secret_key) { Ably::Util::Crypto.generate_random_key(256) }
      let(:cipher_params) { crypto_options.merge(key_length: 256) }

      before do
        subject.decode message, { cipher: cipher_params }
      end

      context 'message with cipher payload' do
        let(:message) { { data: cipher_data, encoding: 'cipher+aes-256-cbc' } }

        it 'decodes cipher' do
          expect(message[:data]).to eql(decoded_data)
        end

        it 'strips the encoding' do
          expect(message[:encoding]).to be_nil
        end
      end
    end
  end

  context '#encode' do
    context 'with channel set up for AES-128-CBC' do
      let(:cipher_params) { crypto_options }
      let(:channel_options) { { cipher: cipher_params } }

      context 'with encrypted set to true' do
        before do
          subject.encode message, channel_options
        end

        context 'message with string payload' do
          let(:message) { { data: decoded_data, encoding: nil } }

          it 'encodes cipher' do
            expect(message[:data]).to_not eql(decoded_data)
            expect(crypto.decrypt(message[:data])).to eql(decoded_data)
          end

          it 'adds the encoding with utf-8' do
            expect(message[:encoding]).to eql('utf-8/cipher+aes-128-cbc')
          end
        end

        context 'message with binary payload' do
          let(:message) { { data: binary_data, encoding: nil } }

          it 'encodes cipher' do
            expect(message[:data]).to_not eql(binary_data)
            expect(crypto.decrypt(message[:data])).to eql(binary_data)
          end

          it 'adds the encoding without utf-8 prefixed' do
            expect(message[:encoding]).to eql('cipher+aes-128-cbc')
          end

          it 'returns ASCII_8BIT encoded binary data' do
            expect(message[:data].encoding).to eql(Encoding::ASCII_8BIT)
          end
        end

        context 'message with json payload' do
          let(:message) { { data: decoded_data, encoding: 'json' } }

          it 'encodes cipher' do
            expect(message[:data]).to_not eql(decoded_data)
            expect(crypto.decrypt(message[:data])).to eql(decoded_data)
          end

          it 'adds the encoding with utf-8' do
            expect(message[:encoding]).to eql('json/utf-8/cipher+aes-128-cbc')
          end
        end

        context 'message with existing cipher encoding before' do
          let(:message) { { data: decoded_data, encoding: 'utf-8/cipher+aes-128-cbc' } }

          it 'leaves message intact as it is already encrypted' do
            expect(message[:data]).to eql(decoded_data)
          end

          it 'leaves encoding intact' do
            expect(message[:encoding]).to eql('utf-8/cipher+aes-128-cbc')
          end
        end

        context 'with encryption set to to false' do
          let(:message) { { data: decoded_data, encoding: 'utf-8' } }
          let(:channel_options) { { encrypted: false, cipher_params: cipher_params } }

          it 'leaves message intact as encryption is not enable' do
            expect(message[:data]).to eql(decoded_data)
          end

          it 'leaves encoding intact' do
            expect(message[:encoding]).to eql('utf-8')
          end
        end
      end

      context 'channel_option cipher params' do
        let(:message) { { data: decoded_data, encoding: nil } }
        let(:encode_method) { subject.encode message, { cipher: cipher_params } }

        context 'have invalid key length' do
          let(:cipher_params) { crypto_options.merge(key_length: 1) }
          it 'raise an exception' do
            expect { encode_method }.to raise_error Ably::Exceptions::CipherError, /Incompatible :key length/
          end
        end

        context 'have invalid algorithm' do
          let(:cipher_params) { crypto_options.merge(algorithm: 'does not exist') }
          it 'raise an exception' do
            expect { encode_method }.to raise_error Ably::Exceptions::CipherError, /unsupported cipher algorithm/
          end
        end

        context 'have missing key' do
          let(:cipher_params) { {} }
          it 'raise an exception' do
            expect { encode_method }.to raise_error Ably::Exceptions::CipherError, /key.*required/
          end
        end
      end
    end

    context 'with AES-256-CBC' do
      let(:secret_key) { Ably::Util::Crypto.generate_random_key(256) }
      let(:cipher_params) { crypto_options.merge(key_length: 256) }

      before do
        subject.encode message, { cipher: cipher_params }
      end

      context 'message with cipher payload' do
        let(:message) { { data: decoded_data, encoding: 'utf-8' } }

        it 'decodes cipher' do
          expect(message[:data]).to_not eql(decoded_data)
          expect(crypto.decrypt(message[:data])).to eql(decoded_data)
        end

        it 'strips the encoding' do
          expect(message[:encoding]).to eql('utf-8/cipher+aes-256-cbc')
        end
      end
    end
  end
end
