# This file was generated by the `rspec --init` command. Conventionally, all
# specs live under a `spec` directory, which RSpec adds to the `$LOAD_PATH`.
# Require this file using `require "spec_helper"` to ensure that it is only
# loaded once.
#
# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration

RSpec.configure do |config|
  config.run_all_when_everything_filtered = true
  config.filter_run :focus

  config.mock_with :rspec do |mocks|
    # This option should be set when all dependencies are being loaded
    # before a spec run, as is the case in a typical spec helper. It will
    # cause any verifying double instantiation for a class that does not
    # exist to raise, protecting against incorrectly spelt names.
    mocks.verify_doubled_constant_names = true
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = 'random'

  config.before(:example) do
    WebMock.disable!
  end

  config.before(:example, :webmock => true) do
    allow(TestApp).to receive(:instance).and_return(instance_double('TestApp',
      app_id: 'app_id',
      key_id: 'app_id.key_id',
      api_key: 'app_id.key_id:secret',
      environment: 'sandbox'
    ))
    WebMock.enable!
  end

  if defined?(EventMachine)
    config.before(:example) do
      # Ensure EventMachine shutdown hooks are deregistered for every test
      EventMachine.instance_variable_set '@tails', []
    end
  end
end
