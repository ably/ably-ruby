require "spec_helper"

describe "Using the Rest client" do
  let(:api_key) { "abc:123" }
  let(:client)  { Ably::Rest::Client.new(api_key: api_key) }

  describe "publishing messages", vcr: { cassette_name: "publishing_messages" } do
    let(:channel) { client.channel("test") }
    let(:message) { { name: "foo", data: "woop!" } }

    it "should publish the message ok" do
      expect(channel.publish message).to eql(true)
    end
  end

  describe "fetching channel history", vcr: { cassette_name: "fetching_channel_history" } do
    let(:channel) { client.channel("test") }
    let(:history) do
      [
        { :name => "test1", :data => "foo" },
        { :name => "test2", :data => "bar" },
        { :name => "test3", :data => "baz" }
      ]
    end

    it "should return all the history for the channel" do
      expect(channel.history).to eql(history)
    end
  end

  describe "fetching application stats", vcr: { cassette_name: "fetching_application_stats" } do
    it "should return all the stats for the channel" do
      stats = client.stats

      # Just check some sizes and keys because what gets returned is quite large
      expect(stats.size).to eql(3)
      stats.each do |stat|
        expect(stat.keys).to include(
          :all,
          :inbound,
          :outbound,
          :persisted,
          :connections,
          :channels,
          :apiRequests,
          :tokenRequests,
          :count,
          :intervalId
        )
      end
    end
  end

  describe "fetching the service time", vcr: { cassette_name: "fetching_service_time" } do
    let(:time) { Time.parse("12th December 2013 14:23:34 +0000") }

    it "should return the service time as a Time object" do
      expect(client.time).to eql(time)
    end
  end
end
