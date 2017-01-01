require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ConnectionStateChange do
  let(:unique) { random_str }

  subject { Ably::Models::ConnectionStateChange }

  context '#current (#TA2)' do
    it 'is required' do
      expect { subject.new(previous: true) }.to raise_error ArgumentError
    end

    it 'is an attribute' do
      expect(subject.new(current: unique, previous: true).current).to eql(unique)
    end
  end

  context '#previous(#TA2)' do
    it 'is required' do
      expect { subject.new(current: true) }.to raise_error ArgumentError
    end

    it 'is an attribute' do
      expect(subject.new(previous: unique, current: true).previous).to eql(unique)
    end
  end

  context '#event(#TA5)' do
    it 'is not required' do
      expect { subject.new(previous: true, current: true) }.to_not raise_error
    end

    it 'is an attribute' do
      expect(subject.new(event: unique, current: true, previous: true).event).to eql(unique)
    end
  end


  context '#retry_in (#TA2)' do
    it 'is not required' do
      expect { subject.new(previous: true, current: true) }.to_not raise_error
    end

    it 'is an attribute' do
      expect(subject.new(retry_in: unique, previous: unique, current: true).retry_in).to eql(unique)
    end
  end

  context '#reason (#TA3)' do
    it 'is not required' do
      expect { subject.new(previous: true, current: true) }.to_not raise_error
    end

    it 'is an attribute' do
      expect(subject.new(reason: unique, previous: unique, current: true).reason).to eql(unique)
    end
  end

  context 'invalid attributes' do
    it 'raises an argument error' do
      expect { subject.new(invalid: true, current: true, previous: true) }.to raise_error ArgumentError
    end
  end
end
