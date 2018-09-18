# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::DeviceDetails do
  include Ably::Modules::Conversions

  subject { Ably::Models::DeviceDetails }

  %w(id platform form_factor client_id device_secret).each do |string_attribute|
    let(:empty_device_details) { subject.new }

    describe "##{string_attribute} and ##{string_attribute}=" do
      let(:new_val) { random_str }

      specify 'setter accepts a string value and getter returns the new value' do
        expect(empty_device_details.public_send(string_attribute)).to be_nil
        empty_device_details.public_send("#{string_attribute}=", new_val)
        expect(empty_device_details.public_send(string_attribute)).to eql(new_val)
      end

      specify 'setter accepts nil' do
        empty_device_details.public_send("#{string_attribute}=", new_val)
        expect(empty_device_details.public_send(string_attribute)).to eql(new_val)
        empty_device_details.public_send("#{string_attribute}=", nil)
        expect(empty_device_details.public_send(string_attribute)).to be_nil
      end

      specify 'rejects non string or nil values' do
        expect { empty_device_details.public_send("#{string_attribute}=", {}) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'camelCase constructor attributes' do
    let(:client_id) { random_str }
    let(:device_details) { subject.new("clientId" => client_id ) }

    specify 'are rubyfied and exposed as underscore case' do
      expect(device_details.client_id).to eql(client_id)
    end

    specify 'are generated when the object is serialised to JSON' do
      expect(JSON.parse(device_details.to_json)["clientId"]).to eql(client_id)
    end
  end

  describe "#metadata and #metadata=" do
    let(:new_val) { { foo: random_str } }

    specify 'setter accepts a Hash value and getter returns the new value' do
      expect(empty_device_details.metadata).to eql({})
      empty_device_details.metadata = new_val
      expect(empty_device_details.metadata.to_json).to eql(new_val.to_json)
    end

    specify 'setter accepts nil but always returns an empty hash' do
      empty_device_details.metadata = new_val
      expect(empty_device_details.metadata.to_json).to eql(new_val.to_json)
      empty_device_details.metadata = nil
      expect(empty_device_details.metadata).to eql({})
    end

    specify 'rejects non Hash or nil values' do
      expect { empty_device_details.metadata = "foo" }.to raise_error(ArgumentError)
    end
  end

  describe "#push and #push=" do
    let(:transport_type) { random_str }
    let(:new_val) { { recipient: { transport_type: transport_type } } }
    let(:json_val) { { recipient: { transportType: transport_type } }.to_json }

    specify 'setter accepts a DevicePushDetails object and getter returns a DevicePushDetails object' do
      expect(empty_device_details.push.to_json).to eql({}.to_json)
      empty_device_details.push = DevicePushDetails(new_val)
      expect(empty_device_details.push).to be_a(Ably::Models::DevicePushDetails)
      expect(empty_device_details.push.recipient[:transport_type]).to eql(transport_type)
      expect(empty_device_details.push.to_json).to eql(json_val)
    end

    specify 'setter accepts a Hash value and getter returns a DevicePushDetails object' do
      expect(empty_device_details.push.to_json).to eql({}.to_json)
      empty_device_details.push = new_val
      expect(empty_device_details.push).to be_a(Ably::Models::DevicePushDetails)
      expect(empty_device_details.push.recipient[:transport_type]).to eql(transport_type)
      expect(empty_device_details.push.to_json).to eql(json_val)
    end

    specify 'setter accepts nil but always returns a DevicePushDetails object' do
      empty_device_details.push = new_val
      expect(empty_device_details.push.to_json).to eql(json_val)
      empty_device_details.push = nil
      expect(empty_device_details.push).to be_a(Ably::Models::DevicePushDetails)
      expect(empty_device_details.push.to_json).to eql({}.to_json)
    end

    specify 'rejects non Hash, DevicePushDetails or nil values' do
      expect { empty_device_details.metadata = "foo" }.to raise_error(ArgumentError)
    end
  end
end
