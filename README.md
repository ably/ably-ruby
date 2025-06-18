# Ably Pub/Sub Ruby SDK

![Ably Pub/Sub Ruby Header](images/rubySDK-github.png)
[![Gem Version](https://img.shields.io/gem/v/ably?style=flat)](https://rubygems.org/gems/ably)
[![License](https://badgen.net/github/license/ably/ably-ruby)](https://github.com/ably/ably-ruby/blob/main/LICENSE)

---

Build any realtime experience using Ably’s Pub/Sub Ruby SDK, Supported on all popular platforms and frameworks.

Ably Pub/Sub provides flexible APIs that deliver features such as pub-sub messaging, message history, presence, and push notifications. Utilizing Ably’s realtime messaging platform, applications benefit from its highly performant, reliable, and scalable infrastructure.

Find out more:

* [Ably Pub/Sub docs.](https://ably.com/docs/basics)
* [Ably Pub/Sub examples.](https://ably.com/examples?product=pubsub)

---

## Getting started

Everything you need to get started with Ably:

- [Quickstart in Pub/Sub using Ruby](https://ably.com/docs/getting-started/quickstart?lang=ruby)

This is a Ruby client library for Ably. The library currently targets the [Ably 2.0.0 client library specification](https://ably.com/documentation/client-lib-development-guide/features/). You can see the complete list of features this client library supports in [our client library SDKs feature support matrix](https://ably.com/download/sdk-feature-support-matrix).

---

## Supported platforms

Ably aims to support a wide range of platforms and browsers. If you experience any compatibility issues, open an issue in the repository or contact [Ably support](https://ably.com/support).

| Platform       | Support |
|----------------|---------|
| Ruby           | >= 2.7 and 3.x. For EventMachine compatibility with Ruby 3.x |
| EventMachine   | Required for using the Realtime API. Compatible with Ruby 3.x with OpenSSL configuration. |
| libcurl        | Required since v1.1.5. On Debian-based systems, install via `sudo apt-get install libcurl4`. |

> [!IMPORTANT]
> SDK versions < 1.2.5 will be [deprecated](https://ably.com/docs/platform/deprecate/protocol-v1) from November 1, 2025.

---

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

1. Create a branch for the release, named like `release/1.2.3` (where `1.2.3` is the new version number)
2. Update the version number in [version.rb](./lib/ably/version.rb) and commit the change.
3. Run [`github_changelog_generator`](https://github.com/github-changelog-generator/github-changelog-generator) to automate the update of the [CHANGELOG](./CHANGELOG.md). This may require some manual intervention, both in terms of how the command is run and how the change log file is modified. Your mileage may vary:
   - The command you will need to run will look something like this: `github_changelog_generator -u ably -p ably-ruby --since-tag v1.2.3 --output delta.md --token $GITHUB_TOKEN_WITH_REPO_ACCESS`. Generate token [here](https://github.com/settings/tokens/new?description=GitHub%20Changelog%20Generator%20token).
   - Using the command above, `--output delta.md` writes changes made after `--since-tag` to a new file
   - The contents of that new file (`delta.md`) then need to be manually inserted at the top of the `CHANGELOG.md`, changing the "Unreleased" heading and linking with the current version numbers
   - Also ensure that the "Full Changelog" link points to the new version tag instead of the `HEAD`
4. Commit this change: `git add CHANGELOG.md && git commit -m "Update change log."`
5. Ideally, run `rake doc:spec` to generate a new [spec file](./SPEC.md). Then commit these changes.
6. Make a PR against `main`. Once the PR is approved, merge it into `main`.
7. Add a tag to the new `main` head commit and push to origin such as `git tag v1.0.3 && git push origin v1.0.3`.
8. Visit [https://github.com/ably/ably-ruby/tags](https://github.com/ably/ably-ruby/tags) and `Add release notes` for the release including links to the changelog entry.
9. Run `rake release` to publish the gem to [Rubygems](https://rubygems.org/gems/ably).
10. Release the [REST-only library `ably-ruby-rest`](https://github.com/ably/ably-ruby-rest#release-process).
11. Create the entry on the [Ably Changelog](https://changelog.ably.com/) (via [headwayapp](https://headwayapp.co/)).
