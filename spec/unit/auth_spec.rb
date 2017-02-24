require 'spec_helper'
require 'shared/protocol_msgbus_behaviour'

describe Ably::Auth do
  let(:client)        { double('client').as_null_object }
  let(:client_id)     { nil }
  let(:auth_options)  { { key: 'appid.keyuid:keysecret', client_id: client_id } }
  let(:token_params)  { { } }

  subject do
    Ably::Auth.new(client, token_params, auth_options)
  end

  describe 'client_id option' do
    let(:client_id) { random_str.encode(encoding) }

    context 'with nil value' do
      let(:client_id) { nil }

      it 'is permitted' do
        expect(subject.client_id).to be_nil
      end
    end

    context 'as UTF_8 string' do
      let(:encoding) { Encoding::UTF_8 }

      it 'is permitted' do
        expect(subject.client_id).to eql(client_id)
      end

      it 'remains as UTF-8' do
        expect(subject.client_id.encoding).to eql(encoding)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoding) { Encoding::SHIFT_JIS }

      it 'gets converted to UTF-8' do
        expect(subject.client_id.encoding).to eql(Encoding::UTF_8)
      end

      it 'is compatible with original encoding' do
        expect(subject.client_id.encode(encoding)).to eql(client_id)
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoding) { Encoding::ASCII_8BIT }

      it 'gets converted to UTF-8' do
        expect(subject.client_id.encoding).to eql(Encoding::UTF_8)
      end

      it 'is compatible with original encoding' do
        expect(subject.client_id.encode(encoding)).to eql(client_id)
      end
    end

    context 'as Integer' do
      let(:client_id) { 1 }

      it 'raises an argument error' do
        expect { subject.client_id }.to raise_error ArgumentError, /must be a String/
      end
    end
  end

  context 'defaults' do
    it 'should have no default TTL' do
      expect(Ably::Auth::TOKEN_DEFAULTS[:ttl]).to be_nil
    end

    it 'should have no default capability' do
      expect(Ably::Auth::TOKEN_DEFAULTS[:capability]).to be_nil
    end
  end
end
