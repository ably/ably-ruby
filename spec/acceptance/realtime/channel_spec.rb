require 'spec_helper'
require 'securerandom'

describe Ably::Realtime::Channel do
  include RSpec::EventMachine

  let(:client) do
    Ably::Realtime::Client.new(api_key: api_key, environment: environment)
  end
  let(:channel_name) { SecureRandom.hex(2) }
  let(:payload) { SecureRandom.hex(4) }

  it 'attachs to a channel' do
    attached = false

    run_reactor do
      channel = client.channel(channel_name)
      channel.attach
      channel.on(:attached) do
        attached = true
        stop_reactor
      end
    end

    expect(attached).to eql(true)
  end

  it 'publishes 3 messages once attached' do
    messages = []

    run_reactor do
      channel = client.channel(channel_name)
      channel.attach
      channel.on(:attached) do
        3.times { channel.publish('event', payload) }
      end
      channel.subscribe do |message|
        messages << message if message.data == payload
        stop_reactor if messages.length == 3
      end
    end

    expect(messages.count).to eql(3)
  end

  it 'publishes 3 messages from queue before attached' do
    messages = []

    run_reactor do
      channel = client.channel(channel_name)
      3.times { channel.publish('event', SecureRandom.hex) }
      channel.subscribe do |message|
        messages << message if message.name == 'event'
        stop_reactor if messages.length == 3
      end
    end

    expect(messages.count).to eql(3)
  end

  it 'publishes 3 messages from queue before attached in a single protocol message' do
    messages = []

    run_reactor do
      channel = client.channel(channel_name)
      3.times { channel.publish('event', SecureRandom.hex) }
      channel.subscribe do |message|
        messages << message if message.name == 'event'
        stop_reactor if messages.length == 3
      end
    end

    # All 3 messages should be batched into a single Protocol Message by the client library
    # message_id = "{connection_id}:{message_serial}:{protocol_message_index}"

    # Check that all messages share the same message_serial
    message_serials = messages.map { |msg| msg.message_id.split(':')[1] }
    expect(message_serials.uniq).to eql(["1"])

    # Check that all messages use message index 0,1,2
    message_indexes = messages.map { |msg| msg.message_id.split(':')[2] }
    expect(message_indexes).to include("0", "1", "2")
  end
end


