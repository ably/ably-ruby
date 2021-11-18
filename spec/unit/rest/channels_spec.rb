# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Channels do
  let(:client)       { instance_double('Ably::Rest::Client') }
  let(:channel_name) { 'unique'.encode(Encoding::UTF_8) }
  let(:options)      do
    { params: { 'bizarre' => 'value' } }
  end

  subject { Ably::Rest::Channels.new(client) }

  describe '#get' do
    context "when channel doesn't exist" do
      with_different_option_types(:options) do
        it 'creates a channel (RSN3a)' do
          expect(Ably::Rest::Channel).to receive(:new).with(client, channel_name, options)
          subject.get(channel_name, options)
        end
      end
    end

    context 'when an existing channel exists' do
      with_different_option_types(:options) do
        it 'will reuse a channel object if it exists (RSN3a)' do
          channel = subject.get(channel_name, channel_options)
          expect(channel).to be_a(Ably::Rest::Channel)
          expect(subject.get(channel_name, channel_options).object_id).to eql(channel.object_id)
        end
      end

      context 'with new channel_options' do
        let(:modes) { %i[subscribe] }
        let(:new_options) do
          { modes:  modes }
        end

        with_different_option_types(:new_options) do
          it 'will update channel with provided options (RSN3c)' do
            channel = subject.get(channel_name, options)
            expect(channel.options.modes).to be_nil

            subject.get(channel_name, channel_options)
            expect(channel.options.modes).to eq(modes)
          end
        end
      end
    end
  end

  it '[] creates a channel' do
    expect(Ably::Rest::Channel).to receive(:new).with(client, channel_name, options)
    subject.get(channel_name, options)
  end

  context '#fetch' do
    it 'retrieves a channel if it exists' do
      channel = subject.get(channel_name, options)
      expect(subject.fetch(channel_name)).to eql(channel)
    end

    it 'calls the block if channel is missing' do
      block_called = false
      subject.fetch(channel_name) { block_called = true }
      expect(block_called).to eql(true)
    end
  end

  context 'destroying channels' do
    it '#release releases the channel resoures' do
      released_channel = subject.get(channel_name, options)
      subject.release(channel_name)
      expect(subject.get(channel_name, options).object_id).to_not eql(released_channel.object_id)
    end
  end

  context 'is Enumerable' do
    let(:channel_count) { 5 }
    let(:mock_channel)  { instance_double('Ably::Rest::Channel') }

    before do
      allow(Ably::Rest::Channel).to receive(:new).and_return(mock_channel)
      channel_count.times { |index| subject.get("channel-#{index}") }
    end

    it 'allows enumeration' do
      expect(subject.map.count).to eql(channel_count)
    end

    context '#each' do
      it 'returns an enumerator' do
        expect(subject.each).to be_a(Enumerator)
      end

      it 'yields each channel' do
        subject.each do |channel|
          expect(channel).to eql(mock_channel)
        end
      end
    end

    it 'provides #length' do
      expect(subject.length).to eql(channel_count)
    end
  end
end
