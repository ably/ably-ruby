require 'json'
# frozen_string_literal: true

module Ably
  module Realtime
  class RecoveryKeyContext
    attr_reader :connection_key
    attr_reader :msg_serial
    attr_reader :channel_serials

    def initialize(connection_key, msg_serial, channel_serials)
      @connection_key = connection_key
      @msg_serial = msg_serial
      @channel_serials = channel_serials
    end

    def encode
      JSON.dump(self)
    end

  end
  end
end
