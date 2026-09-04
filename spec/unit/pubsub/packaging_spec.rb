# encoding: utf-8
require 'spec_helper'

# The Ably namespace is assembled at install time from two gems: ably-pubsub-core ships the
# implementation under lib/ably, and ably-pubsub-server ships only the lib/ably/pubsub/server
# subtree on top of it. That only holds together if each gem ships exactly its own subtree —
# a file shipped by both would be resolved from whichever gem comes first on the load path,
# hiding the other's copy. The release pre-flight checks version agreement but nothing else
# asserts the gems' file lists, so a packaging mistake would otherwise surface only after
# publish. These specs load the gemspecs and check the built file lists directly.
describe 'Pub/Sub gem packaging' do
  repo_root = File.expand_path('../../..', __dir__)

  gemspec_for = lambda do |gem_name, dir|
    path = File.join(repo_root, dir, "#{gem_name}.gemspec")
    Gem::Specification.load(path) || raise("could not load #{path}")
  end

  core_spec = gemspec_for.call('ably-pubsub-core', 'core')
  server_spec = gemspec_for.call('ably-pubsub-server', 'server')

  it 'ships no load-path file in both gems' do
    core_lib = core_spec.files.grep(%r{\Alib/})
    server_lib = server_spec.files.grep(%r{\Alib/})
    expect(core_lib & server_lib).to be_empty
  end

  it 'core does not ship the server subtree' do
    expect(core_spec.files.grep(%r{\Alib/ably/pubsub(/|\.rb\z)})).to be_empty
  end

  it 'server ships only the lib/ably/pubsub/server subtree under lib' do
    lib_files = server_spec.files.grep(%r{\Alib/})
    expect(lib_files).to_not be_empty
    expect(lib_files).to all(match(%r{\Alib/ably/pubsub/server(/|\.rb\z)}))
  end

  it 'core does not ship the ably-common submodule' do
    expect(core_spec.files.grep(%r{\Alib/submodules/})).to be_empty
  end

  it 'releases both gems at one version (lockstep)' do
    expect(server_spec.version).to eql(core_spec.version)
  end

  it 'server pins core at exactly the shared version' do
    core_dep = server_spec.dependencies.find { |dep| dep.name == 'ably-pubsub-core' }
    expect(core_dep).to_not be_nil
    expect(core_dep.requirement.to_s).to eql("= #{core_spec.version}")
  end
end
