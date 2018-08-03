# encoding: utf-8
require 'base64'
require 'msgpack'

require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::Message do
  include Ably::Modules::Conversions

  subject { Ably::Models::Message }
  let(:protocol_message_timestamp) { as_since_epoch(Time.now) }
  let(:protocol_message) { Ably::Models::ProtocolMessage.new(action: 1, timestamp: protocol_message_timestamp) }

  context 'serialization of the Message object (#RSL1j)' do
    it_behaves_like 'a model', with_simple_attributes: %w(id name client_id data encoding) do
      let(:model_args) { [protocol_message: protocol_message] }
    end
  end

  context '#id (#RSL1j)' do
    let(:id) { random_str }
    let(:model) { subject.new(id: id) }

    it 'exposes the #id attribute' do
      expect(model.id).to eql(id)
    end

    specify '#as_json exposes the #id attribute' do
      expect(model.as_json['id']).to eql(id)
    end
  end

  context '#timestamp' do
    let(:model) { subject.new({}, protocol_message: protocol_message) }

    it 'retrieves attribute :timestamp as Time object from ProtocolMessage' do
      expect(model.timestamp).to be_a(Time)
      expect(model.timestamp.to_i).to be_within(1).of(Time.now.to_i)
    end
  end

  context '#extras (#TM2i)' do
    let(:model) { subject.new({ extras: extras }, protocol_message: protocol_message) }

    context 'when missing' do
      let(:model) { subject.new({}, protocol_message: protocol_message) }
      it 'is nil' do
        expect(model.extras).to be_nil
      end
    end

    context 'when a string' do
      let(:extras) { 'string' }
      it 'raises an exception' do
        expect { model.extras }.to raise_error ArgumentError, /extras contains an unsupported type/
      end
    end

    context 'when a Hash' do
      let(:extras) { { key: 'value' } }
      it 'contains a Hash Json object' do
        expect(model.extras).to eq(extras)
      end
    end

    context 'when a Json Array' do
      let(:extras) { [{ 'key' => 'value' }] }
      it 'contains a Json Array object' do
        expect(model.extras).to eq(extras)
      end
    end
  end

  context '#connection_id attribute' do
    let(:protocol_connection_id) { random_str }
    let(:protocol_message) { Ably::Models::ProtocolMessage.new('connectionId' => protocol_connection_id, action: 1, timestamp: protocol_message_timestamp) }
    let(:model_connection_id) { random_str }

    context 'when this model has a connectionId attribute' do
      context 'but no protocol message' do
        let(:model) { subject.new('connectionId' => model_connection_id ) }

        it 'uses the model value' do
          expect(model.connection_id).to eql(model_connection_id)
        end
      end

      context 'with a protocol message with a different connectionId' do
        let(:model) { subject.new({ 'connectionId' => model_connection_id }, protocol_message: protocol_message) }

        it 'uses the model value' do
          expect(model.connection_id).to eql(model_connection_id)
        end
      end
    end

    context 'when this model has no connectionId attribute' do
      context 'and no protocol message' do
        let(:model) { subject.new({ }) }

        it 'uses the model value' do
          expect(model.connection_id).to be_nil
        end
      end

      context 'with a protocol message with a connectionId' do
        let(:model) { subject.new({ }, protocol_message: protocol_message) }

        it 'uses the model value' do
          expect(model.connection_id).to eql(protocol_connection_id)
        end
      end
    end
  end

  context 'Java naming', :api_private do
    let(:model) { subject.new({ clientId: 'joe' }, protocol_message: protocol_message) }

    it 'converts the attribute to ruby symbol naming convention' do
      expect(model.client_id).to eql('joe')
    end
  end

  context 'initialized with' do
    %w(name client_id encoding).each do |attribute|
      context ":#{attribute}" do
        let(:encoded_value)   { value.encode(encoding) }
        let(:value)           { random_str }
        let(:options)         { { attribute.to_sym => encoded_value } }
        let(:model)           { subject.new(options, protocol_message: protocol_message) }
        let(:model_attribute) { model.public_send(attribute) }

        context 'as UTF_8 string' do
          let(:encoding) { Encoding::UTF_8 }

          it 'is permitted' do
            expect(model_attribute).to eql(encoded_value)
          end

          it 'remains as UTF-8' do
            expect(model_attribute.encoding).to eql(encoding)
          end
        end

        context 'as SHIFT_JIS string' do
          let(:encoding) { Encoding::SHIFT_JIS }

          it 'gets converted to UTF-8' do
            expect(model_attribute.encoding).to eql(Encoding::UTF_8)
          end

          it 'is compatible with original encoding' do
            expect(model_attribute.encode(encoding)).to eql(encoded_value)
          end
        end

        context 'as ASCII_8BIT string' do
          let(:encoding) { Encoding::ASCII_8BIT }

          it 'gets converted to UTF-8' do
            expect(model_attribute.encoding).to eql(Encoding::UTF_8)
          end

          it 'is compatible with original encoding' do
            expect(model_attribute.encode(encoding)).to eql(encoded_value)
          end
        end

        context 'as Integer' do
          let(:encoded_value) { 1 }

          it 'raises an argument error' do
            expect { model_attribute }.to raise_error ArgumentError, /must be a String/
          end
        end

        context 'as Nil' do
          let(:encoded_value) { nil }

          it 'is permitted' do
            expect(model_attribute).to be_nil
          end
        end
      end
    end
  end

  context '#to_json', :api_private do
    let(:json_object) { JSON.parse(model.to_json) }

    context 'with valid data' do
      let(:model) { subject.new({ name: 'test', clientId: 'joe' }, protocol_message: protocol_message) }

      it 'converts the attribute back to Java mixedCase notation using string keys' do
        expect(json_object["clientId"]).to eql('joe')
      end
    end

    context 'with binary data' do
      let(:data) { MessagePack.pack(random_str(32)) }
      let(:model) { subject.new({ name: 'test', data: data }, protocol_message: protocol_message) }

      it 'encodes as Base64 so that it can be converted to UTF-8 automatically by JSON#dump' do
        expect(json_object["data"]).to eql(::Base64.encode64(data))
      end

      it 'adds Base64 encoding' do
        expect(json_object["encoding"]).to eql('base64')
      end
    end
  end

  context 'from REST request with embedded fields', :api_private do
    let(:id)                  { random_str }
    let(:protocol_message_id) { random_str }
    let(:message_time)        { Time.now + 60 }
    let(:message_timestamp)   { as_since_epoch(message_time) }
    let(:protocol_time)       { Time.now }
    let(:protocol_timestamp)  { as_since_epoch(protocol_time) }

    let(:protocol_message) do
      Ably::Models::ProtocolMessage.new({
        action: :message,
        timestamp: protocol_timestamp,
        id: protocol_message_id
      })
    end

    context 'with protocol message' do
      let(:model) { subject.new({ id: id, timestamp: message_timestamp }, protocol_message: protocol_message) }

      specify '#id prefers embedded ID' do
        expect(model.id).to eql(id)
      end

      specify '#timestamp prefers embedded timestamp' do
        expect(model.timestamp.to_i).to be_within(1).of(message_time.to_i)
      end
    end

    context 'without protocol message' do
      let(:model) { subject.new(id: id, timestamp: message_timestamp) }

      specify '#id uses embedded ID' do
        expect(model.id).to eql(id)
      end

      specify '#timestamp uses embedded timestamp' do
        expect(model.timestamp.to_i).to be_within(1).of(message_time.to_i)
      end
    end
  end

  context 'part of ProtocolMessage', :api_private do
    let(:ably_time) { Time.now + 5 }
    let(:message_serial) { random_int_str(1_000_000) }
    let(:connection_id) { random_str }

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

    let(:protocol_message_id) { random_str }
    let(:protocol_message) do
      Ably::Models::ProtocolMessage.new({
        action: :message,
        timestamp: ably_time.to_i,
        msg_serial: message_serial,
        id: protocol_message_id,
        messages: [
          message_0_json, message_1_json
        ]
      })
    end

    let(:message_0) { protocol_message.messages.first }
    let(:message_1) { protocol_message.messages.last }

    it 'should generate a message ID from the index, serial and connection id' do
      expect(message_0.id).to eql("#{protocol_message_id}:0")
      expect(message_1.id).to eql("#{protocol_message_id}:1")
    end

    it 'should not modify the data payload' do
      expect(message_0.data['string_key']).to eql('string_value')
      expect(message_0.data[1]).to eql(2)
      expect(message_0.data[true]).to eql(false)
      expect(message_0.data).to eql(message_0_payload)

      expect(message_1.data).to eql('simple string')
    end

    it 'should not allow changes to the payload' do
      expect { message_0.data["test"] = true }.to raise_error RuntimeError, /can't modify frozen.*Hash/
    end

    context 'with identical message objects' do
      let(:protocol_message) do
        Ably::Models::ProtocolMessage.new({
          action: :message,
          timestamp: ably_time.to_i,
          msg_serial: message_serial,
          id: protocol_message_id,
          messages: [
            message_0_json, message_0_json, message_0_json
          ]
        })
      end

      it 'provide a unique ID:index' do
        expect(protocol_message.messages.map(&:id).uniq.count).to eql(3)
      end

      it 'recognises the index based on the object ID as opposed to message payload' do
        expect(protocol_message.messages.first.id).to match(/0$/)
        expect(protocol_message.messages.last.id).to match(/2$/)
      end
    end
  end

  context 'Message conversion method', :api_private do
    let(:json) { { name: 'test', data: 'conversion' } }

    context 'with JSON' do
      context 'without ProtocolMessage' do
        subject { Ably::Models.Message(json) }

        it 'returns a Message object' do
          expect(subject).to be_a(Ably::Models::Message)
        end

        it 'initializes with the JSON' do
          expect(subject.name).to eql('test')
        end

        it 'raises an exception when accessing ProtocolMessage' do
          expect { subject.protocol_message }.to raise_error RuntimeError
        end

        it 'has no ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(false)
        end
      end

      context 'with ProtocolMessage' do
        subject { Ably::Models.Message(json, protocol_message: protocol_message) }

        it 'returns a Message object' do
          expect(subject).to be_a(Ably::Models::Message)
        end

        it 'initializes with the JSON' do
          expect(subject.name).to eql('test')
        end

        it 'provides access to ProtocolMessage' do
          expect(subject.protocol_message).to eql(protocol_message)
        end

        it 'has a ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(true)
        end
      end
    end

    context 'with another Message' do
      let(:message) { Ably::Models::Message.new(json) }

      context 'without ProtocolMessage' do
        subject { Ably::Models.Message(message) }

        it 'returns a Message object' do
          expect(subject).to be_a(Ably::Models::Message)
        end

        it 'initializes with the JSON' do
          expect(subject.name).to eql('test')
        end

        it 'raises an exception when accessing ProtocolMessage' do
          expect { subject.protocol_message }.to raise_error RuntimeError
        end

        it 'has no ProtocolMessage' do
          expect(subject.assigned_to_protocol_message?).to eql(false)
        end
      end

      context 'with ProtocolMessage' do
        subject { Ably::Models.Message(message, protocol_message: protocol_message) }

        it 'returns a Message object' do
          expect(subject).to be_a(Ably::Models::Message)
        end

        it 'initializes with the JSON' do
          expect(subject.name).to eql('test')
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

  context '#from_encoded (#TM3)' do
    context 'with no encoding' do
      let(:message_data) do
        { name: 'name', data: 'data-string' }
      end
      let(:from_encoded) { subject.from_encoded(message_data) }

      it 'returns a message object' do
        expect(from_encoded).to be_a(Ably::Models::Message)
        expect(from_encoded.name).to eql('name')
        expect(from_encoded.data).to eql('data-string')
        expect(from_encoded.encoding).to be_nil
      end

      context 'with a block' do
        it 'does not call the block' do
          block_called = false
          subject.from_encoded(message_data) do |exception, message|
            block_called = true
          end
          expect(block_called).to be_falsey
        end
      end
    end

    context 'with an encoding' do
      let(:hash_data)           { { 'key' => 'value', 'key2' => 123 } }
      let(:message_data) do
        { name: 'name', data: JSON.dump(hash_data), encoding: 'json' }
      end
      let(:from_encoded) { subject.from_encoded(message_data) }

      it 'returns a message object' do
        expect(from_encoded).to be_a(Ably::Models::Message)
        expect(from_encoded.name).to eql('name')
        expect(from_encoded.data).to eql(hash_data)
        expect(from_encoded.encoding).to be_nil
      end
    end

    context 'with a custom encoding' do
      let(:hash_data)           { { 'key' => 'value', 'key2' => 123 } }
      let(:message_data) do
        { name: 'name', data: JSON.dump(hash_data), encoding: 'foo/json' }
      end
      let(:from_encoded) { subject.from_encoded(message_data) }

      it 'returns a message object with the residual incompatible transforms left in the encoding property' do
        expect(from_encoded).to be_a(Ably::Models::Message)
        expect(from_encoded.name).to eql('name')
        expect(from_encoded.data).to eql(hash_data)
        expect(from_encoded.encoding).to eql('foo')
      end
    end

    context 'with a Cipher encoding' do
      let(:hash_data)           { { 'key' => 'value', 'key2' => 123 } }
      let(:cipher_params)       { { key: Ably::Util::Crypto.generate_random_key(128), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
      let(:crypto)              { Ably::Util::Crypto.new(cipher_params) }
      let(:payload)             { random_str }
      let(:message_data) do
        { name: 'name', data: crypto.encrypt(payload), encoding: 'utf-8/cipher+aes-128-cbc' }
      end
      let(:channel_options)     { { cipher: cipher_params } }
      let(:from_encoded)        { subject.from_encoded(message_data, channel_options) }

      it 'returns a message object with the residual incompatible transforms left in the encoding property' do
        expect(from_encoded).to be_a(Ably::Models::Message)
        expect(from_encoded.name).to eql('name')
        expect(from_encoded.data).to eql(payload)
        expect(from_encoded.encoding).to be_nil
      end
    end

    context 'with invalid Cipher encoding' do
      let(:hash_data)           { { 'key' => 'value', 'key2' => 123 } }
      let(:cipher_params)       { { key: Ably::Util::Crypto.generate_random_key(128), algorithm: 'aes', mode: 'cbc', key_length: 128 } }
      let(:unencryped_payload)  { random_str }
      let(:message_data) do
        { name: 'name', data: unencryped_payload, encoding: 'utf-8/cipher+aes-128-cbc' }
      end
      let(:channel_options)     { { cipher: cipher_params } }

      context 'without a block' do
        it 'raises an exception' do
          expect { subject.from_encoded(message_data, channel_options) }.to raise_exception(Ably::Exceptions::CipherError)
        end
      end

      context 'with a block' do
        it 'calls the block with the exception' do
          block_called = false
          subject.from_encoded(message_data, channel_options) do |exception, message|
            expect(exception).to be_a(Ably::Exceptions::CipherError)
            block_called = true
          end
          expect(block_called).to be_truthy
        end
      end
    end
  end

  context '#from_encoded_array (#TM3)' do
    context 'with no encoding' do
      let(:message_data) do
        [{ name: 'name1', data: 'data-string' }, { name: 'name2', data: 'data-string' }]
      end
      let(:from_encoded) { subject.from_encoded_array(message_data) }

      it 'returns an Array of message objects' do
        first = from_encoded.first
        expect(first).to be_a(Ably::Models::Message)
        expect(first.name).to eql('name1')
        expect(first.data).to eql('data-string')
        expect(first.encoding).to be_nil
        last = from_encoded.last
        expect(last.name).to eql('name2')
      end
    end
  end
end
