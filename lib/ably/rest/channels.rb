module Ably
  module Rest
    class Channels
      attr_reader :client

      # Initialize a new Channels object
      #
      # {Ably::Rest::Channels} provides simple accessor methods to access a {Ably::Rest::Channel} object
      def initialize(client)
        @client   = client
        @channels = {}
      end

      # Return a REST {Ably::Rest::Channel} for the given name
      #
      # @param name [String] The name of the channel
      # @param channel_options [Hash] Channel options, currently reserved for Encryption options
      #
      # @return [Ably::Rest::Channel]
      def get(name, channel_options = {})
        @channels[name] ||= Ably::Rest::Channel.new(client, name, channel_options)
      end
      alias_method :[], :get

      def close(channel)
        @channels.delete(channel)
      end
    end
  end
end
