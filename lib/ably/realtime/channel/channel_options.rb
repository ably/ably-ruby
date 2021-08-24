module Ably::Realtime
  class Channel
    # Represents options of a channel
    class ChannelOptions
      # {Ably::Realtime::Channel} this object associated with
      #
      # @return [Ably::Realtime::Channel]
      attr_reader :channel

      # (TB2c) params (for realtime client libraries only) a Dict<string,string> of key/value pairs
      #
      # @return [Hash]
      attr_reader :params

      # (TB2d) modes (for realtime client libraries only) an array of ChannelMode
      #
      # @return [Array<ChannelMode>]
      attr_reader :modes

      def initialize(channel, params = {}, modes = [])
        @channel = channel
        @params = params
        @modes = modes
      end
    end
  end
end
