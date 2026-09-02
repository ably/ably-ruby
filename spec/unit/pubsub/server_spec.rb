# encoding: utf-8
require 'spec_helper'
require 'ably/pubsub/server'

# The agent value asserted here is what MAU billing classification reads (PDR-091).
# These specs must fail loudly if the side-declaring entry is renamed, dropped, or
# becomes overridable by the caller.
describe Ably::PubSub::Server do
  let(:api_key) { 'appid.keyuid:keysecret' }
  # The side entry is a versionless flag, matching its ably-common registration: the
  # ably-ruby/x.y.z entry beside it carries identity and version (see ably-common#361).
  let(:side_entry) { 'ably-pubsub-server' }

  it 'releases in lockstep with ably-pubsub-core' do
    expect(Ably::PubSub::Server::VERSION).to eql(Ably::VERSION)
  end

  it 'declares an identifier whose -server suffix billing classification depends on' do
    expect(Ably::PubSub::Server::SERVER_AGENT_IDENTIFIER).to match(/-server\z/)
  end

  describe '.create_http_client' do
    subject(:client) { Ably::PubSub::Server.create_http_client(api_key) }

    it 'returns an HTTP (REST) client' do
      expect(client).to be_a(Ably::Rest::Client)
    end

    it 'appends the side-declaring agent entry to the base agent, versionless' do
      expect(client.agent).to eql("#{Ably::AGENT} #{side_entry}")
      expect(client.agent).to_not include('ably-pubsub-server/')
    end

    it 'sends the side-declaring agent entry in the Ably-Agent header' do
      expect(client.send(:connection_options)[:headers]['Ably-Agent']).to eql("#{Ably::AGENT} #{side_entry}")
    end

    context 'with an options hash' do
      subject(:client) { Ably::PubSub::Server.create_http_client(key: api_key, environment: 'sandbox') }

      it 'passes the options through and stamps the side' do
        expect(client.environment).to eql('sandbox')
        expect(client.agent).to end_with(side_entry)
      end
    end

    context 'with a token string' do
      subject(:client) { Ably::PubSub::Server.create_http_client('tokenstring') }

      it 'constructs a token-auth client with the side stamped' do
        expect(client.auth.options[:token]).to eql('tokenstring')
        expect(client.agent).to end_with(side_entry)
      end
    end

    context 'when the caller supplies their own agents' do
      subject(:client) { Ably::PubSub::Server.create_http_client(key: api_key, agents: { 'example-sdk' => '1.0.0' }) }

      it 'preserves the caller entries and appends the side entry' do
        expect(client.agent).to eql("#{Ably::AGENT} example-sdk/1.0.0 #{side_entry}")
      end
    end

    context 'when the caller tries to override the side entry' do
      subject(:client) { Ably::PubSub::Server.create_http_client(key: api_key, agents: { 'ably-pubsub-server' => 'not-the-version' }) }

      it 'the package wins the collision on its own identifier' do
        expect(client.agent).to end_with(side_entry)
        expect(client.agent).to_not include('not-the-version')
        expect(client.agent).to_not include('ably-pubsub-server/')
      end

      it 'does not mutate the caller options' do
        options = { key: api_key, agents: { 'example-sdk' => '1.0.0' } }
        Ably::PubSub::Server.create_http_client(options)
        expect(options[:agents]).to eql({ 'example-sdk' => '1.0.0' })
      end
    end
  end

  describe '.create_realtime_client' do
    subject(:client) { Ably::PubSub::Server.create_realtime_client(auto_connect: false, key: api_key) }

    it 'returns a realtime client' do
      expect(client).to be_a(Ably::Realtime::Client)
    end

    it 'appends the side-declaring agent entry sent as the realtime agent connection param' do
      # Ably::Realtime::Connection sends client.rest_client.agent as the `agent` param
      expect(client.rest_client.agent).to eql("#{Ably::AGENT} #{side_entry}")
    end

    context 'with an API key string' do
      subject(:client) { Ably::PubSub::Server.create_realtime_client(api_key) }

      it 'constructs a key-auth client with the side stamped' do
        expect(client.rest_client.agent).to end_with(side_entry)
      end
    end
  end
end
