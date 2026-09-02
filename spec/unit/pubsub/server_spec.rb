# encoding: utf-8
require 'spec_helper'
require 'ably/pubsub/server'

describe Ably::PubSub::Server do
  let(:api_key)          { 'appid.keyuid:keysecret' }
  let(:rest_options)     { { key: api_key, client_id: 'john' } }
  let(:realtime_options) { { key: api_key, client_id: 'john', auto_connect: false } }

  context '#create_http_client' do
    it 'returns the core REST client' do
      expect(subject.create_http_client(rest_options)).to be_instance_of(Ably::Rest::Client)
    end

    it 'passes the options through' do
      client = subject.create_http_client(rest_options.merge(tls: false))
      expect(client.client_id).to eql('john')
      expect(client.use_tls?).to be_falsey
    end

    it 'accepts an API key string, as the constructor does' do
      expect(subject.create_http_client(api_key).auth.key_name).to eql('appid.keyuid')
    end

    it 'still requires options' do
      expect { subject.create_http_client(nil) }.to raise_error(ArgumentError)
    end
  end

  context '#create_realtime_client' do
    it 'returns the core realtime client' do
      expect(subject.create_realtime_client(realtime_options)).to be_instance_of(Ably::Realtime::Client)
    end

    it 'passes the options through' do
      expect(subject.create_realtime_client(realtime_options).client_id).to eql('john')
    end

    it 'accepts an API key string, as the constructor does' do
      expect(subject.create_realtime_client(api_key).auth.key_name).to eql('appid.keyuid')
    end
  end

  # :deprecation opts out of the suite-wide suppression in spec/rspec_config.rb, without which
  # these would pass whether the factories suppressed the warning or not
  context 'deprecation', :deprecation do
    before { Ably::Util::Deprecation.reset_warnings! }

    it 'the factories do not warn, being the recommended entry point' do
      expect(Kernel).to_not receive(:warn)
      subject.create_http_client(rest_options)
      subject.create_realtime_client(realtime_options)
    end

    it 'the constructors still warn after a factory call' do
      subject.create_http_client(rest_options)
      expect(Kernel).to receive(:warn).once
      Ably::Rest::Client.new(rest_options)
    end
  end

  context 'the core public API' do
    it 'is available, this gem being a thin entry point onto it' do
      expect(defined?(Ably::Rest::Client)).to eql('constant')
      expect(defined?(Ably::Realtime::Client)).to eql('constant')
      expect(defined?(Ably::Models::TokenDetails)).to eql('constant')
    end
  end
end
