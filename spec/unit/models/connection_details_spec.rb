require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ConnectionDetails do
  include Ably::Modules::Conversions

  subject { Ably::Models::ConnectionDetails }

  # Spec model items CD2*
  it_behaves_like 'a model', with_simple_attributes: %w(client_id connection_key max_message_size max_frame_size max_inbound_rate) do
    let(:model_args) { [] }
  end

  context 'attributes' do
    let(:connection_state_ttl_ms) { 5_000 }

    context '#connection_state_ttl (#CD2f)' do
      subject { Ably::Models::ConnectionDetails.new({ connection_state_ttl: connection_state_ttl_ms }) }

      it 'retrieves attribute :connection_state_ttl and converts it from ms to s' do
        expect(subject.connection_state_ttl).to eql(connection_state_ttl_ms / 1000)
      end
    end

    let(:max_idle_interval) { 6_000 }

    context '#max_idle_interval (#CD2h)' do
      subject { Ably::Models::ConnectionDetails.new({ max_idle_interval: max_idle_interval }) }

      it 'retrieves attribute :max_idle_interval and converts it from ms to s' do
        expect(subject.max_idle_interval).to eql(max_idle_interval / 1000)
      end
    end
  end

  context '==' do
    let(:attributes) { { client_id: 'unique' } }

    it 'is true when attributes are the same' do
      connection_details = -> { Ably::Models::ConnectionDetails.new(attributes) }
      expect(connection_details.call).to eq(connection_details.call)
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Models::ConnectionDetails.new(client_id: '1')).to_not eq(Ably::Models::ConnectionDetails.new(client_id: '2'))
    end

    it 'is false when class type differs' do
      expect(Ably::Models::ConnectionDetails.new(client_id: '1')).to_not eq(nil)
    end
  end

  context 'ConnectionDetails conversion methods', :api_private do
    context 'with a ConnectionDetails object' do
      let(:details) { Ably::Models::ConnectionDetails.new(client_id: random_str) }

      it 'returns the ConnectionDetails object' do
        expect(Ably::Models::ConnectionDetails(details)).to eql(details)
      end
    end

    context 'with a JSON object' do
      let(:client_id) { random_str }
      let(:details_json) { { client_id: client_id } }

      it 'returns a new ConnectionDetails object from the JSON' do
        expect(Ably::Models::ConnectionDetails(details_json).client_id).to eql(client_id)
      end
    end
  end
end
