require "ably/rest/channel"
require "ably/rest/channels"
require "ably/rest/client"
require "ably/rest/models/message"
require "ably/rest/models/paginated_resource"
require "ably/rest/models/presence_message"
require "ably/rest/presence"

module Ably
  module Rest
    # Convenience method providing an alias to {Ably::Rest::Client} constructor.
    #
    # @param (see Ably::Rest::Client#initialize)
    # @option options (see Ably::Rest::Client#initialize)
    #
    # @yield (see Ably::Rest::Client#initialize)
    # @yieldparam (see Ably::Rest::Client#initialize)
    # @yieldreturn (see Ably::Rest::Client#initialize)
    #
    # @return [Ably::Rest::Client]
    #
    # @example
    #    # create a new client authenticating with basic auth
    #    client = Ably::Rest.new('key.id:secret')
    #
    def self.new(options, &auth_block)
      Ably::Rest::Client.new(options, &auth_block)
    end
  end
end
