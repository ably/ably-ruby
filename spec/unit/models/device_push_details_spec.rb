# encoding: utf-8
require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::DevicePushDetails do
  include Ably::Modules::Conversions

  subject { Ably::Models::DevicePushDetails }

  %w(state).each do |string_attribute|
    let(:empty_push_details) { subject.new }

    describe "##{string_attribute} and ##{string_attribute}=" do
      let(:new_val) { random_str }

      specify 'setter accepts a string value and getter returns the new value' do
        expect(empty_push_details.public_send(string_attribute)).to be_nil
        empty_push_details.public_send("#{string_attribute}=", new_val)
        expect(empty_push_details.public_send(string_attribute)).to eql(new_val)
      end

      specify 'setter accepts nil' do
        empty_push_details.public_send("#{string_attribute}=", new_val)
        expect(empty_push_details.public_send(string_attribute)).to eql(new_val)
        empty_push_details.public_send("#{string_attribute}=", nil)
        expect(empty_push_details.public_send(string_attribute)).to be_nil
      end

      specify 'rejects non string or nil values' do
        expect { empty_push_details.public_send("#{string_attribute}=", {}) }.to raise_error(ArgumentError)
      end
    end
  end

  context 'camelCase constructor attributes' do
    let(:transport_type) { random_str }
    let(:push_details) { subject.new('errorReason' => { 'message' => 'foo' }, 'recipient' => { 'transportType' => transport_type }) }

    specify 'are rubyfied and exposed as underscore case' do
      expect(push_details.recipient[:transport_type]).to eql(transport_type)
      expect(push_details.error_reason.message).to eql('foo')
    end

    specify 'are generated when the object is serialised to JSON' do
      expect(JSON.parse(push_details.to_json)['recipient']['transportType']).to eql(transport_type)
    end
  end

  describe "#recipient and #recipient=" do
    let(:new_val) { { foo: random_str } }

    specify 'setter accepts a Hash value and getter returns the new value' do
      expect(empty_push_details.recipient).to eql({})
      empty_push_details.recipient = new_val
      expect(empty_push_details.recipient.to_json).to eql(new_val.to_json)
    end

    specify 'setter accepts nil but always returns an empty hash' do
      empty_push_details.recipient = new_val
      expect(empty_push_details.recipient.to_json).to eql(new_val.to_json)
      empty_push_details.recipient = nil
      expect(empty_push_details.recipient).to eql({})
    end

    specify 'rejects non Hash or nil values' do
      expect { empty_push_details.recipient = "foo" }.to raise_error(ArgumentError)
    end
  end

  describe "#error_reason and #error_reason=" do
    let(:error_message) { random_str }
    let(:error_attributes) { { message: error_message } }

    specify 'setter accepts a ErrorInfo object and getter returns a ErrorInfo object' do
      expect(empty_push_details.error_reason).to be_nil
      empty_push_details.error_reason = ErrorInfo(error_attributes)
      expect(empty_push_details.error_reason).to be_a(Ably::Models::ErrorInfo)
      expect(empty_push_details.error_reason.message).to eql(error_message)
      expect(empty_push_details.error_reason.to_json).to eql(error_attributes.to_json)
    end

    specify 'setter accepts a Hash value and getter returns a ErrorInfo object' do
      expect(empty_push_details.error_reason).to be_nil
      empty_push_details.error_reason = error_attributes
      expect(empty_push_details.error_reason).to be_a(Ably::Models::ErrorInfo)
      expect(empty_push_details.error_reason.message).to eql(error_message)
      expect(empty_push_details.error_reason.to_json).to eql(error_attributes.to_json)
    end

    specify 'setter accepts nil values' do
      empty_push_details.error_reason = error_attributes
      expect(empty_push_details.error_reason.to_json).to eql(error_attributes.to_json)
      empty_push_details.error_reason = nil
      expect(empty_push_details.error_reason).to be_nil
    end

    specify 'rejects non Hash, ErrorInfo or nil values' do
      expect { empty_push_details.error_reason = "foo" }.to raise_error(ArgumentError)
    end
  end
end
