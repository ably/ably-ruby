require 'ably'
require 'ably/pubsub/server/version'

module Ably
  module PubSub
    # The Ably Pub/Sub SDK for servers. The factory functions here are the only
    # recommended entry points of the +ably-pubsub-server+ gem.
    module Server
      # The agent identifier declaring the server side.
      #
      # The `-server` suffix is load-bearing, not cosmetic. On API-key auth the realtime
      # system grants the MAU server exemption by matching an agent entry ending in
      # `-server`, and an identifier that is not yet in the ably-common registry is
      # classified by that suffix alone. Renaming it without preserving the suffix
      # silently reclassifies every client this package constructs.
      #
      # The entry is stamped WITHOUT a version, matching its registration in the
      # ably-common agents registry (a pure flag, like `browser`): under lockstep
      # versioning a version here always duplicates the ably-pubsub-ruby entry beside it,
      # which keeps carrying identity, version and support status. Wire shape:
      #   ably-pubsub-ruby/2.0.0 ruby/3.3.0 ably-pubsub-server
      SERVER_AGENT_IDENTIFIER = 'ably-pubsub-server'

      class << self
        # Creates a stateless HTTP (REST) client declaring the server side.
        #
        # Accepts everything {Ably::Rest::Client#initialize} accepts: an options Hash,
        # an API key String, or a token String.
        #
        # @return [Ably::Rest::Client]
        def create_http_client(options)
          Ably::Rest::Client.new(options_with_side_agent(options))
        end

        # Creates a stateful realtime client declaring the server side.
        #
        # Accepts everything {Ably::Realtime::Client#initialize} accepts: an options Hash,
        # an API key String, or a token String.
        #
        # @return [Ably::Realtime::Client]
        def create_realtime_client(options)
          Ably::Realtime::Client.new(options_with_side_agent(options))
        end

        private

        # Returns a copy of the caller's options carrying the agent entry that declares
        # this package's side.
        #
        # The caller's own +:agents+ entries are preserved, so an SDK layered on top of
        # this package keeps its attribution. The side entry is merged last and so wins a
        # collision on its own identifier: which side the package declares is the
        # package's to state, not the caller's to redefine.
        #
        # A nil argument passes through unchanged so the caller gets the core
        # constructor's own initialization error rather than a vaguer failure later.
        def options_with_side_agent(options)
          return options if options.nil?

          options = if options.kind_of?(String)
            if options.match(Ably::Auth::API_KEY_REGEX)
              { key: options }
            else
              { token: options }
            end
          else
            options.clone
          end

          agents = options[:agents].to_h.merge(SERVER_AGENT_IDENTIFIER => nil)
          options.merge(agents: agents)
        end
      end
    end
  end
end
