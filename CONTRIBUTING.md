# Contributing

1. Fork it
2. When pulling to local, make sure to also pull the `ably-common` repo (`git submodule init && git submodule update`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Ensure you have added suitable tests and the test suite is passing(`bundle exec rspec`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

---

## Repository layout

This repository builds three gems, released together on the same version. They all install into the one `Ably` namespace, so what you require never tells you which gem shipped it:

| Gem | Source | Required as | Role |
|-----|--------|-------------|------|
| `ably` | [`lib/`](./lib) | `ably` | The shared core, containing all of the implementation |
| `ably-pubsub-server` | [`packages/ably-pubsub-server/`](./packages/ably-pubsub-server) | `ably/pubsub/server` | The server-side factories |
| `ably-pubsub-device` | [`packages/ably-pubsub-device/`](./packages/ably-pubsub-device) | `ably/pubsub/device` | The device-side factory |

Each side adds factories that return the core's clients unchanged, so that the gem a caller installs names the side their application runs on. They pin the core exactly, and requiring either makes the whole `Ably` namespace available.

Two rules keep that arrangement working, and both are covered by [`spec/unit/pubsub/packaging_spec.rb`](./spec/unit/pubsub/packaging_spec.rb):

- **Neither Pub/Sub gem may define `lib/ably/pubsub.rb`.** Both would have to ship it, and whichever came first on the load path would be the one required, hiding the other's. `Ably::PubSub` is opened by each side's own entry point instead.
- **Each Pub/Sub gem ships only its own subtree**, and the core gem ships none of `packages/`, so that no file is shipped by two gems.

The [`Gemfile`](./Gemfile) points at both Pub/Sub gems by path, so `bundle exec rspec` exercises them against the core in this checkout rather than a published version of it. Their specs are in [`spec/unit/pubsub/`](./spec/unit/pubsub) and need no network.

To build all three gems into `pkg/`:

```shell
bundle exec rake build packages:build
```

A gemspec's file list is relative to the working directory, so each Pub/Sub gem is built from its own directory — which `rake packages:build` takes care of.

---

## Release process

This library uses [semantic versioning](http://semver.org/). For each release, the following needs to be done:

`ably`, `ably-pubsub-server` and `ably-pubsub-device` are released in lockstep on the same version, because the Pub/Sub gems pin the core exactly — a partial release is an unusable one.

1. Create a branch for the release, named like `release/1.2.3` (where `1.2.3` is the new version number)
2. Update the version number in all three of [`lib/ably/version.rb`](./lib/ably/version.rb), [`packages/ably-pubsub-server/lib/ably/pubsub/server/version.rb`](./packages/ably-pubsub-server/lib/ably/pubsub/server/version.rb) and [`packages/ably-pubsub-device/lib/ably/pubsub/device/version.rb`](./packages/ably-pubsub-device/lib/ably/pubsub/device/version.rb), and commit the change. The specs in [`spec/unit/pubsub/packaging_spec.rb`](./spec/unit/pubsub/packaging_spec.rb) fail if any of these drift apart, so run them before moving on.
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
9. Run `rake release` to publish the core gem to [Rubygems](https://rubygems.org/gems/ably), then `rake packages:release` to publish [`ably-pubsub-server`](https://rubygems.org/gems/ably-pubsub-server) and [`ably-pubsub-device`](https://rubygems.org/gems/ably-pubsub-device). The Pub/Sub gems pin the core exactly, so publish them in that order — the core first, or their dependency cannot be resolved.
10. Release the [REST-only library `ably-ruby-rest`](https://github.com/ably/ably-ruby-rest#release-process).
11. Create the entry on the [Ably Changelog](https://changelog.ably.com/) (via [headwayapp](https://headwayapp.co/)).
