require "eventmachine"
require "websocket/driver"

require "ably/modules/callbacks"

require "ably/realtime/channel"
require "ably/realtime/client"
require "ably/realtime/connection"

require "ably/realtime/models/shared"
require "ably/realtime/models/error_info"
require "ably/realtime/models/message"
require "ably/realtime/models/protocol_message"

module Ably
  module Realtime
    def self.new(*args)
      Ably::Realtime::Client.new(*args)
    end
  end
end
