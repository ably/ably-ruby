# ably-pubsub-core

Internal implementation package for Ably's own Pub/Sub Ruby packages.

**This gem is not intended for direct external use.** It is published only so that
Ably's public packages can depend on it. Use [`ably-pubsub-server`](../server) instead,
which exposes the supported entry points:

```ruby
client = Ably::PubSub::Server.create_http_client(key)      # stateless HTTP client
client = Ably::PubSub::Server.create_realtime_client(key)  # stateful realtime client
```

`ably-pubsub-core` and `ably-pubsub-server` are released in lockstep at the same version.
