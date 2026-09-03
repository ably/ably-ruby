# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/pubsub/server/version'

Gem::Specification.new do |spec|
  spec.name          = 'ably-pubsub-server'
  spec.version       = Ably::PubSub::Server::VERSION
  spec.authors       = ['Ably']
  spec.email         = ['support@ably.com']
  spec.description   = %q{Ably Pub/Sub client for servers: backend services and other trusted runtimes. Construct clients with Ably::PubSub::Server.create_http_client or Ably::PubSub::Server.create_realtime_client.}
  spec.summary       = %q{Ably Pub/Sub client for servers}
  spec.homepage      = 'https://github.com/ably/ably-pubsub-ruby'
  spec.license       = 'Apache-2.0'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) { `git ls-files -z lib README.md`.split("\x0") }
  spec.require_paths = ['lib']

  # Exact pin: core and server are released in lockstep at the same version (PDR-091b),
  # which also guarantees a consumer can never resolve two different core versions.
  spec.add_runtime_dependency 'ably-pubsub-core', "= #{Ably::PubSub::Server::VERSION}"
end
