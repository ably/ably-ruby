# Contributing

This repository hosts two gems, released in lockstep at the same version:

- [`core/`](./core) — `ably-pubsub-core`: the shared implementation. An internal package; only Ably packages depend on it.
- [`server/`](./server) — `ably-pubsub-server`: the public server-side package. Its factory functions (`Ably::PubSub::Server.create_http_client` / `.create_realtime_client`) are the only recommended entry points.

## Development

1. Fork it
2. When pulling to local, make sure to also pull the `ably-common` repo (`git submodule init && git submodule update`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Ensure you have added suitable tests and the test suite is passing (`bundle exec rspec`) — the root `Gemfile` wires both gems up as path dependencies, so a single `bundle install` at the root covers everything
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

## Release process

This library uses [semantic versioning](http://semver.org/). `ably-pubsub-core` and `ably-pubsub-server` always release together at the same version: the release workflow refuses to publish them independently.

For each release, the following needs to be done:

1. Create a branch for the release, named like `release/2.0.1` (where `2.0.1` is the new version number)
2. Update the version number in **all three places**, which must agree (the release workflow's pre-flight enforces this):
   - `Ably::VERSION` in [core/lib/ably/version.rb](./core/lib/ably/version.rb)
   - `Ably::PubSub::Server::VERSION` in [server/lib/ably/pubsub/server/version.rb](./server/lib/ably/pubsub/server/version.rb)
   - the exact-version `ably-pubsub-core` pin in [server/ably-pubsub-server.gemspec](./server/ably-pubsub-server.gemspec) (derived from the version constant, so it normally follows automatically)
3. Run [`github_changelog_generator`](https://github.com/github-changelog-generator/github-changelog-generator) to automate the update of the [CHANGELOG](./CHANGELOG.md). This may require some manual intervention, both in terms of how the command is run and how the change log file is modified. Your mileage may vary:
   - The command you will need to run will look something like this: `github_changelog_generator -u ably -p ably-ruby --since-tag v2.0.0 --output delta.md --token $GITHUB_TOKEN_WITH_REPO_ACCESS`. Generate token [here](https://github.com/settings/tokens/new?description=GitHub%20Changelog%20Generator%20token).
   - Using the command above, `--output delta.md` writes changes made after `--since-tag` to a new file
   - The contents of that new file (`delta.md`) then need to be manually inserted at the top of the `CHANGELOG.md`, changing the "Unreleased" heading and linking with the current version numbers
   - Also ensure that the "Full Changelog" link points to the new version tag instead of the `HEAD`
4. Commit this change: `git add CHANGELOG.md && git commit -m "Update change log."`
5. Ideally, run `rake doc:spec` to generate a new [spec file](./SPEC.md). Then commit these changes.
6. Make a PR against `main`. Once the PR is approved, merge it into `main`.
7. Add a tag to the new `main` head commit and push to origin such as `git tag v2.0.1 && git push origin v2.0.1`.
8. Visit [the tags page](https://github.com/ably/ably-ruby/tags) and `Add release notes` for the release including links to the changelog entry.
9. Run the [Release workflow](./.github/workflows/release.yml) (Actions → Release → Run workflow) with the version number. It publishes `ably-pubsub-core` and then `ably-pubsub-server` to RubyGems via trusted publishing — no local credentials involved. A failed run is safe to re-run with the same version: already-published gems are skipped.
10. Create the entry on the [Ably Changelog](https://changelog.ably.com/) (via [headwayapp](https://headwayapp.co/)).

### Trusted publishing

The workflow authenticates to RubyGems with [trusted publishing](https://guides.rubygems.org/trusted-publishing/) (GitHub OIDC): both gems have a Trusted Publisher configured on rubygems.org bound to this repository and `.github/workflows/release.yml`. There are no long-lived RubyGems API keys anywhere. If the repository is renamed, both bindings must be reconfigured on rubygems.org or publishing fails.

### The legacy `ably` gem

The `ably` gem is in its maintenance window (security and critical fixes only, released from the maintenance branch) and is **not** released from `main`. The `ably-rest` gem (from the `ably-ruby-rest` repo) is likewise in maintenance and no longer part of this release process.
