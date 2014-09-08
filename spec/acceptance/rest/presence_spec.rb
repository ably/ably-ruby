require "spec_helper"
require "securerandom"

describe "REST" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "fetching presence" do
    let(:channel) { client.channel("persisted:presence_fixtures") }
    let(:presence) { channel.presence.get }

    it "should return current members on the channel" do
      expect(presence.size).to eql(4)

      TestApp::APP_SPEC['channels'].first['presence'].each do |presence_hash|
        presence_match = presence.find { |client| client['clientId'] == presence_hash['clientId'] }
        expect(presence_match['clientData']).to eql(presence_hash['clientData'])
      end
    end
  end
end
