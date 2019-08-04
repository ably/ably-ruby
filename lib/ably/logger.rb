module Ably
  # Logger unifies logging for #debug, #info, #warn, #error, and #fatal messages.
  # A new Ably client uses this Logger and sets the appropriate log level.
  # A custom Logger can be configured when instantiating the client, refer to the {Ably::Rest::Client} and {Ably::Realtime::Client} documentation
  #
  class Logger
    extend Forwardable

    # @param client        [Ably::Rest::Client,Ably::Realtime::Client] Rest or Realtime Ably client
    # @param log_level     [Integer] {http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html Ruby Logger} log level
    # @param custom_logger [nil,Object] A custom logger can optionally be used instead of the,
    #                      however it must provide a {http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html Ruby Logger} compatible interface.
    #
    def initialize(client, log_level, custom_logger = nil)
      @client        = client
      @custom_logger = custom_logger
      @logger        = custom_logger || default_logger
      @log_level     = log_level

      ensure_logger_interface_is_valid

      @logger.level = log_level

      @log_mutex = Mutex.new
    end

    # The logger used by this class, defaults to {http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html Ruby Logger}
    # @return {Object,Logger}
    attr_reader :logger

    # If a custom logger is being used with this Logger, this property is not nil
    # @return {nil,Object}
    attr_reader :custom_logger

    # The log level ranging from DEBUG to FATAL, refer to http://www.ruby-doc.org/stdlib-1.9.3/libdoc/logger/rdoc/Logger.html
    # @return {Integer}
    attr_reader :log_level

    # Catch exceptiosn in blocks passed to the logger, log the error and continue
    %w(fatal error warn info debug).each do |method_name|
      define_method(method_name) do |*args, &block|
        begin
          log_mutex.synchronize do
            logger.public_send(method_name, *args, &block)
          end
        rescue StandardError => e
          logger.error "Logger: Failed to log #{method_name} block - #{e.class}: #{e.message}\n#{e.backtrace.join("\n")}"
        end
      end
    end

    private
    attr_reader :log_mutex

    def client
      @client
    end

    def color(color_value, string)
      "\033[#{color_value}m#{string}\033[0m"
    end

    def red(string)
      color(31, string)
    end

    def magenta(string)
      color(35, string)
    end

    def cyan(string)
      color(36, string)
    end

    def connection_id
      if realtime?
        if client.connection.id
          "[#{cyan(client.connection.id)}] "
        else
          "[ #{cyan('--')} ] "
        end
      end
    end

    def realtime?
      defined?(Ably::Realtime::Client) && client.kind_of?(Ably::Realtime::Client)
    end

    def default_logger
      ::Logger.new(STDOUT).tap do |logger|
        logger.formatter = lambda do |severity, datetime, progname, msg|
          severity = ::Logger::SEV_LABEL.index(severity) if severity.kind_of?(String)

          formatted_date = if severity == ::Logger::DEBUG
            datetime.strftime("%H:%M:%S.%L")
          else
            datetime.strftime("%Y-%m-%d %H:%M:%S.%L")
          end

          severity_label = if severity <= ::Logger::INFO
            magenta(::Logger::SEV_LABEL[severity])
          else
            red(::Logger::SEV_LABEL[severity])
          end

          "#{formatted_date} #{severity_label} #{connection_id}#{msg}\n"
        end
      end
    end

    def ensure_logger_interface_is_valid
      %w(fatal error warn info debug level level=).each do |method|
        unless logger.respond_to?(method)
          raise ArgumentError, "The custom Logger's interface does not provide the method '#{method}'"
        end
      end
    end
  end
end
