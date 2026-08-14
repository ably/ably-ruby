require 'ably'

require 'ably/pubsub/server/version'

module Ably
  module PubSub
    # The Ably Pub/Sub client for servers.
    #
    # Servers are trusted environments which typically authenticate with an API key, and whose
    # connections are exempt from monthly-active-user counting. This gem names that side, so that
    # the client an application reaches for is the one whose gem matches where it runs.
    #
    # Use {create_http_client} for publish, history, presence reads, stats and token issuing over
    # HTTP, and {create_realtime_client} when the server also needs to subscribe to channels or
    # enter presence over a persistent connection. Both return the same clients the `ably` gem
    # does, with identical behaviour, so the whole `Ably` namespace is available once this gem is
    # required.
    #
    # Ships in the `ably-pubsub-server` gem, which adds this module to the `Ably` namespace the
    # `ably` gem provides.
    #
    module Server
      class << self
        # Creates a server Pub/Sub client that operates entirely over HTTP.
        #
        # Takes the same options as {Ably::Rest::Client#initialize}, and behaves identically to it.
        #
        # @param (see Ably::Rest::Client#initialize)
        # @option options (see Ably::Rest::Client#initialize)
        #
        # @return [Ably::Rest::Client]
        #
        # @example
        #    client = Ably::PubSub::Server.create_http_client(key: 'key.id:secret')
        #    client.channels.get('test-channel').publish 'test-event', 'hello world'
        #
        def create_http_client(options)
          Ably::Util::Deprecation.suppress_constructor_deprecation do
            Ably::Rest::Client.new(options)
          end
        end

        # Creates a server Pub/Sub client with a persistent realtime connection.
        #
        # Everything the HTTP client does, plus subscribing to channels and entering presence.
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
        #      client = Ably::PubSub::Server.create_realtime_client(key: 'key.id:secret')
        #      client.channels.get('test-channel').publish 'test-event', 'hello world'
        #    end
        #
        def create_realtime_client(options)
          Ably::Util::Deprecation.suppress_constructor_deprecation do
            Ably::Realtime::Client.new(options)
          end
        end
      end
    end
  end
end
