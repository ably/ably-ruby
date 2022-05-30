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

  # Type that contain channel metrics (CHO1)
  #
  class ChannelOccupancy
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    # The attributes of ChannelOccupancy (CH02)
    #
    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelOccupancy
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    # Metrics object (CHO2a)
    #
    # @return [Ably::Models::ChannelMetrics, nil]
    #
    def metrics
      Ably::Models::ChannelMetrics(attributes[:metrics])
    end
  end
end
