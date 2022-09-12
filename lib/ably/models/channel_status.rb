module Ably::Models
  # Convert token details argument to a {ChannelStatus} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelStatus]
  #
  def self.ChannelStatus(attributes)
    case attributes
    when ChannelStatus
      return attributes
    else
      ChannelStatus.new(attributes)
    end
  end

  # Contains the status of a {Ably::Models::Rest::Channel} or {Ably::Models::Realtime::Channel} object
  # such as whether it is active and its {Ably::Models::ChannelOccupancy}.
  #
  # @spec CHS1
  #
  class ChannelStatus
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    # The attributes of ChannelStatus
    #
    # @spec CHS2
    #
    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelStatus
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    # If true, the channel is active, otherwise false.
    #
    # @spec CHS2a
    #
    # @return [Boolean]
    #
    def is_active
      attributes[:isActive]
    end
    alias_method :active?, :is_active
    alias_method :is_active?, :is_active

    # A {Ably::Models::ChannelOccupancy} object.
    #
    # @spec CHS2b
    #
    # @return [Ably::Models::ChannelOccupancy, nil]
    #
    def occupancy
      Ably::Models::ChannelOccupancy(attributes[:occupancy])
    end
  end
end
