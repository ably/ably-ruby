# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Presence, 'history', :event_machine do
  vary_by_protocol do
    let(:default_options)     { { key: api_key, environment: environment, protocol: protocol } }

    let(:channel_name)        { "persisted:#{random_str(2)}" }

    let(:client_one)          { auto_close Ably::Realtime::Client.new(default_options.merge(client_id: random_str)) }
    let(:channel_client_one)  { client_one.channel(channel_name) }
    let(:presence_client_one) { channel_client_one.presence }

    let(:client_two)          { auto_close Ably::Realtime::Client.new(default_options.merge(client_id: random_str)) }
    let(:channel_client_two)  { client_two.channel(channel_name) }
    let(:presence_client_two) { channel_client_two.presence }

    let(:data)                { random_str }
    let(:leave_data)          { random_str }

    it 'provides up to the moment presence history' do
      presence_client_one.enter(data) do
        presence_client_one.subscribe(:leave) do
          presence_client_one.history do |history_page|
            expect(history_page).to be_a(Ably::Models::PaginatedResult)
            expect(history_page.items.count).to eql(2)

            expect(history_page.items[1].action).to eq(:enter)
            expect(history_page.items[1].client_id).to eq(client_one.client_id)
            expect(history_page.items[1].data).to eql(data)

            expect(history_page.items[0].action).to eq(:leave)
            expect(history_page.items[0].client_id).to eq(client_one.client_id)
            expect(history_page.items[0].data).to eql(leave_data)

            stop_reactor
          end
        end

        presence_client_one.leave(leave_data)
      end
    end

    it 'ensures REST presence history message IDs match ProtocolMessage wrapped message and connection IDs via Realtime' do
      presence_client_one.subscribe(:enter) do |message|
        presence_client_one.history do |history_page|
          expect(history_page.items.count).to eql(1)

          expect(history_page.items[0].id).to eql(message.id)
          expect(history_page.items[0].connection_id).to eql(message.connection_id)
          stop_reactor
        end
      end

      presence_client_one.enter(data)
    end
  end
end
