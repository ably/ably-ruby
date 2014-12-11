# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Channels do
  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:client) do
        Ably::Rest::Client.new(api_key: api_key, environment: environment, protocol: protocol)
      end
      let(:channel_name) { random_str }
      let(:options)      { { key: 'value' } }

      shared_examples 'a channel' do
        it 'should access a channel' do
          expect(channel).to be_a Ably::Rest::Channel
          expect(channel.name).to eql(channel_name)
        end

        it 'should allow options to be set on a channel' do
          expect(channel_with_options.options).to eql(options)
        end
      end

      describe 'using shortcut method on client' do
        let(:channel) { client.channel(channel_name) }
        let(:channel_with_options) { client.channel(channel_name, options) }
        it_behaves_like 'a channel'
      end

      describe 'using documented .get method on client.channels' do
        let(:channel) { client.channels.get(channel_name) }
        let(:channel_with_options) { client.channels.get(channel_name, options) }
        it_behaves_like 'a channel'
      end

      describe 'using undocumented [] method on client.channels' do
        let(:channel) { client.channels[channel_name] }
        let(:channel_with_options) { client.channels[channel_name, options] }
        it_behaves_like 'a channel'
      end
    end
  end
end
