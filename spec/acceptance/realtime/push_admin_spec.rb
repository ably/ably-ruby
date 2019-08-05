# encoding: utf-8
require 'spec_helper'

# These tests are a subset of Ably::Rest::Push::Admin in async EM style
# The more robust complete test suite is in rest/push_admin_spec.rb
describe Ably::Realtime::Push::Admin, :event_machine do
  include Ably::Modules::Conversions

  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol} }
    let(:client_options)  { default_options }
    let(:client) do
      Ably::Realtime::Client.new(client_options)
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

      it 'returns a SafeDeferrable that catches exceptions in callbacks and logs them' do
        publish_deferrable = subject.publish(basic_recipient, basic_notification_payload)
        expect(publish_deferrable).to be_a(Ably::Util::SafeDeferrable)
        publish_deferrable.callback do
          stop_reactor
        end
      end

      context 'invalid arguments' do
        it 'raises an exception with a nil recipient' do
          expect { subject.publish(nil, {}) }.to raise_error ArgumentError, /Expecting a Hash/
          stop_reactor
        end

        it 'raises an exception with a empty recipient' do
          expect { subject.publish({}, {}) }.to raise_error ArgumentError, /empty/
          stop_reactor
        end

        it 'raises an exception with a nil recipient' do
          expect { subject.publish(basic_recipient, nil) }.to raise_error ArgumentError, /Expecting a Hash/
          stop_reactor
        end

        it 'raises an exception with a empty recipient' do
          expect { subject.publish(basic_recipient, {}) }.to raise_error ArgumentError, /empty/
          stop_reactor
        end
      end

      context 'invalid recipient' do
        let(:default_options) { { key: api_key, environment: environment, protocol: protocol, log_level: :fatal } }

        it 'raises an error after receiving a 40x realtime response' do
          subject.publish({ invalid_recipient_details: 'foo.bar' }, basic_notification_payload).errback do |error|
            expect(error.message).to match(/recipient must contain/)
            stop_reactor
          end
        end
      end

      context 'invalid push data' do
        let(:default_options) { { key: api_key, environment: environment, protocol: protocol, log_level: :fatal } }

        it 'raises an error after receiving a 40x realtime response' do
          subject.publish(basic_recipient, { invalid_property_only: true }).errback do |error|
            expect(error.message).to match(/Unexpected field/)
            stop_reactor
          end
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
          stub_request(:post, "#{client.rest_client.endpoint}/push/publish").
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
          subject.publish(recipient_payload, basic_notification_payload) do
            expect(publish_stub).to have_been_requested
            stop_reactor
          end
        end
      end

      it 'accepts valid push data and recipient' do
        subject.publish(basic_recipient, basic_notification_payload) do
          stop_reactor
        end
      end

      context 'using test environment channel recipient (#RSH1a)' do
        let(:channel) { random_str }
        let(:recipient) do
          {
            'transportType' => 'ablyChannel',
            'channel' => channel,
            'ablyKey' => api_key,
            'ablyUrl' => client.rest_client.endpoint.to_s
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
        let(:push_channel) do
          client.channels.get(channel)
        end

        it 'triggers a push notification' do
          push_channel.attach do
            push_channel.subscribe do |message|
              expect(message.name).to eql('__ably_push__')
              expect(JSON.parse(message.data)['data']).to eql(JSON.parse(notification_payload[:data].to_json))
              stop_reactor
            end
            subject.publish recipient, notification_payload
          end
        end
      end
    end

    describe '#device_registrations' do
      subject { client.push.admin.device_registrations }
      let(:rest_device_registrations) {
        client.rest_client.push.admin.device_registrations
      }

      context 'without permissions' do
        let(:client_options) do
          default_options.merge(
            use_token_auth: true,
            default_token_params: { capability: { :foo => ['subscribe'] } },
            log_level: :fatal,
          )
        end

        it 'raises a permissions not authorized exception' do
          subject.get('does-not-exist').errback do |err|
            expect(err).to be_a(Ably::Exceptions::UnauthorizedRequest)
            subject.list.errback do |err|
              expect(err).to be_a(Ably::Exceptions::UnauthorizedRequest)
              subject.remove('does-not-exist').errback do |err|
                expect(err).to be_a(Ably::Exceptions::UnauthorizedRequest)
                subject.remove_where(device_id: 'does-not-exist').errback do |err|
                  expect(err).to be_a(Ably::Exceptions::UnauthorizedRequest)
                  stop_reactor
                end
              end
            end
          end
        end
      end

      describe '#list' do
        let(:client_id) { random_str }
        let(:fixture_count) { 6 }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            Thread.new do # Parallelise the setup
              rest_device_registrations.save({
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
          rest_device_registrations.remove_where client_id: client_id
        end

        it 'returns a PaginatedResult object containing DeviceDetails objects' do
          subject.list do |page|
            expect(page).to be_a(Ably::Models::PaginatedResult)
            expect(page.items.first).to be_a(Ably::Models::DeviceDetails)
            stop_reactor
          end
        end

        it 'supports paging' do
          subject.list(limit: 3, client_id: client_id) do |page|
            expect(page).to be_a(Ably::Models::PaginatedResult)

            expect(page.items.count).to eql(3)
            page.next do |page|
              expect(page.items.count).to eql(3)
              page.next do |page|
                expect(page.items.count).to eql(0)
                expect(page).to be_last
                stop_reactor
              end
            end
          end
        end

        it 'raises an exception if params are invalid' do
          expect { subject.list("invalid_arg") }.to raise_error(ArgumentError)
          stop_reactor
        end
      end

      describe '#get' do
        let(:fixture_count) { 2 }
        let(:client_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            Thread.new do # Parallelise the setup
              rest_device_registrations.save({
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
          rest_device_registrations.remove_where client_id: client_id
        end

        it 'returns a DeviceDetails object if a device ID string is provided' do
          subject.get("device-#{client_id}-0").callback do |device|
            expect(device).to be_a(Ably::Models::DeviceDetails)
            expect(device.platform).to eql('ios')
            expect(device.client_id).to eql(client_id)
            expect(device.push.recipient.fetch(:transport_type)).to eql('gcm')
            stop_reactor
          end
        end

        context 'with a failed request' do
          let(:client_options) do
            default_options.merge(
              log_level: :fatal,
            )
          end

          it 'raises a ResourceMissing exception if device ID does not exist' do
            subject.get("device-does-not-exist").errback do |err|
              expect(err).to be_a(Ably::Exceptions::ResourceMissing)
              stop_reactor
            end
          end
        end
      end

      describe '#save' do
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
          rest_device_registrations.remove_where client_id: client_id
        end

        it 'saves the new DeviceDetails Hash object' do
          subject.save(device_details) do
            subject.get(device_details.fetch(:id)) do |device_retrieved|
              expect(device_retrieved).to be_a(Ably::Models::DeviceDetails)
              expect(device_retrieved.id).to eql(device_id)
              expect(device_retrieved.platform).to eql('android')
              stop_reactor
            end
          end
        end

        context 'with a failed request' do
          let(:client_options) do
            default_options.merge(
              log_level: :fatal,
            )
          end

          it 'fails if data is invalid' do
            subject.save(id: random_str, foo: 'bar').errback do |err|
              expect(err).to be_a(Ably::Exceptions::InvalidRequest)
              stop_reactor
            end
          end
        end
      end

      describe '#remove_where' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          rest_device_registrations.save({
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
        end

        after do
          rest_device_registrations.remove_where client_id: client_id
        end

        it 'removes all matching device registrations by client_id' do
          subject.remove_where(client_id: client_id, full_wait: true) do
            subject.list do |page|
              expect(page.items.count).to eql(0)
              stop_reactor
            end
          end
        end
      end

      describe '#remove' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          rest_device_registrations.save({
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
        end

        after do
          rest_device_registrations.remove_where client_id: client_id
        end

        it 'removes the provided device id string' do
          subject.remove("device-#{client_id}-0") do
            subject.list do |page|
              expect(page.items.count).to eql(0)
              stop_reactor
            end
          end
        end
      end
    end

    describe '#channel_subscriptions' do
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

      let(:rest_device_registrations) {
        client.rest_client.push.admin.device_registrations
      }

      let(:rest_channel_subscriptions) {
        client.rest_client.push.admin.channel_subscriptions
      }

      subject {
        client.push.admin.channel_subscriptions
      }

      before(:all) do
        # As push tests often use the global scope (devices),
        #   we need to ensure tests cannot conflict
        reload_test_app
      end

      # Set up 2 devices with the same client_id
      #  and two device with the unique device_id and no client_id
      before do
        [
          lambda { rest_device_registrations.save(default_device_attr.merge(id: device_id)) },
          lambda { rest_device_registrations.save(default_device_attr.merge(id: device_id_2)) },
          lambda { rest_device_registrations.save(default_device_attr.merge(client_id: client_id, id: random_str)) },
          lambda { rest_device_registrations.save(default_device_attr.merge(client_id: client_id, id: random_str)) }
        ].map do |proc|
          Thread.new { proc.call }
        end.each(&:join) # Wait for all threads to complete
      end

      after do
        rest_device_registrations.remove_where client_id: client_id
        rest_device_registrations.remove_where device_id: device_id
      end

      describe '#list' do
        let(:fixture_count) { 6 }

        before do
          fixture_count.times.map do |index|
            Thread.new { rest_channel_subscriptions.save(channel: "pushenabled:#{random_str}", client_id: client_id) }
          end + fixture_count.times.map do |index|
            Thread.new { rest_channel_subscriptions.save(channel: "pushenabled:#{random_str}", device_id: device_id) }
          end.each(&:join) # Wait for all threads to complete
        end

        it 'returns a PaginatedResult object containing DeviceDetails objects' do
          subject.list(client_id: client_id) do |page|
            expect(page).to be_a(Ably::Models::PaginatedResult)
            expect(page.items.first).to be_a(Ably::Models::PushChannelSubscription)
            stop_reactor
          end
        end

        it 'supports paging' do
          subject.list(limit: 3, device_id: device_id) do |page|
            expect(page).to be_a(Ably::Models::PaginatedResult)

            expect(page.items.count).to eql(3)
            page.next do |page|
              expect(page.items.count).to eql(3)
              page.next do |page|
                expect(page.items.count).to eql(0)
                expect(page).to be_last
                stop_reactor
              end
            end
          end
        end

        it 'raises an exception if none of the required filters are provided' do
          expect { subject.list({ limit: 100 }) }.to raise_error(ArgumentError)
          stop_reactor
        end
      end

      describe '#list_channels' do
        let(:fixture_count) { 6 }

        before(:all) do
          # As push tests often use the global scope (devices),
          #   we need to ensure tests cannot conflict
          reload_test_app
        end

        before do
          fixture_count.times.map do |index|
            Thread.new do
              rest_channel_subscriptions.save(channel: "pushenabled:#{index}:#{random_str}", client_id: client_id)
            end
          end.each(&:join) # Wait for all threads to complete
        end

        after do
          rest_channel_subscriptions.remove_where client_id: client_id, full_wait: true # undocumented arg to do deletes synchronously
        end

        it 'returns a PaginatedResult object containing String objects' do
          subject.list_channels do |page|
            expect(page).to be_a(Ably::Models::PaginatedResult)
            expect(page.items.first).to be_a(String)
            expect(page.items.length).to eql(fixture_count)
            stop_reactor
          end
        end
      end

      describe '#save' do
        let(:channel) { "pushenabled:#{random_str}" }
        let(:client_id) { random_str }
        let(:device_id) { random_str }

        it 'saves the new client_id PushChannelSubscription Hash object' do
          subject.save(channel: channel, client_id: client_id) do
            subject.list(client_id: client_id) do |page|
              channel_sub = page.items.first
              expect(channel_sub).to be_a(Ably::Models::PushChannelSubscription)
              expect(channel_sub.channel).to eql(channel)
              stop_reactor
            end
          end
        end

        it 'raises an exception for invalid params' do
          expect { subject.save(channel: '', client_id: '') }.to raise_error ArgumentError
          expect { subject.save({}) }.to raise_error ArgumentError
          stop_reactor
        end

        context 'failed requests' do
          let(:client_options) do
            default_options.merge(
              log_level: :fatal,
            )
          end

          it 'fails for invalid requests' do
            subject.save(channel: 'not-enabled-channel', device_id: 'foo').errback do |err|
              expect(err).to be_a(Ably::Exceptions::UnauthorizedRequest)
              subject.save(channel: 'pushenabled:foo', device_id: 'not-registered-so-will-fail').errback do |err|
                expect(err).to be_a(Ably::Exceptions::InvalidRequest)
                stop_reactor
              end
            end
          end
        end
      end

      describe '#remove_where' do
        let(:client_id) { random_str }
        let(:device_id) { random_str }
        let(:fixed_channel) { "pushenabled:#{random_str}" }

        let(:fixture_count) { 6 }

        before do
          fixture_count.times.map do |index|
            Thread.new do
              rest_channel_subscriptions.save(channel: "pushenabled:#{random_str}", client_id: client_id)
            end
          end.each(&:join) # Wait for all threads to complete
        end

        it 'removes matching client_ids' do
          subject.list(client_id: client_id) do |page|
            expect(page.items.count).to eql(fixture_count)
            subject.remove_where(client_id: client_id, full_wait: true) do
              subject.list(client_id: client_id) do |page|
                expect(page.items.count).to eql(0)
                stop_reactor
              end
            end
          end
        end

        context 'failed requests' do
          let(:client_options) do
            default_options.merge(
              log_level: :fatal,
            )
          end

          it 'device_id and client_id filters in the same request are not supported' do
            subject.remove_where(device_id: device_id, client_id: client_id).errback do |err|
              expect(err).to be_a(Ably::Exceptions::InvalidRequest)
              stop_reactor
            end
          end
        end

        it 'succeeds on no match' do
          subject.remove_where(device_id: random_str, full_wait: true) do
            subject.list(client_id: client_id) do |page|
              expect(page.items.count).to eql(fixture_count)
              stop_reactor
            end
          end
        end
      end

      describe '#remove' do
        let(:channel) { "pushenabled:#{random_str}" }
        let(:channel2) { "pushenabled:#{random_str}" }
        let(:client_id) { random_str }
        let(:device_id) { random_str }

        before do
          rest_channel_subscriptions.save(channel: channel, client_id: client_id)
        end

        it 'removes match for Hash object by channel and client_id' do
          subject.list(client_id: client_id) do |page|
            expect(page.items.count).to eql(1)
            subject.remove(channel: channel, client_id: client_id, full_wait: true) do
              subject.list(client_id: client_id) do |page|
                expect(page.items.count).to eql(0)
                stop_reactor
              end
            end
          end
        end

        it 'succeeds even if there is no match' do
          subject.remove(device_id: 'does-not-exist', channel: random_str) do
            subject.list(device_id: 'does-not-exist') do |page|
              expect(page.items.count).to eql(0)
              stop_reactor
            end
          end
        end
      end
    end
  end
end
