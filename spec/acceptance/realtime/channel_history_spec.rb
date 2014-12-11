# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Channel do
  include RSpec::EventMachine

  [:json, :msgpack].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) { options.merge(api_key: api_key, environment: environment, protocol: protocol) }

      let(:client) do
        Ably::Realtime::Client.new(default_options)
      end
      let(:channel) { client.channel(channel_name) }

      let(:client2) do
        Ably::Realtime::Client.new(default_options)
      end
      let(:channel2) { client2.channel(channel_name) }

      let(:channel_name) { "persisted:#{random_str(2)}" }
      let(:payload)      { random_str }
      let(:messages)     { [] }

      let(:options) { { :protocol => :json } }

      it 'returns a Deferrable' do
        run_reactor do
          channel.publish('event', payload) do |message|
            expect(channel.history).to be_a(EventMachine::Deferrable)
            stop_reactor
          end
        end
      end

      it 'retrieves real-time history' do
        run_reactor do
          channel.publish('event', payload) do |message|
            channel.history do |history|
              expect(history.length).to eql(1)
              expect(history[0].data).to eql(payload)
              stop_reactor
            end
          end
        end
      end

      it 'retrieves real-time history across two channels' do
        run_reactor do
          channel.publish('event', payload) do |message|
            channel2.publish('event', payload) do |message|
              channel2.history do |history|
                expect(history.length).to eql(2)
                expect(history.map(&:data).uniq).to eql([payload])
                stop_reactor
              end
            end
          end
        end
      end

      context 'with multiple messages' do
        let(:messages_sent) { 20 }
        let(:limit) { 10 }

        def check_limited_history(direction)
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
          it 'retrieves limited history forwards with pagination' do
            run_reactor(5) do
              messages_sent.times do |index|
                channel.publish('event', "history#{index}") do
                  check_limited_history :forwards if index == messages_sent - 1
                end
              end
            end
          end

          it 'retrieves limited history backwards with pagination' do
            run_reactor(5) do
              messages_sent.times.to_a.reverse.each do |index|
                channel.publish('event', "history#{index}") do
                  check_limited_history :backwards if index == messages_sent - 1
                end
              end
            end
          end
        end

        context 'in multiple ProtocolMessages' do
          it 'retrieves limited history forwards with pagination' do
            run_reactor(5) do
              messages_sent.times do |index|
                EventMachine.add_timer(index.to_f / 10) do
                  channel.publish('event', "history#{index}") do
                    check_limited_history :forwards if index == messages_sent - 1
                  end
                end
              end
            end
          end

          it 'retrieves limited history backwards with pagination' do
            run_reactor(5) do
              messages_sent.times.to_a.reverse.each do |index|
                EventMachine.add_timer((messages_sent - index).to_f / 10) do
                  channel.publish('event', "history#{index}") do
                    check_limited_history :backwards if index == 0
                  end
                end
              end
            end
          end
        end

        context 'message IDs for messages with identical event name & data' do
          let(:batches) { 3 }
          let(:messages_per_batch) { 10 }

          specify 'are unqiue and match between Rest & Real-time' do
            run_reactor(5) do
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
  end
end
