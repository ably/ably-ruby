require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'json'

require 'yard'
YARD::Rake::YardocTask.new

begin
  require 'rspec/core/rake_task'

  rspec_task = RSpec::Core::RakeTask.new(:spec)

  task :default => :spec

  namespace :doc do
    desc 'Generate Markdown Specification from the RSpec public API tests'
    task :spec do
      ENV['TEST_LIMIT_PROTOCOLS'] = JSON.dump({ msgpack: 'JSON and MsgPack' })

      rspec_task.rspec_opts = %w(
        --require ./spec/support/markdown_spec_formatter
        --order defined
        --tag ~api_private
        --format documentation
        --format Ably::RSpec::MarkdownSpecFormatter
      ).join(' ')

      Rake::Task[:spec].invoke
    end
  end
rescue LoadError
  # RSpec not available
end
