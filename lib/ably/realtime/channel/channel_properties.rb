# frozen_string_literal: true

module Ably
  module Realtime
    class Channel
      # Represents properties of a channel and its state
      class ChannelProperties
        # {Ably::Realtime::Channel} this object associated with
        # @return [Ably::Realtime::Channel]
        attr_reader :channel

        # Contains the last channelSerial received in an ATTACHED ProtocolMesage for the channel, see RTL15a
        #
        # @return [String]
        attr_reader :attach_serial

        def initialize(channel)
          @channel = channel
        end

        # @api private
        def set_attach_serial(attach_serial)
          @attach_serial = attach_serial
        end
      end
    end
  end
end
