# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/version'

Gem::Specification.new do |spec|
  spec.name          = 'ably-pubsub-core'
  spec.version       = Ably::VERSION
  spec.authors       = ['Ably']
  spec.email         = ['support@ably.com']
  spec.description   = %q{Internal implementation package for Ably's own Pub/Sub packages. Not intended for direct external use: depend on ably-pubsub-server instead.}
  spec.summary       = %q{Shared core implementation for Ably Pub/Sub Ruby SDKs (internal)}
  spec.homepage      = 'https://github.com/ably/ably-pubsub-ruby'
  spec.license       = 'Apache-2.0'

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z lib`.split("\x0").reject { |f| f.start_with?('lib/submodules') }
  end
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'eventmachine', '~> 1.2.6'
  spec.add_runtime_dependency 'ably-em-http-request', '~> 1.1.8'
  spec.add_runtime_dependency 'statesman', '~> 9.0'
  spec.add_runtime_dependency 'faraday', '~> 2.2'
  spec.add_runtime_dependency 'faraday-typhoeus', '~> 1.1.0'
  spec.add_runtime_dependency 'typhoeus', '~> 1.4'
  spec.add_runtime_dependency 'json'
  # We disallow minor version updates, because this gem has introduced breaking API changes in minor releases before (which it's within its rights to do, given it's pre-v1). If you want to allow a new minor version, bump here and run the tests.
  spec.add_runtime_dependency 'websocket-driver', '~> 0.8.0'
  spec.add_runtime_dependency 'msgpack', '>= 1.3.0'
  spec.add_runtime_dependency 'addressable', '>= 2.0.0'

  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'redcarpet', '~> 3.3'
  spec.add_development_dependency 'rspec', '~> 3.11.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.5.1'
  spec.add_development_dependency 'rspec-retry', '~> 0.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'rspec-instafail', '~> 1.0'
  spec.add_development_dependency 'bundler', '>= 1.3.0'
  spec.add_development_dependency 'webmock', '~> 3.11'
  spec.add_development_dependency 'simplecov', '~> 0.22.0'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.8.0'
  spec.add_development_dependency 'parallel_tests', '~> 3.8'
  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.8.0'

  if RUBY_VERSION.match(/^3\./)
    spec.add_development_dependency 'webrick', '~> 1.7.0'
  end
end
