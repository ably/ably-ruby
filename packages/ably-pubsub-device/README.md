# Ably Pub/Sub Ruby SDK for devices

The Ably Pub/Sub client for devices: applications running in end-user environments (desktop apps, CLIs, IoT and embedded clients) whose connections are identified by a `client_id` and counted on accounts with monthly-active-user billing.

This gem adds `Ably::PubSub::Device` to [`ably`](https://rubygems.org/gems/ably), whose client it returns unchanged and whose whole `Ably` namespace it makes available. If your application runs in a trusted server environment instead, use [`ably-pubsub-server`](https://rubygems.org/gems/ably-pubsub-server).

## Installation

```sh
gem install ably-pubsub-device
```

Or add it to your `Gemfile`:

```ruby
gem 'ably-pubsub-device'
```

## Usage

The realtime client runs on [EventMachine](https://github.com/eventmachine/eventmachine), so it needs a running reactor:

```ruby
require 'ably/pubsub/device'

EventMachine.run do
  client = Ably::PubSub::Device.create_client(key: 'your-ably-api-key', client_id: 'me')
  channel = client.channels.get('test-channel')

  channel.subscribe do |message|
    puts "Received message: #{message.data}"
  end

  channel.publish 'test-event', 'hello world'
end
```

`create_client` takes the same options as `Ably::Realtime::Client.new`, and behaves identically to it.

A device is usually best authenticated with a token rather than an API key, so that the key never leaves your server. Pass an `auth_url` or `auth_callback` in place of `key` — see [Ably's authentication docs](https://ably.com/docs/auth).

## Migrating

Constructing `Ably::Realtime::Client` directly still works and is not scheduled for removal, but it emits a deprecation warning, because the factory names the side your application runs on. Replace `Ably::Realtime.new(...)` or `Ably::Realtime::Client.new(...)` with `Ably::PubSub::Device.create_client(...)`.

## Support, feedback, and troubleshooting

For help or technical support, visit Ably's [support page](https://ably.com/support) or [GitHub Issues](https://github.com/ably/ably-ruby/issues).
