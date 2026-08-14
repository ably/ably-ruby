require 'ably'

require 'ably/pubsub/device/version'

module Ably
  module PubSub
    # The Ably Pub/Sub client for devices.
    #
    # Devices are applications running in end-user environments — desktop apps, CLIs, IoT and
    # embedded clients — whose connections are identified by a `client_id` and counted on accounts
    # with monthly-active-user billing. This gem names that side, so that the client an application
    # reaches for is the one whose gem matches where it runs.
    #
    # Use {create_client} to open a realtime connection with channels, presence and history. It
    # returns the same client the `ably` gem does, with identical behaviour, so the whole `Ably`
    # namespace is available once this gem is required.
    #
    # Ships in the `ably-pubsub-device` gem, which adds this module to the `Ably` namespace the
    # `ably` gem provides.
    #
    module Device
      class << self
        # Creates a device Pub/Sub client: a realtime connection to Ably with channels, presence
        # and history.
        #
        # Takes the same options as {Ably::Realtime::Client#initialize}, and behaves identically
        # to it, so it requires a running EventMachine reactor.
        #
        # @param (see Ably::Realtime::Client#initialize)
        # @option options (see Ably::Realtime::Client#initialize)
        #
        # @return [Ably::Realtime::Client]
        #
        # @example
        #    EventMachine.run do
        #      client = Ably::PubSub::Device.create_client(key: 'key.id:secret', client_id: 'me')
        #      client.channels.get('test-channel').subscribe { |message| puts message.data }
        #    end
        #
        def create_client(options)
          Ably::Util::Deprecation.suppress_constructor_deprecation do
            Ably::Realtime::Client.new(options)
          end
        end
      end
    end
  end
end
