require "spec_helper"

describe Ably::Rest::Channel do
  let(:client) { double "client" }

  subject { described_class.new(client, "test") }

  describe "#publish" do
    context "an invalid message" do
      it "should raise an error when the keys are invalid" do
        message = { name: "test", datum: "data" }

        expect { subject.publish message }.to raise_error(ArgumentError, "message must be a Hash with :name and :data keys")
      end

      it "should raise an error when the name is blank" do
        message = { name: "", data: "data" }

        expect { subject.publish message }.to raise_error(ArgumentError, "message name must not be empty")
      end
    end
  end
end
