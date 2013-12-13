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

  describe "fetching a token", vcr: { cassette_name: "fetching_a_token" } do
    let(:timestamp)  { Time.parse("13th December 2013 18:00:00 +0000").to_i }
    let(:nonce)      { "some-random-string" }
    let(:ttl)        { 60 * 60 }
    let(:capability) { { :foo => ["publish"] } }

    it "should return the requested token" do
      expected_token = Ably::Token.new(
        id:         "abcdef",
        key:        "abc",
        issued_at:  timestamp,
        expires:    timestamp + ttl,
        capability: capability
      )

      actual_token = client.request_token(
        timestamp:  timestamp,
        nonce:      nonce,
        ttl:        ttl,
        capability: capability
      )

      expect(actual_token).to eq(expected_token)
    end
  end
end
