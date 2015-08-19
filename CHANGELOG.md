# Change Log

## [Unreleased](https://github.com/ably/ably-ruby/tree/HEAD)

[Full Changelog](https://github.com/ably/ably-ruby/compare/v0.8.2...HEAD)

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

**Fixed bugs:**

- Need a test to handle errors in callbacks [\#13](https://github.com/ably/ably-ruby/issues/13)

**Closed issues:**

- New ttl format [\#15](https://github.com/ably/ably-ruby/issues/15)

**Merged pull requests:**

- Test encoded presence fixture data for \#get & \#history [\#28](https://github.com/ably/ably-ruby/pull/28) ([mattheworiordan](https://github.com/mattheworiordan))

- Add coveralls.io coverage reporting [\#27](https://github.com/ably/ably-ruby/pull/27) ([mattheworiordan](https://github.com/mattheworiordan))

- New paginated resource [\#26](https://github.com/ably/ably-ruby/pull/26) ([mattheworiordan](https://github.com/mattheworiordan))

- Typed stats similar to Java library + zero default for empty stats [\#25](https://github.com/ably/ably-ruby/pull/25) ([mattheworiordan](https://github.com/mattheworiordan))

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