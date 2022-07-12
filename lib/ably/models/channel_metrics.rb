# frozen_string_literal: true

module Ably
  # Models module provides the methods and classes for the Ably library
  #
  module Models
    # Convert token details argument to a {ChannelMetrics} object
    #
    # @param attributes (see #initialize)
    #
    # @return [ChannelMetrics]
    def self.ChannelMetrics(attributes)
      case attributes
      when ChannelMetrics
        attributes
      else
        ChannelMetrics.new(attributes)
      end
    end

    # ChannelMetrics is a type that contains the count of publishers and subscribers, connections and presenceConnections,
    # presenceMembers and presenceSubscribers (CHM1)
    #
    class ChannelMetrics
      extend ::Ably::Modules::Enum
      extend Forwardable
      include ::Ably::Modules::ModelCommon

      # The attributes of ChannelMetrics (CHM2)
      #
      attr_reader :attributes

      alias_method :to_h, :attributes

      # Initialize a new ChannelMetrics
      #
      def initialize(attrs)
        @attributes = IdiomaticRubyWrapper(attrs.clone)
      end

      # The total number of connections to the channel (CHM2a)
      #
      # @return [Integer]
      #
      def connections
        attributes[:connections]
      end

      # The total number of presence connections to the channel (CHM2b)
      #
      # @return [Integer]
      #
      def presence_connections
        attributes[:presence_connections]
      end

      # The total number of presence members for the channel (CHM2c)
      #
      # @return [Integer]
      #
      def presence_members
        attributes[:presence_members]
      end

      # The total number of presence subscribers for the channel (CHM2d)
      #
      # @return [Integer]
      #
      def presence_subscribers
        attributes[:presence_subscribers]
      end

      # The total number of publishers to the channel (CHM2e)
      #
      # @return [Integer]
      #
      def publishers
        attributes[:publishers]
      end

      # The total number of subscribers to the channel (CHM2f)
      #
      # @return [Integer]
      #
      def subscribers
        attributes[:subscribers]
      end
    end
  end
end
