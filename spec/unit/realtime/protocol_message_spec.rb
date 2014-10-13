require 'spec_helper'
require 'support/model_helper'

describe Ably::Realtime::Models::ProtocolMessage do
  include Ably::Modules::Conversions
  subject { Ably::Realtime::Models::ProtocolMessage }

  it_behaves_like 'a realtime model',
    with_simple_attributes: %w(count channel channel_serial connection_id connection_serial) do

    let(:model_args) { [] }
  end

  context 'attributes' do
    let(:unique_value) { SecureRandom.hex }

    context 'Java naming' do
      let(:protocol_message) { subject.new(channelSerial: unique_value) }

      it 'converts the attribute to ruby symbol naming convention' do
        expect(protocol_message.channel_serial).to eql(unique_value)
      end
    end

    context '#action' do
      let(:protocol_message) { subject.new(action: 14) }

      it 'returns an Enum that behaves like a symbol' do
        expect(protocol_message.action).to eq(:presence)
      end

      it 'returns an Enum that behaves like a Numeric' do
        expect(protocol_message.action).to eq(14)
      end

      it 'returns an Enum that behaves like a String' do
        expect(protocol_message.action).to eq('Presence')
      end

      it 'returns an Enum that matchdes the ACTION constant' do
        expect(protocol_message.action).to eql(Ably::Realtime::Models::ProtocolMessage::ACTION.Presence)
      end
    end

    context '#timestamp' do
      let(:protocol_message) { subject.new(timestamp: as_since_epoch(Time.now)) }
      it 'retrieves attribute :timestamp' do
        expect(protocol_message.timestamp).to be_a(Time)
        expect(protocol_message.timestamp.to_i).to be_within(1).of(Time.now.to_i)
      end
    end

    context '#error' do
      context 'with no error attribute' do
        let(:protocol_message) { subject.new(action: 1) }

        it 'returns nil' do
          expect(protocol_message.error).to be_nil
        end
      end

      context 'with nil error' do
        let(:protocol_message) { subject.new(error: nil) }

        it 'returns nil' do
          expect(protocol_message.error).to be_nil
        end
      end

      context 'with error' do
        let(:protocol_message) { subject.new(error: { message: 'test_error' }) }

        it 'returns a valid ErrorInfo object' do
          expect(protocol_message.error).to be_a(Ably::Realtime::Models::ErrorInfo)
          expect(protocol_message.error.message).to eql('test_error')
        end
      end
    end
  end

  context '#to_json' do
    let(:json_object) { JSON.parse(model.to_json) }
    let(:message) { { 'name' => 'event', 'clientId' => 'joe' } }
    let(:attached_action) { Ably::Realtime::Models::ProtocolMessage::ACTION.Attached }
    let(:message_action) { Ably::Realtime::Models::ProtocolMessage::ACTION.Message }

    context 'with valid data' do
      let(:model) { subject.new({ :action => attached_action, :channelSerial => 'unique', messages: [message] }) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["channelSerial"]).to eql('unique')
      end

      it 'populates the messages' do
        expect(json_object["messages"].first).to include(message)
      end
    end

    context 'with invalid name data' do
      let(:model) { subject.new({ clientId: 'joe' }) }

      it 'it raises an exception' do
        expect { model.to_json }.to raise_error KeyError, /Action '' is not supported by ProtocolMessage/
      end
    end

    context 'with missing msg_serial for ack message' do
      let(:model) { subject.new({ :action => message_action }) }

      it 'it raises an exception' do
        expect { model.to_json }.to raise_error RuntimeError, /cannot generate valid JSON/
      end
    end

    context 'is aliased by #to_s' do
      let(:model) { subject.new({ :action => attached_action, :channelSerial => 'unique', messages: [message] }) }

      specify do
        expect(json_object).to eql(JSON.parse("#{model}"))
      end
    end
  end
end
