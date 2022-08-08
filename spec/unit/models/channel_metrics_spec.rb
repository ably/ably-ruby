# frozen_string_literal: true

require "spec_helper"
require "shared/model_behaviour"

describe Ably::Models::ChannelMetrics do
  subject { Ably::Models::ChannelMetrics(connections: 1, presence_connections: 2, presence_members: 2, presence_subscribers: 5, publishers: 7, subscribers: 9) }

  describe "#connections" do
    it "should return integer" do
      expect(subject.connections).to eq(1)
    end
  end

  describe "#presence_connections" do
    it "should return integer" do
      expect(subject.presence_connections).to eq(2)
    end
  end

  describe "#presence_members" do
    it "should return integer" do
      expect(subject.presence_members).to eq(2)
    end
  end

  describe "#presence_subscribers" do
    it "should return integer" do
      expect(subject.presence_subscribers).to eq(5)
    end
  end

  describe "#publishers" do
    it "should return integer" do
      expect(subject.publishers).to eq(7)
    end
  end

  describe "#subscribers" do
    it "should return integer" do
      expect(subject.subscribers).to eq(9)
    end
  end
end
