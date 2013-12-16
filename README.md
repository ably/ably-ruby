# Ably

A Ruby client library for [ably.io](https://ably.io), the real-time messaging service.

## Installation

Add this line to your application's Gemfile:

    gem 'ably'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ably

## Using the Realtime API

### Subscribing to a channel

Given:

```
client = Ably::Realtime::Client.new(api_key: "xxxxx")

channel = client.channel("test")
```

Subscribe to all events:

```
channel.subscribe do |message|
  message[:name] #=> "greeting"
  message[:data] #=> "Hello World!"
end
```

Only certain events:

```
channel.subscribe("myEvent") do |message|
  message[:name] #=> "myEvent"
  message[:data] #=> "myData"
end
```

### Publishing to a channel

```
client = Ably::Realtime::Client.new(api_key: "xxxxx")

channel = client.channel("test")

channel.publish("greeting", "Hello World!")
```

## Using the REST API

### Publishing a message to a channel

```
client = Ably::Rest::Client.new(api_key: "xxxxx")

channel = client.channel("test")

channel.publish("myEvent", "Hello!") #=> true
```

### Fetching a channel's history

```
client = Ably::Rest::Client.new(api_key: "xxxxx")

channel = client.channel("test")

channel.history #=> [{:name=>"test", :data=>"payload"}]
```

### Fetching your application's stats

```
client = Ably::Rest::Client.new(api_key: "xxxxx")

client.stats #=> [{:channels=>..., :apiRequests=>..., ...}]
```

### Fetching the Ably service time

```
client = Ably::Rest::Client.new(api_key: "xxxxx")

client.time #=> 2013-12-12 14:23:34 +0000
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
