require 'ably/models/message_encoders/base'

module Ably::Models::MessageEncoders
  # Delta Vcdiff Encoder and Decoder
  # Uses encoding identifier 'vcdiff' and encodes all JSON objects in Vcdiff format, and sets the encoding when decoding
  #
  class Vcdiff < Base
    ENCODING_ID = 'vcdiff'

    def encode(message, channel_options)

    end

    def decode(message, channel_options)
      return nil unless current_encoding_part(message).to_s.match(/^#{ENCODING_ID}$/i)

      if !channel_options[:plugins] || !(vcdiff = channel_options[:plugins][:vcdiff]) # (PC3)
        raise Ably::Exceptions::VcdiffError.new('Missing vcdiff decoder (https://github.com/ably-forks/vcdiff-decoder-ruby)', 400, 40019)
      end

      delta_base = channel_options[:base_encoded_previous_payload]
      delta_base = delta_base.force_encoding(Encoding::UTF_8) if delta_base.is_a?(String) # (PC3a)

      data = vcdiff.decode(message[:data], delta_base)

      message[:data] = data
      channel_options[:base_encoded_previous_payload] = data
    rescue => exception
      raise Ably::Exceptions::VcdiffError.new("vcdiff delta decode failed with #{exception}", 400, 40018)
    end
  end
end
