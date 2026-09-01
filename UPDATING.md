# Upgrade / Migration Guide

## Version 1.x (`ably` gem) to 2.0.0 (`ably-pubsub-server` gem)

> **Status: draft.** The final public API naming is still under review; this section will be finalized before the 2.0.0 GA release.

Version 2.0.0 splits the SDK into new packages. The `ably` gem is superseded: it receives security and critical-bug fixes only for one year from the 2.0.0 release date, and is then end-of-life. Under MAU-based pricing the platform must classify every connection as device- or server-side; the new packages declare this automatically, while the old constructors cannot — once MAU pricing is live, they raise on MAU-enabled accounts.

Ruby is a server-side SDK, so there is a single new public gem, `ably-pubsub-server`, whose factory functions are the only recommended entry points. (It is built on `ably-pubsub-core`, an internal gem you should never depend on directly.) The objects the factories return are the same clients as today — channels, presence, history, auth and error handling are unchanged. For most applications the migration is confined to the Gemfile, the `require`, and the constructor call.

### Mapping

| 1.x (`ably`) | 2.0 (`ably-pubsub-server`) |
| --- | --- |
| `gem 'ably'` | `gem 'ably-pubsub-server'` |
| `gem 'ably-rest'` (from `ably-ruby-rest`) | `gem 'ably-pubsub-server'` |
| `require 'ably'` | `require 'ably/pubsub/server'` |
| `Ably::Rest::Client.new(options)` | `Ably::PubSub::Server.create_http_client(options)` |
| `Ably::Realtime::Client.new(options)` | `Ably::PubSub::Server.create_realtime_client(options)` |

### Example

```ruby
# 1.x
require 'ably'
client = Ably::Rest::Client.new(key: ENV['ABLY_API_KEY'])

# 2.0
require 'ably/pubsub/server'
client = Ably::PubSub::Server.create_http_client(key: ENV['ABLY_API_KEY'])
```

Both factories accept everything the old constructors accepted: an options `Hash`, an API key `String`, or a token `String`.

## Version 1.1.8 to 1.2.0

### Notable Changes
This release is all about channel options. Here is the full [changelog](https://github.com/ably/ably-ruby/blob/main/CHANGELOG.md)

* Channel options were extracted into a seperate model [ChannelOptions](https://github.com/ably/ably-ruby/blob/main/lib/ably/models/channel_options.rb). However it's still backward campatible with `Hash` and you don't need to do make any adjustments to your code

* The `ChannelOptions` class now supports `:params`, `:modes` and `:cipher` as options. Previously only `:cipher` was available

* The client `:idempotent_rest_publishing` option is `true` by default. Previously `:idempotent_rest_publishing` was `false` by default.

### Breaking Changes

* Changing channel options with `Channels#get` is now deprecated in favor of explicit options change

  1. If channel state is attached or attaching an exception will be raised
  2. Otherwise the library will emit a warning

For example, the following code
```
  client.channels.get(channel_name, new_channel_options)
```

Should be changed to:
```
  channel = client.channels.get(channel_name)
  channel.options = new_channel_options
```
