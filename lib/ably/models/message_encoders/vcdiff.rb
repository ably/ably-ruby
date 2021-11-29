require 'ably/models/message_encoders/base'

module Ably
  module Models
    module MessageEncoders
      # Delta Vcdiff Encoder and Decoder
      # Uses encoding identifier 'vcdiff' and encodes all JSON objects in Vcdiff format, and sets the encoding when decoding
      #
      class Vcdiff < Base
        ENCODING_ID = 'vcdiff'

        def encode(message, channel_options)
          # no vcdiff encoding required
        end

        def decode(message, channel_options)
          return nil unless is_vcdiff_encoded?(message) # (RTL19)

          if !channel_options[:plugins] || !(vcdiff = channel_options[:plugins][:vcdiff]) # (PC3)
            raise Ably::Exceptions::VcdiffError.new('Missing vcdiff decoder (https://github.com/ably-forks/vcdiff-decoder-ruby)', 400, 40019)
          end

          # Comparing against the delta reference id (RTL20, RTL18, RTL18a, RTL18b, RTL18c)
          # The extras.delta.from format is {protocol message id}:{protocol message index} i.e.: hzDoTpFqnD:1:0
          #
          unless message.dig(:extras, :delta, :from) == channel_options[:previous_message_id]
            raise Ably::Exceptions::VcdiffError.new('Last message ID is different than Message.extras.delta.from', 400, 40018)
          end

          delta_base = channel_options[:base_encoded_previous_payload]
          delta_base = delta_base.force_encoding(Encoding::UTF_8) if delta_base.is_a?(String) # (PC3a)

          unless vcdiff.respond_to?(:decode)
            raise Ably::Exceptions::VcdiffError.new('Plugin does not support `decode(data, base)` method with two arguments.', 400, 40018)
          end
          message[:data] = vcdiff.decode(message[:data], delta_base)

          strip_current_encoding_part(message) # (RSL4b)
        rescue => exception
          raise Ably::Exceptions::VcdiffError.new("vcdiff delta decode failed with #{exception}", 400, 40018)
        end

        private

        # It returns true if the message encoding contains vcdiff part. For example
        #   utf-8/cipher+aes-128-cbc/base64/vcdiff => true
        #
        def is_vcdiff_encoded?(message)
          !current_encoding_part(message).to_s.match(/^#{ENCODING_ID}$/i).nil?
        end
      end
    end
  end
end
