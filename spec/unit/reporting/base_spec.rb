# encoding: utf-8
require 'spec_helper'

describe Ably::Reporting::Base do
  subject { described_class.new(dsn: 'https://example.errors/4') }

  it 'should raise NotImplementedError' do
    expect { subject.capture_exception(Exception) }.to raise_error(NotImplementedError)
  end
end
