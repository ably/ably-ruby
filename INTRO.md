# Ably `Ruby` Client Library SDK API Reference

> **Using the `ably` gem?** This is the API reference for the `ably-pubsub-server` gem, which replaces it.
> The API reference for the maintenance-only `ably` gem remains available at
> [sdk.ably.com/builds/ably/ably-ruby/main/docs](https://sdk.ably.com/builds/ably/ably-ruby/main/docs/)
> until its end of life.

The `Ruby` Client Library SDK supports a realtime and a REST interface.

The realtime interface enables a client to maintain a persistent connection to Ably and publish, subscribe and be present on channels.
The REST interface is stateless and typically implemented server-side. It is used to make requests such as retrieving statistics,
token authentication and publishing to a channel.

**Note**: The `Ruby` Client Library SDK implements the realtime and REST interfaces as two separate libraries.

The `Ruby` API references are generated from the [Ably `Ruby` Client Library SDK source code](https://github.com/ably/ably-pubsub-ruby)
using [`yard`](https://yardoc.org/). View the [Ably docs](http://ably.com/docs/) for conceptual information on using Ably
and for client library API references split between the [realtime](http://ably.com/docs/api/realtime-sdk)
and [REST](http://ably.com/docs/api/rest-sdk) interfaces.
