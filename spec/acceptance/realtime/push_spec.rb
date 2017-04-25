# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Push, :event_machine do
  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol} }
    let(:client_options)  { default_options }
    let(:client) do
      Ably::Realtime::Client.new(client_options)
    end
    subject { client.push }

    describe '#activate' do
      it 'raises an unsupported exception' do
        expect { subject.activate('foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
        stop_reactor
      end
    end

    describe '#deactivate' do
      it 'raises an unsupported exception' do
        expect { subject.deactivate('foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
        stop_reactor
      end
    end
  end
end
