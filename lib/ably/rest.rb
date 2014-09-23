require "ably/rest/channel"
require "ably/rest/channels"
require "ably/rest/client"
require "ably/rest/paged_resource"
require "ably/rest/presence"

module Ably
  module Rest
    # Convenience method providing an alias to {Ably::Rest::Client} constructor.
    #
    # @return [Ably::Rest::Client]
    def self.new(*args)
      Ably::Rest::Client.new(*args)
    end
  end
end
