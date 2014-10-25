require 'spec_helper'
require "support/protocol_msgbus_helper"

describe Ably::Realtime::Client do
  let(:client_options) { 'appid.keyuid:keysecret' }
  subject do
    Ably::Realtime::Client.new(client_options)
  end

  context 'delegation to the Rest Client' do
    let(:options) { { arbitrary: 'value' } }

    it 'passes on the options to the initializer' do
      expect(Ably::Rest::Client).to receive(:new).with(client_options).and_return(double('rest_client', auth: double('auth')))
      subject
    end

    specify '#time' do
      expect(subject.rest_client).to receive(:time)
      subject.time
    end

    specify '#stats' do
      expect(subject.rest_client).to receive(:stats).with(options)
      subject.stats options
    end

    context 'for attribute' do
      [:environment, :use_tls?, :logger, :log_level].each do |attribute|
        specify "##{attribute}" do
          expect(subject.rest_client).to receive(attribute)
          subject.public_send attribute
        end
      end
    end
  end
end
