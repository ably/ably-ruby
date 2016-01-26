module Ably::Modules
  # ChannelsCollection module provides common functionality to the Rest and Realtime Channels objects
  # such as #get, #[], #fetch, and #release
  module ChannelsCollection
    include Enumerable

    def initialize(client, channel_klass)
      @client         = client
      @channel_klass  = channel_klass
      @channels       = {}
    end

    # Return a Channel for the given name
    #
    # @param name [String] The name of the channel
    # @param channel_options [Hash] Channel options including the encryption options
    #
    # @return [Channel]
    #
    def get(name, channel_options = {})
      if channels.has_key?(name)
        channels[name].tap do |channel|
          channel.update_options channel_options if channel_options && !channel_options.empty?
        end
      else
        channels[name] ||= channel_klass.new(client, name, channel_options)
      end
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
    # @return [Channel]
    #
    def fetch(name, &missing_block)
      channels.fetch(name, &missing_block)
    end

    # Destroy the Channel and releases the associated resources.
    #
    # Releasing a Channel is not typically necessary as a channel consumes no resources other than the memory footprint of the
    # Channel object. Explicitly release channels to free up resources if required
    #
    # @param name [String] The name of the channel
    #
    # @return [void]
    #
    def release(name)
      channels.delete(name)
    end

    # @!attribute [r] length
    # @return [Integer] number of channels created
    def length
      channels.length
    end
    alias_method :count, :length
    alias_method :size,  :length

    # Method to allow {ChannelsCollection} to be {http://ruby-doc.org/core-2.1.3/Enumerable.html Enumerable}
    def each(&block)
      return to_enum(:each) unless block_given?
      channels.values.each(&block)
    end

    private
    def client
      @client
    end

    def channel_klass
      @channel_klass
    end

    def channels
      @channels
    end
  end
end
