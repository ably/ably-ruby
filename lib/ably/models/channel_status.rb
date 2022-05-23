module Ably::Models
  # Convert token details argument to a {ChannelStatus} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelStatus]
  def self.ChannelStatus(attributes)
    case attributes
    when ChannelStatus
      return attributes
    else
      ChannelStatus.new(attributes)
    end
  end

  # Represents options of a channel
  class ChannelStatus
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelStatus
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    def is_active
      attributes[:isActive]
    end
    alias_method :active?, :is_active
    alias_method :is_active?, :is_active

    def occupancy
      Ably::Models::ChannelOccupancy(attributes[:occupancy])
    end
  end
end
