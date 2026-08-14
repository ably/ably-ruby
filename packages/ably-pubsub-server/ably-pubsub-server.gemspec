# coding: utf-8
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/pubsub/server/version'

Gem::Specification.new do |spec|
  spec.name          = 'ably-pubsub-server'
  spec.version       = Ably::PubSub::Server::VERSION
  spec.authors       = ['Ably']
  spec.email         = ['support@ably.com']
  spec.description   = %q{The Ably Pub/Sub Ruby client for servers: trusted environments which typically authenticate with an API key, and whose connections are exempt from monthly-active-user counting}
  spec.summary       = %q{Ably Pub/Sub client for servers}
  spec.homepage      = 'http://github.com/ably/ably-ruby'
  spec.license       = 'Apache-2.0'
  spec.required_ruby_version = '>= 2.7'

  # This gem adds Ably::PubSub::Server to the Ably namespace the ably gem provides, so it ships
  # that subtree and nothing else. In particular there is no lib/ably/pubsub.rb: it would be
  # shipped by both this gem and ably-pubsub-device, and whichever came first on the load path
  # would be the one required, hiding the other's.
  spec.files         = Dir.chdir(__dir__) { `git ls-files -z`.split("\x0") }
  spec.require_paths = ['lib']

  # Released in lockstep with the ably gem, which this pins exactly: this gem is a thin entry
  # point onto the core's clients, so a mismatched pair is not a combination we ship.
  spec.add_runtime_dependency 'ably', Ably::PubSub::Server::VERSION
end
