# Change Log

## [v1.0.2](https://github.com/ably/ably-ruby/tree/v1.0.2)

[Full Changelog](https://github.com/ably/ably-ruby/compare/v1.0.1...v1.0.2)

**Fixed bugs:**

- Reconnect following disconnection is hitting a 403 error [\#117](https://github.com/ably/ably-ruby/issues/117)
- [Fallback hosts were used upon any disconnection as opposed to only when the primary host is unavailable](https://github.com/ably/ably-ruby/pull/120)

**Merged pull requests:**

- Fallback fixes [\#120](https://github.com/ably/ably-ruby/pull/120) ([mattheworiordan](https://github.com/mattheworiordan))

## [v1.0.1](https://github.com/ably/ably-ruby/tree/v1.0.1) (2017-05-11)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v1.0.0...v1.0.1)

## [v1.0.0](https://github.com/ably/ably-ruby/tree/v1.0.0) (2017-03-07)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.15...v1.0.0)

## [v0.8.15](https://github.com/ably/ably-ruby/tree/v0.8.15) (2017-03-07)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.14...v0.8.15)

**Implemented enhancements:**

- Fix HttpRequest & HttpRetry timeouts [\#110](https://github.com/ably/ably-ruby/issues/110)
- Logger should take blocks [\#107](https://github.com/ably/ably-ruby/issues/107)
- 0.9: Use separate internal/external listeners [\#106](https://github.com/ably/ably-ruby/issues/106)
- Add reuse library test [\#83](https://github.com/ably/ably-ruby/issues/83)
- 0.8 final spec check [\#71](https://github.com/ably/ably-ruby/issues/71)
- Use connection\#id not connection\#key to determine if connection has been resumed [\#62](https://github.com/ably/ably-ruby/issues/62)
- Channel Presence suspended state [\#41](https://github.com/ably/ably-ruby/issues/41)
- Attach / detach timeouts + protocol error handling for Channel [\#38](https://github.com/ably/ably-ruby/issues/38)
- Connection retry and timeout needs to be configurable [\#6](https://github.com/ably/ably-ruby/issues/6)

**Fixed bugs:**

- Subscribing to all connection state changes doesn't work [\#103](https://github.com/ably/ably-ruby/issues/103)
- Ensure DETACHED or DISCONNECTED with error is non-fatal [\#93](https://github.com/ably/ably-ruby/issues/93)
- Incorrect assumption for channel errors [\#91](https://github.com/ably/ably-ruby/issues/91)
- authCallback assumes a blocking callback, even in EM [\#89](https://github.com/ably/ably-ruby/issues/89)
- Token Reauth error codes [\#86](https://github.com/ably/ably-ruby/issues/86)
- Do not persist authorise attributes force & timestamp [\#72](https://github.com/ably/ably-ruby/issues/72)
- 0.8 final spec check [\#71](https://github.com/ably/ably-ruby/issues/71)
- Receiving CONNECTED when already connected [\#69](https://github.com/ably/ably-ruby/issues/69)
- Connection\#connect callback may not be called as expected [\#68](https://github.com/ably/ably-ruby/issues/68)
- nodename nor servname provided [\#65](https://github.com/ably/ably-ruby/issues/65)
- Channel Presence suspended state [\#41](https://github.com/ably/ably-ruby/issues/41)
- Intermittent test fixes [\#33](https://github.com/ably/ably-ruby/issues/33)

**Closed issues:**

- Remove deprecated ProtocolMessage\#connectionKey [\#108](https://github.com/ably/ably-ruby/issues/108)
- 0.9 Extras field [\#105](https://github.com/ably/ably-ruby/issues/105)
- 0.9 UPDATE spec [\#104](https://github.com/ably/ably-ruby/issues/104)
- Token issue bug [\#75](https://github.com/ably/ably-ruby/issues/75)
- Ensure client\_id provided is string or cast to string in Auth request\_token [\#74](https://github.com/ably/ably-ruby/issues/74)
- Standardise timeouts [\#64](https://github.com/ably/ably-ruby/issues/64)
- Ensure RSpec retry compatibility is used [\#54](https://github.com/ably/ably-ruby/issues/54)
- Spec validation [\#43](https://github.com/ably/ably-ruby/issues/43)

**Merged pull requests:**

- 1.0 release [\#111](https://github.com/ably/ably-ruby/pull/111) ([mattheworiordan](https://github.com/mattheworiordan))
- From encoded [\#101](https://github.com/ably/ably-ruby/pull/101) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.14](https://github.com/ably/ably-ruby/tree/v0.8.14) (2016-09-30)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.13...v0.8.14)

**Fixed bugs:**

- Several problems with fallback hosts [\#95](https://github.com/ably/ably-ruby/issues/95)

**Closed issues:**

- Catch common SSL error and show docs [\#96](https://github.com/ably/ably-ruby/issues/96)

**Merged pull requests:**

- Fallback host improvements [\#97](https://github.com/ably/ably-ruby/pull/97) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.13](https://github.com/ably/ably-ruby/tree/v0.8.13) (2016-09-29)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.12...v0.8.13)

**Merged pull requests:**

- Ensure interoperability with other libraries with JSON protocol [\#94](https://github.com/ably/ably-ruby/pull/94) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.12](https://github.com/ably/ably-ruby/tree/v0.8.12) (2016-05-23)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.11...v0.8.12)

**Fixed bugs:**

- Ably::Exceptions::ConnectionError: SSL\_connect returned=1 errno=0 state=SSLv3 read server certificate B: certificate verify failed [\#87](https://github.com/ably/ably-ruby/issues/87)

**Merged pull requests:**

- Reauthorise [\#90](https://github.com/ably/ably-ruby/pull/90) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.11](https://github.com/ably/ably-ruby/tree/v0.8.11) (2016-04-05)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.10...v0.8.11)

**Merged pull requests:**

- Ensure message emitter callbacks are safe \(i.e. cannot break the EM\) [\#85](https://github.com/ably/ably-ruby/pull/85) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.10](https://github.com/ably/ably-ruby/tree/v0.8.10) (2016-04-01)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.9...v0.8.10)

## [v0.8.9](https://github.com/ably/ably-ruby/tree/v0.8.9) (2016-03-01)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.8...v0.8.9)

**Fixed bugs:**

- Support enter\(data\) [\#79](https://github.com/ably/ably-ruby/issues/79)
- Update documentation to hide private API methods [\#77](https://github.com/ably/ably-ruby/issues/77)

**Closed issues:**

- New Crypto Spec [\#80](https://github.com/ably/ably-ruby/issues/80)

**Merged pull requests:**

- Various fixes for open issues [\#82](https://github.com/ably/ably-ruby/pull/82) ([mattheworiordan](https://github.com/mattheworiordan))
- Encryption spec update [\#81](https://github.com/ably/ably-ruby/pull/81) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.8](https://github.com/ably/ably-ruby/tree/v0.8.8) (2016-01-26)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.7...v0.8.8)

**Closed issues:**

- Support :key in ClientOptions and deprecate :api\_key [\#73](https://github.com/ably/ably-ruby/issues/73)

## [v0.8.7](https://github.com/ably/ably-ruby/tree/v0.8.7) (2015-12-31)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.6...v0.8.7)

## [v0.8.6](https://github.com/ably/ably-ruby/tree/v0.8.6) (2015-12-02)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.5...v0.8.6)

**Merged pull requests:**

- Some intermittent test fixes & enable tests that were blocked [\#70](https://github.com/ably/ably-ruby/pull/70) ([mattheworiordan](https://github.com/mattheworiordan))
- Output detailed log for any text failures [\#67](https://github.com/ably/ably-ruby/pull/67) ([mattheworiordan](https://github.com/mattheworiordan))
- 0.8 final spec \(98% compliance\) [\#66](https://github.com/ably/ably-ruby/pull/66) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.5](https://github.com/ably/ably-ruby/tree/v0.8.5) (2015-10-08)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.4...v0.8.5)

**Implemented enhancements:**

- Switch arity of auth methods [\#61](https://github.com/ably/ably-ruby/issues/61)

**Fixed bugs:**

- Switch arity of auth methods [\#61](https://github.com/ably/ably-ruby/issues/61)
- Add test: Message published, connection dropped, then restores to point before last message was published [\#56](https://github.com/ably/ably-ruby/issues/56)
- Documentation for constructor is incorrect [\#49](https://github.com/ably/ably-ruby/issues/49)

**Merged pull requests:**

- Ensure connections are always closed in tests [\#63](https://github.com/ably/ably-ruby/pull/63) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.4](https://github.com/ably/ably-ruby/tree/v0.8.4) (2015-09-08)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.3...v0.8.4)

**Implemented enhancements:**

- Add compatibility support for default Crypto params [\#53](https://github.com/ably/ably-ruby/issues/53)
- EventEmitter on connection [\#52](https://github.com/ably/ably-ruby/issues/52)
- Add test for connectionId attribute for a message sent over REST [\#50](https://github.com/ably/ably-ruby/issues/50)

**Merged pull requests:**

- Spec update to fix a number of issues [\#60](https://github.com/ably/ably-ruby/pull/60) ([mattheworiordan](https://github.com/mattheworiordan))
- Allow clientId to be provided on init if using externally created token [\#58](https://github.com/ably/ably-ruby/pull/58) ([SimonWoolf](https://github.com/SimonWoolf))

## [v0.8.3](https://github.com/ably/ably-ruby/tree/v0.8.3) (2015-08-19)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.2...v0.8.3)

**Implemented enhancements:**

- Implement :queue\_messages option [\#36](https://github.com/ably/ably-ruby/issues/36)
- Check that a non 200-299 status code for REST requests uses fallback hosts [\#35](https://github.com/ably/ably-ruby/issues/35)
- Move stats fixtures into ably-common [\#34](https://github.com/ably/ably-ruby/issues/34)
- Add tests for messages with no data or name fields [\#21](https://github.com/ably/ably-ruby/issues/21)
- Namespace MsgPack as MsgPack5 because compliance is not merged in [\#12](https://github.com/ably/ably-ruby/issues/12)
- Add test coverage for receiving messages more than once i.e. historical messages resent somehow on reconnect [\#11](https://github.com/ably/ably-ruby/issues/11)
- Add async methods for Authentication in the realtime library [\#8](https://github.com/ably/ably-ruby/issues/8)

**Fixed bugs:**

- Check that a non 200-299 status code for REST requests uses fallback hosts [\#35](https://github.com/ably/ably-ruby/issues/35)

**Closed issues:**

- Scope default token params in arguments [\#55](https://github.com/ably/ably-ruby/issues/55)
- Channel options can be reset when accessing a channel with \#get [\#46](https://github.com/ably/ably-ruby/issues/46)

**Merged pull requests:**

- Separate token params for auth [\#57](https://github.com/ably/ably-ruby/pull/57) ([mattheworiordan](https://github.com/mattheworiordan))
- Ensure files are required in a consistent order [\#51](https://github.com/ably/ably-ruby/pull/51) ([SimonWoolf](https://github.com/SimonWoolf))

## [v0.8.2](https://github.com/ably/ably-ruby/tree/v0.8.2) (2015-05-20)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.1...v0.8.2)

**Implemented enhancements:**

- Ensure Array object can be used in place of Hash for payload [\#44](https://github.com/ably/ably-ruby/issues/44)
- Change connect\_automatically option to auto\_connect for consistency [\#42](https://github.com/ably/ably-ruby/issues/42)
- Rename PaginatedResource to PaginatedResult for consistency [\#40](https://github.com/ably/ably-ruby/issues/40)
- EventEmitter should use `emit` not `trigger` to be consistent with other libs [\#31](https://github.com/ably/ably-ruby/issues/31)
- Add exceptions when data attribute for messages/presence is not String, Binary or JSON data [\#4](https://github.com/ably/ably-ruby/issues/4)
- Auth Callback and Auth URL should support tokens as well as token requests [\#2](https://github.com/ably/ably-ruby/issues/2)

**Closed issues:**

- Realtime Presence\#get does not wait by default [\#47](https://github.com/ably/ably-ruby/issues/47)
- No implicit attach when accessing channel.presence [\#45](https://github.com/ably/ably-ruby/issues/45)

**Merged pull requests:**

- Reject invalid payload type [\#48](https://github.com/ably/ably-ruby/pull/48) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.8.1](https://github.com/ably/ably-ruby/tree/v0.8.1) (2015-04-23)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.0...v0.8.1)

## [v0.8.0](https://github.com/ably/ably-ruby/tree/v0.8.0) (2015-04-23)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.7.6...v0.8.0)

**Merged pull requests:**

- Token naming refactor [\#29](https://github.com/ably/ably-ruby/pull/29) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.7.6](https://github.com/ably/ably-ruby/tree/v0.7.6) (2015-04-17)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.7.5...v0.7.6)

**Implemented enhancements:**

- Rename Stat to Stats for consistency [\#32](https://github.com/ably/ably-ruby/issues/32)
- Stats objects [\#24](https://github.com/ably/ably-ruby/issues/24)
- Need a test to handle errors in callbacks [\#13](https://github.com/ably/ably-ruby/issues/13)
- Allow token ID or API key in the client constructor [\#5](https://github.com/ably/ably-ruby/issues/5)
- Typed stats similar to Java library + zero default for empty stats [\#25](https://github.com/ably/ably-ruby/pull/25) ([mattheworiordan](https://github.com/mattheworiordan))

**Fixed bugs:**

- Need a test to handle errors in callbacks [\#13](https://github.com/ably/ably-ruby/issues/13)

**Closed issues:**

- New ttl format [\#15](https://github.com/ably/ably-ruby/issues/15)

**Merged pull requests:**

- Test encoded presence fixture data for \#get & \#history [\#28](https://github.com/ably/ably-ruby/pull/28) ([mattheworiordan](https://github.com/mattheworiordan))
- Add coveralls.io coverage reporting [\#27](https://github.com/ably/ably-ruby/pull/27) ([mattheworiordan](https://github.com/mattheworiordan))
- New paginated resource [\#26](https://github.com/ably/ably-ruby/pull/26) ([mattheworiordan](https://github.com/mattheworiordan))
- History since attach [\#22](https://github.com/ably/ably-ruby/pull/22) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.7.5](https://github.com/ably/ably-ruby/tree/v0.7.5) (2015-03-21)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.7.4...v0.7.5)

## [v0.7.4](https://github.com/ably/ably-ruby/tree/v0.7.4) (2015-03-21)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.7.2...v0.7.4)

**Merged pull requests:**

- Presence Member Map [\#14](https://github.com/ably/ably-ruby/pull/14) ([mattheworiordan](https://github.com/mattheworiordan))

## [v0.7.2](https://github.com/ably/ably-ruby/tree/v0.7.2) (2015-02-10)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.7.1...v0.7.2)

**Implemented enhancements:**

- Use PresenceMap for presence instead of queues [\#10](https://github.com/ably/ably-ruby/issues/10)

**Merged pull requests:**

- Update README to include various missing snippets for core features [\#9](https://github.com/ably/ably-ruby/pull/9) ([kouno](https://github.com/kouno))
- Fix connection retry frequency [\#7](https://github.com/ably/ably-ruby/pull/7) ([kouno](https://github.com/kouno))

## [v0.7.1](https://github.com/ably/ably-ruby/tree/v0.7.1) (2015-01-18)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.7.0...v0.7.1)

## [v0.7.0](https://github.com/ably/ably-ruby/tree/v0.7.0) (2015-01-12)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.6.2...v0.7.0)

**Closed issues:**

- JSON encoder should only append utf-8 before a cipher encoder is applied [\#1](https://github.com/ably/ably-ruby/issues/1)

## [v0.6.2](https://github.com/ably/ably-ruby/tree/v0.6.2) (2014-12-10)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.2.0...v0.6.2)

## [v0.2.0](https://github.com/ably/ably-ruby/tree/v0.2.0) (2014-12-09)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.6...v0.2.0)

## [v0.1.6](https://github.com/ably/ably-ruby/tree/v0.1.6) (2014-10-31)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.5...v0.1.6)

## [v0.1.5](https://github.com/ably/ably-ruby/tree/v0.1.5) (2014-10-23)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.4...v0.1.5)

## [v0.1.4](https://github.com/ably/ably-ruby/tree/v0.1.4) (2014-09-27)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.3...v0.1.4)

## [v0.1.3](https://github.com/ably/ably-ruby/tree/v0.1.3) (2014-09-26)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.2...v0.1.3)

## [v0.1.2](https://github.com/ably/ably-ruby/tree/v0.1.2) (2014-09-25)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.1...v0.1.2)

## [v0.1.1](https://github.com/ably/ably-ruby/tree/v0.1.1) (2014-09-23)
[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.1.0...v0.1.1)

## [v0.1.0](https://github.com/ably/ably-ruby/tree/v0.1.0) (2014-09-23)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
