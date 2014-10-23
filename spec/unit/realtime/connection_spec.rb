require 'spec_helper'
require "support/protocol_msgbus_helper"

describe Ably::Realtime::Connection do
  let(:client) { double(:client) }
  let(:klass) { Class.new(Ably::Realtime::Connection) do; end }

  before do
    # Override self.new with a generic implementation of new as EventMachine::Connection
    # overrides self.new by default, and using EventMachine in unit tests is unnecessary
    klass.instance_eval do
      def self.new(*args)
        obj = self.allocate
        obj.orig_send :initialize, *args
        obj
      end
    end
  end

  subject do
    klass.new(client)
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
  it_behaves_like 'an outgoing protocol message bus'
end
