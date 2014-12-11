# encoding: utf-8
require 'spec_helper'
require 'support/model_helper'

describe Ably::Models::ProtocolMessage do
  include Ably::Modules::Conversions
  subject { Ably::Models::ProtocolMessage }

  def new_protocol_message(options)
    subject.new({ action: 1 }.merge(options))
  end

  it_behaves_like 'a model',
    with_simple_attributes: %w(id channel channel_serial connection_id),
    base_model_options: { action: 1 } do

    let(:model_args) { [] }
  end

  context 'initializer action coercion' do
    it 'ignores actions that are Integers' do
      protocol_message = subject.new(action: 14)
      expect(protocol_message.hash[:action]).to eql(14)
    end

    it 'converts actions to Integers if a symbol' do
      protocol_message = subject.new(action: :message)
      expect(protocol_message.hash[:action]).to eql(15)
    end

    it 'converts actions to Integers if a ACTION' do
      protocol_message = subject.new(action: Ably::Models::ProtocolMessage::ACTION.Message)
      expect(protocol_message.hash[:action]).to eql(15)
    end

    it 'raises an argument error if nil' do
      expect { subject.new({}) }.to raise_error(ArgumentError)
    end
  end

  context 'attributes' do
    let(:unique_value) { SecureRandom.hex }

    context 'Java naming' do
      let(:protocol_message) { new_protocol_message(channelSerial: unique_value) }

      it 'converts the attribute to ruby symbol naming convention' do
        expect(protocol_message.channel_serial).to eql(unique_value)
      end
    end

    context '#action' do
      let(:protocol_message) { new_protocol_message(action: 14) }

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
        expect(protocol_message.action).to eql(Ably::Models::ProtocolMessage::ACTION.Presence)
      end
    end

    context '#timestamp' do
      let(:protocol_message) { new_protocol_message(timestamp: as_since_epoch(Time.now)) }
      it 'retrieves attribute :timestamp' do
        expect(protocol_message.timestamp).to be_a(Time)
        expect(protocol_message.timestamp.to_i).to be_within(1).of(Time.now.to_i)
      end
    end

    context '#count' do
      context 'when missing' do
        let(:protocol_message) { new_protocol_message({}) }
        it 'is 1' do
          expect(protocol_message.count).to eql(1)
        end
      end

      context 'when non numeric' do
        let(:protocol_message) { new_protocol_message(count: 'A') }
        it 'is 1' do
          expect(protocol_message.count).to eql(1)
        end
      end

      context 'when greater than 1' do
        let(:protocol_message) { new_protocol_message(count: '666') }
        it 'is the value of count' do
          expect(protocol_message.count).to eql(666)
        end
      end
    end

    context '#message_serial' do
      let(:protocol_message) { new_protocol_message(msg_serial: "55") }
      it 'converts :msg_serial to an Integer' do
        expect(protocol_message.message_serial).to be_a(Integer)
        expect(protocol_message.message_serial).to eql(55)
      end
    end

    context '#has_message_serial?' do
      context 'without msg_serial' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'returns false' do
          expect(protocol_message.has_message_serial?).to eql(false)
        end
      end

      context 'with msg_serial' do
        let(:protocol_message) { new_protocol_message(msg_serial: "55") }

        it 'returns true' do
          expect(protocol_message.has_message_serial?).to eql(true)
        end
      end
    end

    context '#connection_serial' do
      let(:protocol_message) { new_protocol_message(connection_serial: "55") }
      it 'converts :connection_serial to an Integer' do
        expect(protocol_message.connection_serial).to be_a(Integer)
        expect(protocol_message.connection_serial).to eql(55)
      end
    end

    context '#has_connection_serial?' do
      context 'without connection_serial' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'returns false' do
          expect(protocol_message.has_connection_serial?).to eql(false)
        end
      end

      context 'with connection_serial' do
        let(:protocol_message) { new_protocol_message(connection_serial: "55") }

        it 'returns true' do
          expect(protocol_message.has_connection_serial?).to eql(true)
        end
      end
    end

    context '#serial' do
      context 'with underlying msg_serial' do
        let(:protocol_message) { new_protocol_message(msg_serial: "55") }
        it 'converts :msg_serial to an Integer' do
          expect(protocol_message.serial).to be_a(Integer)
          expect(protocol_message.serial).to eql(55)
        end
      end

      context 'with underlying connection_serial' do
        let(:protocol_message) { new_protocol_message(connection_serial: "55") }
        it 'converts :connection_serial to an Integer' do
          expect(protocol_message.serial).to be_a(Integer)
          expect(protocol_message.serial).to eql(55)
        end
      end

      context 'with underlying connection_serial and msg_serial' do
        let(:protocol_message) { new_protocol_message(connection_serial: "99", msg_serial: "11") }
        it 'prefers connection_serial and converts :connection_serial to an Integer' do
          expect(protocol_message.serial).to be_a(Integer)
          expect(protocol_message.serial).to eql(99)
        end
      end
    end

    context '#has_serial?' do
      context 'without msg_serial or connection_serial' do
        let(:protocol_message) { new_protocol_message({}) }

        it 'returns false' do
          expect(protocol_message.has_serial?).to eql(false)
        end
      end

      context 'with msg_serial' do
        let(:protocol_message) { new_protocol_message(msg_serial: "55") }

        it 'returns true' do
          expect(protocol_message.has_serial?).to eql(true)
        end
      end

      context 'with connection_serial' do
        let(:protocol_message) { new_protocol_message(connection_serial: "55") }

        it 'returns true' do
          expect(protocol_message.has_serial?).to eql(true)
        end
      end
    end

    context '#error' do
      context 'with no error attribute' do
        let(:protocol_message) { new_protocol_message(action: 1) }

        it 'returns nil' do
          expect(protocol_message.error).to be_nil
        end
      end

      context 'with nil error' do
        let(:protocol_message) { new_protocol_message(error: nil) }

        it 'returns nil' do
          expect(protocol_message.error).to be_nil
        end
      end

      context 'with error' do
        let(:protocol_message) { new_protocol_message(error: { message: 'test_error' }) }

        it 'returns a valid ErrorInfo object' do
          expect(protocol_message.error).to be_a(Ably::Models::ErrorInfo)
          expect(protocol_message.error.message).to eql('test_error')
        end
      end
    end
  end

  context '#to_json' do
    let(:json_object) { JSON.parse(model.to_json) }
    let(:message) { { 'name' => 'event', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:attached_action) { Ably::Models::ProtocolMessage::ACTION.Attached }
    let(:message_action) { Ably::Models::ProtocolMessage::ACTION.Message }

    context 'with valid data' do
      let(:model) { new_protocol_message({ :action => attached_action, :channelSerial => 'unique', messages: [message] }) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["channelSerial"]).to eql('unique')
      end

      it 'populates the messages' do
        expect(json_object["messages"].first).to include(message)
      end
    end

    context 'with missing msg_serial for ack message' do
      let(:model) { new_protocol_message({ :action => message_action }) }

      it 'it raises an exception' do
        expect { model.to_json }.to raise_error TypeError, /msg_serial.*missing/
      end
    end

    context 'is aliased by #to_s' do
      let(:model) { new_protocol_message({ :action => attached_action, :channelSerial => 'unique', messages: [message], :timestamp => as_since_epoch(Time.now) }) }

      specify do
        expect(json_object).to eql(JSON.parse("#{model}"))
      end
    end
  end

  context '#to_msgpack' do
    let(:model)    { new_protocol_message({ :connectionSerial => 'unique', messages: [message] }) }
    let(:message)  { { 'name' => 'event', 'clientId' => 'joe', 'timestamp' => as_since_epoch(Time.now) } }
    let(:packed)   { model.to_msgpack }
    let(:unpacked) { MessagePack.unpack(packed) }

    it 'returns a unpackable msgpack object' do
      expect(unpacked['connectionSerial']).to eq('unique')
      expect(unpacked['messages'][0]['name']).to eq('event')
    end
  end
end
