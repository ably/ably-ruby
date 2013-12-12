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
end
