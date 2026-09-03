module Ably::Modules
  module Conversions
    private
    # Convert push_channel_subscription argument to a {Ably::Models::PushChannelSubscription} object
    #
    # @param push_channel_subscription [Ably::Models::PushChannelSubscription,Hash,nil] A device details object
    #
    # @return [Ably::Models::PushChannelSubscription]
    #
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
  # Contains the subscriptions of a device, or a group of devices sharing the same clientId,
  # has to a channel in order to receive push notifications.
  #
  class PushChannelSubscription < Ably::Exceptions::BaseAblyException
    include Ably::Modules::ModelCommon

    # @param hash_object   [Hash,nil]  Device detail attributes
    #
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

    # A static factory method to create a PushChannelSubscription object for a channel and single device.
    #
    # @spec PSC5
    #
    # @param channel    [String]  the realtime pub/sub channel this subscription is registered to
    # @param device_id  [String]  Unique device identifier assigned to the push device
    #
    # @return [PushChannelSubscription]
    #
    def self.for_device(channel, device_id)
      PushChannelSubscription.new(channel: channel, device_id: device_id)
    end

    # A static factory method to create a PushChannelSubscription object for a channel and group of devices sharing the same clientId.
    #
    # @spec PSC5
    #
    # @param channel    [String]  the realtime pub/sub channel this subscription is registered to
    # @param client_id  [String]  Client ID that is assigned to one or more registered push devices
    #
    # @return [PushChannelSubscription]
    #
    def self.for_client_id(channel, client_id)
      PushChannelSubscription.new(channel: channel, client_id: client_id)
    end

    # The channel the push notification subscription is for.
    #
    # @spec PCS4
    #
    # @return [String]
    #
    def channel
      attributes[:channel]
    end

    # The ID of the client the device, or devices are associated to.
    #
    # @spec PCS3, PCS6
    #
    # @return [String]
    #
    def client_id
      attributes[:client_id]
    end

    # The unique ID of the device.
    #
    # @spec PCS2, PCS5, PCS6
    #
    # @return [String]
    #
    def device_id
      attributes[:device_id]
    end

    %w(channel client_id device_id).each do |attribute|
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
