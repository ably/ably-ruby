require 'spec_helper'

describe Ably::Util::Crypto do
  let(:secret) { SecureRandom.hex }
  subject { Ably::Util::Crypto.new(secret: secret) }

  context 'encrypts & decrypt' do
    let(:string) { SecureRandom.hex }
    let(:int) { SecureRandom.random_number(1_000_000_000) }
    let(:float) { SecureRandom.random_number(1_000_000_000) * 0.1 }
    let(:int64) { 15241578750190521 }
    let(:hash) do
      {
        10 => nil,
        'string' => 1,
        'float' => 1.2
      }
    end
    let(:array) { [string, int, float, int64, hash] }
    let(:boolean) { true }
    let(:nil) { nil }

    specify 'a string' do
      encrypted = subject.encrypt(string)
      expect(subject.decrypt(encrypted)).to eql(string)
    end

    specify 'a int' do
      encrypted = subject.encrypt(int)
      expect(subject.decrypt(encrypted)).to eql(int)
    end

    specify 'a int64' do
      encrypted = subject.encrypt(int64)
      expect(subject.decrypt(encrypted)).to eql(int64)
    end

    specify 'a float' do
      encrypted = subject.encrypt(float)
      expect(subject.decrypt(encrypted)).to eql(float)
    end

    specify 'a hash' do
      encrypted = subject.encrypt(hash)
      expect(subject.decrypt(encrypted)).to eql(hash)
    end

    specify 'an array' do
      encrypted = subject.encrypt(array)
      expect(subject.decrypt(encrypted)).to eql(array)
    end

    specify 'a boolean' do
      encrypted = subject.encrypt(boolean)
      expect(subject.decrypt(encrypted)).to eql(boolean)
    end

    specify 'a nil object' do
      encrypted = subject.encrypt(nil)
      expect(subject.decrypt(encrypted)).to eql(nil)
    end
  end
end
