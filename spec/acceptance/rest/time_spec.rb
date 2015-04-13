require 'spec_helper'

describe Ably::Rest::Client, '#time' do
  vary_by_protocol do
    let(:client) do
      Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol)
    end

    describe 'fetching the service time' do
      it 'should return the service time as a Time object' do
        expect(client.time).to be_within(2).of(Time.now)
      end
    end
  end
end
