# frozen_string_literal: true

require 'English'
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/version'

Gem::Specification.new do |spec|
  spec.required_ruby_version = '>= 2.7'

  spec.name          = 'ably'
  spec.version       = Ably::VERSION
  spec.authors       = ['Lewis Marshall', "Matthew O'Riordan"]
  spec.email         = ['lewis@lmars.net', 'matt@ably.io']
  spec.description   = 'A Ruby client library for ably.io realtime messaging'
  spec.summary       = 'A Ruby client library for ably.io realtime messaging implemented using EventMachine'
  spec.homepage      = 'http://github.com/ably/ably-ruby'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files`.split($INPUT_RECORD_SEPARATOR)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'addressable', '>= 2.0.0'
  spec.add_runtime_dependency 'em-http-request', '~> 1.1'
  spec.add_runtime_dependency 'eventmachine', '~> 1.2.6'
  spec.add_runtime_dependency 'faraday', '~> 2.2'
  spec.add_runtime_dependency 'faraday-typhoeus', '~> 0.2.0'
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'msgpack', '>= 1.3.0'
  spec.add_runtime_dependency 'statesman', '~> 9.0'
  spec.add_runtime_dependency 'typhoeus', '~> 1.4'
  spec.add_runtime_dependency 'websocket-driver', '~> 0.7'

  spec.add_development_dependency 'bundler', '>= 1.3.0'
  spec.add_development_dependency 'panolint', '~> 0.1.4'
  spec.add_development_dependency 'parallel_tests', '~> 3.8'
  spec.add_development_dependency 'pry', '~> 0.14.1'
  spec.add_development_dependency 'pry-byebug', '~> 3.8.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'redcarpet', '~> 3.3'
  spec.add_development_dependency 'rspec', '~> 3.11.0'
  spec.add_development_dependency 'rspec-instafail', '~> 1.0'
  spec.add_development_dependency 'rspec_junit_formatter', '~> 0.5.1'
  spec.add_development_dependency 'rspec-retry', '~> 0.6'
  spec.add_development_dependency 'rubocop', '~> 1.31'
  spec.add_development_dependency 'simplecov', '~> 0.21.2'
  spec.add_development_dependency 'simplecov-lcov', '~> 0.8.0'
  spec.add_development_dependency 'webmock', '~> 3.11'
  spec.add_development_dependency 'yard', '~> 0.9'

  spec.add_development_dependency 'webrick', '~> 1.7.0' if RUBY_VERSION.match(/^3\./)
end
