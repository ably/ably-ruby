require 'spec_helper'
require 'support/model_helper'

describe Ably::Models::PresenceMessage do
  include Ably::Modules::Conversions

  subject { Ably::Models::PresenceMessage }
  let(:protocol_message_timestamp) { as_since_epoch(Time.now) }
  let(:protocol_message) { Ably::Models::ProtocolMessage.new(action: 1, timestamp: protocol_message_timestamp) }

  it_behaves_like 'a model', with_simple_attributes: %w(client_id member_id client_data) do
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

  context 'with action' do
    let(:model) { subject.new({ action: 0 }, protocol_message) }

    it 'provides action as an Enum' do
      expect(model.action).to eq(:enter)
    end
  end

  context 'without action' do
    let(:model) { subject.new({}, protocol_message) }

    it 'raises an exception when accessed' do
      expect { model.action }.to raise_error KeyError
    end
  end

  context '#to_json' do
    let(:json_object) { JSON.parse(model.to_json) }

    context 'with valid data' do
      let(:model) { subject.new({ action: 'enter', clientId: 'joe' }, protocol_message) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["clientId"]).to eql('joe')
      end
    end

    context 'with invalid data' do
      let(:model) { subject.new({ clientId: 'joe' }, protocol_message) }

      it 'raises an exception' do
        expect { model.to_json }.to raise_error KeyError, /cannot generate a valid Hash/
      end
    end
  end

  context 'from REST request with embedded fields' do
    let(:id) { SecureRandom.hex }
    let(:message_time) { Time.now + 60 }
    let(:timestamp) { as_since_epoch(message_time) }
    let(:model) { subject.new(id: id, timestamp: timestamp) }

    context 'with protocol message' do
      specify '#id prefers embedded ID' do
        expect(model.id).to eql(id)
      end

      specify '#timestamp prefers embedded timestamp' do
        expect(model.timestamp.to_i).to be_within(1).of(message_time.to_i)
      end
    end

    context 'without protocol message' do
      specify '#id uses embedded ID' do
        expect(model.id).to eql(id)
      end

      specify '#timestamp uses embedded timestamp' do
        expect(model.timestamp.to_i).to be_within(1).of(message_time.to_i)
      end
    end
  end

  context 'part of ProtocolMessage' do
    let(:ably_time) { Time.now + 5 }
    let(:message_serial) { SecureRandom.random_number(1_000_000) }
    let(:connection_id) { SecureRandom.hex }

    let(:presence_0_payload) { SecureRandom.hex(8) }
    let(:presence_0_json) do
      {
        client_id: 'zero',
        client_data: presence_0_payload
      }
    end
    let(:presence_1_payload) { SecureRandom.hex(8) }
    let(:presence_1_json) do
      {
        client_id: 'one',
        client_data: presence_1_payload
      }
    end

    let(:protocol_message_id) { SecureRandom.hex }
    let(:protocol_message) do
      Ably::Models::ProtocolMessage.new({
        action: :message,
        timestamp: ably_time.to_i,
        msg_serial: message_serial,
        id: protocol_message_id,
        presence: [
          presence_0_json, presence_1_json
        ]
      })
    end

    let(:presence_0) { protocol_message.presence.first }
    let(:presence_1) { protocol_message.presence.last }

    it 'should generate a message ID from the index, serial and connection id' do
      expect(presence_0.id).to eql("#{protocol_message_id}:0")
      expect(presence_1.id).to eql("#{protocol_message_id}:1")
    end

    it 'should not modify the data payload' do
      expect(presence_0.client_data).to eql(presence_0_payload)
      expect(presence_1.client_data).to eql(presence_1_payload)
    end
  end

  context 'PresenceMessage conversion method' do
    let(:json) { { client_id: 'test' } }

    context 'with JSON' do
      context 'without ProtocolMessage' do
        subject { Ably::Models.PresenceMessage(json) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Models::PresenceMessage)
        end

        it 'initializes with the JSON' do
          expect(subject.client_id).to eql('test')
        end

        it 'raises an exception when accessing ProtocolMessage' do
          expect { subject.protocol_message }.to raise_error RuntimeError
        end

        it 'has no ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(false)
        end
      end

      context 'with ProtocolMessage' do
        subject { Ably::Models.PresenceMessage(json, protocol_message) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Models::PresenceMessage)
        end

        it 'initializes with the JSON' do
          expect(subject.client_id).to eql('test')
        end

        it 'provides access to ProtocolMessage' do
          expect(subject.protocol_message).to eql(protocol_message)
        end

        it 'has a ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(true)
        end
      end
    end

    context 'with another PresenceMessage' do
      let(:message) { Ably::Models::PresenceMessage.new(json) }

      context 'without ProtocolMessage' do
        subject { Ably::Models.PresenceMessage(message) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Models::PresenceMessage)
        end

        it 'initializes with the JSON' do
          expect(subject.client_id).to eql('test')
        end

        it 'raises an exception when accessing ProtocolMessage' do
          expect { subject.protocol_message }.to raise_error RuntimeError
        end

        it 'has no ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(false)
        end
      end

      context 'with ProtocolMessage' do
        subject { Ably::Models.PresenceMessage(message, protocol_message) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Models::PresenceMessage)
        end

        it 'initializes with the JSON' do
          expect(subject.client_id).to eql('test')
        end

        it 'provides access to ProtocolMessage' do
          expect(subject.protocol_message).to eql(protocol_message)
        end

        it 'has a ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(true)
        end
      end
    end
  end
end
