# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/version'

Gem::Specification.new do |spec|
  spec.name          = 'ably'
  spec.version       = Ably::VERSION
  spec.authors       = ['Lewis Marshall', "Matthew O'Riordan"]
  spec.email         = ['lewis@lmars.net', 'matt@ably.io']
  spec.description   = %q{A Ruby client library for ably.io realtime messaging}
  spec.summary       = %q{A Ruby client library for ably.io realtime messaging implemented using EventMachine}
  spec.homepage      = 'http://github.com/ably/ably-ruby'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'eventmachine', '~> 1.2.6'
  spec.add_runtime_dependency 'em-http-request', '~> 1.1'
  spec.add_runtime_dependency 'statesman', '~> 1.0.0'
  spec.add_runtime_dependency 'faraday', '~> 0.12'
  spec.add_runtime_dependency 'excon', '~> 0.55'

  if RUBY_VERSION.match(/^1\./)
    spec.add_runtime_dependency 'json', '< 2.0'
  else
    spec.add_runtime_dependency 'json'
  end
  spec.add_runtime_dependency 'websocket-driver', '~> 0.7'
  spec.add_runtime_dependency 'msgpack', '>= 1.3.0'
  spec.add_runtime_dependency 'addressable', '>= 2.0.0'

  spec.add_development_dependency 'rake', '~> 11.3'
  spec.add_development_dependency 'redcarpet', '~> 3.3'
  spec.add_development_dependency 'rspec', '~> 3.3.0' # version lock, see config.around(:example, :event_machine) in event_machine_helper.rb
  spec.add_development_dependency 'rspec-retry', '~> 0.6'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'rspec-instafail', '~> 1.0'
  spec.add_development_dependency 'bundler', '>= 1.3.0'

  if RUBY_VERSION.match(/^1\./)
    spec.add_development_dependency 'public_suffix', '~> 1.4.6' # Later versions do not support Ruby 1.9
    spec.add_development_dependency 'webmock', '2.2'
    spec.add_development_dependency 'parallel_tests', '~> 2.9.0'
  else
    spec.add_development_dependency 'webmock', '~> 2.2'
    spec.add_development_dependency 'coveralls'
    spec.add_development_dependency 'parallel_tests', '~> 2.22'
    if !RUBY_VERSION.match(/^2\.[0123]/)
      spec.add_development_dependency 'pry'
      spec.add_development_dependency 'pry-byebug'
    end
  end
end
