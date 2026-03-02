# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Client, '#stats' do
  include Ably::Modules::Conversions

  LAST_YEAR = Time.now.year - 1
  LAST_INTERVAL = Time.new(LAST_YEAR, 2, 3, 15, 5, 0) # 3rd Feb 20(x) 16:05:00

  # Ensure metrics in previous year do not impact on tests for last year
  PREVIOUS_YEAR = Time.now.year - 2
  PREVIOUS_INTERVAL = Time.new(PREVIOUS_YEAR, 2, 3, 15, 5, 0)
  PREVIOUS_YEAR_STATS = 120

  STATS_FIXTURES = [
    {
      intervalId: Ably::Models::Stats.to_interval_id(LAST_INTERVAL - 120, :minute),
      inbound:  { realtime: { messages: { count: 50, data: 5000 } } },
      outbound: { realtime: { messages: { count: 20, data: 2000 } } }
    },
    {
      intervalId: Ably::Models::Stats.to_interval_id(LAST_INTERVAL - 60, :minute),
      inbound:  { realtime: { messages: { count: 60, data: 6000 } } },
      outbound: { realtime: { messages: { count: 10, data: 1000 } } }
    },
    {
      intervalId: Ably::Models::Stats.to_interval_id(LAST_INTERVAL, :minute),
      inbound:       { realtime: { messages: { count: 70, data: 7000 } } },
      outbound:      { realtime: { messages: { count: 40, data: 4000 } } },
      persisted:     { presence: { count: 20, data: 2000 } },
      connections:   { tls:      { peak: 20,  opened: 10 } },
      channels:      { peak: 50, opened: 30 },
      apiRequests:   { succeeded: 50, failed: 10 },
      tokenRequests: { succeeded: 60, failed: 20 },
    }
  ]

  PREVIOUS_YEAR_STATS_FIXTURES = PREVIOUS_YEAR_STATS.times.map do |index|
    {
      intervalId: Ably::Models::Stats.to_interval_id(PREVIOUS_INTERVAL - (index * 60), :minute),
      inbound:       { realtime: { messages: { count: index } } }
    }
  end

  before(:context) do
    reload_test_app # ensure no previous stats interfere
    TestApp.instance.create_test_stats(STATS_FIXTURES + PREVIOUS_YEAR_STATS_FIXTURES)
  end

  vary_by_protocol do
    let(:client) {  Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol) }

    describe 'fetching application stats' do
      it 'returns a PaginatedResult object' do
        expect(client.stats).to be_kind_of(Ably::Models::PaginatedResult)
      end

      context 'by minute' do
        let(:first_inbound_realtime_count) { STATS_FIXTURES.first[:inbound][:realtime][:messages][:count] }
        let(:last_inbound_realtime_count)  { STATS_FIXTURES.last[:inbound][:realtime][:messages][:count] }

        context 'with no options' do
          let(:subject) { client.stats(end: LAST_INTERVAL) } # end is needed to ensure no other tests have effected the stats
          let(:stat)    { subject.items.first }

          it 'returns the unit from the JSON response' do
            expect(stat.unit).to eq('minute')
          end
        end

        context 'with :from set to last interval and :limit set to 1' do
          let(:subject) { client.stats(start: as_since_epoch(LAST_INTERVAL), end: LAST_INTERVAL, unit: :minute, limit: 1) }
          let(:stat)    { subject.items.first }

          it 'retrieves only one stat' do
            expect(subject.items.count).to eql(1)
          end

          it 'returns entries as a flat hash (#TS12r)' do
            expect(stat.entries).to be_a(Hash)
          end

          it 'returns zero or nil for any missing entries' do
            expect(stat.entries['channels.refused']).to be_nil
            expect(stat.entries['messages.outbound.webhook.all.count']).to be_nil
          end

          it 'returns all aggregated message data' do
            expect(stat.entries['messages.all.messages.count']).to eql(70 + 40) # inbound + outbound
            expect(stat.entries['messages.all.messages.data']).to eql(7000 + 4000) # inbound + outbound
          end

          it 'returns inbound realtime all data' do
            expect(stat.entries['messages.inbound.realtime.all.count']).to eql(70)
            expect(stat.entries['messages.inbound.realtime.all.data']).to eql(7000)
          end

          it 'returns inbound realtime message data' do
            expect(stat.entries['messages.inbound.realtime.messages.count']).to eql(70)
            expect(stat.entries['messages.inbound.realtime.messages.data']).to eql(7000)
          end

          it 'returns outbound realtime all data' do
            expect(stat.entries['messages.outbound.realtime.all.count']).to eql(40)
            expect(stat.entries['messages.outbound.realtime.all.data']).to eql(4000)
          end

          it 'returns persisted presence all data' do
            expect(stat.entries['messages.persisted.all.count']).to eql(20)
            expect(stat.entries['messages.persisted.all.data']).to eql(2000)
          end

          it 'returns connections all data' do
            expect(stat.entries['connections.all.peak']).to eql(20)
            expect(stat.entries['connections.all.opened']).to eql(10)
          end

          it 'returns channels data' do
            expect(stat.entries['channels.peak']).to eql(50)
            expect(stat.entries['channels.opened']).to eql(30)
          end

          it 'returns api_requests data' do
            expect(stat.entries['apiRequests.all.succeeded']).to eql(110) # 50 apiRequests + 60 tokenRequests
            expect(stat.entries['apiRequests.all.failed']).to eql(30) # 10 apiRequests + 20 tokenRequests
          end

          it 'returns token_requests data' do
            expect(stat.entries['apiRequests.tokenRequests.succeeded']).to eql(60)
            expect(stat.entries['apiRequests.tokenRequests.failed']).to eql(20)
          end

          it 'returns stat objects with #unit equal to minute' do
            expect(stat.unit).to eq('minute')
          end

          it 'returns stat objects with #interval_id matching :start' do
            expect(stat.interval_id).to eql(LAST_INTERVAL.strftime('%Y-%m-%d:%H:%M'))
          end

          it 'returns stat objects with #interval_time matching :start Time' do
            expect(stat.interval_time.to_i).to eql(LAST_INTERVAL.to_i)
          end
        end

        context 'with :start set to first interval, :limit set to 1 and direction :forwards' do
          let(:first_interval) { LAST_INTERVAL - 120 }
          let(:subject)        { client.stats(start: as_since_epoch(first_interval), end: LAST_INTERVAL, unit: :minute, direction: :forwards, limit: 1) }
          let(:stat)           { subject.items.first }

          it 'returns the first interval stats as stats are provided forwards from :start' do
            expect(stat.entries['messages.inbound.realtime.all.count']).to eql(first_inbound_realtime_count)
          end

          it 'returns 3 pages of stats' do
            expect(subject).to_not be_last
            page3 = subject.next.next
            expect(page3).to be_last
            expect(page3.items.first.entries['messages.inbound.realtime.all.count']).to eql(last_inbound_realtime_count)
          end
        end

        context 'with :end set to last interval, :limit set to 1 and direction :backwards' do
          let(:subject)        { client.stats(end: LAST_INTERVAL, unit: :minute, direction: :backwards, limit: 1) }
          let(:stat)           { subject.items.first }

          it 'returns the 3rd interval stats first as stats are provided backwards from :end' do
            expect(stat.entries['messages.inbound.realtime.all.count']).to eql(last_inbound_realtime_count)
          end

          it 'returns 3 pages of stats' do
            expect(subject).to_not be_last
            page3 = subject.next.next
            expect(page3.items.first.entries['messages.inbound.realtime.all.count']).to eql(first_inbound_realtime_count)
          end
        end

        context 'with :end set to last interval and :limit set to 3 to ensure only last years stats are included' do
          let(:subject) { client.stats(end: LAST_INTERVAL, unit: :minute, limit: 3) }
          let(:stats)   { subject.items }

          context 'the REST API' do
            it 'defaults to direction :backwards' do
              expect(stats.first.entries['messages.inbound.realtime.messages.count']).to eql(70) # current minute
              expect(stats.last.entries['messages.inbound.realtime.messages.count']).to eql(50) # 2 minutes back
            end
          end
        end

        context 'with :end set to previous year interval' do
          let(:subject) { client.stats(end: PREVIOUS_INTERVAL, unit: :minute) }
          let(:stats)   { subject.items }

          context 'the REST API' do
            it 'defaults to 100 items for pagination' do
              expect(stats.count).to eql(100)
              next_page_of_stats = subject.next.items
              expect(next_page_of_stats.count).to eql(PREVIOUS_YEAR_STATS - 100)
            end
          end
        end
      end

      [:hour, :day, :month].each do |interval|
        context "by #{interval}" do
          let(:subject) { client.stats(start: as_since_epoch(LAST_INTERVAL), end: LAST_INTERVAL, unit: interval, direction: 'forwards', limit: 1) }
          let(:stat)    { subject.items.first }
          let(:aggregate_messages_count) do
            STATS_FIXTURES.inject(0) do |sum, fixture|
              sum + fixture[:inbound][:realtime][:messages][:count] + fixture[:outbound][:realtime][:messages][:count]
            end
          end
          let(:aggregate_messages_data) do
            STATS_FIXTURES.inject(0) do |sum, fixture|
              sum + fixture[:inbound][:realtime][:messages][:data] + fixture[:outbound][:realtime][:messages][:data]
            end
          end

          it 'should aggregate the stats for that period' do
            expect(subject.items.count).to eql(1)

            expect(stat.entries['messages.all.messages.count']).to eql(aggregate_messages_count)
            expect(stat.entries['messages.all.messages.data']).to eql(aggregate_messages_data)
          end
        end
      end

      context 'when argument start is after end' do
        let(:subject) { client.stats(start: as_since_epoch(LAST_INTERVAL), end: LAST_INTERVAL - 120, unit: :minute) }

        it 'should raise an exception' do
          expect { subject.items }.to raise_error ArgumentError
        end
      end
    end
  end
end
