require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::AuthDetails do
  include Ably::Modules::Conversions

  subject { Ably::Models::AuthDetails }

  # Spec model items AD2*
  it_behaves_like 'a model', with_simple_attributes: %w(access_token) do
    let(:model_args) { [] }
  end

  context '==' do
    let(:attributes) { { access_token: 'unique' } }

    it 'is true when attributes are the same' do
      auth_details = -> { Ably::Models::AuthDetails.new(attributes) }
      expect(auth_details.call).to eq(auth_details.call)
    end

    it 'is false when attributes are not the same' do
      expect(Ably::Models::AuthDetails.new(access_token: '1')).to_not eq(Ably::Models::AuthDetails.new(access_token: '2'))
    end

    it 'is false when class type differs' do
      expect(Ably::Models::AuthDetails.new(access_token: '1')).to_not eq(nil)
    end
  end

  context 'AuthDetails conversion methods', :api_private do
    context 'with a AuthDetails object' do
      let(:details) { Ably::Models::AuthDetails.new(access_token: random_str) }

      it 'returns the AuthDetails object' do
        expect(Ably::Models::AuthDetails(details)).to eql(details)
      end
    end

    context 'with a JSON object' do
      let(:access_token) { random_str }
      let(:details_json) { { access_token: access_token } }

      it 'returns a new AuthDetails object from the JSON' do
        expect(Ably::Models::AuthDetails(details_json).access_token).to eql(access_token)
      end
    end
  end
end
