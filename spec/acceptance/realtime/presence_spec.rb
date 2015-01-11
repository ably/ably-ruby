# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Presence, :event_machine do
  vary_by_protocol do
    let(:default_options) { { api_key: api_key, environment: environment, protocol: protocol } }
    let(:client_options)  { default_options }

    let(:anonymous_client) { Ably::Realtime::Client.new(client_options) }
    let(:client_one)       { Ably::Realtime::Client.new(client_options.merge(client_id: random_str)) }
    let(:client_two)       { Ably::Realtime::Client.new(client_options.merge(client_id: random_str)) }

    let(:channel_name)              { "presence-#{random_str(4)}" }
    let(:channel_anonymous_client)  { anonymous_client.channel(channel_name) }
    let(:presence_anonymous_client) { channel_anonymous_client.presence }
    let(:channel_client_one)        { client_one.channel(channel_name) }
    let(:channel_rest_client_one)   { client_one.rest_client.channel(channel_name) }
    let(:presence_client_one)       { channel_client_one.presence }
    let(:channel_client_two)        { client_two.channel(channel_name) }
    let(:presence_client_two)       { channel_client_two.presence }
    let(:data_payload)              { random_str }

    context 'when attached (but not present) on a presence channel with an anonymous client (no client ID)' do
      it 'maintains state as other clients enter and leave the channel' do
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

    context '#sync_complete?' do
      context 'when attaching to a channel without any members present' do
        it 'is true and the presence channel is considered synced immediately' do
          channel_anonymous_client.attach do
            expect(channel_anonymous_client.presence).to be_sync_complete
            stop_reactor
          end
        end
      end

      context 'when attaching to a channel with members present' do
        it 'is false and the presence channel will subsequently be synced' do
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

    context 'when the SYNC of a presence channel spans multiple ProtocolMessage messages' do
      context 'with 250 existing (present) members' do
        let(:enter_expected_count) { 250 }
        let(:present) { [] }
        let(:entered) { [] }

        context 'when a new client attaches to the presence channel', em_timeout: 10 do
          it 'emits :present for each member' do
            enter_expected_count.times do |index|
              presence_client_one.enter_client("client:#{index}") do |message|
                entered << message
                next unless entered.count == enter_expected_count

                presence_anonymous_client.subscribe(:present) do |present_message|
                  expect(present_message.action).to eq(:present)
                  present << present_message
                  next unless present.count == enter_expected_count

                  expect(present.map(&:client_id).uniq.count).to eql(enter_expected_count)
                  stop_reactor
                end
              end
            end
          end

          context '#get' do
            it '#waits until sync is complete', event_machine: 15 do
              enter_expected_count.times do |index|
                presence_client_one.enter_client("client:#{index}") do |message|
                  entered << message
                  next unless entered.count == enter_expected_count

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
    end

    context 'automatic attachment of channel on access to presence object' do
      it 'is implicit if presence state is initalized' do
        channel_client_one.presence
        channel_client_one.on(:attached) do
          expect(channel_client_one.state).to eq(:attached)
          stop_reactor
        end
      end

      it 'is disabled if presence state is not initialized' do
        channel_client_one.attach do
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

    context 'state' do
      context 'once opened' do
        it 'once opened, enters the :left state if the channel detaches' do
          detached = false

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
    end

    context '#enter' do
      it 'allows client_id to be set on enter for anonymous clients' do
        channel_anonymous_client.presence.enter client_id: "123"

        channel_anonymous_client.presence.subscribe do |presence|
          expect(presence.client_id).to eq("123")
          stop_reactor
        end
      end

      context 'data attribute' do
        context 'when provided as argument option to #enter' do
          it 'remains intact following #leave' do
            leave_callback_called = false

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

      it 'raises an exception if client_id is not set' do
        expect { channel_anonymous_client.presence.enter }.to raise_error(Ably::Exceptions::Standard, /without a client_id/)
        stop_reactor
      end

      it 'returns a Deferrable' do
        expect(presence_client_one.enter).to be_a(EventMachine::Deferrable)
        stop_reactor
      end

      it 'calls the Deferrable callback on success' do
        presence_client_one.enter.callback do |presence|
          expect(presence).to eql(presence_client_one)
          expect(presence_client_one.state).to eq(:entered)
          stop_reactor
        end
      end
    end

    context '#update' do
      # TODO: Currently an UPDATE is received from the server when sending an update
      skip 'without previous #enter automatically enters' do
        presence_client_one.update(data: data_payload) do
          expect(presence_client_one.state).to eq(:entered)
          stop_reactor
        end
      end

      it 'updates the data' do
        presence_client_one.enter(data: 'prior') do
          presence_client_one.update(data: data_payload)
        end
        presence_client_one.subscribe(:update) do |message|
          expect(message.data).to eql(data_payload)
          stop_reactor
        end
      end

      it 'returns a Deferrable' do
        presence_client_one.enter do
          expect(presence_client_one.update).to be_a(EventMachine::Deferrable)
          stop_reactor
        end
      end

      it 'calls the Deferrable callback on success' do
        presence_client_one.enter do
          presence_client_one.update.callback do |presence|
            expect(presence).to eql(presence_client_one)
            expect(presence_client_one.state).to eq(:entered)
            stop_reactor
          end
        end
      end
    end

    context '#leave' do
      it '#leave raises an exception if not entered' do
        expect { channel_anonymous_client.presence.leave }.to raise_error(Ably::Exceptions::Standard, /Unable to leave presence channel that is not entered/)
        stop_reactor
      end

      it 'returns a Deferrable' do
        presence_client_one.enter do
          expect(presence_client_one.leave).to be_a(EventMachine::Deferrable)
          stop_reactor
        end
      end

      it 'calls the Deferrable callback on success' do
        presence_client_one.enter do
          presence_client_one.leave.callback do |presence|
            expect(presence).to eql(presence_client_one)
            expect(presence_client_one.state).to eq(:left)
            stop_reactor
          end
        end
      end
    end

    context ':left event' do
      it 'emits the data defined in enter' do
        channel_client_one.presence.enter(data: 'data') do
          channel_client_one.presence.leave
        end

        channel_client_two.presence.subscribe(:leave) do |message|
          expect(message.data).to eql('data')
          stop_reactor
        end
      end

      it 'emits the data defined in update' do
        channel_client_one.presence.enter(data: 'something else') do
          channel_client_one.presence.update(data: 'data') do
            channel_client_one.presence.leave
          end
        end

        channel_client_two.presence.subscribe(:leave) do |message|
          expect(message.data).to eql('data')
          stop_reactor
        end
      end
    end

    context 'on behalf of multiple client_ids' do
      let(:client_count) { 5 }
      let(:clients) { [] }
      let(:data) { random_str }

      context '#enter_client' do
        it "has no affect on the client's presence state and only enters on behalf of the provided client_id" do
          client_count.times do |client_id|
            presence_client_one.enter_client("client:#{client_id}") do
              presence_client_one.on(:entered) { raise 'Should not have entered' }
              next unless client_id == client_count - 1

              EventMachine.add_timer(0.5) do
                expect(presence_client_one.state).to eq(:initialized)
                stop_reactor
              end
            end
          end
        end

        it 'enters a channel' do
          client_count.times do |client_id|
            presence_client_one.enter_client("client:#{client_id}", data)
          end

          presence_anonymous_client.subscribe(:enter) do |presence|
            expect(presence.data).to eql(data)
            clients << presence
            next unless clients.count == 5

            expect(clients.map(&:client_id).uniq.count).to eql(5)
            stop_reactor
          end
        end

        it 'returns a Deferrable' do
          expect(presence_client_one.enter_client('client_id')).to be_a(EventMachine::Deferrable)
          stop_reactor
        end

        it 'calls the Deferrable callback on success' do
          presence_client_one.enter_client('client_id').callback do |presence|
            expect(presence).to eql(presence_client_one)
            stop_reactor
          end
        end
      end

      context '#update_client' do
        it 'updates the data attribute for the member' do
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
            next unless clients.count == 5

            EventMachine.add_timer(0.5) do
              expect(clients.map(&:client_id).uniq.count).to eql(5)
              expect(updated_callback_count).to eql(5)
              stop_reactor
            end
          end
        end

        # TODO: Wait until this is fixed in the server
        skip 'enters if not already entered' do
          updated_callback_count = 0

          client_count.times do |client_id|
            presence_client_one.update_client("client:#{client_id}", data) do
              updated_callback_count += 1
            end
          end

          presence_anonymous_client.subscribe(:enter) do |presence|
            expect(presence.data).to eql(data)
            clients << presence
            next unless clients.count == 5

            EventMachine.add_timer(0.5) do
              expect(clients.map(&:client_id).uniq.count).to eql(5)
              expect(updated_callback_count).to eql(5)
              stop_reactor
            end
          end
        end

        it 'returns a Deferrable' do
          expect(presence_client_one.update_client('client_id')).to be_a(EventMachine::Deferrable)
          stop_reactor
        end

        it 'calls the Deferrable callback on success' do
          presence_client_one.update_client('client_id').callback do |presence|
            expect(presence).to eql(presence_client_one)
            stop_reactor
          end
        end
      end

      context '#leave_client' do
        it 'leaves a channel and the data attribute is always empty' do
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
            next unless clients.count == 5

            EventMachine.add_timer(0.5) do
              expect(clients.map(&:client_id).uniq.count).to eql(5)
              expect(left_callback_count).to eql(5)
              stop_reactor
            end
          end
        end

        it 'succeeds if client_id is not entered' do
          left_callback_count = 0

          client_count.times do |client_id|
            presence_client_one.leave_client("client:#{client_id}") do
              left_callback_count += 1
            end
          end

          presence_anonymous_client.subscribe(:leave) do |presence|
            expect(presence.data).to be_nil
            clients << presence
            next unless clients.count == 5

            EventMachine.add_timer(1) do
              expect(clients.map(&:client_id).uniq.count).to eql(5)
              expect(left_callback_count).to eql(5)
              stop_reactor
            end
          end
        end

        it 'returns a Deferrable' do
          expect(presence_client_one.leave_client('client_id')).to be_a(EventMachine::Deferrable)
          stop_reactor
        end

        it 'calls the Deferrable callback on success' do
          presence_client_one.leave_client('client_id').callback do |presence|
            expect(presence).to eql(presence_client_one)
            stop_reactor
          end
        end
      end
    end

    context '#get' do
      it 'returns a Deferrable' do
        expect(presence_client_one.get).to be_a(EventMachine::Deferrable)
        stop_reactor
      end

      it 'calls the Deferrable callback on success' do
        presence_client_one.get.callback do |presence|
          expect(presence).to eq([])
          stop_reactor
        end
      end

      it 'returns the current members on the channel' do
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

      it 'filters by member_id option if provided' do
        when_all(presence_client_one.enter, presence_client_two.enter, and_wait: 0.5) do
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

      it 'filters by client_id option if provided' do
        when_all(presence_client_one.enter(client_id: 'one'), presence_client_two.enter(client_id: 'two')) do
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

      it 'does not wait for SYNC to complete if :wait_for_sync option is false' do
        presence_client_one.enter(client_id: 'one') do
          presence_client_two.get(wait_for_sync: false) do |members|
            expect(members.count).to eql(0)
            stop_reactor
          end
        end
      end

      context 'when a member enters and then leaves' do
        it 'has no members' do
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

      it 'returns both members on both simultaneously connected clients' do
        when_all(presence_client_one.enter(data: data_payload), presence_client_two.enter) do
          EventMachine.add_timer(0.5) do
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
      end
    end

    context '#subscribe' do
      let(:messages) { [] }

      context 'with no arguments' do
        it 'calls the callback for all presence events' do
          when_all(channel_client_one.attach, channel_client_two.attach) do
            presence_client_two.subscribe do |presence_message|
              messages << presence_message
              next unless messages.count == 3

              expect(messages.map(&:action).map(&:to_sym)).to contain_exactly(:enter, :update, :leave)
              stop_reactor
            end

            presence_client_one.enter
            presence_client_one.update
            presence_client_one.leave
          end
        end
      end
    end

    context '#unsubscribe' do
      context 'with no arguments' do
        it 'removes the callback for all presence events' do
          when_all(channel_client_one.attach, channel_client_two.attach) do
            subscribe_callback = proc { raise 'Should not be called' }
            presence_client_two.subscribe &subscribe_callback
            presence_client_two.unsubscribe &subscribe_callback

            presence_client_one.enter
            presence_client_one.update
            presence_client_one.leave do
              EventMachine.add_timer(0.5) do
                stop_reactor
              end
            end
          end
        end
      end
    end

    context 'REST #get' do
      it 'returns current members' do
        presence_client_one.enter(data: data_payload) do
          members = channel_rest_client_one.presence.get
          this_member = members.first

          expect(this_member).to be_a(Ably::Models::PresenceMessage)
          expect(this_member.client_id).to eql(client_one.client_id)
          expect(this_member.data).to eql(data_payload)

          stop_reactor
        end
      end

      it 'returns no members once left' do
        presence_client_one.enter(data: data_payload) do
          presence_client_one.leave do
            members = channel_rest_client_one.presence.get
            expect(members.count).to eql(0)
            stop_reactor
          end
        end
      end
    end

    context 'client_id with ASCII_8BIT' do
      let(:client_id)   { random_str.encode(Encoding::ASCII_8BIT) }

      context 'in connection set up' do
        let(:client_one)  { Ably::Realtime::Client.new(default_options.merge(client_id: client_id)) }

        it 'is converted into UTF_8' do
          presence_client_one.enter
          presence_client_one.on(:entered) do |presence|
            expect(presence.client_id.encoding).to eql(Encoding::UTF_8)
            expect(presence.client_id.encode(Encoding::ASCII_8BIT)).to eql(client_id)
            stop_reactor
          end
        end
      end

      context 'in channel options' do
        let(:client_one)  { Ably::Realtime::Client.new(default_options) }

        it 'is converted into UTF_8' do
          presence_client_one.enter(client_id: client_id)
          presence_client_one.on(:entered) do |presence|
            expect(presence.client_id.encoding).to eql(Encoding::UTF_8)
            expect(presence.client_id.encode(Encoding::ASCII_8BIT)).to eql(client_id)
            stop_reactor
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

      context '#subscribe' do
        it 'emits decrypted enter events' do
          encrypted_channel.attach do
            encrypted_channel.presence.enter data: data
          end

          encrypted_channel.presence.subscribe(:enter) do |presence_message|
            expect(presence_message.encoding).to be_nil
            expect(presence_message.data).to eql(data)
            stop_reactor
          end
        end

        it 'emits decrypted update events' do
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

        it 'emits previously set data for leave events' do
          encrypted_channel.attach do
            encrypted_channel.presence.enter(data: data) do
              encrypted_channel.presence.leave
            end
          end

          encrypted_channel.presence.subscribe(:leave) do |presence_message|
            expect(presence_message.encoding).to be_nil
            expect(presence_message.data).to eql(data)
            stop_reactor
          end
        end
      end

      context '#get' do
        it 'returns a list of members with decrypted data' do
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

      context 'REST #get' do
        it 'returns a list of members with decrypted data' do
          encrypted_channel.presence.enter(data: data) do
            member = channel_rest_client_one.presence.get.first
            expect(member.encoding).to be_nil
            expect(member.data).to eql(data)
            stop_reactor
          end
        end
      end

      context 'when cipher settings do not match publisher' do
        let(:client_options)                 { default_options.merge(log_level: :fatal) }
        let(:incompatible_cipher_options)    { { key: secret_key, algorithm: 'aes', mode: 'cbc', key_length: 128 } }
        let(:incompatible_encrypted_channel) { client_two.channel(channel_name, encrypted: true, cipher_params: incompatible_cipher_options) }

        it 'delivers an unencoded presence message left with encoding value' do
          encrypted_channel.presence.enter data: data

          incompatible_encrypted_channel.presence.subscribe(:enter) do
            incompatible_encrypted_channel.presence.get do |members|
              member = members.first
              expect(member.encoding).to match(/cipher\+aes-256-cbc/)
              expect(member.data).to_not eql(data)
              stop_reactor
            end
          end
        end

        it 'emits an error when cipher does not match and presence data cannot be decoded' do
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

    context 'leaving' do
      specify 'expect :left event once underlying connection is closed' do
        presence_client_one.on(:left) do
          expect(presence_client_one.state).to eq(:left)
          stop_reactor
        end
        presence_client_one.enter do
          client_one.close
        end
      end

      specify 'expect :left event with client data from enter event' do
        presence_client_one.subscribe(:leave) do |message|
          presence_client_one.get do |members|
            expect(members.count).to eq(0)
            expect(message.data).to eql(data_payload)
            stop_reactor
          end
        end
        presence_client_one.enter(data: data_payload) do
          presence_client_one.leave
        end
      end
    end

    skip 'ensure member_id is unique and updated on ENTER'
    skip 'ensure member_id for presence member matches the messages they publish on the channel'
    skip 'stop a call to get when the channel has not been entered'
    skip 'stop a call to get when the channel has been entered but the list is not up to date'
    skip 'presence will resume sync if connection is dropped mid-way'
  end
end
