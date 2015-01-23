# If a test fails and RSPEC_RETRY is set to true, create a new
# application before retrying the RSpec test again
#
RSpec.configure do |config|
  config.around(:example) do |example|
    example.run

    next if example.metadata[:webmock] # new app is not needed for a mocked test

    if example.exception && ENV['RSPEC_RETRY']
      reload_test_app
      puts "** Test app reloaded before next retry **"
    end
  end
end
