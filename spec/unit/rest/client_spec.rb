# encoding: utf-8
require 'spec_helper'
require 'shared/client_initializer_behaviour'

describe Ably::Rest::Client do
  subject do
    Ably::Rest::Client.new(client_options)
  end

  it_behaves_like 'a client initializer'

  context 'TLS' do
    context 'disabled' do
      let(:client_options) { { api_key: 'appid.keyuid:keysecret', tls: false } }

      it 'fails when authenticating with basic auth and attempting to send an API key over a non-secure connection' do
        expect { subject.channel('a').publish('event', 'message') }.to raise_error(Ably::Exceptions::InsecureRequestError)
      end
    end
  end
end
