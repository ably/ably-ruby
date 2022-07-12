# frozen_string_literal: true

require 'spec_helper'
require 'shared/model_behaviour'

describe Ably::Models::ChannelOccupancy do
  subject { Ably::Models::ChannelOccupancy({ metrics: { connections: 1, presence_connections: 2, presence_members: 2, presence_subscribers: 5, publishers: 7, subscribers: 9 } }) }

  describe '#metrics' do
    it 'should return attributes' do
      expect(subject.metrics.connections).to eq(1)
      expect(subject.metrics.presence_connections).to eq(2)
      expect(subject.metrics.presence_members).to eq(2)
      expect(subject.metrics.presence_subscribers).to eq(5)
      expect(subject.metrics.publishers).to eq(7)
      expect(subject.metrics.subscribers).to eq(9)
    end
  end
end
