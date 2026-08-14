# encoding: utf-8
require 'spec_helper'
require 'ably/pubsub/device'

describe Ably::PubSub::Device do
  let(:api_key)          { 'appid.keyuid:keysecret' }
  let(:realtime_options) { { key: api_key, client_id: 'john', auto_connect: false } }

  context '#create_client' do
    it 'returns the core realtime client' do
      expect(subject.create_client(realtime_options)).to be_instance_of(Ably::Realtime::Client)
    end

    it 'passes the options through' do
      client = subject.create_client(realtime_options)
      expect(client.client_id).to eql('john')
      expect(client.auto_connect).to be_falsey
    end

    it 'accepts an API key string, as the constructor does' do
      expect(subject.create_client(api_key).auth.key_name).to eql('appid.keyuid')
    end

    it 'still requires options' do
      expect { subject.create_client(nil) }.to raise_error(ArgumentError)
    end
  end

  # :deprecation opts out of the suite-wide suppression in spec/rspec_config.rb, without which
  # these would pass whether the factory suppressed the warning or not
  context 'deprecation', :deprecation do
    before { Ably::Util::Deprecation.reset_warnings! }

    it 'the factory does not warn, being the recommended entry point' do
      expect(Kernel).to_not receive(:warn)
      subject.create_client(realtime_options)
    end

    it 'the constructor still warns after a factory call' do
      subject.create_client(realtime_options)
      expect(Kernel).to receive(:warn).once
      Ably::Realtime::Client.new(realtime_options)
    end
  end

  context 'the core public API' do
    it 'is available, this gem being a thin entry point onto it' do
      expect(defined?(Ably::Realtime::Client)).to eql('constant')
      expect(defined?(Ably::Models::TokenDetails)).to eql('constant')
    end
  end
end
