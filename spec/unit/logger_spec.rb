require 'spec_helper'

describe Ably::Logger do
  let(:new_client) do
    instance_double('Ably::Realtime::Client', connection: instance_double('Ably::Realtime::Connection', id: nil))
  end
  let(:connected_client) do
    instance_double('Ably::Realtime::Client', connection: instance_double('Ably::Realtime::Connection', id: '0000'))
  end
  let(:rest_client) do
    instance_double('Ably::Rest::Client')
  end

  subject { Ably::Logger.new(new_client, Logger::INFO) }

  def uncolorize(string)
    regex_pattern = /\033\[[0-9]+m(.+?)\033\[0m/m
    string.gsub(regex_pattern, '\1')
  end

  it 'uses the Ruby Logger by default' do
    expect(subject.logger).to be_a(Logger)
  end

  it 'delegates to the logger object' do
    expect(subject.logger).to receive(:warn).with('message')
    subject.warn 'message'
  end

  context 'formatter' do
    context 'when debugging' do
      it 'uses short time format' do
        formatted = subject.logger.formatter.call(Logger::DEBUG, Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to match(/^\d+:\d+:\d+.\d{3} DEBUG/)
      end
    end

    context 'when info -> fatal' do
      it 'uses long time format' do
        formatted = subject.logger.formatter.call(Logger::INFO, Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to match(/^\d+-\d+-\d+ \d+:\d+:\d+.\d{3} INFO/)
      end
    end

    context 'with Realtime disconnected client' do
      subject { Ably::Logger.new(new_client, Logger::INFO) }

      it 'formats logs with an empty client ID' do
        formatted = subject.logger.formatter.call(Logger::DEBUG, Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to match(/\[ \-\- \]/)
        expect(formatted).to match(%r{unique_message$})
        expect(formatted).to match(%r{DEBUG})
      end
    end

    context 'with Realtime connected client' do
      subject { Ably::Logger.new(connected_client, Logger::INFO) }

      it 'formats logs with a client ID' do
        formatted = subject.logger.formatter.call(Logger::DEBUG, Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to match(/\[0000]/)
        expect(formatted).to match(%r{unique_message$})
        expect(formatted).to match(%r{DEBUG})
      end
    end

    context 'with REST client' do
      subject { Ably::Logger.new(rest_client, Logger::INFO) }

      it 'formats logs without a client ID' do
        formatted = subject.logger.formatter.call(Logger::FATAL, Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to_not match(/\[.*\]/)
        expect(formatted).to match(%r{unique_message$})
        expect(formatted).to match(%r{FATAL})
      end
    end

    context 'severity argument' do
      it 'can be an Integer' do
        formatted = subject.logger.formatter.call(Logger::INFO, Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to match(/^\d+-\d+-\d+ \d+:\d+:\d+.\d{3} INFO/)
      end

      it 'can be a string' do
        formatted = subject.logger.formatter.call('INFO', Time.now, 'progid', 'unique_message')
        formatted = uncolorize(formatted)
        expect(formatted).to match(/^\d+-\d+-\d+ \d+:\d+:\d+.\d{3} INFO/)
      end
    end
  end

  context 'with a custom Logger' do
    context 'with an invalid interface' do
      let(:custom_logger_with_bad_interface) do
        Class.new.new
      end
      subject { Ably::Logger.new(new_client, Logger::INFO, custom_logger_with_bad_interface) }

      it 'raises an exception' do
        expect { subject }.to raise_error ArgumentError, /The custom Logger's interface does not provide the method/
      end
    end

    context 'with a valid interface' do
      let(:custom_logger) do
        Class.new do
          extend Forwardable
          def initialize
            @logger = Logger.new(STDOUT)
          end
          def_delegators :@logger, :fatal, :error, :warn, :info, :debug, :level, :level=
        end
      end
      let(:custom_logger_object) { custom_logger.new }

      subject { Ably::Logger.new(new_client, Logger::INFO, custom_logger_object) }

      it 'is used' do
        expect { subject }.to_not raise_error
        expect(subject.logger.class).to eql(custom_logger)
      end

      it 'delegates log messages to logger' do
        expect(custom_logger_object).to receive(:fatal).with('message')
        subject.fatal 'message'
      end
    end
  end
end
