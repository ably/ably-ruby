module Ably::Realtime
  class Channel
    # Describes the properties of the channel state.
    class ChannelProperties
      # {Ably::Realtime::Channel} this object associated with
      #
      # @return [Ably::Realtime::Channel]
      #
      attr_reader :channel

      # Starts unset when a channel is instantiated, then updated with the channelSerial from each
      # {Ably::Realtime::Channel::STATE.Attached} event that matches the channel.
      # Used as the value for {Ably::Realtime::Channel#history}.
      #
      # @spec CP2a
      #
      # @return [String]
      #
      attr_reader :attach_serial

      # ChannelSerial contains the channelSerial from latest ProtocolMessage of action type
      # Message/PresenceMessage received on the channel.
      #
      # @spec CP2b, RTL15b
      #
      # @return [String]
      #
      attr_accessor :channel_serial

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
