module Ably::Models
  # Convert token details argument to a {ChannelMetrics} object
  #
  # @param attributes (see #initialize)
  #
  # @return [ChannelMetrics]
  #
  def self.ChannelMetrics(attributes)
    case attributes
    when ChannelMetrics
      return attributes
    else
      ChannelMetrics.new(attributes)
    end
  end

  # Contains the metrics associated with a {Ably::Models::Rest::Channel} or {Ably::Models::Realtime::Channel},
  # such as the number of publishers, subscribers and connections it has.
  #
  # @spec CHM1
  #
  class ChannelMetrics
    extend Ably::Modules::Enum
    extend Forwardable
    include Ably::Modules::ModelCommon

    # The attributes of ChannelMetrics (CHM2)
    #
    attr_reader :attributes

    alias_method :to_h, :attributes

    # Initialize a new ChannelMetrics
    #
    def initialize(attrs)
      @attributes = IdiomaticRubyWrapper(attrs.clone)
    end

    # The number of realtime connections attached to the channel.
    #
    # @spec CHM2a
    #
    # @return [Integer]
    #
    def connections
      attributes[:connections]
    end

    # The number of realtime connections attached to the channel with permission to enter the presence set, regardless
    # of whether or not they have entered it. This requires the presence capability and for a client to not have specified
    # a {Ably::Models::ChannelOptions::MODES} flag that excludes {Ably::Models::ChannelOptions::MODES}#PRESENCE.
    #
    # @spec CHM2b
    #
    # @return [Integer]
    #
    def presence_connections
      attributes[:presence_connections]
    end

    # The number of members in the presence set of the channel.
    #
    # @spec CHM2c
    #
    # @return [Integer]
    #
    def presence_members
      attributes[:presence_members]
    end

    # The number of realtime attachments receiving presence messages on the channel. This requires the subscribe capability
    # and for a client to not have specified a {Ably::Models::ChannelOptions::MODES} flag that excludes
    # {Ably::Models::ChannelOptions::MODES}#PRESENCE_SUBSCRIBE.
    #
    # @spec CHM2d
    #
    # @return [Integer]
    #
    def presence_subscribers
      attributes[:presence_subscribers]
    end

    # The number of realtime attachments permitted to publish messages to the channel. This requires the publish
    # capability and for a client to not have specified a {Ably::Models::ChannelOptions::MODES} flag that excludes
    # {Ably::Models::ChannelOptions::MODES}#PUBLISH.
    #
    # @spec CHM2e
    #
    # @return [Integer]
    #
    def publishers
      attributes[:publishers]
    end

    # The number of realtime attachments receiving messages on the channel. This requires the subscribe capability and
    # for a client to not have specified a {Ably::Models::ChannelOptions::MODES} flag that excludes
    # {Ably::Models::ChannelOptions::MODES}#SUBSCRIBE.
    #
    # @spec CHM2f
    #
    # @return [Integer]
    #
    def subscribers
      attributes[:subscribers]
    end
  end
end
