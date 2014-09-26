require 'spec_helper'

describe Ably::Util::Crypto do
  let(:secret) { SecureRandom.hex }
  subject { Ably::Util::Crypto.new(secret: secret) }

  context 'encrypts & decrypt' do
    let(:string) { SecureRandom.hex }

    specify 'a string' do
      encrypted = subject.encrypt(string)
      expect(subject.decrypt(encrypted)).to eql(string)
    end
  end
end
