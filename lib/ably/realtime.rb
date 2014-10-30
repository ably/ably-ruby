require "eventmachine"
require "websocket/driver"

require "ably/modules/event_emitter"

require "ably/realtime/channel"
require "ably/realtime/channels"
require "ably/realtime/client"
require "ably/realtime/connection"
require "ably/realtime/connection/connection_state_machine"
require "ably/realtime/connection/websocket_transport"
require "ably/realtime/presence"

require "ably/models/shared"
Dir.glob(File.expand_path("models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

require "ably/realtime/client/incoming_message_dispatcher"
require "ably/realtime/client/outgoing_message_dispatcher"

module Ably
  module Realtime
    # Convenience method providing an alias to {Ably::Realtime::Client} constructor.
    #
    # @param (see Ably::Realtime::Client#initialize)
    # @option options (see Ably::Realtime::Client#initialize)
    #
    # @yield (see Ably::Realtime::Client#initialize)
    # @yieldparam (see Ably::Realtime::Client#initialize)
    # @yieldreturn (see Ably::Realtime::Client#initialize)
    #
    # @return [Ably::Realtime::Client]
    #
    # @example
    #    # create a new client authenticating with basic auth
    #    client = Ably::Realtime.new('key.id:secret')
    #
    def self.new(options, &auth_block)
      Ably::Realtime::Client.new(options, &auth_block)
    end
  end
end
