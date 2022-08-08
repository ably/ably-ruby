# frozen_string_literal: true

require "spec_helper"
require "shared/model_behaviour"

describe Ably::Models::ChannelStatus do
  subject { Ably::Models::ChannelStatus({isActive: "true", occupancy: {metrics: {connections: 1, presence_connections: 2, presence_members: 2, presence_subscribers: 5, publishers: 7, subscribers: 9}}}) }

  describe "#is_active" do
    context "when occupancy is active" do
      subject { Ably::Models::ChannelStatus({isActive: true, occupancy: {metrics: {connections: 1, presence_connections: 2, presence_members: 2, presence_subscribers: 5, publishers: 7, subscribers: 9}}}) }

      it "should return true" do
        expect(subject.is_active).to eq(true)
      end
    end

    context "when occupancy is not active" do
      subject { Ably::Models::ChannelStatus({isActive: false, occupancy: {metrics: {connections: 1, presence_connections: 2, presence_members: 2, presence_subscribers: 5, publishers: 7, subscribers: 9}}}) }

      it "should return false" do
        expect(subject.is_active).to eq(false)
      end
    end
  end

  describe "#occupancy" do
    it "should return occupancy object" do
      expect(subject.occupancy).to be_a(Ably::Models::ChannelOccupancy)
      expect(subject.occupancy.metrics.connections).to eq(1)
      expect(subject.occupancy.metrics.presence_connections).to eq(2)
      expect(subject.occupancy.metrics.presence_members).to eq(2)
      expect(subject.occupancy.metrics.presence_subscribers).to eq(5)
      expect(subject.occupancy.metrics.publishers).to eq(7)
      expect(subject.occupancy.metrics.subscribers).to eq(9)
    end
  end
end
