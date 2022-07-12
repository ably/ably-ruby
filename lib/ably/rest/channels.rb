# frozen_string_literal: true

module Ably
  module Rest
    # Channels provides the top-level class to be instanced for the Ably REST library
    #
    class Channels
      include ::Ably::Modules::ChannelsCollection

      # @return [Ably::Rest::Channels]
      def initialize(client)
        super client, Ably::Rest::Channel
      end

      # @!method get(name, channel_options = {})
      # Return a {Ably::Rest::Channel} for the given name
      #
      # @param name [String] The name of the channel
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      # @return [Ably::Rest::Channel}
      def get(*args)
        super
      end

      # @!method fetch(name, &missing_block)
      # Return a {Ably::Rest::Channel} for the given name if it exists, else the block will be called.
      # This method is intentionally similar to {http://ruby-doc.org/core-2.1.3/Hash.html#method-i-fetch Hash#fetch} providing a simple way to check if a channel exists or not without creating one
      #
      # @param name [String] The name of the channel
      # @yield [options] (optional) if a missing_block is passed to this method and no channel exists matching the name, this block is called
      # @yieldparam [String] name of the missing channel
      # @return [Ably::Rest::Channel]
      def fetch(*args)
        super
      end

      # Destroy the {Ably::Rest::Channel} and releases the associated resources.
      #
      # Releasing a {Ably::Rest::Channel} is not typically necessary as a channel consumes no resources other than the memory footprint of the
      # {Ably::Rest::Channel} object. Explicitly release channels to free up resources if required
      #
      # @return [void]
      def release(*args)
        super
      end
    end
  end
end
