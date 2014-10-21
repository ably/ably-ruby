require 'base64'

require 'ably/rest/middleware/external_exceptions'
require 'ably/rest/middleware/parse_json'
require 'ably/rest/middleware/parse_message_pack'

module Ably::Modules
  module HttpHelpers
    protected
    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end

    def user_agent
      "Ably Ruby client #{Ably::VERSION} (https://ably.io)"
    end

    def setup_middleware(builder)
      # Convert request params to "www-form-urlencoded"
      builder.use Faraday::Request::UrlEncoded

      # Parse JSON / MsgPack response bodies.  ParseJson must be first (default) parsing middleware
      builder.use Ably::Rest::Middleware::ParseJson
      builder.use Ably::Rest::Middleware::ParseMessagePack
    end
  end
end
