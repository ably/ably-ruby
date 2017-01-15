require 'spec_helper'
require 'msgpack'

describe Ably::Util::Crypto do
  let(:cipher)         { OpenSSL::Cipher.new('AES-256-CBC') }
  let(:secret_key)     { cipher.random_key }
  let(:cipher_options) { { key: secret_key } }
  subject { Ably::Util::Crypto.new(cipher_options) }

  context 'defaults' do
    let(:expected_defaults) do
      {
        algorithm: 'aes',
        mode: 'cbc',
        key_length: 256
      }
    end

    specify 'match other client libraries' do
      expect(Ably::Util::Crypto::DEFAULTS).to eql(expected_defaults)
      expect(Ably::Util::Crypto::BLOCK_LENGTH).to eql(16)
    end
  end

  context 'get_default_params' do
    context 'with just a :key param' do
      let(:defaults) { Ably::Util::Crypto.get_default_params(key: secret_key) }

      it 'uses the defaults' do
        expect(defaults.algorithm).to eql('aes')
        expect(defaults.mode).to eql('cbc')
        expect(defaults.key_length).to eql(256)
      end

      it 'contains the provided key' do
        expect(defaults.key).to eql(secret_key)
      end

      it 'returns a CipherParams object' do
        expect(defaults).to be_a(Ably::Models::CipherParams)
      end
    end

    context 'without a :key param' do
      let(:cipher_params) { Ably::Util::Crypto.get_default_params }

      it 'raises an exception' do
        expect { cipher_params }.to raise_error(/key.*required/)
      end
    end

    context 'with a base64-encoded :key param' do
      let(:cipher_params) { Ably::Util::Crypto.get_default_params(key: Base64.encode64(secret_key)) }

      it 'converts the key to binary' do
        expect(cipher_params.key).to eql(secret_key)
      end
    end

    context 'with provided params' do
      let(:algorithm) { 'FOO' }
      let(:mode) { 'BAR' }
      let(:key_length) { 192 }
      let(:key) { secret_key[0...24] }
      let(:cipher_params) { Ably::Util::Crypto.get_default_params(key: key, algorithm: algorithm, mode: mode, key_length: key_length) }

      it 'overrides the defaults' do
        expect(cipher_params.algorithm).to eql('foo')
        expect(cipher_params.mode).to eql('bar')
        expect(cipher_params.key_length).to eql(192)
      end
    end
  end

  context 'encrypts & decrypt' do
    let(:string) { random_str }
    let(:byte_array) { random_str.to_msgpack.unpack('C*') }

    specify '#encrypt encrypts a string' do
      encrypted = subject.encrypt(string)
      expect(subject.decrypt(encrypted)).to eql(string)
    end

    specify '#decrypt decrypts a string' do
      encrypted = subject.encrypt(string)
      expect(subject.decrypt(encrypted)).to eql(string)
    end
  end

  context 'encrypting an empty string' do
    let(:empty_string) { '' }

    it 'raises an ArgumentError' do
      expect { subject.encrypt(empty_string) }.to raise_error ArgumentError, /data must not be empty/
    end
  end

  context 'using shared client lib fixture data' do
    let(:resources_root)      { File.expand_path('../../../../lib/submodules/ably-common/test-resources', __FILE__) }
    let(:encryption_data_128) { JSON.parse(File.read(File.join(resources_root, 'crypto-data-128.json'))) }
    let(:encryption_data_256) { JSON.parse(File.read(File.join(resources_root, 'crypto-data-256.json'))) }

    shared_examples 'an Ably encrypter and decrypter (#RTL7d)' do
      let(:algorithm)      { data['algorithm'].upcase }
      let(:mode)           { data['mode'].upcase }
      let(:key_length)     { data['keylength'] }
      let(:secret_key)     { Base64.decode64(data['key']) }
      let(:iv)             { Base64.decode64(data['iv']) }

      let(:cipher_options) { { key: secret_key, algorithm: algorithm, mode: mode, key_length: key_length } }

      context 'text payload' do
        let(:payload)        { data['items'].first['encoded']['data'] }
        let(:encrypted)      { data['items'].first['encrypted']['data'] }

        it 'encrypts exactly the same binary data as other client libraries' do
          expect(subject.encrypt(payload, iv: iv)).to eql(Base64.decode64(encrypted))
        end

        it 'decrypts exactly the same binary data as other client libraries' do
          expect(subject.decrypt(Base64.decode64(encrypted))).to eql(payload)
        end
      end
    end

    context 'with AES-128-CBC' do
      let(:data) { encryption_data_128 }

      it_behaves_like 'an Ably encrypter and decrypter (#RTL7d)'
    end

    context 'with AES-256-CBC' do
      let(:data) { encryption_data_256 }

      it_behaves_like 'an Ably encrypter and decrypter (#RTL7d)'
    end
  end
end
