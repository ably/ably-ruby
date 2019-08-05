# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Push::Admin do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol} }
    let(:client_options)  { default_options }
    let(:client) do
      Ably::Rest::Client.new(client_options)
    end

    let(:basic_notification_payload) do
      {
        notification: {
          title: 'Test message',
          body: 'Test message body'
        }
      }
    end

    let(:basic_recipient) do
      {
        transport_type: 'apns',
        deviceToken: 'foo.bar'
      }
    end

    describe '#publish' do
      subject { client.push.admin }

      context 'without publish permissions' do
        let(:capability) { { :foo => ['subscribe'] } }

        before do
          client.auth.authorize(capability: capability)
        end

        it 'raises a permissions issue exception' do
          expect { subject.publish(basic_recipient, basic_notification_payload) }.to raise_error Ably::Exceptions::UnauthorizedRequest
        end
      end

      context 'invalid arguments (#RHS1a)' do
        it 'raises an exception with a nil recipient' do
          expect { subject.publish(nil, {}) }.to raise_error ArgumentError, /Expecting a Hash/
        end

        it 'raises an exception with a empty recipient' do
          expect { subject.publish({}, {}) }.to raise_error ArgumentError, /empty/
        end

        it 'raises an exception with a nil recipient' do
          expect { subject.publish(basic_recipient, nil) }.to raise_error ArgumentError, /Expecting a Hash/
        end

        it 'raises an exception with a empty recipient' do
          expect { subject.publish(basic_recipient, {}) }.to raise_error ArgumentError, /empty/
        end
      end

      context 'invalid recipient (#RSH1a)' do
        it 'raises an error after receiving a 40x realtime response' do
          expect { subject.publish({ invalid_recipient_details: 'foo.bar' }, basic_notification_payload) }.to raise_error Ably::Exceptions::InvalidRequest
        end
      end

      context 'invalid push data (#RSH1a)' do
        it 'raises an error after receiving a 40x realtime response' do
          expect { subject.publish(basic_recipient, { invalid_property_only: true }) }.to raise_error Ably::Exceptions::InvalidRequest
        end
      end

      context 'recipient variable case', webmock: true do
        let(:recipient_payload) do
          {
            camel_case: {
              second_level_camel_case: 'val'
            }
          }
        end

        let(:content_type) do
          if protocol == :msgpack
            'application/x-msgpack'
          else
            'application/json'
          end
        end

        def request_body(request, protocol)
          if protocol == :msgpack
            MessagePack.unpack(request.body)
          else
            JSON.parse(request.body)
          end
        end

        def serialize(object, protocol)
          if protocol == :msgpack
            MessagePack.pack(object)
          else
            JSON.dump(object)
          end
        end

        let!(:publish_stub) do
          stub_request(:post, "#{client.endpoint}/push/publish").
            with do |request|
              expect(request_body(request, protocol)['recipient']['camelCase']['secondLevelCamelCase']).to eql('val')
              expect(request_body(request, protocol)['recipient']).to_not have_key('camel_case')
              true
            end.to_return(
              :status => 201,
              :body => serialize({}, protocol),
              :headers => { 'Content-Type' => content_type }
            )
        end

        it 'is converted to snakeCase' do
          subject.publish(recipient_payload, basic_notification_payload)
          expect(publish_stub).to have_been_requested
        end
      end

      it 'accepts valid push data and recipient (#RSH1a)' do
        subject.publish(basic_recipient, basic_notification_payload)
      end

      context 'using test environment channel recipient (#RSH1a)' do
        let(:channel) { random_str }
        let(:recipient) do
          {
            'transportType' => 'ablyChannel',
            'channel' => channel,
            'ablyKey' => api_key,
            'ablyUrl' => client.endpoint.to_s
          }
        end
        let(:notification_payload) do
          {
            notification: {
              title: random_str,
            },
            data: {
              foo: random_str
            }
          }
        end

        it 'triggers a push notification' do
          subject.publish(recipient, notification_payload)
          sleep 5
          notification_published_on_channel = client.channels.get(channel).history.items.first
          expect(notification_published_on_channel.name).to eql('__ably_push__')
          expect(JSON.parse(notification_published_on_channel.data)['data']).to eql(JSON.parse(notification_payload[:data].to_json))
        end
      end
    end

    describe '#device_registrations (#RSH1b)' do
      subject { client.push.admin.device_registrations }

      context 'without permissions' do
        let(:capability) { { :foo => ['subscribe'] } }

        before do
          client.auth.authorize(capability: capability)
        end

        it 'raises a permissions not authorized exception' do
          expect { subject.get('does-not-exist') }.to raise_error Ably::Exceptions::UnauthorizedRequest
          expect { subject.list }.to raise_error Ably::Exceptions::UnauthorizedRequest
          expect { subject.remove('does-not-exist') }.to raise_error Ably::Exceptions::UnauthorizedRequest
          expect { subject.remove_where(device_id: 'does-not-exist') }.to raise_error Ably::Exceptions::UnauthorizedRequest
        end
      end

      describe '#list (#RSH1b2)' do
        let(:client_id) { random_str }
        let(:fixture_count) { 6 }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            Thread.new do
              subject.save({
                id: "device-#{client_id}-#{index}",
                platform: 'ios',
                form_factor: 'phone',
                client_id: client_id,
                push: {
                  recipient: {
                    transport_type: 'gcm',
                    registration_token: 'secret_token',
                  }
                }
              })
            end
          end.each(&:join) # Wait for all threads to complete
        end

        after do
          subject.remove_where client_id: client_id, full_wait: true
        end

        it 'returns a PaginatedResult object containing DeviceDetails objects' do
          page = subject.list
          expect(page).to be_a(Ably::Models::PaginatedResult)
          expect(page.items.first).to be_a(Ably::Models::DeviceDetails)
        end

        it 'returns an empty PaginatedResult if not params match' do
          page = subject.list(client_id: 'does-not-exist')
          expect(page).to be_a(Ably::Models::PaginatedResult)
          expect(page.items).to be_empty
        end

        it 'supports paging' do
          page = subject.list(limit: 3, client_id: client_id)
          expect(page).to be_a(Ably::Models::PaginatedResult)

          expect(page.items.count).to eql(3)
          page = page.next
          expect(page.items.count).to eql(3)
          page = page.next
          expect(page.items.count).to eql(0)
          expect(page).to be_last
        end

        it 'provides filtering' do
          page = subject.list(client_id: client_id)
          expect(page.items.length).to eql(fixture_count)

          page = subject.list(device_id: "device-#{client_id}-0")
          expect(page.items.length).to eql(1)

          page = subject.list(client_id: random_str)
          expect(page.items.length).to eql(0)
        end
      end

      describe '#get (#RSH1b1)' do
        let(:fixture_count) { 2 }
        let(:client_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            Thread.new do
              subject.save({
                id: "device-#{client_id}-#{index}",
                platform: 'ios',
                form_factor: 'phone',
                client_id: client_id,
                push: {
                  recipient: {
                    transport_type: 'gcm',
                    registration_token: 'secret_token',
                  }
                }
              })
            end
          end.each(&:join) # Wait for all threads to complete
        end

        after do
          subject.remove_where client_id: client_id, full_wait: true
        end

        it 'returns a DeviceDetails object if a device ID string is provided' do
          device = subject.get("device-#{client_id}-0")
          expect(device).to be_a(Ably::Models::DeviceDetails)
          expect(device.platform).to eql('ios')
          expect(device.client_id).to eql(client_id)
          expect(device.push.recipient.fetch(:transport_type)).to eql('gcm')
        end

        it 'returns a DeviceDetails object if a DeviceDetails object is provided' do
          device = subject.get(Ably::Models::DeviceDetails.new(id: "device-#{client_id}-1"))
          expect(device).to be_a(Ably::Models::DeviceDetails)
          expect(device.platform).to eql('ios')
          expect(device.client_id).to eql(client_id)
          expect(device.push.recipient.fetch(:transport_type)).to eql('gcm')
        end

        it 'raises a ResourceMissing exception if device ID does not exist' do
          expect { subject.get("device-does-not-exist") }.to raise_error(Ably::Exceptions::ResourceMissing)
        end
      end

      describe '#save (#RSH1b3)' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }
        let(:transport_token) { random_str }

        let(:device_details) do
          {
            id: device_id,
            platform: 'android',
            form_factor: 'phone',
            client_id: client_id,
            metadata: {
              foo: 'bar',
              deep: {
                val: true
              }
            },
            push: {
              recipient: {
                transport_type: 'apns',
                device_token: transport_token,
                foo_bar: 'string',
              },
              error_reason: {
                message: "this will be ignored"
              },
            }
          }
        end

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        after do
          subject.remove_where client_id: client_id, full_wait: true
        end

        it 'saves the new DeviceDetails Hash object' do
          subject.save(device_details)

          device_retrieved = subject.get(device_details.fetch(:id))
          expect(device_retrieved).to be_a(Ably::Models::DeviceDetails)

          expect(device_retrieved.id).to eql(device_id)
          expect(device_retrieved.platform).to eql('android')
          expect(device_retrieved.form_factor).to eql('phone')
          expect(device_retrieved.client_id).to eql(client_id)
          expect(device_retrieved.metadata.keys.length).to eql(2)
          expect(device_retrieved.metadata[:foo]).to eql('bar')
          expect(device_retrieved.metadata['deep']['val']).to eql(true)
        end

        it 'saves the associated DevicePushDetails' do
          subject.save(device_details)

          device_retrieved = subject.list(device_id: device_details.fetch(:id)).items.first

          expect(device_retrieved.push).to be_a(Ably::Models::DevicePushDetails)
          expect(device_retrieved.push.recipient.fetch(:transport_type)).to eql('apns')
          expect(device_retrieved.push.recipient['deviceToken']).to eql(transport_token)
          expect(device_retrieved.push.recipient['foo_bar']).to eql('string')
        end

        context 'with GCM target' do
          let(:device_token) { random_str }

          it 'saves the associated DevicePushDetails' do
            subject.save(device_details.merge(
              push: {
                recipient: {
                  transport_type: 'gcm',
                  registrationToken: device_token
                }
              }
            ))

            device_retrieved = subject.get(device_details.fetch(:id))

            expect(device_retrieved.push.recipient.fetch('transportType')).to eql('gcm')
            expect(device_retrieved.push.recipient[:registration_token]).to eql(device_token)
          end
        end

        context 'with web target' do
          let(:target_url) { 'http://foo.com/bar' }
          let(:encryption_key) { random_str }

          it 'saves the associated DevicePushDetails' do
            subject.save(device_details.merge(
              push: {
                recipient: {
                  transport_type: 'web',
                  targetUrl: target_url,
                  encryptionKey: encryption_key
                }
              }
            ))

            device_retrieved = subject.get(device_details.fetch(:id))

            expect(device_retrieved.push.recipient[:transport_type]).to eql('web')
            expect(device_retrieved.push.recipient['targetUrl']).to eql(target_url)
            expect(device_retrieved.push.recipient['encryptionKey']).to eql(encryption_key)
          end
        end

        it 'does not allow some fields to be configured' do
          subject.save(device_details)

          device_retrieved = subject.get(device_details.fetch(:id))

          expect(device_retrieved.push.state).to eql('ACTIVE')

          expect(device_retrieved.device_secret).to be_nil

          # Errors are exclusively configure by Ably
          expect(device_retrieved.push.error_reason).to be_nil
        end

        it 'allows device_secret to be configured' do
          device_secret = random_str
          subject.save(device_details.merge(device_secret: device_secret))

          device_retrieved = subject.get(device_details.fetch(:id))

          expect(device_retrieved.device_secret).to eql(device_secret)
        end

        it 'saves the new DeviceDetails object' do
          subject.save(DeviceDetails(device_details))

          device_retrieved = subject.get(device_details.fetch(:id))
          expect(device_retrieved.id).to eql(device_id)
          expect(device_retrieved.metadata[:foo]).to eql('bar')
          expect(device_retrieved.push.recipient[:transport_type]).to eql('apns')
        end

        it 'allows arbitrary number of subsequent saves' do
          3.times do
            subject.save(DeviceDetails(device_details))
          end

          device_retrieved = subject.get(device_details.fetch(:id))
          expect(device_retrieved.metadata[:foo]).to eql('bar')

          subject.save(DeviceDetails(device_details.merge(metadata: { foo: 'changed'})))
          device_retrieved = subject.get(device_details.fetch(:id))
          expect(device_retrieved.metadata[:foo]).to eql('changed')
        end

        it 'fails if data is invalid' do
          expect { subject.save(id: random_str, foo: 'bar') }.to raise_error Ably::Exceptions::InvalidRequest
        end
      end

      describe '#remove_where (#RSH1b5)' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          [
            Thread.new do
              subject.save({
                id: "device-#{client_id}-0",
                platform: 'ios',
                form_factor: 'phone',
                client_id: client_id,
                push: {
                  recipient: {
                    transport_type: 'gcm',
                    registrationToken: 'secret_token',
                  }
                }
              })
            end,
            Thread.new do
              subject.save({
                id: "device-#{client_id}-1",
                platform: 'ios',
                form_factor: 'phone',
                client_id: client_id,
                push: {
                  recipient: {
                    transport_type: 'gcm',
                    registration_token: 'secret_token',
                  }
                }
              })
            end
          ].each(&:join) # Wait for all threads to complete
        end

        after do
          subject.remove_where client_id: client_id, full_wait: true
        end

        it 'removes all matching device registrations by client_id' do
          subject.remove_where(client_id: client_id, full_wait: true) # undocumented full_wait to compelte synchronously
          expect(subject.list.items.count).to eql(0)
        end

        it 'removes device by device_id' do
          subject.remove_where(device_id: "device-#{client_id}-1", full_wait: true) # undocumented full_wait to compelte synchronously
          expect(subject.list.items.count).to eql(1)
        end

        it 'succeeds even if there is no match' do
          subject.remove_where(device_id: 'does-not-exist', full_wait: true) # undocumented full_wait to compelte synchronously
          expect(subject.list.items.count).to eql(2)
        end
      end

      describe '#remove (#RSH1b4)' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          [
            Thread.new do
              subject.save({
                id: "device-#{client_id}-0",
                platform: 'ios',
                form_factor: 'phone',
                client_id: client_id,
                push: {
                  recipient: {
                    transport_type: 'gcm',
                    registration_token: 'secret_token',
                  }
                }
              })
            end,
            Thread.new do
              subject.save({
                id: "device-#{client_id}-1",
                platform: 'ios',
                form_factor: 'phone',
                client_id: client_id,
                push: {
                  recipient: {
                    transport_type: 'gcm',
                    registration_token: 'secret_token',
                  }
                }
              })
            end
          ].each(&:join) # Wait for all threads to complete
        end

        after do
          subject.remove_where client_id: client_id, full_wait: true
        end

        it 'removes the provided device id string' do
          subject.remove("device-#{client_id}-0")
          expect(subject.list.items.count).to eql(1)
        end

        it 'removes the provided DeviceDetails' do
          subject.remove(DeviceDetails(id: "device-#{client_id}-1"))
          expect(subject.list.items.count).to eql(1)
        end

        it 'succeeds if the item does not exist' do
          subject.remove('does-not-exist')
          expect(subject.list.items.count).to eql(2)
        end
      end
    end

    describe '#channel_subscriptions (#RSH1c)' do
      let(:client_id) { random_str }
      let(:device_id) { random_str }
      let(:device_id_2) { random_str }
      let(:default_device_attr) {
        {
          platform: 'ios',
          form_factor: 'phone',
          client_id: client_id,
          push: {
            recipient: {
              transport_type: 'gcm',
              registration_token: 'secret_token',
            }
          }
        }
      }

      let(:device_registrations) {
        client.push.admin.device_registrations
      }

      subject {
        client.push.admin.channel_subscriptions
      }

      # Set up 2 devices with the same client_id
      #  and two device with the unique device_id and no client_id
      before do
        [
          lambda { device_registrations.save(default_device_attr.merge(id: device_id, client_id: nil)) },
          lambda { device_registrations.save(default_device_attr.merge(id: device_id_2, client_id: nil)) },
          lambda { device_registrations.save(default_device_attr.merge(client_id: client_id, id: random_str)) },
          lambda { device_registrations.save(default_device_attr.merge(client_id: client_id, id: random_str)) }
        ].map do |proc|
          Thread.new { proc.call }
        end.each(&:join) # Wait for all threads to complete
      end

      after do
        device_registrations.remove_where client_id: client_id
        device_registrations.remove_where device_id: device_id
      end

      describe '#list (#RSH1c1)' do
        let(:fixture_count) { 6 }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            Thread.new { subject.save(channel: "pushenabled:#{random_str}", client_id: client_id) }
          end + fixture_count.times.map do |index|
            Thread.new { subject.save(channel: "pushenabled:#{random_str}", device_id: device_id) }
          end.each(&:join) # Wait for all threads to complete
        end

        it 'returns a PaginatedResult object containing DeviceDetails objects' do
          page = subject.list(client_id: client_id)
          expect(page).to be_a(Ably::Models::PaginatedResult)
          expect(page.items.first).to be_a(Ably::Models::PushChannelSubscription)
        end

        it 'returns an empty PaginatedResult if params do not match' do
          page = subject.list(client_id: 'does-not-exist')
          expect(page).to be_a(Ably::Models::PaginatedResult)
          expect(page.items).to be_empty
        end

        it 'supports paging' do
          page = subject.list(limit: 3, device_id: device_id)
          expect(page).to be_a(Ably::Models::PaginatedResult)

          expect(page.items.count).to eql(3)
          page = page.next
          expect(page.items.count).to eql(3)
          page = page.next
          expect(page.items.count).to eql(0)
          expect(page).to be_last
        end

        it 'provides filtering' do
          page = subject.list(device_id: device_id)
          expect(page.items.length).to eql(fixture_count)

          page = subject.list(client_id: client_id)
          expect(page.items.length).to eql(fixture_count)

          random_channel = "pushenabled:#{random_str}"
          subject.save(channel: random_channel, client_id: client_id)
          page = subject.list(channel: random_channel)
          expect(page.items.length).to eql(1)

          page = subject.list(channel: random_channel, client_id: client_id)
          expect(page.items.length).to eql(1)

          page = subject.list(channel: random_channel, device_id: random_str)
          expect(page.items.length).to eql(0)

          page = subject.list(device_id: random_str)
          expect(page.items.length).to eql(0)

          page = subject.list(client_id: random_str)
          expect(page.items.length).to eql(0)

          page = subject.list(channel: random_str)
          expect(page.items.length).to eql(0)
        end

        it 'raises an exception if none of the required filters are provided' do
          expect { subject.list({ limit: 100 }) }.to raise_error(ArgumentError)
        end
      end

      describe '#list_channels (#RSH1c2)' do
        let(:fixture_count) { 6 }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          # Create 6 channel subscriptions to the client ID for this test
          fixture_count.times.map do |index|
            Thread.new do
              subject.save(channel: "pushenabled:#{index}:#{random_str}", client_id: client_id)
            end
          end.each(&:join) # Wait for all threads to complete
        end

        after do
          subject.remove_where client_id: client_id, full_wait: true # undocumented arg to do deletes synchronously
        end

        it 'returns a PaginatedResult object containing String objects' do
          page = subject.list_channels
          expect(page).to be_a(Ably::Models::PaginatedResult)
          expect(page.items.first).to be_a(String)
          expect(page.items.length).to eql(fixture_count)
        end

        it 'supports paging' do
          subject.list_channels
          page = subject.list_channels(limit: 3)
          expect(page).to be_a(Ably::Models::PaginatedResult)

          expect(page.items.count).to eql(3)
          page = page.next
          expect(page.items.count).to eql(3)
          page = page.next
          expect(page.items.count).to eql(0)
          expect(page).to be_last
        end

        # This test is not necessary for client libraries, but was useful when building the Ruby
        # lib to ensure the realtime implementation did not suffer from timing issues
        it 'returns an accurate number of channels after devices are deleted' do
          expect(subject.list_channels.items.length).to eql(fixture_count)
          subject.save(channel: "pushenabled:#{random_str}", device_id: device_id)
          subject.save(channel: "pushenabled:#{random_str}", device_id: device_id)
          expect(subject.list_channels.items.length).to eql(fixture_count + 2)
          expect(device_registrations.list(device_id: device_id).items.count).to eql(1)
          device_registrations.remove_where device_id: device_id, full_wait: true # undocumented arg to do deletes synchronously
          expect(device_registrations.list(device_id: device_id).items.count).to eql(0)
          expect(subject.list_channels.items.length).to eql(fixture_count)
          subject.remove_where client_id: client_id, full_wait: true # undocumented arg to do deletes synchronously
          expect(subject.list_channels.items.length).to eql(0)
        end
      end

      describe '#save (#RSH1c3)' do
        let(:channel) { "pushenabled:#{random_str}" }
        let(:client_id) { random_str }
        let(:device_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        it 'saves the new client_id PushChannelSubscription Hash object' do
          subject.save(channel: channel, client_id: client_id)

          channel_sub = subject.list(client_id: client_id).items.first
          expect(channel_sub).to be_a(Ably::Models::PushChannelSubscription)

          expect(channel_sub.channel).to eql(channel)
          expect(channel_sub.client_id).to eql(client_id)
          expect(channel_sub.device_id).to be_nil
        end

        it 'saves the new device_id PushChannelSubscription Hash object' do
          subject.save(channel: channel, device_id: device_id)

          channel_sub = subject.list(device_id: device_id).items.first
          expect(channel_sub).to be_a(Ably::Models::PushChannelSubscription)

          expect(channel_sub.channel).to eql(channel)
          expect(channel_sub.device_id).to eql(device_id)
          expect(channel_sub.client_id).to be_nil
        end

        it 'saves the client_id PushChannelSubscription object' do
          subject.save(PushChannelSubscription(channel: channel, client_id: client_id))

          channel_sub = subject.list(client_id: client_id).items.first
          expect(channel_sub).to be_a(Ably::Models::PushChannelSubscription)

          expect(channel_sub.channel).to eql(channel)
          expect(channel_sub.client_id).to eql(client_id)
          expect(channel_sub.device_id).to be_nil
        end

        it 'saves the device_id PushChannelSubscription object' do
          subject.save(PushChannelSubscription(channel: channel, device_id: device_id))

          channel_sub = subject.list(device_id: device_id).items.first
          expect(channel_sub).to be_a(Ably::Models::PushChannelSubscription)

          expect(channel_sub.channel).to eql(channel)
          expect(channel_sub.device_id).to eql(device_id)
          expect(channel_sub.client_id).to be_nil
        end

        it 'allows arbitrary number of subsequent saves' do
          10.times do
            subject.save(PushChannelSubscription(channel: channel, device_id: device_id))
          end

          channel_subs = subject.list(device_id: device_id).items
          expect(channel_subs.length).to eql(1)
          expect(channel_subs.first).to be_a(Ably::Models::PushChannelSubscription)
          expect(channel_subs.first.channel).to eql(channel)
          expect(channel_subs.first.device_id).to eql(device_id)
          expect(channel_subs.first.client_id).to be_nil
        end

        it 'fails if data is invalid' do
          expect { subject.save(channel: '', client_id: '') }.to raise_error ArgumentError
          expect { subject.save({}) }.to raise_error ArgumentError
          expect { subject.save(channel: 'not-enabled-channel', device_id: 'foo') }.to raise_error Ably::Exceptions::UnauthorizedRequest
          expect { subject.save(channel: 'pushenabled:foo', device_id: 'not-registered-so-will-fail') }.to raise_error Ably::Exceptions::InvalidRequest
        end
      end

      describe '#remove_where (#RSH1c5)' do
        let(:client_id) { random_str }
        let(:device_id) { random_str }
        let(:fixed_channel) { "pushenabled:#{random_str}" }

        let(:fixture_count) { 6 }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            [
              lambda { subject.save(channel: "pushenabled:#{random_str}", client_id: client_id) },
              lambda { subject.save(channel: "pushenabled:#{random_str}", device_id: device_id) },
              lambda { subject.save(channel: fixed_channel, device_id: device_id_2) }
            ]
          end.flatten.map do |proc|
            Thread.new { proc.call }
          end.each(&:join) # Wait for all threads to complete
        end

        # TODO: Reinstate once delete subscriptions by channel is possible
        #       See https://github.com/ably/realtime/issues/1359
        it 'removes matching channels' do
          skip 'deleting subscriptions is not yet supported realtime#1359'
          subject.remove_where channel: fixed_channel, full_wait: true
          expect(subject.list(channel: fixed_channel).items.count).to eql(0)
          expect(subject.list(client_id: client_id).items.count).to eql(0)
          expect(subject.list(device_id: device_id).items.count).to eql(0)
        end

        it 'removes matching client_ids' do
          subject.remove_where client_id: client_id, full_wait: true
          expect(subject.list(client_id: client_id).items.count).to eql(0)
          expect(subject.list(device_id: device_id).items.count).to eql(fixture_count)
        end

        it 'removes matching device_ids' do
          subject.remove_where device_id: device_id, full_wait: true
          expect(subject.list(device_id: device_id).items.count).to eql(0)
          expect(subject.list(client_id: client_id).items.count).to eql(fixture_count)
        end

        it 'device_id and client_id filters in the same request are not suppoorted' do
          expect { subject.remove_where(device_id: device_id, client_id: client_id) }.to raise_error(Ably::Exceptions::InvalidRequest)
        end

        it 'succeeds on no match' do
          subject.remove_where device_id: random_str, full_wait: true
          expect(subject.list(device_id: device_id).items.count).to eql(fixture_count)
          subject.remove_where client_id: random_str
          expect(subject.list(client_id: client_id).items.count).to eql(fixture_count)
        end
      end

      describe '#remove (#RSH1c4)' do
        let(:channel) { "pushenabled:#{random_str}" }
        let(:channel2) { "pushenabled:#{random_str}" }
        let(:client_id) { random_str }
        let(:device_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          [
            lambda { subject.save(channel: channel, client_id: client_id) },
            lambda { subject.save(channel: channel, device_id: device_id) },
            lambda { subject.save(channel: channel2, client_id: client_id) }
          ].map do |proc|
            Thread.new { proc.call }
          end.each(&:join) # Wait for all threads to complete
        end

        it 'removes match for Hash object by channel and client_id' do
          subject.remove(channel: channel, client_id: client_id)
          expect(subject.list(client_id: client_id).items.count).to eql(1)
        end

        it 'removes match for PushChannelSubscription object by channel and client_id' do
          push_sub = subject.list(channel: channel, client_id: client_id).items.first
          expect(push_sub).to be_a(Ably::Models::PushChannelSubscription)
          subject.remove(push_sub)
          expect(subject.list(client_id: client_id).items.count).to eql(1)
        end

        it 'removes match for Hash object by channel and device_id' do
          subject.remove(channel: channel, device_id: device_id)
          expect(subject.list(device_id: device_id).items.count).to eql(0)
        end

        it 'removes match for PushChannelSubscription object by channel and client_id' do
          push_sub = subject.list(channel: channel, device_id: device_id).items.first
          expect(push_sub).to be_a(Ably::Models::PushChannelSubscription)
          subject.remove(push_sub)
          expect(subject.list(device_id: device_id).items.count).to eql(0)
        end

        it 'succeeds even if there is no match' do
          subject.remove(device_id: 'does-not-exist', channel: random_str)
          expect(subject.list(device_id: 'does-not-exist').items.count).to eql(0)
        end
      end
    end
  end
end
