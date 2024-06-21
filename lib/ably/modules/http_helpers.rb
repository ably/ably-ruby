require 'base64'

require 'ably/version'

require 'ably/rest/middleware/encoder'
require 'ably/rest/middleware/external_exceptions'
require 'ably/rest/middleware/fail_if_unsupported_mime_type'
require 'ably/rest/middleware/logger'
require 'ably/rest/middleware/parse_json'
require 'ably/rest/middleware/parse_message_pack'

module Ably::Modules
  # HttpHelpers provides common private methods to classes to simplify HTTP interactions with Ably
  module HttpHelpers
    protected
    def encode64(text)
      Base64.encode64(text).gsub("\n", '')
    end

    def user_agent
      "Ably Ruby client #{Ably::VERSION} (https://www.ably.io)"
    end

    def setup_outgoing_middleware(builder)
      # Convert request params to "www-form-urlencoded"
      builder.use Ably::Rest::Middleware::Encoder
    end

    def setup_incoming_middleware(builder, logger, options = {})
      builder.use Ably::Rest::Middleware::Logger, logger

      # Parse JSON / MsgPack response bodies. ParseJson must be first (default) parsing middleware
      if options[:fail_if_unsupported_mime_type] == true
        builder.use Ably::Rest::Middleware::FailIfUnsupportedMimeType
      end

      builder.use Ably::Rest::Middleware::ParseJson
      builder.use Ably::Rest::Middleware::ParseMessagePack
    end
  end
end
