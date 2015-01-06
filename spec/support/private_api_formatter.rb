module Ably::RSpec
  # PrivateApiFormatter is an RSpec Formatter that prefixes all tests that are part of a Private API with '(private)'
  #
  # Private API methods are tested for this library, but every implementation of the Ably client library
  # will likely be different and thus the private API method tests are not shared.
  #
  # Filter private API tests with `rspec --tag ~api_private`
  #
  class PrivateApiFormatter
    ::RSpec::Core::Formatters.register self, :example_started

    def initialize(output)
      @output = output
    end

    def example_started(notification)
      if notification.example.metadata[:api_private]
        notification.example.metadata[:description] = "#{yellow('(private)')} #{green(notification.example.metadata[:description])}"
      end
    end

    private
    def colorize(color_code, string)
      "\e[#{color_code}m#{string}\e[0m"
    end

    def yellow(string)
      colorize(33, string)
    end


    def green(string)
      colorize(32, string)
    end
  end
end
