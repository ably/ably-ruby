require 'spec_helper'
require 'support/protocol_msgbus_helper'

describe Ably::Auth do
  let(:client)    { double('client').as_null_object }
  let(:client_id) { nil }
  let(:options)   { { api_key: 'appid.keyuid:keysecret', client_id: client_id } }

  subject do
    Ably::Auth.new(client, options)
  end

  describe 'client_id option' do
    let(:value)   { random_str }

    context 'with nil value' do
      let(:client_id) { nil }

      it 'is permitted' do
        expect(subject.client_id).to be_nil
      end
    end

    context 'as UTF_8 string' do
      let(:client_id) { value.force_encoding(Encoding::UTF_8) }

      it 'is permitted' do
        expect(subject.client_id).to eql(client_id)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:client_id) { value.force_encoding(Encoding::SHIFT_JIS) }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as ASCII_8BIT string' do
      let(:client_id) { value.force_encoding(Encoding::ASCII_8BIT) }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:client_id) { 1 }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end
end
