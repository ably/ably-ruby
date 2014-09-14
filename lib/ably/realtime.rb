require "eventmachine"
require "websocket/driver"

require "ably/realtime/callbacks"
require "ably/realtime/channel"
require "ably/realtime/client"
require "ably/realtime/connection"

module Ably
  module Realtime
    # Actions which are sent by the Ably Realtime API
    #
    # The values correspond to the ints which the API
    # understands.
    ACTIONS = {
      heartbeat:    0,
      ack:          1,
      nack:         2,
      connect:      3,
      connected:    4,
      disconnect:   5,
      disconnected: 6,
      close:        7,
      closed:       8,
      error:        9,
      attach:       10,
      attached:     11,
      detach:       12,
      detached:     13,
      presence:     14,
      message:      15
    }

    def self.new(*args)
      Ably::Realtime::Client.new(*args)
    end
  end
end
