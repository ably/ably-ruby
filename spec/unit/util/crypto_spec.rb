require 'spec_helper'
require 'msgpack'

describe Ably::Util::Crypto do
  let(:seret_key)  { random_str }
  let(:cipher_options) { { key: seret_key } }
  subject { Ably::Util::Crypto.new(cipher_options) }

  context 'defaults' do
    let(:expected_defaults) do
      {
        algorithm: 'AES',
        mode: 'CBC',
        key_length: 128
      }
    end

    specify 'match other client libraries' do
      expect(Ably::Util::Crypto::DEFAULTS).to eql(expected_defaults)
      expect(Ably::Util::Crypto::BLOCK_LENGTH).to eql(16)
    end
  end

  context 'encrypts & decrypt' do
    let(:string) { random_str }
    let(:byte_array) { random_str.to_msgpack.unpack('C*') }

    specify 'a string' do
      encrypted = subject.encrypt(string)
      expect(subject.decrypt(encrypted)).to eql(string)
    end
  end

  context 'encrypting an empty string' do
    let(:empty_string) { '' }

    it 'raises an ErgumentError' do
      expect { subject.encrypt(empty_string) }.to raise_error ArgumentError, /data must not be empty/
    end
  end

  context 'using shared client lib fixture data' do
    let(:resources_root)      { File.expand_path('../../../resources', __FILE__) }
    let(:encryption_data_128) { JSON.parse(File.read(File.join(resources_root, 'crypto-data-128.json'))) }
    let(:encryption_data_256) { JSON.parse(File.read(File.join(resources_root, 'crypto-data-256.json'))) }

    shared_examples 'an Ably encrypter and decrypter' do
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

      it_behaves_like 'an Ably encrypter and decrypter'
    end

    context 'with AES-256-CBC' do
      let(:data) { encryption_data_256 }

      it_behaves_like 'an Ably encrypter and decrypter'
    end
  end
end
