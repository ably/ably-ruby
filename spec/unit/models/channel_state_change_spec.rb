require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ChannelStateChange do
  let(:unique) { random_str }

  subject { Ably::Models::ChannelStateChange }

  context '#current' do
    it 'is required' do
      expect { subject.new(previous: true) }.to raise_error ArgumentError
    end

    it 'is an attribute' do
      expect(subject.new(current: unique, previous: true).current).to eql(unique)
    end
  end

  context '#previous' do
    it 'is required' do
      expect { subject.new(current: true) }.to raise_error ArgumentError
    end

    it 'is an attribute' do
      expect(subject.new(previous: unique, current: true).previous).to eql(unique)
    end
  end

  context '#reason' do
    it 'is not required' do
      expect { subject.new(previous: true, current: true) }.to_not raise_error
    end

    it 'is an attribute' do
      expect(subject.new(reason: unique, previous: unique, current: true).reason).to eql(unique)
    end
  end

  context '#resumed' do
    it 'is false when ommitted' do
      expect(subject.new(previous: true, current: true).resumed).to be_falsey
    end

    it 'is true when provided' do
      expect(subject.new(previous: true, current: true, resumed: true).resumed).to be_truthy
    end
  end

  context 'invalid attributes' do
    it 'raises an argument error' do
      expect { subject.new(invalid: true, current: true, previous: true) }.to raise_error ArgumentError
    end
  end
end
