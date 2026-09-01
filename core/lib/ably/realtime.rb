require 'eventmachine'
require 'websocket/driver'
require 'em-http-request'

require 'ably/modules/event_emitter'

require 'ably/realtime/auth'
require 'ably/realtime/channel'
require 'ably/realtime/channels'
require 'ably/realtime/client'
require 'ably/realtime/connection'
require 'ably/realtime/push'
require 'ably/realtime/presence'

require 'ably/models/message_encoders/base'

Dir.glob(File.expand_path("models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

Dir.glob(File.expand_path("realtime/models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

require 'ably/models/message_encoders/base'

require 'ably/realtime/client/incoming_message_dispatcher'
require 'ably/realtime/client/outgoing_message_dispatcher'

module Ably
  # Realtime provides the top-level class to be instanced for the Ably Realtime library
  #
  # @example
  #   client = Ably::Realtime.new("xxxxx")
  #   channel = client.channel("test")
  #   channel.subscribe do |message|
  #     message[:name] #=> "greeting"
  #   end
  #   channel.publish "greeting", "data"
  #
  module Realtime
    # Convenience method providing an alias to {Ably::Realtime::Client} constructor.
    #
    # @param (see Ably::Realtime::Client#initialize)
    # @option options (see Ably::Realtime::Client#initialize)
    #
    # @return [Ably::Realtime::Client]
    #
    # @example
    #    # create a new client authenticating with basic auth
    #    client = Ably::Realtime.new('key.id:secret')
    #
    #    # create a new client authenticating with basic auth and a client_id
    #    client = Ably::Realtime.new(key: 'key.id:secret', client_id: 'john')
    #
    def self.new(options)
      Ably::Realtime::Client.new(options)
    end
  end
end
