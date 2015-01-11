# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Client, '#stats' do
  before(:context) do
    WebMock.disable! # ensure previous test's WebMock does not have side effects
    reload_test_app
  end

  before(:context) do
    client = Ably::Rest::Client.new(api_key: api_key, environment: environment)

    number_of_channels             = 3
    number_of_messages_per_channel = 5

    # Wait until the start of the next minute according to the service
    # time because stats are created in 1 minute intervals
    service_time   = client.time
    stats_setup_at = (service_time.to_i / 60 + 1) * 60
    sleep_time     = stats_setup_at - Time.now.to_i

    if sleep_time > 30
      stats_setup_at -= 60 # there is enough time to generate the stats in this minute interval
    elsif sleep_time > 0
      sleep sleep_time
    end

    number_of_channels.times do |i|
      channel = client.channel("stats-#{i}")

      number_of_messages_per_channel.times do |j|
        channel.publish("event-#{j}", "data-#{j}") || raise("Unable to publish message")
      end
    end

    # wait for stats to be persisted
    sleep 10

    @stats_setup_at = stats_setup_at
    @messages_published_count = number_of_channels * number_of_messages_per_channel
  end

  vary_by_protocol do
    describe 'fetching application stats' do
      [:minute, :hour, :day, :month].each do |interval|
        context "by #{interval}" do
          let(:client) {  Ably::Rest::Client.new(api_key: api_key, environment: environment, protocol: protocol) }

          it 'should return all the stats for the application' do
            stats = client.stats(start: @stats_setup_at * 1000, by: interval.to_s, direction: 'forwards')

            expect(stats.size).to eql(1)
            stat = stats.first

            expect(@messages_published_count).to be_a(Numeric)
            expect(stat[:inbound][:all][:messages][:count]).to eql(@messages_published_count)
            expect(stat[:inbound][:rest][:messages][:count]).to eql(@messages_published_count)
          end
        end
      end
    end
  end
end
