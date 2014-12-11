# encoding: utf-8
require 'spec_helper'
require 'securerandom'

describe Ably::Rest::Presence do
  include Ably::Modules::Conversions

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:client) do
        Ably::Rest::Client.new(api_key: api_key, environment: environment, protocol: protocol)
      end

      let(:fixtures) do
        TestApp::APP_SPEC['channels'].first['presence'].map do |fixture|
          IdiomaticRubyWrapper(fixture, stop_at: [:data])
        end
      end

      describe '#get presence' do
        let(:channel) { client.channel('persisted:presence_fixtures') }
        let(:presence) { channel.presence.get }

        it 'returns current members on the channel' do
          expect(presence.size).to eql(4)

          fixtures.each do |fixture|
            presence_message = presence.find { |client| client.client_id == fixture[:client_id] }
            expect(presence_message.data).to eq(fixture[:data])
          end
        end

        skip 'with options'
      end

      describe 'presence #history' do
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

          context 'forwards' do
            let(:presence_history) { channel.presence.history(direction: :forwards) }
            let(:paged_history_forward) { channel.presence.history(limit: page_size, direction: :forwards) }

            it 'returns recent presence activity with options passed to Ably' do
              expect(paged_history_forward).to be_a(Ably::Models::PaginatedResource)
              expect(paged_history_forward.size).to eql(2)

              next_page = paged_history_forward.next_page

              expect(paged_history_forward.first.id).to eql(presence_history.first.id)
              expect(next_page.first.id).to eql(presence_history[page_size].id)
            end
          end

          context 'backwards' do
            let(:presence_history) { channel.presence.history(direction: :backwards) }
            let(:paged_history_backward) { channel.presence.history(limit: page_size, direction: :backwards) }

            it 'returns recent presence activity with options passed to Ably' do
              expect(paged_history_backward).to be_a(Ably::Models::PaginatedResource)
              expect(paged_history_backward.size).to eql(2)

              next_page = paged_history_backward.next_page

              expect(paged_history_backward.first.id).to eql(presence_history.first.id)
              expect(next_page.first.id).to eql(presence_history[page_size].id)
            end
          end
        end
      end

      describe 'options' do
        let(:channel_name) { "persisted:#{SecureRandom.hex(4)}".force_encoding(Encoding::UTF_8) }
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
              stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history?live=true&#{option}=#{milliseconds}").
                to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
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

      describe 'decoding', webmock: true do
        let(:user) { 'appid.keyuid' }
        let(:secret) { SecureRandom.hex(8) }
        let(:endpoint) do
          client.endpoint.tap do |client_end_point|
            client_end_point.user = user
            client_end_point.password = secret
          end
        end
        let(:client) do
          Ably::Rest::Client.new(api_key: "#{user}:#{secret}", environment: environment, protocol: protocol)
        end

        let(:data)            { SecureRandom.hex(32) }
        let(:channel_name)    { "persisted:#{SecureRandom.hex(4)}".force_encoding(Encoding::UTF_8) }
        let(:cipher_options)  { { key: SecureRandom.hex(32), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
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
              stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history?live=true").
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
            let!(:get_stub)   {
              stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence").
                to_return(:body => serialized_encoded_message_with_invalid_encoding, :headers => { 'Content-Type' => content_type })
            }

            after do
              expect(get_stub).to have_been_requested
            end

            it 'raises a cipher error' do
              expect { presence.get }.to raise_error Ably::Exceptions::CipherError
            end
          end

          context '#history' do
            let!(:history_stub)   {
              stub_request(:get, "#{endpoint}/channels/#{CGI.escape(channel_name)}/presence/history?live=true").
                to_return(:body => serialized_encoded_message_with_invalid_encoding, :headers => { 'Content-Type' => content_type })
            }

            after do
              expect(history_stub).to have_been_requested
            end

            it 'raises a cipher error' do
              expect { presence.history }.to raise_error Ably::Exceptions::CipherError
            end
          end
        end
      end
    end
  end
end
