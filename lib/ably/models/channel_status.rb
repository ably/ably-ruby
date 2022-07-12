# frozen_string_literal: true

module Ably
  # Models module provides the methods and classes for the Ably library
  #
  module Models
    # Convert token details argument to a {ChannelStatus} object
    #
    # @param attributes (see #initialize)
    #
    # @return [ChannelStatus]
    def self.ChannelStatus(attributes)
      case attributes
      when ChannelStatus
        attributes
      else
        ChannelStatus.new(attributes)
      end
    end

    # ChannelStatus is a type that contains status and occupancy for a channel (CHS1)
    #
    class ChannelStatus
      extend ::Ably::Modules::Enum
      extend Forwardable
      include ::Ably::Modules::ModelCommon

      # The attributes of ChannelStatus (CHS2)
      #
      attr_reader :attributes

      alias_method :to_h, :attributes

      # Initialize a new ChannelStatus
      #
      def initialize(attrs)
        @attributes = IdiomaticRubyWrapper(attrs.clone)
      end

      # Represents if the channel is active (CHS2a)
      #
      # @return [Boolean]
      #
      def is_active
        attributes[:isActive]
      end
      alias_method :active?, :is_active
      alias_method :is_active?, :is_active

      # Occupancy ChannelOccupancy – occupancy is an object containing the metrics for the channel (CHS2b)
      #
      # @return [Ably::Models::ChannelOccupancy, nil]
      #
      def occupancy
        Ably::Models::ChannelOccupancy(attributes[:occupancy])
      end
    end
  end
end
