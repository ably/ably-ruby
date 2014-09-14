module Ably
  module Support
    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end
  end
end
