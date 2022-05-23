module Ably::Models
  # Convert token details argument to a {ChannelDetails} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelDetails]
  def self.ChannelDetails(attributes)
    case attributes
    when ChannelDetails
      return attributes
    else
      ChannelDetails.new(attributes)
    end
  end

  # Represents options of a channel
  class ChannelDetails
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelDetails
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    def channel_id
      attributes[:channel_id]
    end

    def name
      attributes[:name]
    end

    def status
      Ably::Models::ChannelStatus(attributes[:status])
    end
  end
end
