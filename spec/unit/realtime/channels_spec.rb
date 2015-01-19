# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channels do
  let(:connection) { instance_double('Ably::Realtime::Connection', on: true) }
  let(:client) { instance_double('Ably::Realtime::Client', connection: connection, client_id: 'clientId') }
  let(:channel_name) { 'unique' }
  let(:options) { { 'bizarre' => 'value' } }

  subject { Ably::Realtime::Channels.new(client) }

  context 'creating channels' do
    it '#get creates a channel' do
      expect(Ably::Realtime::Channel).to receive(:new).with(client, channel_name, options)
      subject.get(channel_name, options)
    end

    it '#get will reuse the channel object' do
      channel = subject.get(channel_name, options)
      expect(channel).to be_a(Ably::Realtime::Channel)
      expect(subject.get(channel_name, options).object_id).to eql(channel.object_id)
    end

    it '[] creates a channel' do
      expect(Ably::Realtime::Channel).to receive(:new).with(client, channel_name, options)
      subject.get(channel_name, options)
    end
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
    it '#release detaches and then releases the channel resources' do
      released_channel = subject.get(channel_name, options)
      expect(released_channel).to receive(:detach).and_yield
      subject.release(channel_name)
      expect(subject.get(channel_name, options).object_id).to_not eql(released_channel.object_id)
    end
  end

  context 'is Enumerable' do
    let(:channel_count) { 5 }
    let(:mock_channel)  { instance_double('Ably::Realtime::Channel') }

    before do
      allow(Ably::Realtime::Channel).to receive(:new).and_return(mock_channel)
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
