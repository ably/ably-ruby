require "spec_helper"
require "securerandom"

describe "REST" do
  include Ably::Modules::Conversions

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
        expect(actual_history).to include(Ably::Models::Message.new(message))
        expect(actual_history.map(&:json)).to include(message)
      end
    end

    it "should return paged history" do
      page_1 = channel.history(limit: 1)
      page_2 = page_1.next_page
      page_3 = page_2.next_page

      all_items = [page_1[0], page_2[0], page_3[0]]
      expect(all_items.uniq).to eql(all_items)

      expect(page_1.size).to eql(1)
      expect(page_1).to_not be_last_page
      expect(page_1).to be_first_page

      # Page 2
      expect(page_2.size).to eql(1)
      expect(page_2).to_not be_last_page
      expect(page_2).to_not be_first_page

      # Page 3
      expect(page_3.size).to eql(1)
      expect(page_3).to be_last_page
      expect(page_3).to_not be_first_page
    end
  end

  describe "options" do
    let(:channel_name) { "persisted:#{SecureRandom.hex(4)}" }
    let(:channel) { client.channel(channel_name) }
    let(:endpoint) do
      client.endpoint.tap do |client_end_point|
        client_end_point.user = key_id
        client_end_point.password = key_secret
      end
    end

    [:start, :end].each do |option|
      describe ":{option}", webmock: true do
        let!(:history_stub) {
          stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/messages?live=true&#{option}=#{milliseconds}").to_return(:body => '{}')
        }

        before do
          channel.history(options)
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
