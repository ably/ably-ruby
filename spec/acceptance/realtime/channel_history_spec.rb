# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channel, '#history', :event_machine do
  vary_by_protocol do
    let(:default_options) { options.merge(key: api_key, environment: environment, protocol: protocol) }

    let(:client)       { auto_close Ably::Realtime::Client.new(default_options) }
    let(:channel)      { client.channel(channel_name) }
    let(:rest_channel) { client.rest_client.channel(channel_name) }

    let(:client2)      { auto_close Ably::Realtime::Client.new(default_options) }
    let(:channel2)     { client2.channel(channel_name) }

    let(:channel_name) { "persisted:#{random_str(2)}" }
    let(:payload)      { random_str }
    let(:messages)     { [] }

    let(:options)      { { :protocol => :json } }

    it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
      channel.publish('event', payload) do
        history = channel.history
        expect(history).to be_a(Ably::Util::SafeDeferrable)
        history.callback do |page|
          expect(page.items.count).to eql(1)
          expect(page).to be_a(Ably::Models::PaginatedResult)
          stop_reactor
        end
      end
    end

    context 'with a single client publishing and receiving' do
      it 'retrieves realtime history' do
        channel.publish('event', payload) do
          channel.history do |page|
            expect(page.items.length).to eql(1)
            expect(page.items[0].data).to eql(payload)
            stop_reactor
          end
        end
      end
    end

    context 'with two clients publishing messages on the same channel' do
      it 'retrieves realtime history on both channels' do
        channel.publish('event', payload) do
          channel2.publish('event', payload) do
            channel.history do |page|
              expect(page.items.length).to eql(2)
              expect(page.items.map(&:data).uniq).to eql([payload])

              channel2.history do |page_2|
                expect(page_2.items.length).to eql(2)
                stop_reactor
              end
            end
          end
        end
      end
    end

    context 'with lots of messages published with a single client and channel' do
      let(:messages_sent)   { 30 }
      let(:rate_per_second) { 10 }
      let(:limit)           { 15 }

      def ensure_message_history_direction_and_paging_is_correct(direction)
        channel.history(direction: direction, limit: limit) do |history_page|
          expect(history_page.items.length).to eql(limit)
          limit.times do |index|
            expect(history_page.items[index].data).to eql("history#{index}")
          end

          history_page.next do |next_page|
            expect(next_page.items.length).to eql(limit)
            limit.times do |index|
              expect(next_page.items[index].data).to eql("history#{index + limit}")
            end
            if next_page.has_next?
              next_page.next do |last|
                expect(last.items.length).to eql(0)
              end
            else
              expect(next_page).to be_last
            end

            stop_reactor
          end
        end
      end

      context 'as one ProtocolMessage' do
        it 'retrieves history forwards with pagination through :limit option' do
          messages_sent.times do |index|
            channel.publish('event', "history#{index}") do
              next unless index == messages_sent - 1
              ensure_message_history_direction_and_paging_is_correct :forwards
            end
          end
        end

        it 'retrieves history backwards with pagination through :limit option' do
          messages_sent.times.to_a.reverse.each do |index|
            channel.publish('event', "history#{index}") do
              next unless index == 0
              ensure_message_history_direction_and_paging_is_correct :backwards
            end
          end
        end
      end

      context 'in multiple ProtocolMessages', em_timeout: (30 / 10) + 5 do
        it 'retrieves limited history forwards with pagination' do
          channel.attach do
            messages_sent.times do |index|
              EventMachine.add_timer(index.to_f / rate_per_second) do
                channel.publish('event', "history#{index}") do
                  next unless index == messages_sent - 1
                  ensure_message_history_direction_and_paging_is_correct :forwards
                end
              end
            end
          end
        end

        it 'retrieves limited history backwards with pagination' do
          channel.attach do
            messages_sent.times.to_a.reverse.each do |index|
              EventMachine.add_timer((messages_sent - index).to_f / rate_per_second) do
                channel.publish('event', "history#{index}") do
                  next unless index == 0
                  ensure_message_history_direction_and_paging_is_correct :backwards if index == 0
                end
              end
            end
          end
        end
      end

      context 'and REST history' do
        let(:batches) { 3 }
        let(:messages_per_batch) { 10 }

        it 'return the same results with unique matching message IDs' do
          channel.attach do
            batches.times do |batch|
              EventMachine.add_timer(batch.to_f / batches.to_f) do
                messages_per_batch.times { |index| channel.publish('event') }
              end
            end

            channel.subscribe('event') do |message|
              messages << message
              if messages.count == batches * messages_per_batch
                channel.history do |page|
                  expect(page.items.map(&:id).sort).to eql(messages.map(&:id).sort)
                  stop_reactor
                end
              end
            end
          end
        end
      end
    end

    context 'with option until_attach: true' do
      let(:event) { random_str }
      let(:message_before_attach) { random_str }
      let(:message_after_attach) { random_str }

      it 'retrieves all messages before channel was attached' do
        rest_channel.publish event, message_before_attach

        channel.attach do
          channel.publish(event, message_after_attach) do
            channel.history(until_attach: true) do |messages|
              expect(messages.items.count).to eql(1)
              expect(messages.items.first.data).to eql(message_before_attach)
              stop_reactor
            end
          end
        end
      end

      context 'and two pages of messages' do
        it 'retrieves two pages of messages before channel was attached' do
          10.times { rest_channel.publish event, message_before_attach }

          channel.attach do
            10.times { rest_channel.publish event, message_after_attach }

            EventMachine.add_timer(0.5) do
              channel.history(until_attach: true, limit: 5) do |messages|
                expect(messages.items.count).to eql(5)
                expect(messages.items.map(&:data).uniq.first).to eql(message_before_attach)

                messages.next do |next_page_messages|
                  expect(next_page_messages.items.count).to eql(5)
                  expect(next_page_messages.items.map(&:data).uniq.first).to eql(message_before_attach)

                  if next_page_messages.last?
                    expect(next_page_messages).to be_last
                    stop_reactor
                  else
                    # If previous page said there is another page it is plausible and correct that
                    # the next page is empty and then the last, if the limit was satisfied
                    next_page_messages.next do |empty_page|
                      expect(empty_page.items.count).to eql(0)
                      expect(empty_page).to be_last
                      stop_reactor
                    end
                  end
                end
              end
            end
          end
        end
      end

      it 'fails the deferrable unless the state is attached' do
        channel.history(until_attach: true).errback do |error|
          expect(error.message).to match(/not attached/)
          stop_reactor
        end
      end
    end
  end
end
