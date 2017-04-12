# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Push do
  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol} }
    let(:client_options)  { default_options }
    let(:client) do
      Ably::Rest::Client.new(client_options)
    end
    subject { client.push }

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
      context 'without publish permissions' do
        let(:capability) { { :foo => ['subscribe'] } }

        before do
          client.auth.authorize(capability: capability)
        end

        it 'raises a permissions issue exception' do
          expect { subject.publish(basic_recipient, basic_notification_payload) }.to raise_error Ably::Exceptions::UnauthorizedRequest
        end
      end

      context 'invalid arguments' do
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

      context 'invalid recipient' do
        it 'raises an error after receiving a 40x realtime response' do
          expect { subject.publish({ invalid_recipient_details: 'foo.bar' }, basic_notification_payload) }.to raise_error Ably::Exceptions::InvalidRequest
        end
      end

      context 'invalid push data' do
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

      it 'accepts valid push data and recipient' do
        subject.publish(basic_recipient, basic_notification_payload)
      end

      context 'using test environment channel recipient' do
        let(:channel) { random_str }
        let(:recipient) do
          {
            ablyChannel: channel
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
          notification_published_on_channel = client.channels.get(channel).history.items.first
          expect(notification_published_on_channel.name).to eql('__ably_push__')
          expect(notification_published_on_channel.data).to eql(JSON.parse(notification_payload.to_json))
        end
      end
    end

    describe '#activate' do
      it 'raises an unsupported exception' do
        expect { subject.activate('foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
      end
    end

    describe '#deactivate' do
      it 'raises an unsupported exception' do
        expect { subject.deactivate('foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
      end
    end
  end
end
