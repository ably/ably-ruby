# encoding: utf-8
require 'spec_helper'
require 'shared/client_initializer_behaviour'

describe Ably::Realtime::Client do
  subject do
    Ably::Realtime::Client.new(client_options)
  end

  it_behaves_like 'a client initializer'

  context 'delegation to the REST Client' do
    let(:client_options) { { key: 'appid.keyuid:keysecret', auto_connect: false } }

    it 'passes on the options to the initializer' do
      rest_client = instance_double('Ably::Rest::Client', auth: instance_double('Ably::Auth'), options: client_options, environment: 'production', use_tls?: true, custom_tls_port: nil)
      expect(Ably::Rest::Client).to receive(:new).with(hash_including(client_options)).and_return(rest_client)
      subject
    end

    context 'for attribute' do
      [:environment, :use_tls?, :log_level, :custom_host].each do |attribute|
        specify "##{attribute}" do
          expect(subject.rest_client).to receive(attribute)
          subject.public_send attribute
        end
      end
    end
  end

  context 'push' do
    let(:client_options) { { key: 'appid.keyuid:keysecret' } }

    specify '#device is not supported and raises an exception' do
      expect { subject.device }.to raise_error Ably::Exceptions::PushNotificationsNotSupported
    end

    specify '#push returns a Push object' do
      expect(subject.push).to be_a(Ably::Realtime::Push)
    end
  end

  after(:all) do
    sleep 1 # let realtime library shut down any open clients
  end
end
