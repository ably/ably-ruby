# encoding: utf-8
require 'spec_helper'

describe Ably::Models::UpdateDeleteResult do
  subject { Ably::Models::UpdateDeleteResult }

  context '#version_serial (#UDR2a)' do
    context 'when present' do
      let(:model) { subject.new(version_serial: 'v1-serial') }

      it 'returns the version serial' do
        expect(model.version_serial).to eql('v1-serial')
      end
    end

    context 'when nil' do
      let(:model) { subject.new(version_serial: nil) }

      it 'returns nil' do
        expect(model.version_serial).to be_nil
      end
    end

    context 'when not provided' do
      let(:model) { subject.new({}) }

      it 'returns nil' do
        expect(model.version_serial).to be_nil
      end
    end
  end

  context 'with camelCase keys from wire' do
    let(:model) { subject.new('versionSerial' => 'v1-serial') }

    it 'converts to snake_case access' do
      expect(model.version_serial).to eql('v1-serial')
    end
  end

  context '#attributes' do
    let(:model) { subject.new(version_serial: 'v1') }

    it 'returns the underlying attributes' do
      expect(model.attributes).to be_a(Ably::Models::IdiomaticRubyWrapper)
    end

    it 'prevents modification' do
      expect { model.attributes[:version_serial] = 'changed' }.to raise_error(/can't modify frozen|FrozenError/)
    end
  end
end
