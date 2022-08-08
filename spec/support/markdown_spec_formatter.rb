# frozen_string_literal: true

module Ably
  module RSpec
    # Generate Markdown Specification from the RSpec public API tests
    #
    class MarkdownSpecFormatter
      ::RSpec::Core::Formatters.register self, :start, :close,
        :example_group_started, :example_group_finished,
        :example_passed, :example_failed, :example_pending,
        :dump_summary

      def initialize(_output)
        @output = if documenting_rest_only?
          File.open(File.expand_path("../../../../../SPEC.md", __dir__), "w")
        else
          File.open(File.expand_path("../../SPEC.md", __dir__), "w")
        end

        @indent = 0
        @passed = 0
        @pending = 0
        @failed = 0
      end

      def start(_notification)
        puts "\n\e[33m --> Creating SPEC.md <--\e[0m\n"
        scope = if defined?(Ably::Realtime)
          "Realtime & REST"
        else
          "REST"
        end
        output.write "# Ably #{scope} Client Library #{Ably::VERSION} Specification\n"
      end

      def close(_notification)
        output.close
      end

      def example_group_started(notification)
        output.write "#{indent_prefix}#{notification.group.description}\n"
        output.write "_(see #{heading_location_path(notification)})_\n" if indent == 0
        @indent += 1
      end

      def example_group_finished(_notification)
        @indent -= 1
      end

      def example_passed(notification)
        return if notification.example.metadata[:api_private]

        output.write "#{indent_prefix}#{example_name_and_link(notification)}\n"
        @passed += 1
      end

      def example_failed(notification)
        return if notification.example.metadata[:api_private]

        output.write "#{indent_prefix}FAILED: ~~#{example_name_and_link(notification)}~~\n"
        @failed += 1
      end

      def example_pending(notification)
        return if notification.example.metadata[:api_private]

        output.write "#{indent_prefix}PENDING: *#{example_name_and_link(notification)}*\n"
        @pending += 1
      end

      def dump_summary(_notification)
        output.write <<-MARKDOWN.gsub("        ", "")

          -------

          ## Test summary

          * Passing tests: #{@passed}
          * Pending tests: #{@pending}
          * Failing tests: #{@failed}
        MARKDOWN
      end

      private

      attr_reader :output, :indent

      def documenting_rest_only?
        File.exist?(File.expand_path("../../../../../ably-rest.gemspec", __dir__))
      end

      def example_name_and_link(notification)
        "[#{notification.example.metadata[:description]}](#{path_for(notification.example.location).gsub(/:(\d+)/, '#L\1')})"
      end

      def heading_location_path(notification)
        "[#{notification.group.location.gsub(/:(\d+)/, "").gsub(%r{^\./}, "")}](#{path_for(notification.group.location).gsub(/:(\d+)/, "")})"
      end

      def path_for(location)
        if documenting_rest_only?
          "https://github.com/ably/ably-ruby/tree/#{submodule_sha}#{location.gsub(%r{^\./lib/submodules/ably-ruby}, "")}"
        else
          location
        end
      end

      def submodule_sha
        @submodule_sha ||= `git ls-tree HEAD:lib/submodules grep ably-ruby`[/^\w+\s+\w+\s+(\w+)/, 1]
      end

      def indent_prefix
        if indent > 0
          "#{"  " * indent}* "
        else
          "\n### "
        end
      end
    end
  end
end
