# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/version'

Gem::Specification.new do |spec|
  spec.name          = 'ably'
  spec.version       = Ably::VERSION
  spec.authors       = ['Lewis Marshall', "Matthew O'Riordan"]
  spec.email         = ['lewis@lmars.net', 'matt@ably.io']
  spec.description   = %q{A Ruby client library for ably.io, the realtime messaging service}
  spec.summary       = %q{A Ruby client library for ably.io, the realtime messaging service}
  spec.homepage      = 'http://github.com/ably/ably-ruby'
  spec.license       = 'MIT'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'eventmachine', '~> 1.0'
  spec.add_runtime_dependency 'em-http-request', '~> 1.1'
  spec.add_runtime_dependency 'statesman', '~> 1.0.0'
  spec.add_runtime_dependency 'faraday', '~> 0.9'
  spec.add_runtime_dependency 'json'
  spec.add_runtime_dependency 'websocket-driver', '~> 0.3'
  spec.add_runtime_dependency 'msgpack-ably', '~> 0.5.10'

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'redcarpet'
  spec.add_development_dependency 'rspec', '~> 3.1.0' # version lock, see config.around(:example, :event_machine) in event_machine_helper.rb
  spec.add_development_dependency 'rspec-retry'
  spec.add_development_dependency 'yard'
  spec.add_development_dependency 'webmock'

  spec.add_development_dependency 'coveralls'
end
