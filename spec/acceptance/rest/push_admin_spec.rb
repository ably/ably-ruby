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

    describe '#device_registrations' do
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

      describe '#list' do
        let(:client_id) { random_str }
        let(:fixture_count) { 10 }

        before do
          fixture_count.times do |index|
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
        end

        after do
          subject.remove_where client_id: client_id
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
          page = subject.list(limit: 5, client_id: client_id)
          expect(page).to be_a(Ably::Models::PaginatedResult)

          expect(page.items.count).to eql(5)
          page = page.next
          expect(page.items.count).to eql(5)
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

      describe '#get' do
        let(:fixture_count) { 2 }
        let(:client_id) { random_str }

        before do
          fixture_count.times do |index|
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
        end

        after do
          subject.remove_where client_id: client_id
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

        after do
          subject.remove_where client_id: client_id
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

          expect(device_retrieved.update_token).to_not be_nil

          # Errors are exclusively configure by Ably
          expect(device_retrieved.push.error_reason).to be_nil
        end

        it 'saves the new DeviceDetails object' do
          subject.save(DeviceDetails(device_details))

          device_retrieved = subject.get(device_details.fetch(:id))
          expect(device_retrieved.id).to eql(device_id)
          expect(device_retrieved.metadata[:foo]).to eql('bar')
          expect(device_retrieved.push.recipient[:transport_type]).to eql('apns')
        end

        it 'allows arbitrary number of subsequent saves' do
          10.times do
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

      describe '#remove_where' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }

        before do
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

        after do
          subject.remove_where client_id: client_id
        end

        it 'removes all matching device registrations by client_id' do
          subject.remove_where(client_id: client_id)
          expect(subject.list.items.count).to eql(0)
        end

        it 'removes device by device_id' do
          subject.remove_where(device_id: "device-#{client_id}-1")
          expect(subject.list.items.count).to eql(1)
        end

        it 'succeeds even if there is no match' do
          subject.remove_where(device_id: 'does-not-exist')
          expect(subject.list.items.count).to eql(2)
        end
      end

      describe '#remove' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }

        before do
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

        after do
          subject.remove_where client_id: client_id
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
  end
end
