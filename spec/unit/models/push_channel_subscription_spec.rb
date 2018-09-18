# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::PushChannelSubscription do
  include Ably::Modules::Conversions

  subject { Ably::Models::PushChannelSubscription }

  %w(channel client_id device_id).each do |string_attribute|
    describe "##{string_attribute} and ##{string_attribute}=" do
      let(:empty_device_details) do
        if string_attribute == 'device_id'
          subject.new(channel: 'default', device_id: 'default')
        else
          subject.new(channel: 'default', client_id: 'default')
        end
      end
      let(:new_val) { random_str }

      specify 'setter accepts a string value and getter returns the new value' do
        expect(empty_device_details.public_send(string_attribute)).to eql('default')
        empty_device_details.public_send("#{string_attribute}=", new_val)
        expect(empty_device_details.public_send(string_attribute)).to eql(new_val)
      end

      specify 'setter accepts nil' do
        empty_device_details.public_send("#{string_attribute}=", new_val)
        expect(empty_device_details.public_send(string_attribute)).to eql(new_val)
        empty_device_details.public_send("#{string_attribute}=", nil)
        expect(empty_device_details.public_send(string_attribute)).to be_nil
      end

      specify 'rejects non string or nil values' do
        expect { empty_device_details.public_send("#{string_attribute}=", {}) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'camelCase constructor attributes' do
    let(:client_id) { random_str }
    let(:device_details) { subject.new(channel: 'foo', 'clientId' => client_id ) }

    specify 'are rubyfied and exposed as underscore case' do
      expect(device_details.client_id).to eql(client_id)
    end

    specify 'are generated when the object is serialised to JSON' do
      expect(JSON.parse(device_details.to_json)["clientId"]).to eql(client_id)
    end
  end

  describe 'conversion method PushChannelSubscription' do
    let(:channel) { 'foo' }
    let(:device_id) { 'bar' }

    it 'accepts a PushChannelSubscription object' do
      push_channel_sub = PushChannelSubscription(channel: channel, device_id: device_id)
      expect(push_channel_sub.channel).to eql('foo')
      expect(push_channel_sub.client_id).to be_nil
      expect(push_channel_sub.device_id).to eql('bar')
    end
  end

  describe '#for_client_id constructor' do
    context 'with a valid object' do
      let(:channel) { 'foo' }
      let(:client_id) { 'bob' }

      it 'accepts a Hash object' do
        push_channel_sub = Ably::Models::PushChannelSubscription.for_client_id(channel, client_id)
        expect(push_channel_sub.channel).to eql('foo')
        expect(push_channel_sub.client_id).to eql('bob')
        expect(push_channel_sub.device_id).to be_nil
      end
    end

    context 'with an invalid valid object' do
      let(:subscription) { { channel: 'foo' } }

      it 'accepts a Hash object' do
        expect { Ably::Models::PushChannelSubscription.for_device(subscription) }.to raise_error(ArgumentError)
      end
    end
  end
end
