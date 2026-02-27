# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Channel do
  let(:post_response) { instance_double('Faraday::Response', status: 201, body: { 'serials' => ['serial-001'] }) }
  let(:client) do
    instance_double(
      'Ably::Rest::Client',
      encoders: [],
      post: post_response,
      idempotent_rest_publishing: false, max_message_size: max_message_size
    )
  end
  let(:channel_name) { 'unique' }
  let(:max_message_size) { nil }

  subject { Ably::Rest::Channel.new(client, channel_name) }

  describe '#initializer' do
    let(:channel_name) { random_str.encode(encoding) }

    context 'as UTF_8 string' do
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.name).to eql(channel_name)
      end

      it 'remains as UTF-8' do
        expect(subject.name.encoding).to eql(encoding)
      end
    end

    context 'as frozen UTF_8 string' do
      let(:channel_name) { 'unique'.freeze }
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.name).to eql(channel_name)
      end

      it 'remains as UTF-8' do
        expect(subject.name.encoding).to eql(encoding)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoding) { Encoding::SHIFT_JIS }

      it 'gets converted to UTF-8' do
        expect(subject.name.encoding).to eql(Encoding::UTF_8)
      end

      it 'is compatible with original encoding' do
        expect(subject.name.encode(encoding)).to eql(channel_name)
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoding) { Encoding::ASCII_8BIT }

      it 'gets converted to UTF-8' do
        expect(subject.name.encoding).to eql(Encoding::UTF_8)
      end

      it 'is compatible with original encoding' do
        expect(subject.name.encode(encoding)).to eql(channel_name)
      end
    end

    context 'as Integer' do
      let(:channel_name) { 1 }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError, /must be a String/
      end
    end

    context 'as Nil' do
      let(:channel_name) { nil }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError, /must be a String/
      end
    end
  end

  describe '#publish name argument' do
    let(:encoded_value) { random_str.encode(encoding) }

    context 'as UTF_8 string' do
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to be_a(Ably::Models::PublishResult)
      end
    end

    context 'as frozen UTF_8 string' do
      let(:encoded_value) { 'unique'.freeze }
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to be_a(Ably::Models::PublishResult)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoding) { Encoding::SHIFT_JIS }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to be_a(Ably::Models::PublishResult)
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoding) { Encoding::ASCII_8BIT }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to be_a(Ably::Models::PublishResult)
      end
    end

    context 'as Integer' do
      let(:encoded_value) { 1 }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError, /must be a String/
      end
    end

    context 'max message size exceeded' do
      context 'when max_message_size is nil' do
        context 'and a message size is 65537 bytes' do
          it 'should raise Ably::Exceptions::MaxMessageSizeExceeded' do
            expect { subject.publish('x' * 65537, 'data') }.to raise_error Ably::Exceptions::MaxMessageSizeExceeded
          end
        end
      end

      context 'when max_message_size is 65536 bytes' do
        let(:max_message_size) { 65536 }

        context 'and a message size is 65537 bytes' do
          it 'should raise Ably::Exceptions::MaxMessageSizeExceeded' do
            expect { subject.publish('x' * 65537, 'data') }.to raise_error Ably::Exceptions::MaxMessageSizeExceeded
          end
        end

        context 'and a message size is 10 bytes' do
          it 'should send a message' do
            expect(subject.publish('x' * 10, 'data')).to be_a(Ably::Models::PublishResult)
          end
        end
      end

      context 'when max_message_size is 10 bytes' do
        let(:max_message_size) { 10 }

        context 'and a message size is 11 bytes' do
          it 'should raise Ably::Exceptions::MaxMessageSizeExceeded' do
            expect { subject.publish('x' * 11, 'data') }.to raise_error Ably::Exceptions::MaxMessageSizeExceeded
          end
        end

        context 'and a message size is 2 bytes' do
          it 'should send a message' do
            expect(subject.publish('x' * 2, 'data')).to be_a(Ably::Models::PublishResult)
          end
        end
      end
    end
  end

  describe '#publish returns PublishResult (#RSL1n)' do
    context 'with serials in response body' do
      let(:post_response) { instance_double('Faraday::Response', status: 201, body: { 'serials' => ['serial-abc', 'serial-def'] }) }

      it 'returns a PublishResult with serials' do
        result = subject.publish('event', 'data')
        expect(result).to be_a(Ably::Models::PublishResult)
        expect(result.serials).to eql(['serial-abc', 'serial-def'])
      end
    end

    context 'with empty response body (204)' do
      let(:post_response) { instance_double('Faraday::Response', status: 204, body: nil) }

      it 'returns a PublishResult with empty serials' do
        result = subject.publish('event', 'data')
        expect(result).to be_a(Ably::Models::PublishResult)
        expect(result.serials).to eql([])
      end
    end

    context 'with non-hash response body' do
      let(:post_response) { instance_double('Faraday::Response', status: 201, body: '') }

      it 'returns a PublishResult with empty serials' do
        result = subject.publish('event', 'data')
        expect(result).to be_a(Ably::Models::PublishResult)
        expect(result.serials).to eql([])
      end
    end
  end

  describe '#update_message (#RSL15)' do
    let(:serial) { 'msg-serial-001' }
    let(:patch_response) { instance_double('Faraday::Response', status: 200, body: { 'versionSerial' => 'v1-serial' }) }
    let(:client) do
      instance_double(
        'Ably::Rest::Client',
        encoders: [],
        post: instance_double('Faraday::Response', status: 201, body: { 'serials' => ['serial-001'] }),
        patch: patch_response,
        idempotent_rest_publishing: false,
        max_message_size: max_message_size
      )
    end

    context 'with a valid message containing serial' do
      let(:message) { Ably::Models::Message.new(name: 'test', data: 'hello', serial: serial) }

      it 'sends a PATCH request' do
        expect(client).to receive(:patch).with(
          "/channels/#{channel_name}/messages/#{serial}",
          hash_including('action' => 1),
          {}
        ).and_return(patch_response)

        subject.update_message(message)
      end

      it 'returns an UpdateDeleteResult' do
        result = subject.update_message(message)
        expect(result).to be_a(Ably::Models::UpdateDeleteResult)
        expect(result.version_serial).to eql('v1-serial')
      end

      it 'sets action to MESSAGE_UPDATE' do
        expect(client).to receive(:patch) do |_path, payload, _opts|
          expect(payload['action']).to eq(Ably::Models::Message::ACTION.MessageUpdate.to_i)
          patch_response
        end

        subject.update_message(message)
      end
    end

    context 'with an operation parameter' do
      let(:message) { Ably::Models::Message.new(name: 'test', serial: serial) }
      let(:operation) { { description: 'Fixed typo', metadata: { 'reason' => 'correction' } } }

      it 'includes the operation as version in the payload' do
        expect(client).to receive(:patch) do |_path, payload, _opts|
          expect(payload['version']).to eq({ 'description' => 'Fixed typo', 'metadata' => { 'reason' => 'correction' } })
          patch_response
        end

        subject.update_message(message, operation)
      end
    end

    context 'with a MessageOperation object' do
      let(:message) { Ably::Models::Message.new(name: 'test', serial: serial) }
      let(:operation) { Ably::Models::MessageOperation.new(description: 'Fixed typo') }

      it 'serializes the operation via as_json' do
        expect(client).to receive(:patch) do |_path, payload, _opts|
          expect(payload['version']).to be_a(Hash)
          expect(payload['version']['description']).to eq('Fixed typo')
          patch_response
        end

        subject.update_message(message, operation)
      end
    end

    context 'without serial (#RSL15a)' do
      let(:message) { Ably::Models::Message.new(name: 'test', data: 'hello') }

      it 'raises an InvalidRequest exception' do
        expect { subject.update_message(message) }.to raise_error(Ably::Exceptions::InvalidRequest, /serial is required/)
      end
    end

    context 'with a Hash message' do
      it 'converts to Message and validates serial' do
        expect { subject.update_message({ name: 'test' }) }.to raise_error(Ably::Exceptions::InvalidRequest, /serial is required/)
      end

      it 'works when serial is present' do
        result = subject.update_message({ name: 'test', serial: serial })
        expect(result).to be_a(Ably::Models::UpdateDeleteResult)
      end
    end

    context 'does not mutate the original message (#RSL15c)' do
      let(:message) { Ably::Models::Message.new(name: 'test', serial: serial) }

      it 'the original message is unchanged' do
        original_json = message.as_json.dup
        subject.update_message(message)
        expect(message.as_json).to eq(original_json)
        expect(message.action).to be_nil
      end
    end

    context 'with query params (#RSL15f)' do
      let(:message) { Ably::Models::Message.new(name: 'test', serial: serial) }

      it 'passes params as qs_params' do
        expect(client).to receive(:patch).with(
          anything,
          anything,
          { qs_params: { 'key' => 'value' } }
        ).and_return(patch_response)

        subject.update_message(message, nil, { 'key' => 'value' })
      end
    end
  end

  describe '#delete_message (#RSL15)' do
    let(:serial) { 'msg-serial-001' }
    let(:patch_response) { instance_double('Faraday::Response', status: 200, body: { 'versionSerial' => 'v1-serial' }) }
    let(:client) do
      instance_double(
        'Ably::Rest::Client',
        encoders: [],
        post: instance_double('Faraday::Response', status: 201, body: { 'serials' => ['serial-001'] }),
        patch: patch_response,
        idempotent_rest_publishing: false,
        max_message_size: max_message_size
      )
    end

    context 'with a valid message containing serial' do
      let(:message) { Ably::Models::Message.new(name: 'test', data: 'hello', serial: serial) }

      it 'sends a PATCH request with action MESSAGE_DELETE' do
        expect(client).to receive(:patch).with(
          "/channels/#{channel_name}/messages/#{serial}",
          hash_including('action' => Ably::Models::Message::ACTION.MessageDelete.to_i),
          {}
        ).and_return(patch_response)

        subject.delete_message(message)
      end

      it 'returns an UpdateDeleteResult' do
        result = subject.delete_message(message)
        expect(result).to be_a(Ably::Models::UpdateDeleteResult)
        expect(result.version_serial).to eql('v1-serial')
      end
    end

    context 'with an operation parameter' do
      let(:message) { Ably::Models::Message.new(name: 'test', serial: serial) }
      let(:operation) { { description: 'Removed by moderator' } }

      it 'includes the operation as version in the payload' do
        expect(client).to receive(:patch) do |_path, payload, _opts|
          expect(payload['version']).to eq({ 'description' => 'Removed by moderator' })
          patch_response
        end

        subject.delete_message(message, operation)
      end
    end

    context 'without serial' do
      let(:message) { Ably::Models::Message.new(name: 'test', data: 'hello') }

      it 'raises an InvalidRequest exception' do
        expect { subject.delete_message(message) }.to raise_error(Ably::Exceptions::InvalidRequest, /serial is required/)
      end
    end

    context 'does not mutate the original message' do
      let(:message) { Ably::Models::Message.new(name: 'test', serial: serial) }

      it 'the original message is unchanged' do
        original_json = message.as_json.dup
        subject.delete_message(message)
        expect(message.as_json).to eq(original_json)
        expect(message.action).to be_nil
      end
    end
  end
end
