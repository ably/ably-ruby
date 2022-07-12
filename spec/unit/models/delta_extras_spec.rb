# frozen_string_literal: true

require 'spec_helper'

describe Ably::Models::DeltaExtras do
  subject { described_class.new({ format: 'vcdiff', from: '1234-4567-8910-1001-1111' }) }

  it 'should have `from` attribute' do
    expect(subject.from).to eq('1234-4567-8910-1001-1111')
  end

  it 'should have `format` attribute' do
    expect(subject.format).to eq('vcdiff')
  end
end
