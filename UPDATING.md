# Upgrade / Migration Guide

## Version 1.1.8 to 1.2.0

### Notable Changes
This release is all about channel options. Here is the full [changelog](https://github.com/ably/ably-ruby/blob/main/CHANGELOG.md)

* Channel options were extracted into a seperate model [ChannelOptions](https://github.com/ably/ably-ruby/blob/main/lib/ably/models/channel_options.rb). However it's still backward campatible with `Hash` and you don't need to do make any adjustments to your code

* The `ChannelOptions` class now supports `:params`, `:modes` and `:cipher` as options. Previously only `:cipher` was available

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
