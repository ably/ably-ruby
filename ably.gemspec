# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ably/version'

Gem::Specification.new do |spec|
  spec.name          = "ably"
  spec.version       = Ably::VERSION
  spec.authors       = ["Lewis Marshall"]
  spec.email         = ["lewis@lmars.net"]
  spec.description   = %q{A Ruby client library for ably.io, the real-time messaging service}
  spec.summary       = %q{A Ruby client library for ably.io, the real-time messaging service}
  spec.homepage      = "https://ably.io"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "eventmachine"
  spec.add_runtime_dependency "faraday"
  spec.add_runtime_dependency "json"
  spec.add_runtime_dependency "websocket-driver"

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "redcarpet"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "vcr"
  spec.add_development_dependency "webmock"
  spec.add_development_dependency "yard"
end
