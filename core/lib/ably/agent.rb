module Ably
  # The SDK family identifier renamed from `ably-ruby` with the per-side package split, so the
  # identifier alone partitions the fleet: `ably-ruby/*` is legacy-gem traffic,
  # `ably-pubsub-ruby/*` is new-package traffic. It names the family rather than any one
  # published gem; the side a client declares travels as a separate versionless agent entry
  # (see Ably::PubSub::Server and the agents registry in ably-common).
  AGENT = "ably-pubsub-ruby/#{Ably::VERSION} ruby/#{RUBY_VERSION}"
end
