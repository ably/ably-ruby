module Ably::Models
  # Represents options of a channel
  class ChannelOptions
    MODES = [:publish, :subscribe, :presence, :presence_subscribe].freeze

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
    # @return [Array<>]
    attr_reader :modes

    def initialize(channel, params = {}, modes = [])
      @channel = channel
      @params = params
      @modes = modes
    end

    # Get value of the key from the params
    # @return [String]
    #
    def [](key)
      @params[key]
    end

    # Delegates fetching a key from the params to the params instance variable
    # @return [String]
    #
    def fetch(*args)
      @params.fetch(*args)
    end

    # Returns a params hash
    # @return [Hash]
    #
    def to_h
      @params.to_h
    end
    alias to_hash to_h

    # Converts the params to the string
    # @return [String]
    #
    def to_s
      @params.to_s
    end
  end
end
