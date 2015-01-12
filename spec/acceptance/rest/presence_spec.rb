# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Presence do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:default_options) { { api_key: api_key, environment: environment, protocol: protocol } }
    let(:client_options) { default_options }
    let(:client) do
      Ably::Rest::Client.new(client_options)
    end

    let(:fixtures) do
      TestApp::APP_SPEC['channels'].first['presence'].map do |fixture|
        IdiomaticRubyWrapper(fixture, stop_at: [:data])
      end
    end

    describe '#get' do
      let(:channel) { client.channel('persisted:presence_fixtures') }
      let(:presence) { channel.presence.get }

      it 'returns current members on the channel with their action set to :present' do
        expect(presence.size).to eql(4)

        fixtures.each do |fixture|
          presence_message = presence.find { |client| client.client_id == fixture[:client_id] }
          expect(presence_message.data).to eq(fixture[:data])
          expect(presence_message.action).to eq(:present)
        end
      end

      context 'with :limit option' do
        let(:page_size) { 2 }
        let(:presence)  { channel.presence.get(limit: page_size) }

        it 'returns a paged response limiting number of members per page' do
          expect(presence.size).to eql(2)
          next_page = presence.next_page
          expect(next_page.size).to eql(2)
          expect(next_page).to be_last_page
        end
      end
    end

    describe '#history' do
      let(:channel) { client.channel('persisted:presence_fixtures') }
      let(:presence_history) { channel.presence.history }

      it 'returns recent presence activity' do
        expect(presence_history.size).to eql(4)

        fixtures.each do |fixture|
          presence_message = presence_history.find { |client| client.client_id == fixture['clientId'] }
          expect(presence_message.data).to eq(fixture[:data])
        end
      end

      context 'with options' do
        let(:page_size) { 2 }

        context 'direction: :forwards' do
          let(:presence_history) { channel.presence.history(direction: :forwards) }
          let(:paged_history_forward) { channel.presence.history(limit: page_size, direction: :forwards) }

          it 'returns recent presence activity forwards with most recent history last' do
            expect(paged_history_forward).to be_a(Ably::Models::PaginatedResource)
            expect(paged_history_forward.size).to eql(2)

            next_page = paged_history_forward.next_page

            expect(paged_history_forward.first.id).to eql(presence_history.first.id)
            expect(next_page.first.id).to eql(presence_history[page_size].id)
          end
        end

        context 'direction: :backwards' do
          let(:presence_history) { channel.presence.history(direction: :backwards) }
          let(:paged_history_backward) { channel.presence.history(limit: page_size, direction: :backwards) }

          it 'returns recent presence activity backwards with most recent history first' do
            expect(paged_history_backward).to be_a(Ably::Models::PaginatedResource)
            expect(paged_history_backward.size).to eql(2)

            next_page = paged_history_backward.next_page

            expect(paged_history_backward.first.id).to eql(presence_history.first.id)
            expect(next_page.first.id).to eql(presence_history[page_size].id)
          end
        end

        describe 'time options' do
          let(:channel_name) { "persisted:#{random_str(4)}" }
          let(:presence) { client.channel(channel_name).presence }
          let(:user) { 'appid.keyuid' }
          let(:secret) { random_str(8) }
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
            describe ":#{option}", :webmock do
              let!(:history_stub) {
                stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history?#{option}=#{milliseconds}").
                  to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
              }

              before do
                presence.history(options)
              end

              context 'with milliseconds since epoch value' do
                let(:milliseconds) { as_since_epoch(Time.now) }
                let(:options) { { option => milliseconds } }

                it 'uses this value in the history request' do
                  expect(history_stub).to have_been_requested
                end
              end

              context 'with Time object value' do
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

    describe 'decoding', :webmock do
      let(:user) { 'appid.keyuid' }
      let(:secret) { random_str(8) }
      let(:endpoint) do
        client.endpoint.tap do |client_end_point|
          client_end_point.user = user
          client_end_point.password = secret
        end
      end
      let(:client) do
        Ably::Rest::Client.new(client_options.merge(api_key: "#{user}:#{secret}"))
      end

      let(:data)            { random_str(32) }
      let(:channel_name)    { "persisted:#{random_str(4)}" }
      let(:cipher_options)  { { key: random_str(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
      let(:presence)        { client.channel(channel_name, encrypted: true, cipher_params: cipher_options).presence }

      let(:crypto)          { Ably::Util::Crypto.new(cipher_options) }

      let(:content_type) do
        if protocol == :msgpack
          'application/x-msgpack'
        else
          'application/json'
        end
      end

      context 'valid decodeable content' do
        let(:serialized_encoded_message) do
          if protocol == :msgpack
            msg = Ably::Models::PresenceMessage.new({ action: :enter, data: crypto.encrypt(data), encoding: 'utf-8/cipher+aes-256-cbc' })
            MessagePack.pack([msg.as_json])
          else
            msg = Ably::Models::PresenceMessage.new({ action: :enter, data: Base64.encode64(crypto.encrypt(data)), encoding: 'utf-8/cipher+aes-256-cbc/base64' })
            [msg].to_json
          end
        end

        context '#get' do
          let!(:get_stub)   {
            stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence").
              to_return(:body => serialized_encoded_message, :headers => { 'Content-Type' => content_type })
          }

          after do
            expect(get_stub).to have_been_requested
          end

          it 'automaticaly decodes presence messages' do
            present = presence.get
            expect(present.first.encoding).to be_nil
            expect(present.first.data).to eql(data)
          end
        end

        context '#history' do
          let!(:history_stub)   {
            stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history").
              to_return(:body => serialized_encoded_message, :headers => { 'Content-Type' => content_type })
          }

          after do
            expect(history_stub).to have_been_requested
          end

          it 'automaticaly decodes presence messages' do
            history = presence.history
            expect(history.first.encoding).to be_nil
            expect(history.first.data).to eql(data)
          end
        end
      end

      context 'invalid data' do
        let(:serialized_encoded_message_with_invalid_encoding) do
          if protocol == :msgpack
            msg = Ably::Models::PresenceMessage.new({ action: :enter, data: crypto.encrypt(data), encoding: 'utf-8/cipher+aes-128-cbc' })
            MessagePack.pack([msg.as_json])
          else
            msg = Ably::Models::PresenceMessage.new({ action: :enter, data: Base64.encode64(crypto.encrypt(data)), encoding: 'utf-8/cipher+aes-128-cbc/base64' })
            [msg].to_json
          end
        end

        context '#get' do
          let(:client_options) { default_options.merge(log_level: :fatal) }
          let!(:get_stub)   {
            stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence").
              to_return(:body => serialized_encoded_message_with_invalid_encoding, :headers => { 'Content-Type' => content_type })
          }
          let(:presence_message) { presence.get.first }

          after do
            expect(get_stub).to have_been_requested
          end

          it 'returns the messages still encoded' do
            expect(presence_message.encoding).to match(/cipher\+aes-128-cbc/)
          end

          it 'logs a cipher error' do
            expect(client.logger).to receive(:error) do |message|
              expect(message).to match(/Cipher algorithm [\w-]+ does not match/)
            end
            presence.get
          end
        end

        context '#history' do
          let(:client_options) { default_options.merge(log_level: :fatal) }
          let!(:history_stub)   {
            stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history").
              to_return(:body => serialized_encoded_message_with_invalid_encoding, :headers => { 'Content-Type' => content_type })
          }
          let(:presence_message) { presence.history.first }

          after do
            expect(history_stub).to have_been_requested
          end

          it 'returns the messages still encoded' do
            expect(presence_message.encoding).to match(/cipher\+aes-128-cbc/)
          end

          it 'logs a cipher error' do
            expect(client.logger).to receive(:error) do |message|
              expect(message).to match(/Cipher algorithm [\w-]+ does not match/)
            end
            presence.history
          end
        end
      end
    end
  end
end
