# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channel, '#history', :event_machine do
  vary_by_protocol do
    let(:default_options) { options.merge(api_key: api_key, environment: environment, protocol: protocol) }

    let(:client)       { Ably::Realtime::Client.new(default_options) }
    let(:channel)      { client.channel(channel_name) }

    let(:client2)      { Ably::Realtime::Client.new(default_options) }
    let(:channel2)     { client2.channel(channel_name) }

    let(:channel_name) { "persisted:#{random_str(2)}" }
    let(:payload)      { random_str }
    let(:messages)     { [] }

    let(:options)      { { :protocol => :json } }

    it 'returns a Deferrable' do
      channel.publish('event', payload) do |message|
        history = channel.history
        expect(history).to be_a(EventMachine::Deferrable)
        history.callback do |messages|
          expect(messages.count).to eql(1)
          expect(messages).to be_a(Ably::Models::PaginatedResource)
          stop_reactor
        end
      end
    end

    context 'with a single client publishing and receiving' do
      it 'retrieves real-time history' do
        channel.publish('event', payload) do |message|
          channel.history do |history|
            expect(history.length).to eql(1)
            expect(history[0].data).to eql(payload)
            stop_reactor
          end
        end
      end
    end

    context 'with two clients publishing messages on the same channel' do
      it 'retrieves real-time history on both channels' do
        channel.publish('event', payload) do |message|
          channel2.publish('event', payload) do |message|
            channel.history do |history|
              expect(history.length).to eql(2)
              expect(history.map(&:data).uniq).to eql([payload])

              channel2.history do |history_2|
                expect(history_2.length).to eql(2)
                stop_reactor
              end
            end
          end
        end
      end
    end

    context 'with lots of messages published with a single client and channel' do
      let(:messages_sent)   { 30 }
      let(:rate_per_second) { 4 }
      let(:limit)           { 15 }

      def ensure_message_history_direction_and_paging_is_correct(direction)
        channel.history(direction: direction, limit: limit) do |history|
          expect(history.length).to eql(limit)
          limit.times do |index|
            expect(history[index].data).to eql("history#{index}")
          end

          history.next_page do |history|
            expect(history.length).to eql(limit)
            limit.times do |index|
              expect(history[index].data).to eql("history#{index + limit}")
            end
            expect(history.last_page?).to eql(true)

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

      context 'in multiple ProtocolMessages', em_timeout: (30 / 4) + 10 do
        it 'retrieves limited history forwards with pagination' do
          messages_sent.times do |index|
            EventMachine.add_timer(index.to_f / rate_per_second) do
              channel.publish('event', "history#{index}") do
                next unless index == messages_sent - 1
                ensure_message_history_direction_and_paging_is_correct :forwards
              end
            end
          end
        end

        it 'retrieves limited history backwards with pagination' do
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

      context 'and REST history' do
        let(:batches) { 3 }
        let(:messages_per_batch) { 10 }

        it 'return the same results with unique matching message IDs' do
          batches.times do |batch|
            EventMachine.add_timer(batch.to_f / batches.to_f) do
              messages_per_batch.times { channel.publish('event', 'data') }
            end
          end

          channel.subscribe('event') do |message|
            messages << message
            if messages.count == batches * messages_per_batch
              channel.history do |history|
                expect(history.map(&:id).sort).to eql(messages.map(&:id).sort)
                stop_reactor
              end
            end
          end
        end
      end
    end
  end
end
