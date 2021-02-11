# encoding: utf-8
require 'spec_helper'
require 'shared/client_initializer_behaviour'

describe Ably::Realtime::Client do
  subject(:realtime_client) do
    Ably::Realtime::Client.new(client_options)
  end

  it_behaves_like 'a client initializer'

  context 'delegation to the REST Client' do
    let(:client_options) { { key: 'appid.keyuid:keysecret', auto_connect: false } }

    it 'passes on the options to the initializer' do
      rest_client = instance_double('Ably::Rest::Client', auth: instance_double('Ably::Auth'), options: client_options, environment: 'production', use_tls?: true, custom_tls_port: nil)
      expect(Ably::Rest::Client).to receive(:new).with(hash_including(client_options)).and_return(rest_client)
      realtime_client
    end

    context 'for attribute' do
      [:environment, :use_tls?, :log_level, :custom_host].each do |attribute|
        specify "##{attribute}" do
          expect(realtime_client.rest_client).to receive(attribute)
          realtime_client.public_send attribute
        end
      end
    end
  end

  context 'when :transport_params option is passed' do
    let(:expected_transport_params) do
      { 'heartbeats' => 'true', 'v' => '1.0', 'extra_param' => 'extra_param' }
    end
    let(:client_options) do
      { key: 'appid.keyuid:keysecret', transport_params: { heartbeats: true, v: 1.0, extra_param: 'extra_param'} }
    end

    it 'converts options to strings' do
      expect(realtime_client.transport_params).to eq(expected_transport_params)
    end
  end

  context 'push' do
    let(:client_options) { { key: 'appid.keyuid:keysecret' } }

    specify '#device is not supported and raises an exception' do
      expect { realtime_client.device }.to raise_error Ably::Exceptions::PushNotificationsNotSupported
    end

    specify '#push returns a Push object' do
      expect(realtime_client.push).to be_a(Ably::Realtime::Push)
    end
  end

  after(:all) do
    sleep 1 # let realtime library shut down any open clients
  end
end
