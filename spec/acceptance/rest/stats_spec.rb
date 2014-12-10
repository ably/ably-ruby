require 'spec_helper'
require 'securerandom'

describe 'Ably::Rest::Client Stats' do
  [:json, :msgpack].each do |protocol|
    context "over #{protocol}" do
      describe 'fetching application stats' do
        before(:context) do
          reload_test_app
        end

        def number_of_channels()             3 end
        def number_of_messages_per_channel() 5 end

        before(:context) do
          @context_client = Ably::Rest::Client.new(api_key: api_key, environment: environment, protocol: protocol)

          # Wait until the start of the next minute according to the service
          # time because stats are created in 1 minute intervals
          service_time    = @context_client.time
          @interval_start = (service_time.to_i / 60 + 1) * 60
          sleep_time      = @interval_start - Time.now.to_i

          if sleep_time > 30
            @interval_start -= 60 # there is enough time to generate the stats in this minute interval
          elsif sleep_time > 0
            sleep sleep_time
          end

          number_of_channels.times do |i|
            channel = @context_client.channel("stats-#{i}")

            number_of_messages_per_channel.times do |j|
              channel.publish("event-#{j}", "data-#{j}") || raise("Unable to publish message")
            end
          end

          sleep(10)
        end

        [:minute, :hour, :day, :month].each do |interval|
          context "by #{interval}" do
            it 'should return all the stats for the application' do
              stats = @context_client.stats(start: @interval_start * 1000, by: interval.to_s, direction: 'forwards')

              expect(stats.size).to eql(1)

              stat = stats.first

              expect(stat[:inbound][:all][:messages][:count]).to eql(number_of_channels * number_of_messages_per_channel)
              expect(stat[:inbound][:rest][:messages][:count]).to eql(number_of_channels * number_of_messages_per_channel)
            end
          end
        end
      end
    end
  end
end
