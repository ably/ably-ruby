RSpec.configure do |config|
  config.before(:example) do |example|
    next if example.metadata[:prevent_log_stubbing]

    log_mutex = Mutex.new

    @log_output = []
    %w(fatal error warn info debug).each do |method_name|
      allow_any_instance_of(Ably::Logger).to receive(method_name.to_sym).and_wrap_original do |method, *args, &block|
        # Don't log shutdown sequence to keep log noise to a minimum
        next if RSpec.const_defined?(:EventMachine) && RSpec::EventMachine.reactor_stopping?

        prefix = "#{Time.now.strftime('%H:%M:%S.%L')} [\e[33m#{method_name}\e[0m] "

        log_mutex.synchronize do
          begin
            args << block.call unless block.nil?
            @log_output << "#{prefix}#{args.compact.join(' ')}"
          rescue StandardError => e
            @log_output << "#{prefix}Failed to log block - #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}}"
          end
        end

        # Call original
        method.call(*args, &block)
      end
    end
  end

  config.after(:example) do |example|
    next if example.metadata[:prevent_log_stubbing]

    exception = example.exception
    puts "\n#{'-'*34}\n\e[36mVerbose Ably log from test failure\e[0m\n#{'-'*34}\n#{@log_output.join("\n")}\n\n" if exception
  end
end
