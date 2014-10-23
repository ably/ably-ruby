require 'spec_helper'
require "support/protocol_msgbus_helper"

describe Ably::Realtime::Channel do
  let(:client) { double(:client) }
  let(:channel_name) { 'test' }

  subject do
    Ably::Realtime::Channel.new(client, channel_name)
  end

  describe 'callbacks' do
    specify 'are supported for valid STATE events' do
      state = nil
      subject.on(:initialized) { state = :ready }
      expect { subject.trigger(:initialized) }.to change { state }.to(:ready)
    end

    specify 'fail with unacceptable STATE event names' do
      expect { subject.on(:invalid) }.to raise_error KeyError
      expect { subject.trigger(:invalid) }.to raise_error KeyError
      expect { subject.off(:invalid) }.to raise_error KeyError
    end
  end

  it_behaves_like 'an incoming protocol message bus'
end
