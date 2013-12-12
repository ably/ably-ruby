# Ably

A Ruby client library for [ably.io](https://ably.io), the real-time messaging service.

## Installation

Add this line to your application's Gemfile:

    gem 'ably'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install ably

## Usage

### Publishing a message to a channel

```
client = Ably::Rest::Client.new(api_key: "xxxxx")

channel = client.channel("test")

channel.publish("Hello!") #=> true
```

### Fetching a channel's history

```
client = Ably::Rest::Client.new(api_key: "xxxxx")

channel = client.channel("test")

channel.history #=> [{:name=>"test", :data=>"payload"}]
```

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
