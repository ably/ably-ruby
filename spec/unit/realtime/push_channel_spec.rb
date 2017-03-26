require 'spec_helper'

describe Ably::Realtime::Channel::PushChannel do
  subject { Ably::Realtime::Channel::PushChannel }

  let(:channel_name) { 'unique' }
  let(:client) { double('client').as_null_object }
  let(:channel) { Ably::Realtime::Channel.new(client, channel_name) }

  it 'is constructed with a channel' do
    expect(subject.new(channel)).to be_a(Ably::Realtime::Channel::PushChannel)
  end

  it 'raises an exception if constructed with an invalid type' do
    expect { subject.new(Hash.new) }.to raise_error(ArgumentError)
  end

  it 'exposes the channel as attribute #channel' do
    expect(subject.new(channel).channel).to eql(channel)
  end

  it 'is available in the #push attribute of the channel' do
    expect(channel.push).to be_a(Ably::Realtime::Channel::PushChannel)
    expect(channel.push.channel).to eql(channel)
  end

  context 'methods not implemented as push notifications' do
    subject { Ably::Realtime::Channel::PushChannel.new(channel) }

    %w(subscribe_device subscribe_client_id unsubscribe_device unsubscribe_client_id get_subscriptions).each do |method_name|
      specify "##{method_name} raises an unsupported exception" do
        expect { subject.public_send(method_name, 'foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
      end
    end
  end
end
