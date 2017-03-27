# encoding: utf-8
require 'spec_helper'

describe Ably::Realtime::Push, :event_machine do
  vary_by_protocol do
    let(:default_options) { { key: api_key, environment: environment, protocol: protocol} }
    let(:client_options)  { default_options }
    let(:client) do
      Ably::Realtime::Client.new(client_options)
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
        it 'raises an error after receiving a 40x realtime response' do
          skip 'validation on raw push is not enabled in realtime'
          subject.publish({ invalid_recipient_details: 'foo.bar' }, basic_notification_payload).errback do |error|
            expect(error.message).to match(/Invalid recipient/)
            stop_reactor
          end
        end
      end

      context 'invalid push data' do
        it 'raises an error after receiving a 40x realtime response' do
          skip 'validation on raw push is not enabled in realtime'
          subject.publish(basic_recipient, { invalid_property_only: true }).errback do |error|
            expect(error.message).to match(/Invalid push notification data/)
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
        let(:push_channel) do
          client.channels.get(channel)
        end

        it 'triggers a push notification' do
          push_channel.attach do
            push_channel.subscribe do |message|
              expect(message.name).to eql('__ably_push__')
              expect(message.data).to eql(JSON.parse(notification_payload.to_json))
              stop_reactor
            end
            subject.publish recipient, notification_payload
          end
        end
      end
    end

    describe '#activate' do
      it 'raises an unsupported exception' do
        expect { subject.activate('foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
        stop_reactor
      end
    end

    describe '#deactivate' do
      it 'raises an unsupported exception' do
        expect { subject.deactivate('foo') }.to raise_error(Ably::Exceptions::PushNotificationsNotSupported)
        stop_reactor
      end
    end
  end
end
