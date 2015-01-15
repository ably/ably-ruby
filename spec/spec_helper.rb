# Output the message to the console
# Useful for debugging as clearly visible, and name is not used anywhere else in library as opposed to debug or puts
def console(message)
  puts "\033[31m[#{Time.now.strftime('%H:%M:%S.%L')}]\033[0m \033[33m#{message}\033[0m"
end

require 'webmock/rspec'

require 'ably'

require 'support/api_helper'
require 'support/private_api_formatter'
require 'support/protocol_helper'
require 'support/random_helper'

require 'rspec_config'

# EM Helper must be loaded after rspec_config to ensure around block occurs before RSpec retry
require 'support/event_machine_helper'
