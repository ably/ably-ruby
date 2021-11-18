# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ably::Models::ChannelOptions do
  let(:modes) { nil }
  let(:options) { described_class.new(modes: modes) }

  describe '#modes_to_flags' do
    let(:modes) { %w[publish subscribe presence_subscribe] }

    subject(:protocol_message) do
      Ably::Models::ProtocolMessage.new(action: Ably::Models::ProtocolMessage::ACTION.Attach, flags: options.modes_to_flags)
    end

    it 'converts modes to ProtocolMessage#flags correctly' do
      expect(protocol_message.has_attach_publish_flag?).to eq(true)
      expect(protocol_message.has_attach_subscribe_flag?).to eq(true)
      expect(protocol_message.has_attach_presence_subscribe_flag?).to eq(true)

      expect(protocol_message.has_attach_resume_flag?).to eq(false)
      expect(protocol_message.has_attach_presence_flag?).to eq(false)
    end
  end

  describe '#set_modes_from_flags' do
    let(:subscribe_flag) { 262144 }

    it 'converts flags to ChannelOptions#modes correctly' do
      result = options.set_modes_from_flags(subscribe_flag)

      expect(result).to eq(options.modes)
      expect(options.modes.map(&:to_sym)).to eq(%i[subscribe])
    end
  end
end
