require "bundler/gem_tasks"

require "yard"
YARD::Rake::YardocTask.new

begin
  require 'rspec/core/rake_task'

  RSpec::Core::RakeTask.new(:spec)

  task :default => :spec
rescue LoadError
  # no rspec available
end
