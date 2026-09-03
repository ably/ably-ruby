# encoding: utf-8
require 'spec_helper'

describe Ably::Models::PublishResult do
  subject { Ably::Models::PublishResult }

  context '#serials (#RSL1n)' do
    context 'when present' do
      let(:model) { subject.new(serials: ['serial-001', 'serial-002']) }

      it 'returns the serials array' do
        expect(model.serials).to eql(['serial-001', 'serial-002'])
      end
    end

    context 'with nullable entries' do
      let(:model) { subject.new(serials: ['serial-001', nil, 'serial-003']) }

      it 'preserves nil entries' do
        expect(model.serials).to eql(['serial-001', nil, 'serial-003'])
      end
    end

    context 'when empty array' do
      let(:model) { subject.new(serials: []) }

      it 'returns empty array' do
        expect(model.serials).to eql([])
      end
    end

    context 'when nil' do
      let(:model) { subject.new(serials: nil) }

      it 'returns empty array' do
        expect(model.serials).to eql([])
      end
    end

    context 'when not provided' do
      let(:model) { subject.new({}) }

      it 'returns empty array' do
        expect(model.serials).to eql([])
      end
    end
  end

  context '#attributes' do
    let(:model) { subject.new(serials: ['s1']) }

    it 'returns the underlying attributes' do
      expect(model.attributes).to be_a(Ably::Models::IdiomaticRubyWrapper)
    end

    it 'prevents modification' do
      expect { model.attributes[:serials] = ['changed'] }.to raise_error(/can't modify frozen|FrozenError/)
    end
  end

  context 'truthiness' do
    let(:model) { subject.new(serials: []) }

    it 'is truthy for backward compatibility with boolean publish returns' do
      expect(model).to be_truthy
    end
  end
end
