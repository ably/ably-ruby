require 'ably/models/message_encoders/base'

module Ably::Models::MessageEncoders
  # Utf8 Encoder and Decoder
  # Uses encoding identifier 'utf-8' and encodes all JSON objects as UTF-8, and sets the encoding when decoding
  #
  class Utf8 < Base
    ENCODING_ID = 'utf-8'

    def encode(message, channel_options)
      if is_json_encoded?(message)
        message[:data] = message[:data].encode(Encoding::UTF_8)
        add_encoding_to_message ENCODING_ID, message
      end
    end

    def decode(message, channel_options)
      if is_utf8_encoded?(message)
        message[:data] = message[:data].force_encoding(Encoding::UTF_8)
        strip_current_encoding_part message
      end
    end

    private
    def is_utf8_encoded?(message)
      current_encoding_part(message).to_s.match(/^#{ENCODING_ID}$/i)
    end

    def is_json_encoded?(message)
      current_encoding_part(message).to_s.match(/^json$/i)
    end
  end
end
