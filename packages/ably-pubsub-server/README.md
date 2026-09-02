# Ably Pub/Sub Ruby SDK for servers

The Ably Pub/Sub client for servers: trusted environments which typically authenticate with an API key, and whose connections are exempt from monthly-active-user counting.

This gem adds `Ably::PubSub::Server` to [`ably`](https://rubygems.org/gems/ably), whose clients it returns unchanged and whose whole `Ably` namespace it makes available. If your application runs on an end-user device instead, use [`ably-pubsub-device`](https://rubygems.org/gems/ably-pubsub-device).

## Installation

```sh
gem install ably-pubsub-server
```

Or add it to your `Gemfile`:

```ruby
gem 'ably-pubsub-server'
```

## Usage

Use `create_http_client` when publish, history, presence reads, stats and token issuing over HTTP are enough:

```ruby
require 'ably/pubsub/server'

client = Ably::PubSub::Server.create_http_client(key: 'your-ably-api-key')
client.channels.get('test-channel').publish 'test-event', 'hello world'
```

Use `create_realtime_client` when the server needs a persistent connection — subscribing to channels, or entering presence. The realtime client runs on [EventMachine](https://github.com/eventmachine/eventmachine), so it needs a running reactor:

```ruby
require 'ably/pubsub/server'

EventMachine.run do
  client = Ably::PubSub::Server.create_realtime_client(key: 'your-ably-api-key')
  channel = client.channels.get('test-channel')

  channel.subscribe do |message|
    puts "Received message: #{message.data}"
  end

  channel.publish 'test-event', 'hello world'
end
```

Both factories take the same options as `Ably::Rest::Client.new` and `Ably::Realtime::Client.new`, and behave identically to them.

## Migrating

Constructing the clients directly still works and is not scheduled for removal, but it emits a deprecation warning, because the factories name the side your application runs on. Replace:

| Before | After |
|--------|-------|
| `Ably::Rest.new(...)`, `Ably::Rest::Client.new(...)` | `Ably::PubSub::Server.create_http_client(...)` |
| `Ably::Realtime.new(...)`, `Ably::Realtime::Client.new(...)` | `Ably::PubSub::Server.create_realtime_client(...)` |

## Support, feedback, and troubleshooting

For help or technical support, visit Ably's [support page](https://ably.com/support) or [GitHub Issues](https://github.com/ably/ably-ruby/issues).
