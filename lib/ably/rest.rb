require "ably/rest/channel"
require "ably/rest/client"
require "ably/rest/paged_resource"
require "ably/rest/presence"

module Ably
  module Rest
    def self.new(*args)
      Ably::Rest::Client.new(*args)
    end
  end
end
