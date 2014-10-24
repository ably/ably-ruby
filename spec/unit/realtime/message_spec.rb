require 'spec_helper'
require 'support/model_helper'

describe Ably::Realtime::Models::Message do
  include Ably::Modules::Conversions

  subject { Ably::Realtime::Models::Message }
  let(:protocol_message_timestamp) { as_since_epoch(Time.now) }
  let(:protocol_message) { Ably::Realtime::Models::ProtocolMessage.new(action: 1, timestamp: protocol_message_timestamp) }

  it_behaves_like 'a realtime model', with_simple_attributes: %w(name client_id data) do
    let(:model_args) { [protocol_message] }
  end

  context '#timestamp' do
    let(:model) { subject.new({}, protocol_message) }
    it 'retrieves attribute :timestamp from ProtocolMessage' do
      expect(model.timestamp).to be_a(Time)
      expect(model.timestamp.to_i).to be_within(1).of(Time.now.to_i)
    end
  end

  context 'Java naming' do
    let(:model) { subject.new({ clientId: 'joe' }, protocol_message) }

    it 'converts the attribute to ruby symbol naming convention' do
      expect(model.client_id).to eql('joe')
    end
  end

  context '#to_json' do
    let(:json_object) { JSON.parse(model.to_json) }

    context 'with valid data' do
      let(:model) { subject.new({ name: 'test', clientId: 'joe' }, protocol_message) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["clientId"]).to eql('joe')
      end
    end

    context 'with invalid data' do
      let(:model) { subject.new({ clientId: 'joe' }, protocol_message) }

      it 'raises an exception' do
        expect { model.to_json }.to raise_error RuntimeError, /cannot generate valid JSON/
      end
    end
  end

  context 'part of ProtocolMessage' do
    let(:ably_time) { Time.now + 5 }
    let(:message_serial) { SecureRandom.random_number(1_000_000) }
    let(:connection_id) { SecureRandom.hex }

    let(:message_0_payload) do
      {
        'string_key' => 'string_value',
        1 => 2,
        true => false
      }
    end

    let(:message_0_json) do
      {
        name: 'zero',
        data: message_0_payload
      }
    end

    let(:message_1_json) do
      {
        name: 'one',
        data: 'simple string'
      }
    end

    let(:protocol_message) do
      Ably::Realtime::Models::ProtocolMessage.new({
        timestamp: ably_time.to_i,
        msg_serial: message_serial,
        connection_id: connection_id,
        messages: [
          message_0_json, message_1_json
        ]
      })
    end

    let(:message_0) { protocol_message.messages.first }
    let(:message_1) { protocol_message.messages.last }

    it 'should generate a message ID from the index, serial and connection id' do
      expect(message_0.id).to eql("#{connection_id}:#{message_serial}:0")
      expect(message_1.id).to eql("#{connection_id}:#{message_serial}:1")
    end

    it 'should not modify the data payload' do
      expect(message_0.data['string_key']).to eql('string_value')
      expect(message_0.data[1]).to eql(2)
      expect(message_0.data[true]).to eql(false)
      expect(message_0.data).to eql(message_0_payload)

      expect(message_1.data).to eql('simple string')
    end

    it 'should not allow changes to the payload' do
      expect { message_0.data["test"] = true }.to raise_error RuntimeError, /can't modify frozen Hash/
    end
  end
end
