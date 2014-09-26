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

  describe "options" do
    let(:channel_name) { "persisted:#{SecureRandom.hex(4)}" }
    let(:presence) { client.channel(channel_name).presence }
    let(:endpoint) do
      client.endpoint.tap do |client_end_point|
        client_end_point.user = key_id
        client_end_point.password = key_secret
      end
    end

    [:start, :end].each do |option|
      describe ":{option}", webmock: true do
        let!(:history_stub) {
          stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history?live=true&#{option}=#{milliseconds}").to_return(:body => '{}')
        }

        before do
          presence.history(options)
        end

        context 'with milliseconds since epoch' do
          let(:milliseconds) { as_since_epoch(Time.now) }
          let(:options) { { option => milliseconds } }

          specify 'are left unchanged' do
            expect(history_stub).to have_been_requested
          end
        end

        context 'with Time' do
          let(:time) { Time.now }
          let(:milliseconds) { as_since_epoch(time) }
          let(:options) { { option => time } }

          specify 'are left unchanged' do
            expect(history_stub).to have_been_requested
          end
        end
      end
    end
  end
end
