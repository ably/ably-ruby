# frozen_string_literal: true

require "spec_helper"
require "shared/model_behaviour"

describe Ably::Models::ChannelDetails do
  subject { Ably::Models::ChannelDetails(channel_id: "channel-id-123-xyz", name: "name", status: {isActive: "true", occupancy: {metrics: {connections: 1, presence_connections: 2, presence_members: 2, presence_subscribers: 5, publishers: 7, subscribers: 9}}}) }

  describe "#channel_id" do
    it "should return channel id" do
      expect(subject.channel_id).to eq("channel-id-123-xyz")
    end
  end

  describe "#name" do
    it "should return name" do
      expect(subject.name).to eq("name")
    end
  end

  describe "#status" do
    it "should return status" do
      expect(subject.status).to be_a(Ably::Models::ChannelStatus)
      expect(subject.status.occupancy.metrics.connections).to eq(1)
      expect(subject.status.occupancy.metrics.presence_connections).to eq(2)
      expect(subject.status.occupancy.metrics.presence_members).to eq(2)
      expect(subject.status.occupancy.metrics.presence_subscribers).to eq(5)
      expect(subject.status.occupancy.metrics.publishers).to eq(7)
      expect(subject.status.occupancy.metrics.subscribers).to eq(9)
    end
  end
end
