# frozen_string_literal: true

require 'base64'
require 'ably/models/message_encoders/base'

module Ably
  module Models
    module MessageEncoders
      # Base64 binary Encoder and Decoder
      # Uses encoding identifier 'base64'
      #
      class Base64 < Base
        ENCODING_ID = 'base64'

        def encode(message, _channel_options)
          return if is_empty?(message)
          return unless is_binary?(message) && transport_protocol_text?

          message[:data] = ::Base64.encode64(message[:data])
          add_encoding_to_message ENCODING_ID, message
        end

        def decode(message, _channel_options)
          return unless is_base64_encoded?(message)

          message[:data] = ::Base64.decode64(message[:data])
          strip_current_encoding_part message
        end

        private

        def is_binary?(message)
          message[:data].is_a?(String) && message[:data].encoding == Encoding::ASCII_8BIT
        end

        def is_base64_encoded?(message)
          current_encoding_part(message).to_s.match(/^#{ENCODING_ID}$/i)
        end

        def transport_protocol_text?
          !options[:binary_protocol]
        end
      end
    end
  end
end
