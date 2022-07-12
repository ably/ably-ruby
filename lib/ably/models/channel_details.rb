# frozen_string_literal: true

module Ably
  # Models module provides the methods and classes for the Ably library
  #
  module Models
    # Convert token details argument to a {ChannelDetails} object
    #
    # @param attributes (see #initialize)
    #
    # @return [ChannelDetails]
    def self.ChannelDetails(attributes)
      case attributes
      when ChannelDetails
        attributes
      else
        ChannelDetails.new(attributes)
      end
    end

    # ChannelDetails is a type that represents information for a channel including channelId, name, status and occupancy (CHD1)
    #
    class ChannelDetails
      extend ::Ably::Modules::Enum
      extend Forwardable
      include ::Ably::Modules::ModelCommon

      # The attributes of ChannelDetails (CHD2)
      #
      attr_reader :attributes

      alias_method :to_h, :attributes

      # Initialize a new ChannelDetails
      #
      def initialize(attrs)
        @attributes = IdiomaticRubyWrapper(attrs.clone)
      end

      # The identifier of the channel (CHD2a)
      #
      # @return [String]
      #
      def channel_id
        attributes[:channel_id]
      end

      # The identifier of the channel (CHD2a)
      #
      # @return [String]
      #
      def name
        attributes[:name]
      end

      # The status of the channel (CHD2b)
      #
      # @return [Ably::Models::ChannelStatus, nil]
      #
      def status
        Ably::Models::ChannelStatus(attributes[:status])
      end
    end
  end
end
