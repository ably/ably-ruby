# Ably Pub/Sub Ruby SDK

![Ably Pub/Sub Ruby Header](images/rubySDK-github.png)
[![Gem Version](https://img.shields.io/gem/v/ably?style=flat)](https://rubygems.org/gems/ably)
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

- [Quickstart in Pub/Sub using Ruby.](https://ably.com/docs/getting-started/quickstart?lang=ruby)

This is a Ruby client library for Ably. The library currently targets the [Ably 2.0.0 client library specification](https://ably.com/documentation/client-lib-development-guide/features/). You can see the complete list of features this client library supports in [our client library SDKs feature support matrix](https://ably.com/download/sdk-feature-support-matrix).

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

## EventMachine

To use the Ably Realtime SDK in Ruby, the EventMachine reactor loop must be running. This is required because the Realtime library depends on EventMachine to handle asynchronous events.

Wrap your code inside an EventMachine.run block:

```ruby
require 'ably'

EventMachine.run do
  client = Ably::Realtime.new(key: 'your-api-key')

  client.connection.connect do
    puts "Connected with connection ID: #{client.connection.id}"
  end
```

---

## Releases

The [CHANGELOG.md](/ably/ably-ruby/blob/main/CONTRIBUTING.md) contains details of the latest releases for this SDK. You can also view all Ably releases on [changelog.ably.com](https://changelog.ably.com).

---

## Contributing

Read the [CONTRIBUTING.md](./CONTRIBUTING.md) guidelines to contribute to Ably.

---

## Support, feedback and troubleshooting

For help or technical support, visit Ably's [support page](https://ably.com/support). You can also view the [community reported Github issues](https://github.com/ably/ably-ruby/issues) or raise one yourself.

