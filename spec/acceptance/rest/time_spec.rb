require 'spec_helper'

describe 'Ably::REST::Client time' do
  [:msgpack, :json].each do |protocol|
    context "over #{protocol}" do
      let(:client) do
        Ably::Rest::Client.new(api_key: api_key, environment: environment, protocol: protocol)
      end

      describe 'fetching the service time' do
        it 'should return the service time as a Time object' do
          expect(client.time).to be_within(2).of(Time.now)
        end
      end
    end
  end
end
