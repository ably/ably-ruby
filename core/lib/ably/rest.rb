require 'ably/rest/channel'
require 'ably/rest/channels'
require 'ably/rest/client'
require 'ably/rest/push'
require 'ably/rest/presence'

require 'ably/models/message_encoders/base'

Dir.glob(File.expand_path("models/*.rb", File.dirname(__FILE__))).each do |file|
  require file
end

module Ably
  # Rest provides the top-level class to be instanced for the Ably Rest library
  #
  # @example
  #   client = Ably::Rest.new("xxxxx")
  #   channel = client.channel("test")
  #   channel.publish "greeting", "data"
  #
  module Rest
    # Convenience method providing an alias to {Ably::Rest::Client} constructor.
    #
    # @param (see Ably::Rest::Client#initialize)
    # @option options (see Ably::Rest::Client#initialize)
    #
    # @return [Ably::Rest::Client]
    #
    # @example
    #    # create a new client authenticating with basic auth
    #    client = Ably::Rest.new('key.id:secret')
    #
    #    # create a new client authenticating with basic auth and a client_id
    #    client = Ably::Rest.new(key: 'key.id:secret', client_id: 'john')
    #
    def self.new(options)
      Ably::Rest::Client.new(options)
    end
  end
end
