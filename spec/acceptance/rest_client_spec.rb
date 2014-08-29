require "spec_helper"
require "securerandom"

describe "Using the Rest client" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "initializing the client" do
    it "should disallow an invalid key" do
      expect { Ably::Rest::Client.new({}) }.to raise_error(ArgumentError, /api_key is missing/)
      expect { Ably::Rest::Client.new(api_key: 'invalid') }.to raise_error(ArgumentError, /api_key is invalid/)
      expect { Ably::Rest::Client.new(api_key: 'invalid:asdad') }.to raise_error(ArgumentError, /api_key is invalid/)
      expect { Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret') }.to_not raise_error
    end

    it "should default to the production REST end point" do
      expect(Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret').endpoint.to_s).to eql('https://rest.ably.io')
    end

    it "should allow an environment to be set" do
      expect(Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret', environment: 'sandbox').endpoint.to_s).to eql('https://sandbox-rest.ably.io')
    end
  end

  describe "invalid requests" do
    it "should raise a InvalidRequest exception with a valid message" do
      invalid_client = Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret')
      expect { invalid_client.channel('test').publish('foo', 'choo') }.to raise_error(Ably::InvalidRequest, /invalid credentials/)
    end

    describe "server error with JSON response", webmock: true do
      let(:error_response) { '{ "error": { "statusCode": 500, "code": 50000, "message": "Internal error" } }' }

      before do
        stub_request(:get, "#{client.endpoint}/time").to_return(:status => 500, :body => error_response, :headers => { 'Content-Type' => 'application/json' })
      end

      it "should raise a ServerError exception" do
        expect { client.time }.to raise_error(Ably::ServerError, /Internal error/)
      end
    end

    describe "server error", webmock: true do
      before do
        stub_request(:get, "#{client.endpoint}/time").to_return(:status => 500)
      end

      it "should raise a ServerError exception" do
        expect { client.time }.to raise_error(Ably::ServerError, /Unknown/)
      end
    end
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
    let(:channel) { client.channel("persisted:#{SecureRandom.hex(4)}") }
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
    end

    it "should return all the history for the channel" do
      actual_history = channel.history

      expect(actual_history.size).to eql(3)

      expected_history.each do |message|
        expect(actual_history).to include(message)
      end
    end

    it "should return paged history" do
      page_1 = channel.history(limit: 1)
      page_2 = page_1.next
      page_3 = page_2.next

      all_items = [page_1[0], page_2[0], page_3[0]]
      expect(all_items.uniq).to eql(all_items)

      expect(page_1.size).to eql(1)
      expect(page_1).to_not be_last
      expect(page_1).to be_first

      # Page 2
      expect(page_2.size).to eql(1)
      expect(page_2).to_not be_last
      expect(page_2).to_not be_first

      # Page 3
      expect(page_3.size).to eql(1)
      expect(page_3).to be_last
      expect(page_3).to_not be_first
    end
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
