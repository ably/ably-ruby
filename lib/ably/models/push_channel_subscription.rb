module Ably::Modules
  module Conversions
    private
    # Convert push_channel_subscription argument to a {Ably::Models::PushChannelSubscription} object
    #
    # @param push_channel_subscription [Ably::Models::PushChannelSubscription,Hash,nil] A device details object
    #
    # @return [Ably::Models::PushChannelSubscription]
    def PushChannelSubscription(push_channel_subscription)
      case push_channel_subscription
      when Ably::Models::PushChannelSubscription
        push_channel_subscription
      else
        Ably::Models::PushChannelSubscription.new(push_channel_subscription)
      end
    end
  end
end

module Ably::Models
  # An object representing a devices details, used currently for push notifications
  #
  # @!attribute [r] channel
  #   @return [String] The realtime pub/sub channel this subscription is registered to
  # @!attribute [r] client_id
  #   @return [String] Client ID that is assigned to one or more registered push devices
  # @!attribute [r] device_id
  #   @return [String] Unique device identifier assigned to the push device
  #
  class PushChannelSubscription < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    # @param hash_object   [Hash,nil]  Device detail attributes
    #a
    def initialize(hash_object = {})
      @raw_hash_object = hash_object || {}
      @hash_object     = IdiomaticRubyWrapper(hash_object)

      if !attributes[:client_id] && !attributes[:device_id]
        raise ArgumentError, 'Either client_id or device_id must be provided'
      end
      if attributes[:client_id] && attributes[:device_id]
        raise ArgumentError, 'client_id and device_id cannot both be provided, they are mutually exclusive'
      end
      if !attributes[:channel]
        raise ArgumentError, 'channel is required'
      end
    end

    # Constructor for channel subscription by device ID
    #
    # @param channel    [String]  the realtime pub/sub channel this subscription is registered to
    # @param device_id  [String]  Unique device identifier assigned to the push device
    #
    # @return [PushChannelSubscription]
    #
    def self.for_device(channel, device_id)
      PushChannelSubscription.new(channel: channel, device_id: device_id)
    end

    # Constructor for channel subscription by client ID
    #
    # @param channel    [String]  the realtime pub/sub channel this subscription is registered to
    # @param client_id  [String]  Client ID that is assigned to one or more registered push devices
    #
    # @return [PushChannelSubscription]
    #
    def self.for_client_id(channel, client_id)
      PushChannelSubscription.new(channel: channel, client_id: client_id)
    end

    %w(channel client_id device_id).each do |attribute|
      define_method attribute do
        attributes[attribute.to_sym]
      end

      define_method "#{attribute}=" do |val|
        unless val.nil? || val.kind_of?(String)
          raise ArgumentError, "#{attribute} must be nil or a string value"
        end
        attributes[attribute.to_sym] = val
      end
    end

    def attributes
      @hash_object
    end
  end
end
