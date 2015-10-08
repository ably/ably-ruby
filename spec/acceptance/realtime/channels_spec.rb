# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channels, :event_machine do
  shared_examples 'a channel' do
    it 'returns a channel object' do
      expect(channel).to be_a Ably::Realtime::Channel
      expect(channel.name).to eql(channel_name)
      stop_reactor
    end

    it 'returns channel object and passes the provided options' do
      expect(channel_with_options.options).to eql(options)
      stop_reactor
    end
  end

  vary_by_protocol do
    let(:client) do
      auto_close Ably::Realtime::Client.new(key: api_key, environment: environment, protocol: protocol)
    end
    let(:channel_name) { random_str }
    let(:options)      { { key: 'value' } }

    describe 'using shortcut method #channel on the client object' do
      let(:channel) { client.channel(channel_name) }
      let(:channel_with_options) { client.channel(channel_name, options) }
      it_behaves_like 'a channel'
    end

    describe 'using #get method on client#channels' do
      let(:channel) { client.channels.get(channel_name) }
      let(:channel_with_options) { client.channels.get(channel_name, options) }
      it_behaves_like 'a channel'
    end

    describe 'accessing an existing channel object with different options' do
      let(:new_channel_options) { { encrypted: true } }
      let(:original_channel)    { client.channels.get(channel_name, options) }

      it 'overrides the existing channel options and returns the channel object' do
        expect(original_channel.options).to_not include(:encrypted)
        new_channel = client.channels.get(channel_name, new_channel_options)
        expect(new_channel).to be_a(Ably::Realtime::Channel)
        expect(new_channel.options[:encrypted]).to eql(true)
        stop_reactor
      end
    end

    describe 'accessing an existing channel object without specifying any channel options' do
      let(:original_channel) { client.channels.get(channel_name, options) }

      it 'returns the existing channel without modifying the channel options' do
        expect(original_channel.options).to eql(options)
        new_channel = client.channels.get(channel_name)
        expect(new_channel).to be_a(Ably::Realtime::Channel)
        expect(original_channel.options).to eql(options)
        stop_reactor
      end
    end

    describe 'using undocumented array accessor [] method on client#channels' do
      let(:channel) { client.channels[channel_name] }
      let(:channel_with_options) { client.channels[channel_name, options] }
      it_behaves_like 'a channel'
    end
  end
end
