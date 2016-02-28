require 'spec_helper'
require 'base64'

describe Ably::Models::CipherParams do
  context ':key missing from constructor' do
    subject { Ably::Models::CipherParams.new }

    it 'raises an exception' do
      expect { subject }.to raise_error(/key.*required/)
    end
  end

  describe '#key' do
    context 'with :key in constructor' do
      subject { Ably::Models::CipherParams.new(key: key) }

      context 'as nil' do
        let(:key) { nil }

        it 'raises an exception' do
          expect { subject }.to raise_error(/key.*required/)
        end
      end

      context 'as a base64 encoded string' do
        let(:binary_key) { Ably::Util::Crypto.generate_random_key }
        let(:key) { Base64.encode64(binary_key) }

        it 'is a binary representation of the base64 encoded string' do
          expect(subject.key).to eql(binary_key)
          expect(subject.key.encoding).to eql(Encoding::ASCII_8BIT)
        end
      end

      context 'as a URL safe base64 encoded string' do
        let(:base64_key) { "t+8lK21q7/44/YTpKTpHa6Icc/a08wIATyhxbVBb4RE=\n" }
        let(:binary_key) { Base64.decode64(base64_key) }
        let(:key) { base64_key.gsub('/', '_').gsub('+', '-') }

        it 'is a binary representation of the URL safe base64 encoded string' do
          expect(subject.key).to eql(binary_key)
        end
      end

      context 'as a binary encoded string' do
        let(:key) { Ably::Util::Crypto.generate_random_key }

        it 'contains the binary string' do
          expect(subject.key).to eql(key)
          expect(subject.key.encoding).to eql(Encoding::ASCII_8BIT)
        end
      end

      context 'with an incompatible :key_length constructor param' do
        let(:key) { Ably::Util::Crypto.generate_random_key(256) }
        subject { Ably::Models::CipherParams.new(key: key, key_length: 128) }

        it 'raises an exception' do
          expect { subject }.to raise_error(/Incompatible.*key.*length/)
        end
      end

      context 'with an unsupported :key_length for aes-cbc encryption' do
        let(:key) { "A" * 48 }
        subject { Ably::Models::CipherParams.new(key: key, algorithm: 'aes', mode: 'cbc') }

        it 'raises an exception' do
          expect { subject }.to raise_error(/Unsupported key length/)
        end
      end

      context 'with an invalid type' do
        let(:key) { 111 }
        subject { Ably::Models::CipherParams.new(key: key) }

        it 'raises an exception' do
          expect { subject }.to raise_error(/key param must/)
        end
      end
    end
  end

  context 'with specified params in the constructor' do
    let(:key) { Ably::Util::Crypto.generate_random_key(128) }
    subject { Ably::Models::CipherParams.new(key: key, algorithm: 'aes', key_length: 128, mode: 'cbc') }

    describe '#cipher_type' do
      it 'contains the complete algorithm string as an upper case string' do
        expect(subject.cipher_type).to eql ('AES-128-CBC')
      end
    end

    describe '#mode' do
      it 'contains the mode' do
        expect(subject.mode).to eql ('cbc')
      end
    end

    describe '#algorithm' do
      it 'contains the algorithm' do
        expect(subject.algorithm).to eql ('aes')
      end
    end

    describe '#key_length' do
      it 'contains the key_length' do
        expect(subject.key_length).to eql(128)
      end
    end
  end

  context 'with combined param in the constructor' do
    let(:key) { Ably::Util::Crypto.generate_random_key(128) }
    subject { Ably::Models::CipherParams.new(key: key, combined: "FOO-128-BAR") }

    describe '#cipher_type' do
      it 'contains the complete algorithm string as an upper case string' do
        expect(subject.cipher_type).to eql ('FOO-128-BAR')
      end
    end

    describe '#mode' do
      it 'contains the mode' do
        expect(subject.mode).to eql ('bar')
      end
    end

    describe '#algorithm' do
      it 'contains the algorithm' do
        expect(subject.algorithm).to eql ('foo')
      end
    end

    describe '#key_length' do
      it 'contains the key_length' do
        expect(subject.key_length).to eql(128)
      end
    end
  end
end
