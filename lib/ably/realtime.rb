require "eventmachine"
require "websocket/driver"

require "ably/modules/event_emitter"

require "ably/realtime/channel"
require "ably/realtime/client"
require "ably/realtime/connection"

require "ably/realtime/models/shared"
require "ably/realtime/models/error_info"
require "ably/realtime/models/message"
require "ably/realtime/models/nil_channel"
require "ably/realtime/models/protocol_message"

require "ably/realtime/client/message_dispatcher"

module Ably
  module Realtime
    def self.new(*args)
      Ably::Realtime::Client.new(*args)
    end
  end
end
