require "spec_helper"
require "securerandom"

describe "REST" do
  let(:client) do
    Ably::Rest::Client.new(api_key: api_key, environment: environment)
  end

  describe "fetching the service time" do
    it "should return the service time as a Time object" do
      expect(client.time).to be_within(2).of(Time.now)
    end
  end
end
