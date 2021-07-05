# encoding: utf-8
require 'spec_helper'

describe Ably::Reporting::Sentry do
  subject { described_class.new }

  describe '#capture_exception' do
    before { expect(Sentry).to receive(:capture_exception) }

    it 'should call Sentry.capture_exception(...)' do
      subject.capture_exception(Exception.new)
    end
  end
end
