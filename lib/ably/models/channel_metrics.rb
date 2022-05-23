module Ably::Models
  # Convert token details argument to a {ChannelMetrics} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelMetrics]
  def self.ChannelMetrics(attributes)
    case attributes
    when ChannelMetrics
      return attributes
    else
      ChannelMetrics.new(attributes)
    end
  end

  # Represents metrics of a channel
  class ChannelMetrics
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelMetrics
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    def connections
      attributes[:connections]
    end

    def presence_connections
      attributes[:presence_connections]
    end

    def presence_members
      attributes[:presence_members]
    end

    def presence_subscribers
      attributes[:presence_subscribers]
    end

    def publishers
      attributes[:publishers]
    end

    def subscribers
      attributes[:subscribers]
    end
  end
end
