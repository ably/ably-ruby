require "spec_helper"
require "securerandom"

describe "REST" do
  include Ably::Modules::Conversions

  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  let(:fixtures) do
    TestApp::APP_SPEC['channels'].first['presence'].map do |fixture|
      IdiomaticRubyWrapper(fixture, stop_at: [:client_data])
    end
  end

  describe "fetching presence" do
    let(:channel) { client.channel("persisted:presence_fixtures") }
    let(:presence) { channel.presence.get }

    it "should return current members on the channel" do
      expect(presence.size).to eql(4)

      fixtures.each do |fixture|
        presence_message = presence.find { |client| client[:client_id] == fixture[:client_id] }
        expect(presence_message[:client_data]).to eq(fixture[:client_data])
      end
    end
  end

  describe "presence history" do
    let(:channel) { client.channel("persisted:presence_fixtures") }
    let(:history) { channel.presence.history }

    it "should return recent presence activity" do
      expect(history.size).to eql(4)

      fixtures.each do |fixture|
        presence_message = history.find { |client| client[:client_id] == fixture['clientId'] }
        expect(presence_message[:client_data]).to eq(fixture[:client_data])
      end
    end
  end

  describe "options" do
    let(:channel_name) { "persisted:#{SecureRandom.hex(4)}" }
    let(:presence) { client.channel(channel_name).presence }
    let(:user) { 'appid.keyuid' }
    let(:secret) { SecureRandom.hex(8) }
    let(:endpoint) do
      client.endpoint.tap do |client_end_point|
        client_end_point.user = user
        client_end_point.password = secret
      end
    end
    let(:client) do
      Ably::Rest::Client.new(api_key: "#{user}:#{secret}")
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
