# [Ably](https://ably.io)

[![Build Status](https://travis-ci.org/ably/ably-ruby.png)](https://travis-ci.org/ably/ably-ruby)
[![Gem Version](https://badge.fury.io/rb/ably.svg)](http://badge.fury.io/rb/ably)

A Ruby client library for [ably.io](https://ably.io), the real-time messaging service.

## Installation

The client library is available as a [gem from RubyGems.org](https://rubygems.org/gems/ably).

Add this line to your application's Gemfile:

    gem 'ably'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ably

## Using the Realtime API

### Introduction

Before using any of the examples below, you'll need to encapsulate them within an event machine run block:

```ruby
EventMachine.run do
  # ...
end
```

Also we will admit that the client library has been instanciated as follow:

```ruby
client = Ably::Realtime.new(api_key: "xxxxx")
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
channel = client.channel("test")
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
channel.subscribe("myEvent") do |message|
  message[:name] #=> "myEvent"
  message[:data] #=> "myData"
end
```

### Publishing to a channel

```ruby
channel.publish("greeting", "Hello World!")
```

### Querying the History

```ruby
channel.history do |messages|
  messages # Ably::Models::PaginatedResource
  messages.first # Ably::Models::Message
  messages.length # messages in history length
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
channel.presence.history do |presences|
  presences.first.action # Any of :enter, :update or :leave
  presences.first.client_id
  presences.first.data
end
```

## Using the REST API

### Introduction

Unlike the Realtime API, all calls are synchronous and therefore don't need to
be encapsulated within EventMachine.

We will admit that the client library has been instanciated as follow:

```ruby
client = Ably::Rest.new(api_key: "xxxxx")
channel = client.channel('test')
```

### Publishing a message to a channel

```ruby
channel.publish("myEvent", "Hello!") #=> true
```

### Querying the History

```ruby
channel.history #=> # => #<Ably::Models::PaginatedResource ...>
```

### Presence on a channel

```ruby
channel.presence.get # => #<Ably::Models::PaginatedResource ...>
```

### Querying the Presence History

```ruby
channel.presence.history # => #<Ably::Models::PaginatedResource ...>
```

### Generate Token and Token Request

```ruby
client.auth.request_token
# => #<Ably::Models::Token ...>

client.auth.create_token_request
# => {"id"=>...,
#     "clientId"=>nil,
#     "ttl"=>3600,
#     "timestamp"=>...,
#     "capability"=>"{\"*\":[\"*\"]}",
#     "nonce"=>...,
#     "mac"=>...}
```

### Fetching your application's stats

```ruby
client.stats #=> PaginatedResource [{:channels=>..., :apiRequests=>..., ...}]
```

## Dependencies

If you only need to use the REST features of this library and do not want EventMachine as a dependency, then you should use the [Ably Ruby REST gem](https://rubygems.org/gems/ably-rest).

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
