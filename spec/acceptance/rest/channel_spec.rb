# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Channel do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:client) do
      Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol)
    end

    describe '#publish' do
      let(:channel) { client.channel('test') }
      let(:event)   { 'foo' }
      let(:message) { 'woop!' }

      it 'should publish the message and return true indicating success' do
        expect(channel.publish(event, message)).to eql(true)
      end
    end

    describe '#history' do
      let(:channel) { client.channel("persisted:#{random_str(4)}") }
      let(:expected_history) do
        [
          { :name => 'test1', :data => 'foo' },
          { :name => 'test2', :data => 'bar' },
          { :name => 'test3', :data => 'baz' }
        ]
      end
      let!(:before_published) { client.time }

      before(:each) do
        expected_history.each do |message|
          channel.publish(message[:name], message[:data]) || raise('Unable to publish message')
        end
      end

      it 'should return the current message history for the channel' do
        actual_history_items = channel.history.items

        expect(actual_history_items.size).to eql(3)

        expected_history.each do |message|
          message_name, message_data = message[:name], message[:data]
          matching_message = actual_history_items.find { |message| message.name == message_name && message.data == message_data }
          expect(matching_message).to be_a(Ably::Models::Message)
        end
      end

      context 'message timestamps' do
        it 'should all be after the messages were published' do
          channel.history.items.each do |message|
            expect(before_published.to_f).to be < message.timestamp.to_f
          end
        end
      end

      context 'message IDs' do
        it 'should be unique' do
          message_ids = channel.history.items.map(&:id).compact
          expect(message_ids.count).to eql(3)
          expect(message_ids.uniq.count).to eql(3)
        end
      end

      it 'should return paged history using the PaginatedResource model' do
        page_1 = channel.history(limit: 1)
        page_2 = page_1.next
        page_3 = page_2.next

        all_items = [page_1.items[0].id, page_2.items[0].id, page_3.items[0].id]
        expect(all_items.uniq).to eql(all_items)

        expect(page_1.items.size).to eql(1)
        expect(page_1).to_not be_last
        expect(page_1).to be_first

        # Page 2
        expect(page_2.items.size).to eql(1)
        expect(page_2).to_not be_last
        expect(page_2).to_not be_first

        # Page 3
        expect(page_3.items.size).to eql(1)
        expect(page_3).to be_last
        expect(page_3).to_not be_first
      end
    end

    describe '#history option' do
      let(:channel_name) { "persisted:#{random_str(4)}" }
      let(:channel) { client.channel(channel_name) }
      let(:endpoint) do
        client.endpoint.tap do |client_end_point|
          client_end_point.user = key_id
          client_end_point.password = key_secret
        end
      end

      [:start, :end].each do |option|
        describe ":#{option}", :webmock do
          let!(:history_stub) {
            stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/messages?#{option}=#{milliseconds}").
              to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
          }

          before do
            channel.history(options)
          end

          context 'with milliseconds since epoch value' do
            let(:milliseconds) { as_since_epoch(Time.now) }
            let(:options) { { option => milliseconds } }

            it 'uses this value in the history request' do
              expect(history_stub).to have_been_requested
            end
          end

          context 'with a Time object value' do
            let(:time) { Time.now }
            let(:milliseconds) { as_since_epoch(time) }
            let(:options) { { option => time } }

            it 'converts the value to milliseconds since epoch in the hisotry request' do
              expect(history_stub).to have_been_requested
            end
          end
        end
      end
    end
  end
end
