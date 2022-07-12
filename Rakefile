# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'bundler/gem_tasks'
require 'json'

require 'yard'
YARD::Rake::YardocTask.new

begin
  require 'rspec/core/rake_task'

  rspec_task = RSpec::Core::RakeTask.new(:spec)

  task default: :spec

  namespace :doc do
    desc 'Generate Markdown Specification from the RSpec public API tests'
    task :spec do
      ENV['PROTOCOL'] = 'json'

      rspec_task.rspec_opts = %w[
        --require ./spec/support/markdown_spec_formatter
        --order defined
        --tag ~api_private
        --format documentation
        --format Ably::RSpec::MarkdownSpecFormatter
      ].join(' ')

      Rake::Task[:spec].invoke
    end
  end

  desc 'Generate error code constants from ably-common: https://github.com/ably/ably-common/issues/32'
  task :generate_error_codes do
    errors_json_path = File.join(File.dirname(__FILE__), 'lib/submodules/ably-common/protocol/errors.json')
    module_path = File.join(File.dirname(__FILE__), 'lib/ably/modules/exception_codes.rb')
    max_length = 0

    errors = JSON.parse(File.read(errors_json_path)).transform_values do |val|
      val.split(/\s+/).map { |d| d.upcase.gsub(/[^a-zA-Z]+/, '') }.join('_')
    end.each do |_code, const_name|
      max_length = [const_name.length, max_length].max
    end.map do |code, const_name|
      "      #{const_name.ljust(max_length, ' ')} = #{code}"
    end.join("\n")
    module_content = <<~EOF
      # This file is generated by running `rake :generate_error_codes`
      # Do not manually modify this file
      # Generated at: #{Time.now.utc}
      #
      module Ably
        module Exceptions
          module Codes
      #{errors}
          end
        end
      end
    EOF
    File.open(module_path, 'w') { |file| file.write module_content }

    puts "Error code constants have been generated into #{module_path}"
    puts 'Warning: Search for any constants referenced in this library if their name has changed as a result of this constant generation!'
  end
rescue LoadError
  # RSpec not available
end
