# encoding: utf-8
require 'spec_helper'

describe 'Ably::Realtime::Presence' do
  include RSpec::EventMachine

  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:default_options) { { api_key: api_key, environment: environment, protocol: protocol } }
      let(:client_options)  { default_options }

      let(:channel_name) { "presence-#{random_str(4)}" }

      let(:anonymous_client) { Ably::Realtime::Client.new(client_options) }
      let(:client_one)       { Ably::Realtime::Client.new(client_options.merge(client_id: random_str)) }
      let(:client_two)       { Ably::Realtime::Client.new(client_options.merge(client_id: random_str)) }

      let(:channel_anonymous_client)  { anonymous_client.channel(channel_name) }
      let(:presence_anonymous_client) { channel_anonymous_client.presence }
      let(:channel_client_one)        { client_one.channel(channel_name) }
      let(:channel_rest_client_one)   { client_one.rest_client.channel(channel_name) }
      let(:presence_client_one)       { channel_client_one.presence }
      let(:channel_client_two)        { client_two.channel(channel_name) }
      let(:presence_client_two)       { channel_client_two.presence }

      let(:data_payload) { random_str }

      context 'when attached to channel but has not entered (not present)' do
        it 'maintains state' do
          run_reactor do
            channel_anonymous_client.attach do
              presence_anonymous_client.subscribe(:enter) do |presence_message|
                expect(presence_message.client_id).to eql(client_one.client_id)
                presence_anonymous_client.get do |members|
                  expect(members.first.client_id).to eql(client_one.client_id)
                  expect(members.first.action).to eq(:enter)

                  presence_anonymous_client.subscribe(:leave) do |presence_message|
                    expect(presence_message.client_id).to eql(client_one.client_id)
                    presence_anonymous_client.get do |members|
                      expect(members.count).to eql(0)
                      stop_reactor
                    end
                  end
                end
              end
            end

            presence_client_one.enter do
              presence_client_one.leave
            end
          end
        end
      end

      context '#sync_complete?' do
        context 'when attaching to a channel without any members present' do
          it 'is true and the presence channel is considered synced immediately' do
            run_reactor do
              channel_anonymous_client.attach do
                expect(channel_anonymous_client.presence).to be_sync_complete
                stop_reactor
              end
            end
          end
        end

        context 'when attaching to a channel with members present' do
          it 'is false and the presence channel will subsequently be synced' do
            run_reactor do
              presence_client_one.enter do
                channel_anonymous_client.attach do
                  expect(channel_anonymous_client.presence).to_not be_sync_complete
                  channel_anonymous_client.presence.get do
                    expect(channel_anonymous_client.presence).to be_sync_complete
                    stop_reactor
                  end
                end
              end
            end
          end
        end
      end

      context 'a channel with 250 existing (present) members' do
        let(:enter_expected_count) { 250 }
        let(:present) { [] }
        let(:entered) { [] }

        it 'emits :present for each member when attaching and subscribing to presence messages' do
          run_reactor(15) do
            enter_expected_count.times do |index|
              presence_client_one.enter_client("client:#{index}") do |message|
                entered << message
                if entered.count == enter_expected_count
                  presence_anonymous_client.subscribe(:present) do |present_message|
                    expect(present_message.action).to eq(:present)
                    present << present_message
                    if present.count == enter_expected_count
                      expect(present.map(&:client_id).uniq.count).to eql(enter_expected_count)
                      stop_reactor
                    end
                  end
                end
              end
            end
          end
        end

        specify '#get waits until sync is complete' do
          run_reactor(15) do
            enter_expected_count.times do |index|
              presence_client_one.enter_client("client:#{index}") do |message|
                entered << message
                if entered.count == enter_expected_count
                  presence_anonymous_client.get do |members|
                    expect(members.map(&:client_id).uniq.count).to eql(enter_expected_count)
                    expect(members.count).to eql(enter_expected_count)
                    stop_reactor
                  end
                end
              end
            end
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

      context '#data attribute' do
        context 'when provided as argument option to #enter' do
          it 'remains intact following #leave' do
            leave_callback_called = false

            run_reactor do
              presence_client_one.enter(data: 'stored') do
                expect(presence_client_one.data).to eql('stored')

                presence_client_one.leave do |presence|
                  leave_callback_called = true
                end

                presence_client_one.on(:left) do
                  expect(presence_client_one.data).to eql('stored')

                  EventMachine.next_tick do
                    expect(leave_callback_called).to eql(true)
                    stop_reactor
                  end
                end
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

      it 'emits no data for the :left event' do
        run_reactor do
          channel_client_one.presence.enter(data: 'data') do
            channel_client_one.presence.leave
          end
          channel_client_two.presence.subscribe(:enter) do |message|
            expect(message.data).to eql('data')
          end
          channel_client_two.presence.subscribe(:leave) do |message|
            expect(message.data).to be_nil
            stop_reactor
          end
        end
      end

      context 'on behalf of multiple client_ids' do
        let(:client_count) { 5 }
        let(:clients) { [] }
        let(:data) { SecureRandom.hex }

        context '#enter_client' do
          it "has no affect on the client's presence state and only enters on behalf of the provided client_id" do
            run_reactor do
              client_count.times do |client_id|
                presence_client_one.enter_client("client:#{client_id}") do
                  presence_client_one.on(:entered) { raise 'Should not have entered' }

                  EventMachine.add_timer(0.5) do
                    expect(presence_client_one.state).to eq(:initialized)
                    stop_reactor
                  end if client_id == client_count - 1
                end
              end
            end
          end

          it 'enters a channel' do
            run_reactor do
              client_count.times do |client_id|
                presence_client_one.enter_client("client:#{client_id}", data)
              end

              presence_anonymous_client.subscribe(:enter) do |presence|
                expect(presence.data).to eql(data)
                clients << presence
                if clients.count == 5
                  expect(clients.map(&:client_id).uniq.count).to eql(5)
                  stop_reactor
                end
              end
            end
          end
        end

        context '#update_client' do
          it 'updates the data attribute for the member' do
            run_reactor do
              updated_callback_count = 0

              client_count.times do |client_id|
                presence_client_one.enter_client("client:#{client_id}") do
                  presence_client_one.update_client("client:#{client_id}", data) do
                    updated_callback_count += 1
                  end
                end
              end

              presence_anonymous_client.subscribe(:update) do |presence|
                expect(presence.data).to eql(data)
                clients << presence
                if clients.count == 5
                  EventMachine.add_timer(0.5) do
                    expect(clients.map(&:client_id).uniq.count).to eql(5)
                    expect(updated_callback_count).to eql(5)
                    stop_reactor
                  end
                end
              end
            end
          end

          # TODO: Wait until this is fixed in the server
          skip 'enters if not already entered' do
            run_reactor do
              updated_callback_count = 0

              client_count.times do |client_id|
                presence_client_one.update_client("client:#{client_id}", data) do
                  updated_callback_count += 1
                end
              end

              presence_anonymous_client.subscribe(:enter) do |presence|
                expect(presence.data).to eql(data)
                clients << presence
                if clients.count == 5
                  EventMachine.add_timer(0.5) do
                    expect(clients.map(&:client_id).uniq.count).to eql(5)
                    expect(updated_callback_count).to eql(5)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        context '#leave_client' do
          it 'leaves a channel and the data attribute is always empty' do
            run_reactor do
              left_callback_count = 0

              client_count.times do |client_id|
                presence_client_one.enter_client("client:#{client_id}", data) do
                  presence_client_one.leave_client("client:#{client_id}") do
                    left_callback_count += 1
                  end
                end
              end

              presence_anonymous_client.subscribe(:leave) do |presence|
                expect(presence.data).to be_nil
                clients << presence
                if clients.count == 5
                  EventMachine.add_timer(0.5) do
                    expect(clients.map(&:client_id).uniq.count).to eql(5)
                    expect(left_callback_count).to eql(5)
                    stop_reactor
                  end
                end
              end
            end
          end

          it 'succeeds if client_id is not entered' do
            run_reactor do
              left_callback_count = 0

              client_count.times do |client_id|
                presence_client_one.leave_client("client:#{client_id}") do
                  left_callback_count += 1
                end
              end

              presence_anonymous_client.subscribe(:leave) do |presence|
                expect(presence.data).to be_nil
                clients << presence
                if clients.count == 5
                  EventMachine.add_timer(1) do
                    expect(clients.map(&:client_id).uniq.count).to eql(5)
                    expect(left_callback_count).to eql(5)
                    stop_reactor
                  end
                end
              end
            end
          end
        end
      end

      context '#get' do
        it 'returns the current members on the channel' do
          run_reactor do
            presence_client_one.enter do
              presence_client_one.get do |members|
                expect(members.count).to eq(1)

                expect(client_one.client_id).to_not be_nil

                this_member = members.first
                expect(this_member.client_id).to eql(client_one.client_id)

                stop_reactor
              end
            end
          end
        end

        it 'filters by member_id option if provided' do
          run_reactor do
            presence_client_one.enter do
              presence_client_two.enter do
                presence_client_one.get(member_id: client_one.connection.member_id) do |members|
                  expect(members.count).to eq(1)
                  expect(members.first.member_id).to eql(client_one.connection.member_id)

                  presence_client_one.get(member_id: client_two.connection.member_id) do |members|
                    expect(members.count).to eq(1)
                    expect(members.first.member_id).to eql(client_two.connection.member_id)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        it 'filters by client_id option if provided' do
          run_reactor do
            presence_client_one.enter(client_id: 'one') do
              presence_client_two.enter(client_id: 'two') do
                presence_client_one.get(client_id: 'one') do |members|
                  expect(members.count).to eq(1)
                  expect(members.first.client_id).to eql('one')
                  expect(members.first.member_id).to eql(client_one.connection.member_id)

                  presence_client_one.get(client_id: 'two') do |members|
                    expect(members.count).to eq(1)
                    expect(members.first.client_id).to eql('two')
                    expect(members.first.member_id).to eql(client_two.connection.member_id)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        it 'does not wait for SYNC to complete if :wait_for_sync option is false' do
          run_reactor do
            presence_client_one.enter(client_id: 'one') do
              presence_client_two.get(wait_for_sync: false) do |members|
                expect(members.count).to eql(0)
                stop_reactor
              end
            end
          end
        end

        context 'when a member enters and then leaves' do
          it 'has no members' do
            run_reactor do
              presence_client_one.enter do
                presence_client_one.leave do
                  presence_client_one.get do |members|
                    expect(members.count).to eq(0)
                    stop_reactor
                  end
                end
              end
            end
          end
        end

        it 'returns both members on both simultaneously connected clients' do
          run_reactor do
            presence_client_one.enter(data: data_payload)
            presence_client_two.enter

            entered_callback = Proc.new do
              next unless presence_client_one.state == :entered && presence_client_two.state == :entered

              EventMachine.add_timer(0.25) do
                presence_client_one.get do |client_one_members|
                  presence_client_two.get do |client_two_members|
                    expect(client_one_members.count).to eq(client_two_members.count)

                    member_client_one = client_one_members.find { |presence| presence.client_id == client_one.client_id }
                    member_client_two = client_one_members.find { |presence| presence.client_id == client_two.client_id }

                    expect(member_client_one).to be_a(Ably::Models::PresenceMessage)
                    expect(member_client_one.data).to eql(data_payload)
                    expect(member_client_two).to be_a(Ably::Models::PresenceMessage)

                    stop_reactor
                  end
                end
              end
            end

            presence_client_one.on :entered, &entered_callback
            presence_client_two.on :entered, &entered_callback
          end
        end
      end

      specify '#subscribe and #unsubscribe to presence events' do
        run_reactor do
          client_two_subscribe_messages = []

          subscribe_client_one_leaving_callback = Proc.new do |presence_object|
            expect(presence_object.client_id).to eql(client_one.client_id)
            expect(presence_object.data).to be_nil
            expect(presence_object.action).to eq(:leave)

            stop_reactor
          end

          subscribe_self_callback = Proc.new do |presence_object|
            if presence_object.client_id == client_two.client_id
              expect(presence_object.action).to eq(:enter)

              presence_client_two.unsubscribe &subscribe_self_callback
              presence_client_two.subscribe &subscribe_client_one_leaving_callback

              presence_client_one.leave
            end
          end

          presence_client_one.enter do
            presence_client_two.enter
            presence_client_two.subscribe &subscribe_self_callback
          end
        end
      end

      context 'REST #get' do
        it 'returns current members' do
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

        it 'returns no members once left' do
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

        it '#subscribe emits nil data for leave events' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter(data: 'to be updated') do
                encrypted_channel.presence.leave
              end
            end

            encrypted_channel.presence.subscribe(:leave) do |presence_message|
              expect(presence_message.encoding).to be_nil
              expect(presence_message.data).to be_nil
              stop_reactor
            end
          end
        end

        it '#get returns a list of members with decrypted data' do
          run_reactor do
            encrypted_channel.attach do
              encrypted_channel.presence.enter(data: data) do
                encrypted_channel.presence.get do |members|
                  member = members.first
                  expect(member.encoding).to be_nil
                  expect(member.data).to eql(data)
                  stop_reactor
                end
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
          let(:client_options)                 { default_options.merge(log_level: :fatal) }
          let(:incompatible_cipher_options)    { { key: secret_key, algorithm: 'aes', mode: 'cbc', key_length: 128 } }
          let(:incompatible_encrypted_channel) { client_two.channel(channel_name, encrypted: true, cipher_params: incompatible_cipher_options) }

          it 'delivers an unencoded presence message left with encoding value' do
            run_reactor do
              incompatible_encrypted_channel.attach do
                encrypted_channel.attach do
                  encrypted_channel.presence.enter(data: data) do
                    incompatible_encrypted_channel.presence.get do |members|
                      member = members.first
                      expect(member.encoding).to match(/cipher\+aes-256-cbc/)
                      expect(member.data).to_not eql(data)
                      stop_reactor
                    end
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

      specify 'expect :left event with no client data to use nil for data in leave event' do
        run_reactor do
          presence_client_one.subscribe(:leave) do |message|
            presence_client_one.get do |members|
              expect(members.count).to eq(0)
              expect(message.data).to be_nil
              stop_reactor
            end
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

      skip 'ensure member_id is unique and updated on ENTER'
      skip 'stop a call to get when the channel has not been entered'
      skip 'stop a call to get when the channel has been entered but the list is not up to date'
    end
  end
end
