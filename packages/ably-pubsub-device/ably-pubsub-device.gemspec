# coding: utf-8
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/pubsub/device/version'

Gem::Specification.new do |spec|
  spec.name          = 'ably-pubsub-device'
  spec.version       = Ably::PubSub::Device::VERSION
  spec.authors       = ['Ably']
  spec.email         = ['support@ably.com']
  spec.description   = %q{The Ably Pub/Sub Ruby client for devices: applications running in end-user environments whose connections are identified by a client_id and counted on accounts with monthly-active-user billing}
  spec.summary       = %q{Ably Pub/Sub client for devices}
  spec.homepage      = 'http://github.com/ably/ably-ruby'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.7'

  # See the equivalent comment in packages/ably-pubsub-server/ably-pubsub-server.gemspec for why
  # this ships only its own subtree, and why there is no lib/ably/pubsub.rb.
  spec.files         = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }
  spec.require_paths = ['lib']

  # Released in lockstep with the ably gem, which this pins exactly: this gem is a thin entry
  # point onto the core's clients, so a mismatched pair is not a combination we ship.
  spec.add_runtime_dependency 'ably', Ably::PubSub::Device::VERSION
end
