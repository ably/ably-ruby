# [Ably](https://ably.com)

[![Features](https://github.com/ably/ably-ruby/actions/workflows/features.yml/badge.svg)](https://github.com/ably/ably-ruby/actions/workflows/features.yml)

[![Gem Version](https://img.shields.io/gem/v/ably?style=flat)](https://img.shields.io/gem/v/ably?style=flat)
[![Coverage Status](https://coveralls.io/repos/ably/ably-ruby/badge.svg)](https://coveralls.io/r/ably/ably-ruby)

_[Ably](https://ably.com) is the platform that powers synchronized digital experiences in realtime. Whether attending an event in a virtual venue, receiving realtime financial information, or monitoring live car performance data – consumers simply expect realtime digital experiences as standard. Ably provides a suite of APIs to build, extend, and deliver powerful digital experiences in realtime for more than 250 million devices across 80 countries each month. Organizations like Bloomberg, HubSpot, Verizon, and Hopin depend on Ably’s platform to offload the growing complexity of business-critical realtime data synchronization at global scale. For more information, see the [Ably documentation](https://ably.com/documentation)._

This is a Ruby client library for Ably. The library currently targets the [Ably 2.0.0 client library specification](https://ably.com/documentation/client-lib-development-guide/features/). You can see the complete list of features this client library supports in [our client library SDKs feature support matrix](https://ably.com/download/sdk-feature-support-matrix).

## Supported platforms

This SDK supports Ruby 2.7 and 3.x. For eventmachine and Ruby 3.x note please visit [Ruby 3.0 support](#ruby-30-support) section.

As of v1.1.5 this library requires `libcurl` as a system dependency. On most systems this is already installed but in rare cases where it isn't (for example debian-slim Docker images such as ruby-slim) you will need to install it yourself. On debian you can install it with the command `sudo apt-get install libcurl4`.

We regression-test the SDK against a selection of Ruby versions (which we update over time, but usually consists of mainstream and widely used versions). Please refer to [.github/workflows/check.yml](./.github/workflows/check.yml) for the set of versions that currently undergo CI testing.

If you find any compatibility issues, please [do raise an issue](https://github.com/ably/ably-ruby/issues/new) in this repository or [contact Ably customer support](https://ably.com/support/) for advice.

## Documentation

Visit https://ably.com/documentation for a complete API reference and code examples.

## Installation

The client library is available as a [gem from RubyGems.org](https://rubygems.org/gems/ably).

Add this line to your application's Gemfile:

    gem 'ably'

And then install this Bundler dependency:

    $ bundle

Or install it yourself as:

    $ gem install ably

### Using with Rails or Sinatra

This `ably` gem provides both a [Realtime](https://ably.com/documentation/realtime/usage) and [REST](https://ably.com/documentation/rest/usage) version of the Ably library. Realtime depends on EventMachine to provide an asynchronous evented framework to run the library in, whereas the REST library depends only on synchronous libraries such as Faraday.

If you are using Ably within your Rails or Sinatra apps, more often than not, you probably want to use the REST only version of the library that has no dependency on EventMachine and provides a synchronous API that you will be used to using within Rails and Sinatra. [See the REST only Ruby version of the Ably library](https://github.com/ably/ably-ruby-rest).

## Using the Realtime API

### Introduction

All examples must be run within an [EventMachine](https://github.com/eventmachine/eventmachine) [reactor](https://github.com/eventmachine/eventmachine/wiki/General-Introduction) as follows:

```ruby
EventMachine.run do
  # ...
end
```

All examples assume a client has been created using one of the following:

```ruby
# basic auth with an API key
client = Ably::Realtime.new(key: 'xxxxx')

# using token auth
client = Ably::Realtime.new(token: 'xxxxx')
```

If you do not have an API key, [sign up for a free API key now](https://ably.com/signup)

### Connection

Successful connection:

```ruby
client.connection.connect do
  # successful connection
end
```

Failed connection:

```ruby
connection_result = client.connection.connect
connection_result.errback = Proc.new do
  # failed connection
end
```

Subscribing to connection state changes:

```ruby
client.connection.on do |state_change|
  state_change.current #=> :connected
  state_change.previous #=> :connecting
end
```

### Subscribing to a channel

Given a channel is created as follows:

```ruby
channel = client.channels.get('test')
```

Subscribe to all events:

```ruby
channel.subscribe do |message|
  message.name #=> "greeting"
  message.data #=> "Hello World!"
end
```

Only certain events:

```ruby
channel.subscribe('myEvent') do |message|
  message.name #=> "myEvent"
  message.data #=> "myData"
end
```

### Publishing a message to a channel

```ruby
channel.publish('greeting', 'Hello World!')
```

### Querying the History

```ruby
channel.history do |messages_page|
  messages_page #=> #<Ably::Models::PaginatedResult ...>
  messages_page.items.first # #<Ably::Models::Message ...>
  messages_page.items.first.data # payload for the message
  messages_page.items.length # number of messages in the current page of history
  messages_page.next do |next_page|
    next_page #=> the next page => #<Ably::Models::PaginatedResult ...>
  end
  messages_page.has_next? # false, there are more pages
end
```

### Presence on a channel

```ruby
channel.presence.enter(data: 'metadata') do |presence|
  presence.get do |members|
    members #=> [Array of members present]
  end
end
```

### Subscribing to presence events

```ruby
channel.presence.subscribe do |member|
  member #=> { action: :enter, client_id: 'bob' }
end
```

### Querying the Presence History

```ruby
channel.presence.history do |presence_page|
  presence_page.items.first.action # Any of :enter, :update or :leave
  presence_page.items.first.client_id # client ID of member
  presence_page.items.first.data # optional data payload of member
  presence_page.next do |next_page|
    next_page #=> the next page => #<Ably::Models::PaginatedResult ...>
  end
  presence_page.has_next? # false, there are more pages
end
```

### Symmetric end-to-end encrypted payloads on a channel

When a 128 bit or 256 bit key is provided to the library, all payloads are encrypted and decrypted automatically using that key on the channel. The secret key is never transmitted to Ably and thus it is the developer's responsibility to distribute a secret key to both publishers and subscribers.

```ruby
secret_key = Ably::Util::Crypto.generate_random_key
channel = client.channels.get('test', cipher: { key: secret_key })
channel.subscribe do |message|
  message.data #=> "sensitive data (encrypted before being published)"
end
channel.publish "name (not encrypted)", "sensitive data (encrypted before being published)"
```

## Using the REST API

### Introduction

Unlike the Realtime API, all calls are synchronous and are not run within [EventMachine](https://github.com/eventmachine/eventmachine).

All examples assume a client and/or channel has been created as follows:

```ruby
client = Ably::Rest.new(key: 'xxxxx')
channel = client.channel('test')
```

### Publishing a message to a channel

```ruby
channel.publish('myEvent', 'Hello!') #=> true
```

### Querying the History

```ruby
messages_page = channel.history #=> #<Ably::Models::PaginatedResult ...>
messages_page.items.first #=> #<Ably::Models::Message ...>
messages_page.items.first.data # payload for the message
messages_page.next # retrieves the next page => #<Ably::Models::PaginatedResult ...>
messages_page.has_next? # false, there are more pages
```

### Current presence members on a channel

```ruby
members_page = channel.presence.get # => #<Ably::Models::PaginatedResult ...>
members_page.items.first # first member present in this page => #<Ably::Models::PresenceMessage ...>
members_page.items.first.client_id # client ID of first member present
members_page.next # retrieves the next page => #<Ably::Models::PaginatedResult ...>
members_page.has_next? # false, there are more pages
```

### Querying the presence history

```ruby
presence_page = channel.presence.history #=> #<Ably::Models::PaginatedResult ...>
presence_page.items.first #=> #<Ably::Models::PresenceMessage ...>
presence_page.items.first.client_id # client ID of first member
presence_page.next # retrieves the next page => #<Ably::Models::PaginatedResult ...>
```

### Symmetric end-to-end encrypted payloads on a channel

When a 128 bit or 256 bit key is provided to the library, all payloads are encrypted and decrypted automatically using that key on the channel. The secret key is never transmitted to Ably and thus it is the developer's responsibility to distribute a secret key to both publishers and subscribers.

```ruby
secret_key = Ably::Util::Crypto.generate_random_key
channel = client.channels.get('test', cipher: { key: secret_key })
channel.publish nil, "sensitive data" # data will be encrypted before publish
messages_page = channel.history
messages_page.items.first.data #=> "sensitive data"
```

### Generate a Token

Tokens are issued by Ably and are readily usable by any client to connect to Ably:

```ruby
token_details = client.auth.request_token
# => #<Ably::Models::TokenDetails ...>
token_details.token # => "xVLyHw.CLchevH3hF....MDh9ZC_Q"
client = Ably::Rest.new(token: token_details)
```

### Generate a TokenRequest

Token requests are issued by your servers and signed using your private API key. This is the preferred method of authentication as no secrets are ever shared, and the token request can be issued to trusted clients without communicating with Ably.

```ruby
token_request = client.auth.create_token_request(ttl: 3600, client_id: 'jim')
# => {"id"=>...,
#     "clientId"=>"jim",
#     "ttl"=>3600,
#     "timestamp"=>...,
#     "capability"=>"{\"*\":[\"*\"]}",
#     "nonce"=>...,
#     "mac"=>...}

client = Ably::Rest.new(token: token_request)
```

### Fetching your application's stats

```ruby
stats_page = client.stats #=> #<Ably::Models::PaginatedResult ...>
stats_page.items.first = #<Ably::Models::Stats ...>
stats_page.next # retrieves the next page => #<Ably::Models::PaginatedResult ...>
```

### Fetching the Ably service time

```ruby
client.time #=> 2013-12-12 14:23:34 +0000
```

## Ruby 3.0 support

If you cannot install ably realtime gem because of eventmachine openssl problems, please try to set your `openssl-dir`, i.e.:

```ruby
gem install eventmachine -- --with-openssl-dir=/usr/local/opt/openssl@1.1
```

More about eventmachine and ruby 3.0 support here https://github.com/eventmachine/eventmachine/issues/932

## Dependencies

If you only need to use the REST features of this library and do not want EventMachine as a dependency, then you should consider using the [Ably Ruby REST gem](https://rubygems.org/gems/ably-rest).

## Upgrading from an older version

- [Release and upgrade notes for v0.8 -> v1.0](https://github.com/ably/docs/issues/235)

## Support, feedback and troubleshooting

Please visit https://ably.com/support for access to our knowledgebase and to ask for any assistance.

You can also view the [community reported Github issues](https://github.com/ably/ably-ruby/issues).

To see what has changed in recent versions of Bundler, see the [CHANGELOG](CHANGELOG.md).

## Contributing

1. Fork it
2. When pulling to local, make sure to also pull the `ably-common` repo (`git submodule init && git submodule update`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Ensure you have added suitable tests and the test suite is passing(`bundle exec rspec`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## Release process

This library uses [semantic versioning](http://semver.org/). For each release, the following needs to be done:

* Update the version number in [version.rb](./lib/ably/version.rb) and commit the change.
* Run [`github_changelog_generator`](https://github.com/skywinder/Github-Changelog-Generator) to automate the update of the [CHANGELOG](./CHANGELOG.md). Once the `CHANGELOG` update has completed, manually change the `Unreleased` heading and link with the current version number such as `v1.0.0`. Also ensure that the `Full Changelog` link points to the new version tag instead of the `HEAD`. Ideally, run `rake doc:spec` to generate a new [spec file](./SPEC.md). Then commit these changes.
* Add a tag and push to origin such as `git tag v1.0.0 && git push origin v1.0.0`
* Visit [https://github.com/ably/ably-ruby/tags](https://github.com/ably/ably-ruby/tags) and `Add release notes` for the release including links to the changelog entry.
* Run `rake release` to publish the gem to [Rubygems](https://rubygems.org/gems/ably)
* Release the [REST-only library `ably-ruby-rest`](https://github.com/ably/ably-ruby-rest#release-process)
