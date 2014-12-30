# encoding: utf-8
require 'spec_helper'

describe 'Ably::Realtime::Presence Messages' do
  include RSpec::EventMachine

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) { { api_key: api_key, environment: environment, protocol: protocol } }

      let(:channel_name) { "presence-#{random_str(2)}" }

      let(:anonymous_client) { Ably::Realtime::Client.new(default_options) }
      let(:client_one)       { Ably::Realtime::Client.new(default_options.merge(client_id: random_str)) }
      let(:client_two)       { Ably::Realtime::Client.new(default_options.merge(client_id: random_str)) }

      let(:channel_anonymous_client)  { anonymous_client.channel(channel_name) }
      let(:presence_anonymous_client) { channel_anonymous_client.presence }
      let(:channel_client_one)        { client_one.channel(channel_name) }
      let(:channel_rest_client_one)   { client_one.rest_client.channel(channel_name) }
      let(:presence_client_one)       { channel_client_one.presence }
      let(:channel_client_two)        { client_two.channel(channel_name) }
      let(:presence_client_two)       { channel_client_two.presence }

      let(:data_payload) { random_str }

      specify 'an attached channel that is not presence maintains presence state' do
        run_reactor do
          channel_anonymous_client.attach do
            presence_anonymous_client.subscribe(:enter) do |presence_message|
              expect(presence_message.client_id).to eql(client_one.client_id)
              members = presence_anonymous_client.get
              expect(members.first.client_id).to eql(client_one.client_id)
              expect(members.first.action).to eq(:enter)

              presence_anonymous_client.subscribe(:leave) do |presence_message|
                expect(presence_message.client_id).to eql(client_one.client_id)
                members = presence_anonymous_client.get
                expect(members.count).to eql(0)

                stop_reactor
              end
            end
          end

          presence_client_one.enter do
            presence_client_one.leave
          end
        end
      end

      context 'automatic channel attach on access to presence object' do
        it 'is implicit if presence state is initalized' do
          run_reactor do
            channel_client_one.presence
            channel_client_one.on(:attached) do
              expect(channel_client_one.state).to eq(:attached)
              stop_reactor
            end
          end
        end

        it 'is disabled if presence state is not initalized' do
          run_reactor do
            channel_client_one.presence
            channel_client_one.on(:attached) do
              channel_client_one.detach do
                expect(channel_client_one.state).to eq(:detached)
                channel_client_one.presence # access the presence object
                EventMachine.add_timer(1) do
                  expect(channel_client_one.state).to eq(:detached)
                  stop_reactor
                end
              end
            end
          end
        end
      end

      it '#enter allows client_id to be set on enter for anonymous clients' do
        run_reactor do
          channel_anonymous_client.presence.enter client_id: "123"

          channel_anonymous_client.presence.subscribe do |presence|
            expect(presence.client_id).to eq("123")
            stop_reactor
          end
        end
      end

      it 'enters and then leaves' do
        leave_callback_called = false
        run_reactor do
          presence_client_one.enter do
            presence_client_one.leave do |presence|
              leave_callback_called = true
            end
            presence_client_one.on(:left) do
              EventMachine.next_tick do
                expect(leave_callback_called).to eql(true)
                stop_reactor
              end
            end
          end
        end
      end

      it 'enters the :left state if the channel detaches' do
        detached = false
        run_reactor do
          channel_client_one.presence.on(:left) do
            expect(channel_client_one.presence.state).to eq(:left)
            EventMachine.next_tick do
              expect(detached).to eq(true)
              stop_reactor
            end
          end
          channel_client_one.presence.enter do |presence|
            expect(presence.state).to eq(:entered)
            channel_client_one.detach do
              expect(channel_client_one.state).to eq(:detached)
              detached = true
            end
          end
        end
      end

      specify '#get returns the current member on the channel' do
        run_reactor do
          presence_client_one.enter do
            members = presence_client_one.get
            expect(members.count).to eq(1)

            expect(client_one.client_id).to_not be_nil

            this_member = members.first
            expect(this_member.client_id).to eql(client_one.client_id)

            stop_reactor
          end
        end
      end

      specify '#get returns no members on the channel following an enter and leave' do
        run_reactor do
          presence_client_one.enter do
            presence_client_one.leave do
              expect(presence_client_one.get).to eq([])
              stop_reactor
            end
          end
        end
      end

      specify 'verify two clients appear in members from #get' do
        run_reactor do
          presence_client_one.enter(data: data_payload)
          presence_client_two.enter

          entered_callback = Proc.new do
            next unless presence_client_one.state == :entered && presence_client_two.state == :entered

            EventMachine.add_timer(0.25) do
              expect(presence_client_one.get.count).to eq(presence_client_two.get.count)

              members = presence_client_one.get
              member_client_one = members.find { |presence| presence.client_id == client_one.client_id }
              member_client_two = members.find { |presence| presence.client_id == client_two.client_id }

              expect(member_client_one).to be_a(Ably::Models::PresenceMessage)
              expect(member_client_one.data).to eql(data_payload)
              expect(member_client_two).to be_a(Ably::Models::PresenceMessage)

              stop_reactor
            end
          end

          presence_client_one.on :entered, &entered_callback
          presence_client_two.on :entered, &entered_callback
        end
      end

      specify '#subscribe and #unsubscribe to presence events' do
        run_reactor do
          client_two_subscribe_messages = []

          subscribe_client_one_leaving_callback = Proc.new do |presence_message|
            expect(presence_message.client_id).to eql(client_one.client_id)
            expect(presence_message.data).to eql(data_payload)
            expect(presence_message.action).to eq(:leave)

            stop_reactor
          end

          subscribe_self_callback = Proc.new do |presence_message|
            if presence_message.client_id == client_two.client_id
              expect(presence_message.action).to eq(:enter)

              presence_client_two.unsubscribe &subscribe_self_callback
              presence_client_two.subscribe &subscribe_client_one_leaving_callback

              presence_client_one.leave data: data_payload
            end
          end

          presence_client_one.enter do
            presence_client_two.enter
            presence_client_two.subscribe &subscribe_self_callback
          end
        end
      end

      specify 'REST #get returns current members' do
        run_reactor do
          presence_client_one.enter(data: data_payload) do
            members = channel_rest_client_one.presence.get
            this_member = members.first

            expect(this_member).to be_a(Ably::Models::PresenceMessage)
            expect(this_member.client_id).to eql(client_one.client_id)
            expect(this_member.data).to eql(data_payload)

            stop_reactor
          end
        end
      end

      specify 'REST #get returns no members once left' do
        run_reactor do
          presence_client_one.enter(data: data_payload) do
            presence_client_one.leave do
              members = channel_rest_client_one.presence.get
              expect(members.count).to eql(0)
              stop_reactor
            end
          end
        end
      end

      context 'with ASCII_8BIT client_id' do
        let(:client_id)   { random_str.encode(Encoding::ASCII_8BIT) }

        context 'in connection set up' do
          let(:client_one)  { Ably::Realtime::Client.new(default_options.merge(client_id: client_id)) }

          it 'is converted into UTF_8' do
            run_reactor do
              presence_client_one.enter
              presence_client_one.on(:entered) do |presence|
                expect(presence.client_id.encoding).to eql(Encoding::UTF_8)
                expect(presence.client_id.encode(Encoding::ASCII_8BIT)).to eql(client_id)
                stop_reactor
              end
            end
          end
        end

        context 'in channel options' do
          let(:client_one)  { Ably::Realtime::Client.new(default_options) }

          it 'is converted into UTF_8' do
            run_reactor do
              presence_client_one.enter(client_id: client_id)
              presence_client_one.on(:entered) do |presence|
                expect(presence.client_id.encoding).to eql(Encoding::UTF_8)
                expect(presence.client_id.encode(Encoding::ASCII_8BIT)).to eql(client_id)
                stop_reactor
              end
            end
          end
        end
      end

      context 'encoding and decoding of presence message data' do
        let(:secret_key)              { random_str }
        let(:cipher_options)          { { key: secret_key, algorithm: 'aes', mode: 'cbc', key_length: 256 } }
        let(:channel_name)            { random_str }
        let(:encrypted_channel)       { client_one.channel(channel_name, encrypted: true, cipher_params: cipher_options) }
        let(:channel_rest_client_one) { client_one.rest_client.channel(channel_name, encrypted: true, cipher_params: cipher_options) }

        let(:crypto)                  { Ably::Util::Crypto.new(cipher_options) }

        let(:data)                    { { 'key' => random_str } }
        let(:data_as_json)            { data.to_json }
        let(:data_as_cipher)          { crypto.encrypt(data.to_json) }

        it 'encrypts presence message data' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter data: data
            end

            encrypted_channel.presence.__incoming_msgbus__.unsubscribe(:presence) # remove all subscribe callbacks that could decrypt the message
            encrypted_channel.presence.__incoming_msgbus__.subscribe(:presence) do |presence|
              if protocol == :json
                expect(presence['encoding']).to eql('json/utf-8/cipher+aes-256-cbc/base64')
                expect(crypto.decrypt(Base64.decode64(presence['data']))).to eql(data_as_json)
              else
                expect(presence['encoding']).to eql('json/utf-8/cipher+aes-256-cbc')
                expect(crypto.decrypt(presence['data'])).to eql(data_as_json)
              end
              stop_reactor
            end
          end
        end

        it '#subscribe emits decrypted enter events' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter data: data
            end

            encrypted_channel.presence.subscribe(:enter) do |presence_message|
              expect(presence_message.encoding).to be_nil
              expect(presence_message.data).to eql(data)
              stop_reactor
            end
          end
        end

        it '#subscribe emits decrypted update events' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter(data: 'to be updated') do
                encrypted_channel.presence.update data: data
              end
            end

            encrypted_channel.presence.subscribe(:update) do |presence_message|
              expect(presence_message.encoding).to be_nil
              expect(presence_message.data).to eql(data)
              stop_reactor
            end
          end
        end

        it '#subscribe emits decrypted leave events' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter(data: 'to be updated') do
                encrypted_channel.presence.leave data: data
              end
            end

            encrypted_channel.presence.subscribe(:leave) do |presence_message|
              expect(presence_message.encoding).to be_nil
              expect(presence_message.data).to eql(data)
              stop_reactor
            end
          end
        end

        it '#get returns a list of members with decrypted data' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter(data: data) do
                member = encrypted_channel.presence.get.first
                expect(member.encoding).to be_nil
                expect(member.data).to eql(data)
                stop_reactor
              end
            end
          end
        end

        it 'REST #get returns a list of members with decrypted data' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter(data: data) do
                member = channel_rest_client_one.presence.get.first
                expect(member.encoding).to be_nil
                expect(member.data).to eql(data)
                stop_reactor
              end
            end
          end
        end

        context 'when cipher settings do not match publisher' do
          let(:incompatible_cipher_options)    { { key: secret_key, algorithm: 'aes', mode: 'cbc', key_length: 128 } }
          let(:incompatible_encrypted_channel) { client_two.channel(channel_name, encrypted: true, cipher_params: incompatible_cipher_options) }

          it 'delivers an unencoded presence message left with encoding value' do
            run_reactor do
              incompatible_encrypted_channel.attach do
                encrypted_channel.attach do
                  encrypted_channel.presence.enter(data: data) do
                    member = incompatible_encrypted_channel.presence.get.first
                    expect(member.encoding).to match(/cipher\+aes-256-cbc/)
                    expect(member.data).to_not eql(data)
                    stop_reactor
                  end
                end
              end
            end
          end

          it 'emits an error when cipher does not match and presence data cannot be decoded' do
            run_reactor do
              incompatible_encrypted_channel.attach do
                incompatible_encrypted_channel.on(:error) do |error|
                  expect(error).to be_a(Ably::Exceptions::CipherError)
                  expect(error.message).to match(/Cipher algorithm AES-128-CBC does not match/)
                  stop_reactor
                end

                encrypted_channel.attach do
                  encrypted_channel.presence.enter data: data
                end
              end
            end
          end
        end
      end

      specify 'expect :left event once underlying connection is closed' do
        run_reactor do
          presence_client_one.on(:left) do
            expect(presence_client_one.state).to eq(:left)
            stop_reactor
          end
          presence_client_one.enter do
            client_one.close
          end
        end
      end

      specify 'expect :left event with no client data to retain original data in Leave event' do
        run_reactor do
          presence_client_one.subscribe(:leave) do |message|
            expect(presence_client_one.get.count).to eq(0)
            expect(message.data).to eq(data_payload)
            stop_reactor
          end
          presence_client_one.enter(data: data_payload) do
            presence_client_one.leave
          end
        end
      end

      specify '#update automatically connects' do
        run_reactor do
          presence_client_one.update(data: data_payload) do
            expect(presence_client_one.state).to eq(:entered)
            stop_reactor
          end
        end
      end

      specify '#update changes the data' do
        run_reactor do
          presence_client_one.enter(data: 'prior') do
            presence_client_one.update(data: data_payload)
          end
          presence_client_one.subscribe(:update) do |message|
            expect(message.data).to eql(data_payload)
            stop_reactor
          end
        end
      end

      it 'raises an exception if client_id is not set' do
        run_reactor do
          expect { channel_anonymous_client.presence.enter }.to raise_error(Ably::Exceptions::Standard, /without a client_id/)
          stop_reactor
        end
      end

      it '#leave raises an exception if not entered' do
        run_reactor do
          expect { channel_anonymous_client.presence.leave }.to raise_error(Ably::Exceptions::Standard, /Unable to leave presence channel that is not entered/)
          stop_reactor
        end
      end

      skip 'ensure member_id is unique an updated on ENTER'
      skip 'stop a call to get when the channel has not been entered'
      skip 'stop a call to get when the channel has been entered but the list is not up to date'
    end
  end
end
