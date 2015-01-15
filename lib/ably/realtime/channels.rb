module Ably
  module Realtime
    # Class that maintains a map of Channels ensuring Channels are reused
    class Channels
      include Ably::Modules::ChannelsCollection

      # @return [Ably::Realtime::Channels]
      def initialize(client)
        super client, Ably::Realtime::Channel
      end

      # @!method get(name, channel_options = {})
      # Return a {Ably::Realtime::Channel} for the given name
      #
      # @param name [String] The name of the channel
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      # @return [Ably::Realtime::Channel}
      #
      def get(*args)
        super
      end

      # @!method fetch(name, &missing_block)
      # Return a {Ably::Realtime::Channel} for the given name if it exists, else the block will be called.
      # This method is intentionally similar to {http://ruby-doc.org/core-2.1.3/Hash.html#method-i-fetch Hash#fetch} providing a simple way to check if a channel exists or not without creating one
      #
      # @param name [String] The name of the channel
      # @yield [options] (optional) if a missing_block is passed to this method and no channel exists matching the name, this block is called
      # @yieldparam [String] name of the missing channel
      # @return [Ably::Realtime::Channel]
      #
      def fetch(*args)
        super
      end

      # Detaches the {Ably::Realtime::Channel Realtime Channel} and releases all associated resources.
      #
      # Releasing a Realtime Channel is not typically necessary as a channel, once detached, consumes no resources other than
      # the memory footprint of the {Ably::Realtime::Channel Realtime Channel object}. Release channels to free up resources if required
      #
      # @return [void]
      #
      def release(channel)
        get(channel).detach do
          @channels.delete(channel)
        end if @channels.has_key?(channel)
      end
    end
  end
end
