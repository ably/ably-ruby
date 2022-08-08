# frozen_string_literal: true

require "json"
require "ably/models/message_encoders/base"

module Ably
  module Models
    module MessageEncoders
      # JSON Encoder and Decoder
      # Uses encoding identifier 'json' and encodes all objects that are not strings or byte arrays
      #
      class Json < Base
        ENCODING_ID = "json"

        def encode(message, _channel_options)
          return unless needs_json_encoding?(message)

          message[:data] = ::JSON.dump(message[:data])
          add_encoding_to_message ENCODING_ID, message
        end

        def decode(message, _channel_options)
          return unless is_json_encoded?(message)

          message[:data] = ::JSON.parse(message[:data])
          strip_current_encoding_part message
        end

        private

        def needs_json_encoding?(message)
          !message[:data].is_a?(String) && !message[:data].nil?
        end

        def is_json_encoded?(message)
          current_encoding_part(message).to_s.match(/^#{ENCODING_ID}$/io)
        end
      end
    end
  end
end
