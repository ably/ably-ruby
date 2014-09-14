require "base64"

module Ably
  module Support
    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end

    def user_agent
      "Ably Ruby client #{Ably::VERSION} (https://ably.io)"
    end
  end
end
