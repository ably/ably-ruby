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
          expect { subject.get }.to raise_error Ably::Exceptions::UnauthorizedRequest
        end
      end

      describe '#get' do
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
                transport_type: 'gcm'
              }
            })
          end
        end

        after do
          subject.remove client_id: client_id
        end

        it 'supports paging' do
          page = subject.get(limit: 5, client_id: client_id)
          expect(page).to be_a(Ably::Models::PaginatedResult)

          expect(page.items.count).to eql(5)
          page = page.next
          expect(page.items.count).to eql(5)
          page = page.next
          expect(page.items.count).to eql(0)
          expect(page).to be_last
        end

        it 'provides filtering' do
          page = subject.get(client_id: client_id)
          expect(page.items.length).to eql(fixture_count)

          page = subject.get(device_id: "device-#{client_id}-0")
          expect(page.items.length).to eql(1)

          page = subject.get(client_id: random_str)
          expect(page.items.length).to eql(0)
        end
      end

      describe '#save' do
        let(:device_id) { random_str }
        let(:client_id) { random_str }
        let(:transport_id) { random_str }
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
            update_token: 'ignore',
            push: {
              transport_type: 'apns',
              transport_id: transport_id,
              transport_token: transport_token,
              state: 1, # ignored
              error_reason: {
                message: "this will be ignored"
              },
              metadata: {
                foo_bar: 'string'
              }
            }
          }
        end

        after do
          subject.remove client_id: client_id
        end

        it 'saves the new DeviceDetails Hash object' do
          subject.save(device_details)

          devices_retrieved = subject.get(device_id: device_details.fetch(:id))
          expect(devices_retrieved).to be_a(Ably::Models::PaginatedResult)

          device_retrieved = devices_retrieved.items.first
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
          skip 'transportId and transportToken rae not writeable'
          subject.save(device_details)

          device_retrieved = subject.get(device_id: device_details.fetch(:id)).items.first

          expect(device_retrieved.push).to be_a(Ably::Models::DevicePushDetails)
          expect(device_retrieved.push.transport_type).to eql('apns')
          expect(device_retrieved.push.transport_id).to eql(transport_id)
          expect(device_retrieved.push.transport_token).to eql(transport_token)
        end

        it 'does not allow some fields to be configured' do
          subject.save(device_details)

          device_retrieved = subject.get(device_id: device_details.fetch(:id)).items.first

          # this was set to 1 i.e. FAILED
          # TODO: Fix this
          # expect(device_retrieved.push.state).to eql('ACTIVE')

          # value was set to "ignore"
          expect(device_retrieved.update_token).to_not eql('ignored')
          expect(device_retrieved.update_token).to_not be_nil

          # Errors are exclusively configure by Ably
          expect(device_retrieved.push.error_reason).to be_nil
        end

        it 'saves the new DeviceDetails object' do
          subject.save(DeviceDetails(device_details))

          device_retrieved = subject.get(device_id: device_details.fetch(:id)).items.first
          expect(device_retrieved.id).to eql(device_id)
          expect(device_retrieved.metadata[:foo]).to eql('bar')
          expect(device_retrieved.push.transport_type).to eql('apns')
        end

        it 'allows arbitrary number of subsequent saves' do
          skip 'Subsequent updates fail because of id being disallowed'

          10.times do
            subject.save(DeviceDetails(device_details))
          end

          device_retrieved = subject.get(device_id: device_details.fetch(:id)).items.first
          expect(device_retrieved.metadata[:foo]).to eql('bar')

          subject.save(DeviceDetails(device_details.merge(metadata: { foo: 'changed'})))
          device_retrieved = subject.get(device_id: device_details.fetch(:id)).items.first
          expect(device_retrieved.metadata[:foo]).to eql('changed')
        end

        it 'fails if data is invalid' do
          expect { subject.save(id: random_str, foo: 'bar') }.to raise_error Ably::Exceptions::InvalidRequest
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
              transport_type: 'gcm'
            }
          })

          subject.save({
            id: "device-#{client_id}-1",
            platform: 'ios',
            form_factor: 'phone',
            client_id: client_id,
            push: {
              transport_type: 'gcm'
            }
          })
        end

        after do
          subject.remove client_id: client_id
        end

        it 'removes all matching device registrations by client_id' do
          skip 'Delete by client_id not working'

          subject.remove(client_id: client_id)
          expect(subject.get.items.count).to eql(0)
        end

        it 'removes device by device_id' do
          subject.remove(device_id: "device-#{client_id}-1")
          expect(subject.get.items.count).to eql(1)
        end

        it 'removes DeviceDetails' do
          subject.remove(DeviceDetails(id: "device-#{client_id}-1"))
          expect(subject.get.items.count).to eql(1)
        end

        it 'succeeds even if no match' do
          subject.remove(device_id: random_str)
        end

        it 'fails if not params provided' do
          expect { subject.remove({}) }.to raise_error Ably::Exceptions::InvalidRequest
        end
      end
    end
  end
end
