# ably-pubsub-server

Ably Pub/Sub client for servers: backend services and other trusted runtimes.

Installing this package declares that its traffic originates from the server side —
[MAU classification](https://ably.com/pricing) is a side effect of the install decision.

## Installation

```ruby
gem 'ably-pubsub-server'
```

## Usage

The factory functions are the only recommended entry points:

```ruby
require 'ably/pubsub/server'

# Stateless HTTP client: publish, history, presence reads, token issuance
http_client = Ably::PubSub::Server.create_http_client('your-api-key')
http_client.channels.get('example').publish('event', 'payload')

# Stateful realtime client: a persistent, live connection (EventMachine-based)
realtime_client = Ably::PubSub::Server.create_realtime_client('your-api-key')
```

Both factories accept everything the underlying constructors accept: an options `Hash`,
an API key `String`, or a token `String`.

This gem is built on `ably-pubsub-core`, an internal implementation package. Depend on
this gem, not on the core.
