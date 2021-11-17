# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Channels do
  shared_examples 'a channel' do
    it 'returns a channel object' do
      expect(channel).to be_a Ably::Rest::Channel
      expect(channel.name).to eq(channel_name)
    end

    it 'returns channel object and passes the provided options' do
      expect(channel_with_options.options.to_h).to eq(options)
    end
  end

  vary_by_protocol do
    let(:client) do
      Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol)
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

    describe '#set_options (#RTL16)' do
      let(:channel) { client.channel(channel_name) }

      it "updates channel's options" do
        expect { channel.options = options }.to change { channel.options.to_h }.from({}).to(options)
      end

      context 'when providing Ably::Models::ChannelOptions object' do
        let(:options_object) { Ably::Models::ChannelOptions.new(options) }

        it "updates channel's options" do
          expect { channel.options =  options_object}.to change { channel.options.to_h }.from({}).to(options)
        end
      end
    end

    describe 'accessing an existing channel object with different options' do
      let(:new_channel_options) { { encrypted: true } }
      let(:original_channel)    { client.channels.get(channel_name, options) }

      it 'overrides the existing channel options and returns the channel object (RSN3c)' do
        expect(original_channel.options.to_h).to_not include(:encrypted)

        new_channel = client.channels.get(channel_name, new_channel_options)
        expect(new_channel).to be_a(Ably::Rest::Channel)
        expect(new_channel.options[:encrypted]).to eql(true)
      end
    end

    describe 'accessing an existing channel object without specifying any channel options' do
      let(:original_channel) { client.channels.get(channel_name, options) }

      it 'returns the existing channel without modifying the channel options' do
        expect(original_channel.options.to_h).to eq(options)
        new_channel = client.channels.get(channel_name)
        expect(new_channel).to be_a(Ably::Rest::Channel)
        expect(original_channel.options.to_h).to eq(options)
      end
    end

    describe 'using undocumented array accessor [] method on client#channels' do
      let(:channel) { client.channels[channel_name] }
      let(:channel_with_options) { client.channels[channel_name, options] }
      it_behaves_like 'a channel'
    end

    describe 'using a frozen channel name' do
      let(:channel) { client.channels[channel_name.freeze] }
      let(:channel_with_options) { client.channels[channel_name.freeze, options] }
      it_behaves_like 'a channel'
    end
  end
end
