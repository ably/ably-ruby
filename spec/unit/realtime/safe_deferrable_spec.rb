# encoding: utf-8
require 'spec_helper'
require 'shared/safe_deferrable_behaviour'
require 'ably/realtime'

[Ably::Models::ProtocolMessage, Ably::Models::Message, Ably::Models::PresenceMessage].each do |model_klass|
  describe model_klass do
    subject { model_klass.new(action: 1) }

    it_behaves_like 'a safe Deferrable'
  end
end
