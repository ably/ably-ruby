module Ably::Models
  # Convert token details argument to a {ChannelDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelDetails]
  #
  def self.ChannelDetails(attributes)
    case attributes
    when ChannelDetails
      return attributes
    else
      ChannelDetails.new(attributes)
    end
  end

  # Contains the details of a {Ably::Models::Rest::Channel} or {Ably::Models::Realtime::Channel} object
  # such as its ID and {Ably::Models::ChannelStatus}.
  #
  class ChannelDetails
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    # The attributes of ChannelDetails
    #
    # @spec CHD2
    #
    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelDetails
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    # The identifier of the channel
    #
    # @spec CHD2a
    #
    # @return [String]
    #
    def channel_id
      attributes[:channel_id]
    end

    # The identifier of the channel
    #
    # @spec CHD2a
    #
    # @return [String]
    #
    def name
      attributes[:name]
    end

    # A {Ably::Models::ChannelStatus} object.
    #
    # @spec CHD2b
    #
    # @return [Ably::Models::ChannelStatus, nil]
    #
    def status
      Ably::Models::ChannelStatus(attributes[:status])
    end
  end
end
