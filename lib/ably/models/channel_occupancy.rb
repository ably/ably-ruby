module Ably::Models
  # Convert token details argument to a {ChannelOccupancy} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelOccupancy]
  def self.ChannelOccupancy(attributes)
    case attributes
    when ChannelOccupancy
      return attributes
    else
      ChannelOccupancy.new(attributes)
    end
  end

  # Represents occupancy of a channel
  class ChannelOccupancy
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelOccupancy
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    def metrics
      Ably::Models::ChannelMetrics(attributes[:metrics])
    end
  end
end
