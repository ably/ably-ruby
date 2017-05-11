# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Presence do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol } }
    let(:client_options) { default_options }
    let(:client) do
      Ably::Rest::Client.new(client_options)
    end

    let(:fixtures) do
      TestApp::APP_SPEC['channels'].first['presence'].map do |fixture|
        IdiomaticRubyWrapper(fixture, stop_at: [:data])
      end
    end
    let(:non_encoded_fixtures) { fixtures.reject { |fixture| fixture['encoding'] } }

    # Encrypted fixtures need encryption details or an error will be raised
    let(:cipher_details)   { TestApp::APP_SPEC_CIPHER }
    let(:algorithm)        { cipher_details.fetch('algorithm').upcase }
    let(:mode)             { cipher_details.fetch('mode').upcase }
    let(:key_length)       { cipher_details.fetch('keylength') }
    let(:secret_key)       { Base64.decode64(cipher_details.fetch('key')) }
    let(:iv)               { Base64.decode64(cipher_details.fetch('iv')) }

    let(:cipher_options)   { { key: secret_key, algorithm: algorithm, mode: mode, key_length: key_length, fixed_iv: iv } }
    let(:fixtures_channel) { client.channel('persisted:presence_fixtures', cipher: cipher_options, fixed_iv: iv) }

    context 'tested against presence fixture data set up in test app' do
      before(:context) do
        # When this test is run as a part of a test suite, the presence data injected in the test app may have expired
        reload_test_app
      end

      describe '#get' do
        let(:presence_page) { fixtures_channel.presence.get }

        it 'returns current members on the channel with their action set to :present' do
          expect(presence_page).to be_a(Ably::Models::PaginatedResult)
          expect(presence_page.items.size).to eql(fixtures.count)

          non_encoded_fixtures.each do |fixture|
            presence_message = presence_page.items.find { |client| client.client_id == fixture[:client_id] }
            expect(presence_message).to be_a(Ably::Models::PresenceMessage)
            expect(presence_message.data).to eq(fixture[:data])
            expect(presence_message.action).to eq(:present)
          end
        end

        context 'with :limit option' do
          let(:page_size) { 3 }
          let(:presence_page)  { fixtures_channel.presence.get(limit: page_size) }

          it 'returns a paged response limiting number of members per page' do
            expect(presence_page.items.size).to eql(page_size)
            next_page = presence_page.next
            expect(next_page.items.size).to eql(page_size)
            expect(next_page).to be_last
          end
        end

        context 'default :limit', webmock: true do
          let(:query_options) do
            {
              limit: 100
            }
          end
          let(:endpoint) do
            client.endpoint
          end
          let!(:get_stub) {
            query_params = query_options.map { |k, v| "#{k}=#{v}" }.join('&')
            stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence?#{query_params}").
              to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
          }
          let(:channel_name) { random_str }
          let(:channel)      { client.channels.get(channel_name) }

          before do
            channel.presence.get
          end

          it 'defaults to a limit of 100' do
            expect(get_stub).to have_been_requested
          end
        end

        context 'with :client_id option' do
          let(:client_id) { non_encoded_fixtures.first[:client_id] }
          let(:presence_page) { fixtures_channel.presence.get(client_id: client_id) }

          it 'returns a list members filtered by the provided client ID' do
            expect(presence_page.items.count).to eql(1)
            expect(presence_page.items.first.client_id).to eql(client_id)
          end
        end

        context 'with :connection_id option' do
          let(:all_members)   { fixtures_channel.presence.get.items }
          let(:connection_id) { all_members.first.connection_id }
          let(:presence_page) { fixtures_channel.presence.get(connection_id: connection_id) }

          it 'returns a list members filtered by the provided connection ID' do
            expect(presence_page.items.all? { |member| member.connection_id == connection_id }).to eql(true)
          end

          it 'returns a list members filtered by the provided connection ID' do
            expect(fixtures_channel.presence.get(connection_id: 'does.not.exist').items).to be_empty
          end
        end

        context 'with a non ASCII channel name' do
          let(:channel_name) { 'foo:¡€≤`☃' }
          let(:channel_name_encoded) { 'foo%3A%C2%A1%E2%82%AC%E2%89%A4%60%E2%98%83' }
          let(:endpoint) { client.endpoint }
          let(:channel) { client.channels.get(channel_name) }

          context 'stubbed', :webmock do
            let!(:get_stub) {
              stub_request(:get, "#{endpoint}/channels/#{channel_name_encoded}/presence?limit=100").
                to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
            }

            it 'correctly encodes the channel name' do
              channel.presence.get
              expect(get_stub).to have_been_requested
            end
          end
        end
      end

      describe '#history' do
        let(:history_page) { fixtures_channel.presence.history }

        it 'returns recent presence activity' do
          expect(history_page).to be_a(Ably::Models::PaginatedResult)
          expect(history_page.items.size).to eql(fixtures.count)

          non_encoded_fixtures.each do |fixture|
            presence_message = history_page.items.find { |client| client.client_id == fixture['clientId'] }
            expect(presence_message).to be_a(Ably::Models::PresenceMessage)
            expect(presence_message.data).to eq(fixture[:data])
          end
        end

        context 'default behaviour' do
          let(:default_page)   { fixtures_channel.presence.history }
          let(:backwards_page) { fixtures_channel.presence.history(direction: :backwards) }

          it 'uses backwards direction' do
            expect(default_page.items).to eq(backwards_page.items)
          end
        end

        context 'with options' do
          let(:page_size) { 3 }

          context 'direction: :forwards' do
            let(:history_page) { fixtures_channel.presence.history(direction: :forwards) }
            let(:paged_history_forward) { fixtures_channel.presence.history(limit: page_size, direction: :forwards) }

            it 'returns recent presence activity forwards with most recent history last' do
              expect(paged_history_forward).to be_a(Ably::Models::PaginatedResult)
              expect(paged_history_forward.items.size).to eql(page_size)

              next_page = paged_history_forward.next

              expect(paged_history_forward.items.first.id).to eql(history_page.items.first.id)
              expect(next_page.items.first.id).to eql(history_page.items[page_size].id)
            end
          end

          context 'direction: :backwards' do
            let(:history_page) { fixtures_channel.presence.history(direction: :backwards) }
            let(:paged_history_backward) { fixtures_channel.presence.history(limit: page_size, direction: :backwards) }

            it 'returns recent presence activity backwards with most recent history first' do
              expect(paged_history_backward).to be_a(Ably::Models::PaginatedResult)
              expect(paged_history_backward.items.size).to eql(page_size)

              next_page = paged_history_backward.next

              expect(paged_history_backward.items.first.id).to eql(history_page.items.first.id)
              expect(next_page.items.first.id).to eql(history_page.items[page_size].id)
            end
          end
        end
      end
    end

    describe '#history' do
      context 'with options' do
        let(:channel_name) { "persisted:#{random_str(4)}" }
        let(:presence) { client.channel(channel_name).presence }
        let(:user) { 'appid.keyuid' }
        let(:secret) { random_str(8) }
        let(:endpoint) do
          client.endpoint
        end
        let(:client) do
          Ably::Rest::Client.new(key: "#{user}:#{secret}")
        end
        let(:history_options) do
          {
            direction: :backwards,
            limit: 100
          }
        end

        context 'limit options', :webmock do
          let!(:history_stub) {
            query_params = history_options.map { |k, v| "#{k}=#{v}" }.join('&')
            stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence/history?#{query_params}").
              to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
          }

          before do
            presence.history(history_options)
          end

          context 'default' do
            it 'is set to 100' do
              expect(history_stub).to have_been_requested
            end
          end

          context 'set to 1000' do
            let(:history_options) do
              {
                direction: :backwards,
                limit: 1000
              }
            end

            it 'is passes the limit query param value 1000' do
              expect(history_stub).to have_been_requested
            end
          end
        end

        context 'with time range options' do
          [:start, :end].each do |option|
            describe ":#{option}", :webmock do
              let(:history_options) {
                {
                  direction: :backwards,
                  limit: 100,
                  option => milliseconds
                }
              }
              let!(:history_stub) {
                query_params = history_options.map { |k, v| "#{k}=#{v}" }.join('&')
                stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence/history?#{query_params}").
                  to_return(:body => '{}', :headers => { 'Content-Type' => 'application/json' })
              }

              before do
                presence.history(history_options)
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

          context 'when argument start is after end' do
            let(:presence) { client.channel(random_str).presence }
            let(:subject) { presence.history(start: as_since_epoch(Time.now), end: Time.now - 120) }

            it 'should raise an exception' do
              expect { subject.items }.to raise_error ArgumentError
            end
          end
        end
      end
    end

    describe 'decoding' do
      context 'with encoded fixture data' do
        let(:decoded_client_id) { 'client_decoded' }
        let(:encoded_client_id) { 'client_encoded' }

        def message(client_id, messages)
          messages.items.find { |message| message.client_id == client_id }
        end

        describe '#history' do
          let(:history) { fixtures_channel.presence.history }
          it 'decodes encoded and encryped presence fixture data automatically' do
            expect(message(decoded_client_id, history).data).to eql(message(encoded_client_id, history).data)
          end
        end

        describe '#get' do
          let(:present) { fixtures_channel.presence.get }
          it 'decodes encoded and encryped presence fixture data automatically' do
            expect(message(decoded_client_id, present).data).to eql(message(encoded_client_id, present).data)
          end
        end
      end
    end

    describe 'decoding permutations using mocked #history', :webmock do
      let(:user) { 'appid.keyuid' }
      let(:secret) { random_str(8) }
      let(:endpoint) do
        client.endpoint
      end
      let(:client) do
        Ably::Rest::Client.new(client_options.merge(key: "#{user}:#{secret}"))
      end

      let(:data)            { random_str(32) }
      let(:channel_name)    { "persisted:#{random_str(4)}" }
      let(:cipher_options)  { { key: Ably::Util::Crypto.generate_random_key(256), algorithm: 'aes', mode: 'cbc', key_length: 256 } }
      let(:presence)        { client.channel(channel_name, cipher: cipher_options).presence }

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
            stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence?limit=100").
              to_return(:body => serialized_encoded_message, :headers => { 'Content-Type' => content_type })
          }

          after do
            expect(get_stub).to have_been_requested
          end

          it 'automaticaly decodes presence messages' do
            present_page = presence.get
            expect(present_page.items.first.encoding).to be_nil
            expect(present_page.items.first.data).to eql(data)
          end
        end

        context '#history' do
          let!(:history_stub)   {
            stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence/history?direction=backwards&limit=100").
              to_return(:body => serialized_encoded_message, :headers => { 'Content-Type' => content_type })
          }

          after do
            expect(history_stub).to have_been_requested
          end

          it 'automaticaly decodes presence messages' do
            history_page = presence.history
            expect(history_page.items.first.encoding).to be_nil
            expect(history_page.items.first.data).to eql(data)
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
            stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence?limit=100").
              to_return(:body => serialized_encoded_message_with_invalid_encoding, :headers => { 'Content-Type' => content_type })
          }
          let(:presence_message) { presence.get.items.first }

          after do
            expect(get_stub).to have_been_requested
          end

          it 'returns the messages still encoded' do
            expect(presence_message.encoding).to match(/cipher\+aes-128-cbc/)
          end

          it 'logs a cipher error' do
            expect(client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Cipher algorithm [\w-]+ does not match/)
            end
            presence.get
          end
        end

        context '#history' do
          let(:client_options) { default_options.merge(log_level: :fatal) }
          let!(:history_stub)   {
            stub_request(:get, "#{endpoint}/channels/#{URI.encode_www_form_component(channel_name)}/presence/history?direction=backwards&limit=100").
              to_return(:body => serialized_encoded_message_with_invalid_encoding, :headers => { 'Content-Type' => content_type })
          }
          let(:presence_message) { presence.history.items.first }

          after do
            expect(history_stub).to have_been_requested
          end

          it 'returns the messages still encoded' do
            expect(presence_message.encoding).to match(/cipher\+aes-128-cbc/)
          end

          it 'logs a cipher error' do
            expect(client.logger).to receive(:error) do |*args, &block|
              expect(args.concat([block ? block.call : nil]).join(',')).to match(/Cipher algorithm [\w-]+ does not match/)
            end
            presence.history
          end
        end
      end
    end
  end
end
