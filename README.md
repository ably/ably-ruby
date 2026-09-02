# Ably Pub/Sub Ruby SDK

![Ably Pub/Sub Ruby Header](images/rubySDK-github.png)
[![Gem Version](https://img.shields.io/gem/v/ably?style=flat)](https://rubygems.org/gems/ably)
[![Coverage Status](https://coveralls.io/repos/ably/ably-ruby/badge.svg)](https://coveralls.io/r/ably/ably-ruby)
[![License](https://badgen.net/github/license/ably/ably-ruby)](https://github.com/ably/ably-ruby/blob/main/LICENSE)

---

Build any realtime experience using Ably’s Pub/Sub Ruby SDK, Supported on all popular platforms and frameworks.

Ably Pub/Sub provides flexible APIs that deliver features such as pub-sub messaging, message history, presence, and push notifications. Utilizing Ably’s realtime messaging platform, applications benefit from its highly performant, reliable, and scalable infrastructure.

Find out more:

* [Ably Pub/Sub docs.](https://ably.com/docs/basics)
* [Ably Pub/Sub examples.](https://ably.com/examples?product=pubsub)

---

## Getting started

Everything you need to get started with Ably:

* [Getting started with Pub/Sub using Ruby.](https://ably.com/docs/getting-started/ruby)
* [SDK Setup for Ruby.](https://ably.com/docs/getting-started/setup?lang=ruby)

---

## Supported platforms

Ably aims to support a wide range of platforms and browsers. If you experience any compatibility issues, open an issue in the repository or contact [Ably support](https://ably.com/support).

| Platform       | Support |
|----------------|---------|
| Ruby           | >= 2.7 and 3.x. For EventMachine compatibility with Ruby 3.x |
| EventMachine   | Required for using the Realtime API. Compatible with Ruby 3.x with OpenSSL configuration. |
| libcurl        | Required since v1.1.5. On Debian-based systems, install via `sudo apt-get install libcurl4`. |

> [!IMPORTANT]
> SDK versions < 1.2.5 will be [deprecated](https://ably.com/docs/platform/deprecate/protocol-v1) from November 1, 2025.

---


## Installation

Install the gem for the side your application runs on. Each pulls in `ably` and adds an entry point under `Ably::PubSub` naming that side:

```sh
# Create a new Gemfile
echo "source 'https://rubygems.org'" > Gemfile

# Trusted server environments — publishing, token issuing, backend subscribers
echo "gem 'ably-pubsub-server'" >> Gemfile   # provides Ably::PubSub::Server

# End-user devices — desktop apps, CLIs, IoT and embedded clients
echo "gem 'ably-pubsub-device'" >> Gemfile   # provides Ably::PubSub::Device

# Install the gem
bundle install
```

Installing `ably` on its own also still works, and remains fully supported. It is the shared core both build on, and the clients they return are its clients unchanged.

> [!NOTE]
Install [Ruby](https://www.ruby-lang.org/en/documentation/installation/) version 2.7 or greater.

---

### EventMachine

To use the Ably Realtime SDK in Ruby, the `EventMachine` reactor loop must be running. This is required because the Realtime library depends on EventMachine to handle asynchronous events.

Wrap your code inside a `EventMachine.run` block:

```ruby
require 'ably/pubsub/device'

EventMachine.run do
  client = Ably::PubSub::Device.create_client(key: 'your-api-key')

  client.connection.connect do
    puts "Connected with connection ID: #{client.connection.id}"
  end
end
```

---

## Usage

The following code connects to Ably's realtime messaging service, subscribes to a channel to receive messages, and publishes a test message to that same channel.

```ruby
  # Initialize Ably Realtime client
  realtime_client = Ably::PubSub::Device.create_client(key: 'your-ably-api-key', client_id: 'me')
  
  # Wait for connection to be established
  realtime_client.connection.on(:connected) do
    puts 'Connected to Ably'
    
    # Get a reference to the 'test-channel' channel
    channel = realtime_client.channels.get('test-channel')
    
    # Subscribe to all messages published to this channel
    channel.subscribe do |message|
      puts "Received message: #{message.data}"
    end
    
    # Publish a test message to the channel
    channel.publish 'test-event', 'hello world'
  end
end

```

On a server, use `Ably::PubSub::Server.create_realtime_client` for the same client over a persistent connection, or `Ably::PubSub::Server.create_http_client` when publish, history, presence reads, stats and token issuing over HTTP are enough. The HTTP client is synchronous and needs no EventMachine reactor.

### Migrating from the client constructors

Constructing `Ably::Rest::Client` or `Ably::Realtime::Client` directly — including through the `Ably::Rest.new` and `Ably::Realtime.new` shorthands — still works and is not scheduled for removal, but it emits a deprecation warning naming the factory for your side:

| Before | After |
|--------|-------|
| `Ably::Realtime.new(...)` on a device | `Ably::PubSub::Device.create_client(...)` |
| `Ably::Realtime.new(...)` on a server | `Ably::PubSub::Server.create_realtime_client(...)` |
| `Ably::Rest.new(...)` | `Ably::PubSub::Server.create_http_client(...)` |

The factories take the same options as the constructors they replace and behave identically to them, so migrating is a change of entry point only.

---

## Releases

The [CHANGELOG.md](./CHANGELOG.md) contains details of the latest releases for this SDK. You can also view all Ably releases on [changelog.ably.com](https://changelog.ably.com).

---

## Contributing

Read the [CONTRIBUTING.md](./CONTRIBUTING.md) guidelines to contribute to Ably.

---

## Support, feedback and troubleshooting

For help or technical support, visit Ably's [support page](https://ably.com/support). You can also view the [community reported Github issues](https://github.com/ably/ably-ruby/issues) or raise one yourself.

