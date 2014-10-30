require 'spec_helper'
require 'securerandom'

describe 'Ably::Realtime::Presence Messages' do
  include RSpec::EventMachine

  let(:default_options) { { api_key: api_key, environment: environment } }
  let(:channel_name) { "presence-#{SecureRandom.hex(2)}" }

  let(:anonymous_client) { Ably::Realtime::Client.new(default_options) }
  let(:client_one)       { Ably::Realtime::Client.new(default_options.merge(client_id: SecureRandom.hex(4))) }
  let(:client_two)       { Ably::Realtime::Client.new(default_options.merge(client_id: SecureRandom.hex(4))) }

  let(:channel_anonymous_client) { anonymous_client.channel(channel_name) }
  let(:channel_client_one)       { client_one.channel(channel_name) }
  let(:channel_rest_client_one)  { client_one.rest_client.channel(channel_name) }
  let(:presence_client_one)      { channel_client_one.presence }
  let(:channel_client_two)       { client_two.channel(channel_name) }
  let(:presence_client_two)      { channel_client_two.presence }

  let(:client_data_payload) { SecureRandom.hex(8) }

  it 'enters the :entered state without channel#attach or client#connect' do
    run_reactor do
      presence_client_one.enter do
        expect(presence_client_one.state).to eq(:entered)
        stop_reactor
      end
    end
  end

  it 'enters and then leaves' do
    leave_callback_called = false
    run_reactor do
      presence_client_one.enter do
        presence_client_one.leave do |presence|
          leave_callback_called = true
        end
        presence_client_one.on(:left) do
          EventMachine.next_tick do
            expect(leave_callback_called).to eql(true)
            stop_reactor
          end
        end
      end
    end
  end

  it 'enters the :left state if the channel detaches' do
    detached = false
    run_reactor do
      channel_client_one.presence.on(:left) do
        expect(channel_client_one.presence.state).to eq(:left)
        EventMachine.next_tick do
          expect(detached).to eq(true)
          stop_reactor
        end
      end
      channel_client_one.presence.enter do |presence|
        expect(presence.state).to eq(:entered)
        channel_client_one.detach do
          expect(channel_client_one.state).to eq(:detached)
          detached = true
        end
      end
    end
  end

  specify '#get returns the current member on the channel' do
    run_reactor do
      presence_client_one.enter do
        members = presence_client_one.get
        expect(members.count).to eq(1)

        expect(client_one.client_id).to_not be_nil

        this_member = members.first
        expect(this_member.client_id).to eql(client_one.client_id)

        stop_reactor
      end
    end
  end

  specify '#get returns no members on the channel following an enter and leave' do
    run_reactor do
      presence_client_one.enter do
        presence_client_one.leave do
          expect(presence_client_one.get).to eq([])
          stop_reactor
        end
      end
    end
  end

  specify 'verify two clients appear in members from #get' do
    run_reactor do
      presence_client_one.enter(client_data: client_data_payload)
      presence_client_two.enter

      entered_callback = Proc.new do
        next unless presence_client_one.state == :entered && presence_client_two.state == :entered

        EventMachine.add_timer(0.25) do
          expect(presence_client_one.get.count).to eq(presence_client_two.get.count)

          members = presence_client_one.get
          member_client_one = members.find { |presence| presence.client_id == client_one.client_id }
          member_client_two = members.find { |presence| presence.client_id == client_two.client_id }

          expect(member_client_one).to be_a(Ably::Models::PresenceMessage)
          expect(member_client_one.client_data).to eql(client_data_payload)
          expect(member_client_two).to be_a(Ably::Models::PresenceMessage)

          stop_reactor
        end
      end

      presence_client_one.on :entered, &entered_callback
      presence_client_two.on :entered, &entered_callback
    end
  end

  specify '#subscribe and #unsubscribe to presence events' do
    run_reactor do
      client_two_subscribe_messages = []

      subscribe_client_one_leaving_callback = Proc.new do |presence_message|
        expect(presence_message.client_id).to eql(client_one.client_id)
        expect(presence_message.client_data).to eql(client_data_payload)
        expect(presence_message.state).to eq(:leave)

        stop_reactor
      end

      subscribe_self_callback = Proc.new do |presence_message|
        if presence_message.client_id == client_two.client_id
          expect(presence_message.state).to eq(:enter)

          presence_client_two.unsubscribe &subscribe_self_callback
          presence_client_two.subscribe &subscribe_client_one_leaving_callback

          presence_client_one.leave client_data: client_data_payload
        end
      end

      presence_client_one.enter do
        presence_client_two.subscribe &subscribe_self_callback
      end
    end
  end

  specify 'verify REST #get returns current members' do
    run_reactor do
      presence_client_one.enter(client_data: client_data_payload) do
        members = channel_rest_client_one.presence.get
        this_member = members.first

        expect(this_member).to be_a(Ably::Models::PresenceMessage)
        expect(this_member.client_id).to eql(client_one.client_id)
        expect(this_member.client_data).to eql(client_data_payload)

        stop_reactor
      end
    end
  end

  specify 'verify REST #get returns no members once left' do
    run_reactor do
      presence_client_one.enter(client_data: client_data_payload) do
        presence_client_one.leave do
          members = channel_rest_client_one.presence.get
          expect(members.count).to eql(0)
          stop_reactor
        end
      end
    end
  end

  specify 'expect :left event once underlying connection is closed' do
    run_reactor do
      presence_client_one.on(:left) do
        expect(presence_client_one.state).to eq(:left)
        stop_reactor
      end
      presence_client_one.enter do
        client_one.close
      end
    end
  end

  it 'raises an exception if client_id is not set' do
    run_reactor do
      expect { channel_anonymous_client.presence.enter }.to raise_error(Ably::Exceptions::Standard, /without a client_id/)
      stop_reactor
    end
  end

  skip 'stop a call to get when the channel has not been entered'
  skip 'stop a call to get when the channel has been entered'
end
