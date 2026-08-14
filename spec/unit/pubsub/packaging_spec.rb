# encoding: utf-8

# The Ably namespace is assembled at install time from three gems: ably ships the core,
# ably-pubsub-server ships Ably::PubSub::Server and ably-pubsub-device ships
# Ably::PubSub::Device. That only holds together if each ships its own subtree and the three
# stay on one version, so this covers both — neither would otherwise fail anywhere closer to
# the mistake than a release.
require 'spec_helper'
require 'ably/pubsub/server'
require 'ably/pubsub/device'

describe 'Pub/Sub gem packaging' do
  repo_root = File.expand_path('../../..', __dir__)

  pubsub_gems = {
    'ably-pubsub-server' => { side: 'server', version: Ably::PubSub::Server::VERSION },
    'ably-pubsub-device' => { side: 'device', version: Ably::PubSub::Device::VERSION }
  }

  gemspec_for = lambda do |gem_name|
    path = if gem_name == 'ably'
      File.join(repo_root, 'ably.gemspec')
    else
      File.join(repo_root, 'packages', gem_name, "#{gem_name}.gemspec")
    end
    Gem::Specification.load(path) || raise("could not load #{path}")
  end

  it 'the core gem does not ship the Pub/Sub gems' do
    expect(gemspec_for.call('ably').files.grep(%r{\Apackages/})).to be_empty
  end

  # In Ruby the equivalent of a namespace package collision is a shared file: lib/ably/pubsub.rb
  # would be shipped by both Pub/Sub gems, and whichever came first on the load path would be the
  # one required, hiding the other's
  it 'no gem defines lib/ably/pubsub.rb, which two of them would each have to ship' do
    all_files = ['ably', *pubsub_gems.keys].flat_map { |gem_name| gemspec_for.call(gem_name).files }
    expect(all_files).to_not include('lib/ably/pubsub.rb')
  end

  pubsub_gems.each do |gem_name, gem_details|
    context gem_name do
      let(:gemspec) { gemspec_for.call(gem_name) }

      it 'ships only its own subtree' do
        outside_own_subtree = gemspec.files.grep(/\.rb\z/).reject do |file|
          file.start_with?("lib/ably/pubsub/#{gem_details[:side]}")
        end
        expect(outside_own_subtree).to be_empty
      end

      it 'ships the entry point that gives it its name' do
        expect(gemspec.files).to include("lib/ably/pubsub/#{gem_details[:side]}.rb")
      end

      it 'carries the version of its VERSION constant' do
        expect(gemspec.version.to_s).to eql(gem_details[:version])
      end

      it 'is released in lockstep with the core' do
        expect(gem_details[:version]).to eql(Ably::VERSION)
      end

      it 'pins the core exactly' do
        core = gemspec.dependencies.find { |dependency| dependency.name == 'ably' }
        expect(core).to_not be_nil
        expect(core.requirement.to_s).to eql("= #{Ably::VERSION}")
      end
    end
  end
end
