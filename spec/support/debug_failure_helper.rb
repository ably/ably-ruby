RSpec.configure do |config|
  config.before(:example) do
    @log_output = []
    %w(fatal error warn info debug).each do |method_name|
      allow_any_instance_of(Ably::Logger).to receive(method_name.to_sym).and_wrap_original do |method, *args|
        @log_output << "[#{method_name}] #{args[0]}"
        method.call(*args)
      end
    end
  end

  config.after(:example) do |example|
    exception = example.exception
    puts "\n#{'-'*35}\nVerbose Ably log from test failure:\n#{'-'*35}\n#{@log_output.join("\n")}\n\n" if exception
  end
end
