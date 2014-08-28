require "spec_helper"

describe "Using the Rest client" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "publishing messages" do
    let(:channel) { client.channel("test") }
    let(:event)   { "foo" }
    let(:message) { "woop!" }

    it "should publish the message ok" do
      expect(channel.publish(event, message)).to eql(true)
    end
  end

  describe "fetching channel history" do
    let(:channel) { client.channel("persisted") }
    let(:expected_history) do
      [
        { :name => "test1", :data => "foo" },
        { :name => "test2", :data => "bar" },
        { :name => "test3", :data => "baz" }
      ]
    end

    before(:each) do
      expected_history.each do |message|
        channel.publish(message[:name], message[:data]) || raise("Unable to publish message")
      end

      sleep(10)
    end

    it "should return all the history for the channel" do
      actual_history = channel.history

      expect(actual_history.size).to eql(3)

      expected_history.each do |message|
        expect(actual_history).to include(message)
      end
    end
  end

  describe "fetching application stats" do
    def number_of_channels()             3 end
    def number_of_messages_per_channel() 5 end

    before(:context) do
      @context_client = Ably::Rest::Client.new(api_key: api_key, environment: environment)

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
        it "should return all the stats for the application" do
          stats = @context_client.stats(start: @interval_start * 1000, by: interval.to_s, direction: 'forwards')

          expect(stats.size).to eql(1)

          stat = stats.first

          expect(stat[:inbound][:all][:all][:count]).to eql(number_of_channels * number_of_messages_per_channel)
          expect(stat[:inbound][:rest][:all][:count]).to eql(number_of_channels * number_of_messages_per_channel)

          # TODO: Review number of Channels opened issue for intervals other than minute
          expect(stat[:channels][:opened]).to eql(number_of_channels) if interval == :minute
        end
      end
    end
  end

  describe "fetching the service time" do
    it "should return the service time as a Time object" do
      expect(client.time).to be_within(2).of(Time.now)
    end
  end

  describe "fetching a token" do
    let(:ttl)        { 60 * 60 }
    let(:capability) { { :foo => ["publish"] } }

    it "should return the requested token" do
      actual_token = client.request_token(
        ttl:        ttl,
        capability: capability
      )

      expect(actual_token.id).to match(/^#{app_id}\.[\w-]+$/)
      expect(actual_token.app_key).to match(/^#{app_id}\.#{key_id}$/)
      expect(actual_token.issued_at).to be_within(2).of(Time.now)
      expect(actual_token.expires_at).to be_within(2).of(Time.now + ttl)
    end
  end
end
