# [Ably](https://ably.io)

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

### Subscribing to a channel

Given:

```ruby
client = Ably::Realtime.new(api_key: "xxxxx")
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
client = Ably::Realtime.new(api_key: "xxxxx")
channel = client.channel("test")
channel.publish("greeting", "Hello World!")
```

### Presence on a channel

```ruby
client = Ably::Realtime.new(api_key: "xxxxx")
channel = client.channel("test")
channel.presence.enter(client_data: 'john.doe') do |presence|
  presence.get #=> [Array of members present]
end
```

## Using the REST API

### Publishing a message to a channel

```ruby
client = Ably::Rest.new(api_key: "xxxxx")
channel = client.channel("test")
channel.publish("myEvent", "Hello!") #=> true
```

### Fetching a channel's history

```ruby
client = Ably::Rest.new(api_key: "xxxxx")
channel = client.channel("test")
channel.history #=> [{:name=>"test", :data=>"payload"}]
```

### Authentication with a token

```ruby
client = Ably::Rest.new(api_key: "xxxxx")
client.auth.authorise # creates a token and will use token authentication moving forwards
client.auth.current_token #=> #<Ably::Models::Token>
channel.publish("myEvent", "Hello!") #=> true, sent using token authentication
```

### Fetching your application's stats

```ruby
client = Ably::Rest.new(api_key: "xxxxx")
client.stats #=> [{:channels=>..., :apiRequests=>..., ...}]
```

### Fetching the Ably service time

```ruby
client = Ably::Rest.new(api_key: "xxxxx")
client.time #=> 2013-12-12 14:23:34 +0000
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
