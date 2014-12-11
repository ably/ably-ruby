# encoding: utf-8
require 'spec_helper'

describe Ably::Rest::Channels do
  let(:client)       { instance_double('Ably::Rest::Client', encoders: [], post: instance_double('Faraday::Response', status: 201)) }
  let(:channel_name) { 'unique' }

  subject { Ably::Rest::Channel.new(client, channel_name) }

  describe '#initializer' do
    context 'as UTF_8 string' do
      let(:channel_name) { random_str.force_encoding(Encoding::UTF_8) }

      it 'is permitted' do
        expect(subject.name).to eql(channel_name)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:channel_name) { random_str.force_encoding(Encoding::SHIFT_JIS) }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as ASCII_8BIT string' do
      let(:channel_name) { random_str.force_encoding(Encoding::ASCII_8BIT) }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:channel_name) { 1 }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:channel_name) { nil }

      it 'raises an argument error' do
        expect { subject }.to raise_error ArgumentError
      end
    end
  end

  describe '#publish name argument' do
    let(:value) { random_str }

    context 'as UTF_8 string' do
      let(:encoded_value) { value.force_encoding(Encoding::UTF_8) }

      it 'is permitted' do
        expect(subject.publish(encoded_value, 'data')).to eql(true)
      end
    end

    context 'as SHIFT_JIS string' do
      let(:encoded_value) { value.force_encoding(Encoding::SHIFT_JIS) }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError
      end
    end

    context 'as ASCII_8BIT string' do
      let(:encoded_value) { value.force_encoding(Encoding::ASCII_8BIT) }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError
      end
    end

    context 'as Integer' do
      let(:encoded_value) { 1 }

      it 'raises an argument error' do
        expect { subject.publish(encoded_value, 'data') }.to raise_error ArgumentError
      end
    end
  end
end
