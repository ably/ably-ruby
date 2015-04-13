# encoding: utf-8
require 'spec_helper'
require 'shared/client_initializer_behaviour'

describe Ably::Rest::Client do
  subject do
    Ably::Rest::Client.new(client_options)
  end

  it_behaves_like 'a client initializer'

  context 'initializer options' do
    context 'TLS' do
      context 'disabled' do
        let(:client_options) { { key: 'appid.keyuid:keysecret', tls: false } }

        it 'fails for any operation with basic auth and attempting to send an API key over a non-secure connection' do
          expect { subject.channel('a').publish('event', 'message') }.to raise_error(Ably::Exceptions::InsecureRequestError)
        end
      end
    end

    context ':use_token_auth' do
      context 'set to false' do
        context 'with an key with :tls => false' do
          let(:client_options) { { use_token_auth: false, key: 'appid.keyuid:keysecret', tls: false } }

          it 'fails for any operation with basic auth and attempting to send an API key over a non-secure connection' do
            expect { subject.channel('a').publish('event', 'message') }.to raise_error(Ably::Exceptions::InsecureRequestError)
          end
        end

        context 'without an key' do
          let(:client_options) { { use_token_auth: false } }

          it 'fails as an key is required if not using token auth' do
            expect { subject.channel('a').publish('event', 'message') }.to raise_error(ArgumentError)
          end
        end
      end

      context 'set to true' do
        context 'without an key or token_id' do
          let(:client_options) { { use_token_auth: true, key: true } }

          it 'fails as an key is required to issue tokens' do
            expect { subject.channel('a').publish('event', 'message') }.to raise_error(ArgumentError)
          end
        end
      end
    end
  end
end
