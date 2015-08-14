# encoding: utf-8
require 'spec_helper'

# Very high level test coverage of the Realtime::Auth object which is just an async
# wrapper around the Ably::Auth object
#
describe Ably::Realtime::Auth, :event_machine do
  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }
    let(:client)          { Ably::Realtime::Client.new(client_options) }
    let(:auth)            { client.auth }

    context 'with basic auth' do
      context '#authentication_security_requirements_met?' do
        before do
          expect(client.use_tls?).to eql(true)
        end

        it 'returns true' do
          expect(auth.authentication_security_requirements_met?).to eql(true)
          stop_reactor
        end
      end

      context '#key' do
        it 'contains the API key' do
          expect(auth.key).to eql(api_key)
          stop_reactor
        end
      end

      context '#key_name' do
        it 'contains the API key name' do
          expect(auth.key_name).to eql(key_name)
          stop_reactor
        end
      end

      context '#key_secret' do
        it 'contains the API key secret' do
          expect(auth.key_secret).to eql(key_secret)
          stop_reactor
        end
      end

      context '#using_basic_auth?' do
        it 'is true when using Basic Auth' do
          expect(auth).to be_using_basic_auth
          stop_reactor
        end
      end

      context '#using_token_auth?' do
        it 'is false when using Basic Auth' do
          expect(auth).to_not be_using_token_auth
          stop_reactor
        end
      end
    end

    context 'with token auth' do
      let(:client_id)      { random_str }
      let(:client_options) { default_options.merge(client_id: client_id) }

      context '#client_id' do
        it 'contains the ClientOptions client ID' do
          expect(auth.client_id).to eql(client_id)
          stop_reactor
        end
      end

      context '#token' do
        let(:client_options) { default_options.merge(token: random_str) }

        it 'contains the current token after auth' do
          expect(auth.token).to_not be_nil
          stop_reactor
        end
      end

      context '#current_token_details' do
        it 'contains the current token after auth' do
          expect(auth.current_token_details).to be_nil
          auth.authorise do
            expect(auth.current_token_details).to be_a(Ably::Models::TokenDetails)
            stop_reactor
          end
        end
      end

      context '#token_renewable?' do
        it 'is true when an API key exists' do
          expect(auth).to be_token_renewable
          stop_reactor
        end
      end

      context '#options' do
        let(:custom_ttl) { 33 }

        it 'contains the configured auth options' do
          auth.authorise(ttl: custom_ttl) do
            expect(auth.options[:ttl]).to eql(custom_ttl)
            stop_reactor
          end
        end
      end

      context '#using_basic_auth?' do
        it 'is false when using Token Auth' do
          auth.authorise do
            expect(auth).to_not be_using_basic_auth
            stop_reactor
          end
        end
      end

      context '#using_token_auth?' do
        it 'is true when using Token Auth' do
          auth.authorise do
            expect(auth).to be_using_token_auth
            stop_reactor
          end
        end
      end
    end

    context '#create_token_request' do
      it 'returns a token request asynchronously' do
        auth.create_token_request do |token_request|
          expect(token_request).to be_a(Ably::Models::TokenRequest)
          stop_reactor
        end
      end
    end

    context '#create_token_request_async' do
      it 'returns a token request synchronously' do
        expect(auth.create_token_request_sync).to be_a(Ably::Models::TokenRequest)
        stop_reactor
      end
    end

    context '#request_token' do
      it 'returns a token asynchronously' do
        auth.request_token do |token_details|
          expect(token_details).to be_a(Ably::Models::TokenDetails)
          stop_reactor
        end
      end
    end

    context '#request_token_async' do
      it 'returns a token synchronously' do
        expect(auth.request_token_sync).to be_a(Ably::Models::TokenDetails)
        stop_reactor
      end
    end

    context '#authorise' do
      it 'returns a token asynchronously' do
        auth.authorise do |token_details|
          expect(token_details).to be_a(Ably::Models::TokenDetails)
          stop_reactor
        end
      end
    end

    context '#authorise_async' do
      it 'returns a token synchronously' do
        expect(auth.authorise_sync).to be_a(Ably::Models::TokenDetails)
        stop_reactor
      end
    end

    context '#auth_params' do
      it 'returns the auth params asynchronously' do
        auth.auth_params do |auth_params|
          expect(auth_params).to be_a(Hash)
          stop_reactor
        end
      end
    end

    context '#auth_params' do
      it 'returns the auth params synchronously' do
        expect(auth.auth_params_sync).to be_a(Hash)
        stop_reactor
      end
    end

    context '#auth_header' do
      it 'returns an auth header asynchronously' do
        auth.auth_header do |auth_header|
          expect(auth_header).to be_a(String)
          stop_reactor
        end
      end
    end

    context '#auth_header' do
      it 'returns an auth header synchronously' do
        expect(auth.auth_header_sync).to be_a(String)
        stop_reactor
      end
    end
  end
end
