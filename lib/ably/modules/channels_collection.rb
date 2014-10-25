module Ably::Modules
  module ChannelsCollection
    # Initialize a new Channels object
    #
    # {self} provides simple accessor methods to access a Channel object
    def initialize(client, channel_klass)
      @client         = client
      @channel_klass  = channel_klass
      @channels       = {}
    end

    # Return a Channel for the given name
    #
    # @param name [String] The name of the channel
    # @param channel_options [Hash] Channel options, currently reserved for Encryption options
    #
    # @return Channel
    def get(name, channel_options = {})
      @channels[name] ||= channel_klass.new(client, name, channel_options)
    end
    alias_method :[], :get

    # Return a Channel for the given name if it exists, else the block will be called.
    # This method is intentionally similar to {http://ruby-doc.org/core-2.1.3/Hash.html#method-i-fetch Hash#fetch} providing a simple way to check if a channel exists or not without creating one
    #
    # @param name [String] The name of the channel
    #
    # @yield [options] (optional) if a missing_block is passed to this method and no channel exists matching the name, this block is called
    # @yieldparam [String] name of the missing channel
    #
    # @return Channel
    def fetch(name, &missing_block)
      @channels.fetch(name, &missing_block)
    end

    # Destroy the Channel and releases the associated resources.
    #
    # Releasing a Channel is not typically necessary as a channel consumes no resources other than the memory footprint of the
    # Channel object. Explicitly release channels to free up resources if required
    def release(channel)
      @channels.delete(channel)
    end

    private
    attr_reader :client, :channel_klass
  end
end
