# Contributing

1. Fork it
2. When pulling to local, make sure to also pull the `ably-common` repo (`git submodule init && git submodule update`)
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Ensure you have added suitable tests and the test suite is passing(`bundle exec rspec`)
6. Push to the branch (`git push origin my-new-feature`)
7. Create a new Pull Request

---

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
