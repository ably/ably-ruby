# encoding: utf-8
require 'spec_helper'

describe Ably::Reporting::Service do
  subject { described_class.new(dsn: 'https://example.errors/4') }

  it 'should inherits from Ably::Reporting::Sentry by default' do
    expect(Ably::Reporting::Service).to be < Ably::Reporting::Sentry
  end
end
