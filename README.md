# [Ably](https://ably.io)

[![Build Status](https://travis-ci.org/ably/ably-ruby.png)](https://travis-ci.org/ably/ably-ruby)
[![Gem Version](https://badge.fury.io/rb/ably.svg)](http://badge.fury.io/rb/ably)
[![Coverage Status](https://coveralls.io/repos/ably/ably-ruby/badge.svg)](https://coveralls.io/r/ably/ably-ruby)

A Ruby client library for [ably.io](https://ably.io), the real-time messaging service.

## Documentation

Visit https://ably.io/documentation for a complete API reference and more examples.

## Installation

The client library is available as a [gem from RubyGems.org](https://rubygems.org/gems/ably).

Add this line to your application's Gemfile:

    gem 'ably'

And then install this Bundler dependency:

    $ bundle

Or install it yourself as:

    $ gem install ably

## Using the Realtime API

### Introduction

All examples must be run within an [EventMachine](https://github.com/eventmachine/eventmachine) [reactor](https://github.com/eventmachine/eventmachine/wiki/General-Introduction) as follows:

```ruby
EventMachine.run do
  # ...
end
```

All examples assume a client has been created as follows:

```ruby
client = Ably::Realtime.new(key: 'xxxxx')
```

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

### Subscribing to a channel

Given:

```ruby
channel = client.channel('test')
```

Subscribe to all events:

```ruby
channel.subscribe do |message|
  message[:name] #=> "greeting"
  message[:data] #=> "Hello World!"
end
```

Only certain events:

```ruby
channel.subscribe('myEvent') do |message|
  message[:name] #=> "myEvent"
  message[:data] #=> "myData"
end
```

### Publishing to a channel

```ruby
channel.publish('greeting', 'Hello World!')
```

### Querying the History

```ruby
channel.history do |messages_page|
  messages_page #=> #<Ably::Models::PaginatedResource ...>
  messages_page.items.first # #<Ably::Models::Message ...>
  messages_page.items.first.data # payload for the message
  messages_page.items.length # number of messages in the current page of history
  messages_page.next # retrieves the next page => #<Ably::Models::PaginatedResource ...>
  messages_page.has_next? # false, there are more pages
end
```

### Presence on a channel

```ruby
channel.presence.enter(data: 'john.doe') do |presence|
  presence.get #=> [Array of members present]
end
```

### Querying the Presence History

```ruby
channel.presence.history do |presence_page|
  presence_page.items.first.action # Any of :enter, :update or :leave
  presence_page.items.first.client_id # client ID of member
  presence_page.items.first.data # optional data payload of member
  presence_page.next # retrieves the next page => #<Ably::Models::PaginatedResource ...>
end
```

## Using the REST API

### Introduction

Unlike the Realtime API, all calls are synchronous and are not run within an [EventMachine](https://github.com/eventmachine/eventmachine) [reactor](https://github.com/eventmachine/eventmachine/wiki/General-Introduction).

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
messages_page = channel.history #=> #<Ably::Models::PaginatedResource ...>
messages_page.items.first #=> #<Ably::Models::Message ...>
messages_page.items.first.data # payload for the message
messages_page.next # retrieves the next page => #<Ably::Models::PaginatedResource ...>
messages_page.has_next? # false, there are more pages
```

### Presence on a channel

```ruby
members_page = channel.presence.get # => #<Ably::Models::PaginatedResource ...>
members_page.items.first # first member present in this page => #<Ably::Models::PresenceMessage ...>
members_page.items.first.client_id # client ID of first member present
members_page.next # retrieves the next page => #<Ably::Models::PaginatedResource ...>
members_page.has_next? # false, there are more pages
```

### Querying the Presence History

```ruby
presence_page = channel.presence.history #=> #<Ably::Models::PaginatedResource ...>
presence_page.items.first #=> #<Ably::Models::PresenceMessage ...>
presence_page.items.first.client_id # client ID of first member
presence_page.next # retrieves the next page => #<Ably::Models::PaginatedResource ...>
```

### Generate Token and Token Request

```ruby
client.auth.request_token
# => #<Ably::Models::Token ...>

token = client.auth.create_token_request
# => {"id"=>...,
#     "clientId"=>nil,
#     "ttl"=>3600,
#     "timestamp"=>...,
#     "capability"=>"{\"*\":[\"*\"]}",
#     "nonce"=>...,
#     "mac"=>...}

client = Ably::Rest.new(token_id: token.id)
```

### Fetching your application's stats

```ruby
stats_page = client.stats #=> #<Ably::Models::PaginatedResource ...>
stats_page.items.first = #<Ably::Models::Stat ...>
stats_page.next # retrieves the next page => #<Ably::Models::PaginatedResource ...>
```

### Fetching the Ably service time

```ruby
client.time #=> 2013-12-12 14:23:34 +0000
```

## Dependencies

If you only need to use the REST features of this library and do not want EventMachine as a dependency, then you should use the [Ably Ruby REST gem](https://rubygems.org/gems/ably-rest).

## Support and feedback

Please visit https://support.ably.io/ for access to our knowledgebase and to ask for any assistance.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Ensure you have added suitable tests and the test suite is passing(`bundle exec rspec`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## License

Copyright (c) 2015 Ably, Licensed under an MIT license.  Refer to [LICENSE.txt](LICENSE.txt) for the license terms.
