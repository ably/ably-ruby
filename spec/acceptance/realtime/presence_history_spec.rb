# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Presence, 'history' do
  include RSpec::EventMachine

  vary_by_protocol do
    let(:default_options)     { { api_key: api_key, environment: environment, protocol: protocol } }

    let(:channel_name)        { "persisted:#{random_str(2)}" }

    let(:client_one)          { Ably::Realtime::Client.new(default_options.merge(client_id: random_str)) }
    let(:channel_client_one)  { client_one.channel(channel_name) }
    let(:presence_client_one) { channel_client_one.presence }

    let(:client_two)          { Ably::Realtime::Client.new(default_options.merge(client_id: random_str)) }
    let(:channel_client_two)  { client_two.channel(channel_name) }
    let(:presence_client_two) { channel_client_two.presence }

    let(:data)                { random_str }

    it 'provides up to the moment presence history' do
      run_reactor do
        presence_client_one.enter(data: data) do
          presence_client_one.leave do
            presence_client_one.history do |history|
              expect(history.count).to eql(2)

              expect(history[1].action).to eq(:enter)
              expect(history[1].client_id).to eq(client_one.client_id)
              expect(history[1].data).to eql(data)

              expect(history[0].action).to eq(:leave)
              expect(history[0].client_id).to eq(client_one.client_id)
              expect(history[0].data).to be_nil

              stop_reactor
            end
          end
        end
      end
    end

    it 'ensures REST presence history message IDs match ProtocolMessage wrapped message and member IDs via Realtime' do
      run_reactor do
        presence_client_one.subscribe(:enter) do |message|
          presence_client_one.history do |history|
            expect(history.count).to eql(1)

            expect(history[0].id).to eql(message.id)
            expect(history[0].member_id).to eql(message.member_id)
            stop_reactor
          end
        end

        presence_client_one.enter(data: data)
      end
    end
  end
end
