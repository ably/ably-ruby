require 'spec_helper'
require 'support/model_helper'

describe Ably::Realtime::Models::PresenceMessage do
  include Ably::Modules::Conversions

  subject { Ably::Realtime::Models::PresenceMessage }
  let(:protocol_message_timestamp) { as_since_epoch(Time.now) }
  let(:protocol_message) { Ably::Realtime::Models::ProtocolMessage.new(action: 1, timestamp: protocol_message_timestamp) }

  it_behaves_like 'a realtime model', with_simple_attributes: %w(client_id member_id client_data) do
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

  context 'with state' do
    let(:model) { subject.new({ state: 0 }, protocol_message) }

    it 'provides state as an Enum' do
      expect(model.state).to eq(:enter)
    end
  end

  context 'without state' do
    let(:model) { subject.new({}, protocol_message) }

    it 'raises an exception when accessed' do
      expect { model.state }.to raise_error KeyError
    end
  end

  context '#to_json' do
    let(:json_object) { JSON.parse(model.to_json) }

    context 'with valid data' do
      let(:model) { subject.new({ state: 'enter', clientId: 'joe' }, protocol_message) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["clientId"]).to eql('joe')
      end
    end

    context 'with invalid data' do
      let(:model) { subject.new({ clientId: 'joe' }, protocol_message) }

      it 'raises an exception' do
        expect { model.to_json }.to raise_error KeyError, /cannot generate valid JSON/
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

    let(:protocol_message) do
      Ably::Realtime::Models::ProtocolMessage.new({
        action: :message,
        timestamp: ably_time.to_i,
        msg_serial: message_serial,
        connection_id: connection_id,
        presence: [
          presence_0_json, presence_1_json
        ]
      })
    end

    let(:presence_0) { protocol_message.presence.first }
    let(:presence_1) { protocol_message.presence.last }

    it 'should not modify the data payload' do
      expect(presence_0.client_data).to eql(presence_0_payload)
      expect(presence_1.client_data).to eql(presence_1_payload)
    end
  end

  context 'PresenceMessage conversion method' do
    let(:json) { { client_id: 'test' } }

    context 'with JSON' do
      context 'without ProtocolMessage' do
        subject { Ably::Realtime::Models.PresenceMessage(json) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Realtime::Models::PresenceMessage)
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
        subject { Ably::Realtime::Models.PresenceMessage(json, protocol_message) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Realtime::Models::PresenceMessage)
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
      let(:message) { Ably::Realtime::Models::PresenceMessage.new(json) }

      context 'without ProtocolMessage' do
        subject { Ably::Realtime::Models.PresenceMessage(message) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Realtime::Models::PresenceMessage)
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
        subject { Ably::Realtime::Models.PresenceMessage(message, protocol_message) }

        it 'returns a PresenceMessage object' do
          expect(subject).to be_a(Ably::Realtime::Models::PresenceMessage)
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
