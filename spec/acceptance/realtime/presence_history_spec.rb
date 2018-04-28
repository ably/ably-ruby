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
        presence_client_one.leave(leave_data) do
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

    context 'with option until_attach: true' do
      let(:event) { random_str }
      let(:presence_data_before_attach) { random_str }
      let(:presence_data_after_attach) { random_str }

      it 'retrieves all presence messages before channel was attached' do
        presence_client_two.enter(presence_data_before_attach) do
          presence_client_one.enter(presence_data_after_attach) do
            presence_client_one.history(until_attach: true) do |presence_page|
              expect(presence_page.items.count).to eql(1)
              expect(presence_page.items.first.data).to eql(presence_data_before_attach)
              stop_reactor
            end
          end
        end
      end

      context 'and two pages of messages' do
        let(:wildcard_token) { lambda { |token_params| Ably::Rest::Client.new(default_options).auth.request_token(client_id: '*') } }
        let(:client_one)     { auto_close Ably::Realtime::Client.new(default_options.merge(auth_callback: wildcard_token)) }
        let(:client_two)     { auto_close Ably::Realtime::Client.new(default_options.merge(auth_callback: wildcard_token)) }

        # TODO: Remove retry logic when presence history regression fixed
        #       https://github.com/ably/realtime/issues/1707
        #
        it 'retrieves two pages of messages before channel was attached', retry: 10, :retry_wait => 5 do
          when_all(*10.times.map { |i| presence_client_two.enter_client("client:#{i}", presence_data_before_attach) }) do
            when_all(*10.times.map { |i| presence_client_one.enter_client("client:#{i}", presence_data_after_attach) }) do
              presence_client_one.history(until_attach: true, limit: 5) do |presence_page|
                expect(presence_page.items.count).to eql(5)
                expect(presence_page.items.map(&:data).uniq.first).to eql(presence_data_before_attach)

                presence_page.next do |presence_next_page|
                  expect(presence_next_page.items.count).to eql(5)
                  expect(presence_next_page.items.map(&:data).uniq.first).to eql(presence_data_before_attach)
                  if presence_next_page.has_next?
                    presence_next_page.next do |last|
                      expect(last.items.count).to eql(0)
                    end
                  else
                    expect(presence_next_page).to be_last
                  end
                  stop_reactor
                end
              end
            end
          end
        end
      end

      it 'fails with an exception unless state is attached' do
        presence_client_one.history(until_attach: true).errback do |error|
          expect(error.message).to match(/not attached/)
          stop_reactor
        end
      end
    end
  end
end
