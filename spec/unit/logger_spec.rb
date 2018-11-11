require 'spec_helper'

describe Ably::Logger do
  let(:rest_client) do
    instance_double('Ably::Rest::Client')
  end

  subject { Ably::Logger.new(rest_client, Logger::INFO) }

  def uncolorize(string)
    regex_pattern = /\033\[[0-9]+m(.+?)\033\[0m/m
    string.gsub(regex_pattern, '\1')
  end

  it 'uses the language provided Logger by default' do
    expect(subject.logger).to be_a(Logger)
  end

  context 'internals', :api_private do
    it 'delegates to the default Logger object' do
      received = false
      expect(subject.logger).to be_a(::Logger)
      allow_any_instance_of(::Logger).to receive(:warn) do |*args, &block|
        expect(args.concat([block ? block.call : nil]).join(',')).to match(/message/)
        received = true
      end
      subject.warn 'message'
      expect(received).to be_truthy
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

      if defined?(Ably::Realtime)
        context 'with Realtime client' do
          let(:new_realtime_client) do
            instance_double('Ably::Realtime::Client', connection: instance_double('Ably::Realtime::Connection', id: nil))
          end
          let(:connected_realtime_client) do
            instance_double('Ably::Realtime::Client', connection: instance_double('Ably::Realtime::Connection', id: '0000'))
          end
          before do
            allow(new_realtime_client).to receive(:kind_of?).with(Ably::Realtime::Client).and_return(true)
            allow(connected_realtime_client).to receive(:kind_of?).with(Ably::Realtime::Client).and_return(true)
          end

          context 'with Realtime disconnected client' do
            subject { Ably::Logger.new(new_realtime_client, Logger::INFO) }

            it 'formats logs with an empty client ID' do
              formatted = subject.logger.formatter.call(Logger::DEBUG, Time.now, 'progid', 'unique_message')
              formatted = uncolorize(formatted)
              expect(formatted).to match(/\[ \-\- \]/)
              expect(formatted).to match(%r{unique_message$})
              expect(formatted).to match(%r{DEBUG})
            end
          end

          context 'with Realtime connected client' do
            subject { Ably::Logger.new(connected_realtime_client, Logger::INFO) }

            it 'formats logs with a client ID' do
              formatted = subject.logger.formatter.call(Logger::DEBUG, Time.now, 'progid', 'unique_message')
              formatted = uncolorize(formatted)
              expect(formatted).to match(/\[0000\]/)
              expect(formatted).to match(%r{unique_message$})
              expect(formatted).to match(%r{DEBUG})
            end
          end
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
  end

  context 'with a custom Logger' do
    context 'with an invalid interface' do
      let(:custom_logger_with_bad_interface) do
        Class.new.new
      end
      subject { Ably::Logger.new(rest_client, Logger::INFO, custom_logger_with_bad_interface) }

      it 'raises an exception' do
        expect { subject }.to raise_error ArgumentError, /The custom Logger's interface does not provide the method/
      end
    end

    context 'with a valid interface' do
      let(:custom_logger) { TestLogger }
      let(:custom_logger_object) { custom_logger.new }

      subject { Ably::Logger.new(rest_client, Logger::INFO, custom_logger_object) }

      it 'is used' do
        expect { subject }.to_not raise_error
        expect(subject.logger.class).to eql(custom_logger)
      end

      it 'delegates log messages to logger', :api_private do
        received = false
        allow(custom_logger_object).to receive(:fatal) do |*args, &block|
          expect(args.concat([block ? block.call : nil]).join(',')).to match(/message/)
          received = true
        end
        subject.fatal 'message'
        expect(received).to be_truthy
      end
    end
  end

  context 'with blocks', :prevent_log_stubbing do
    it 'does not call the block unless the log level is met' do
      log_level_blocks = []
      subject.warn { log_level_blocks << :warn }
      subject.info { log_level_blocks << :info }
      subject.debug { log_level_blocks << :debug }
      expect(log_level_blocks).to contain_exactly(:warn, :info)
    end

    context 'with an exception in the logger block' do
      before do
        expect(subject.logger).to receive(:error) do |*args, &block|
        expect(args.concat([block ? block.call : nil]).join(',')).to match(/Raise an error in the block/)
        end
      end

      it 'catches the error and continues' do
        subject.info { raise "Raise an error in the block" }
      end
    end
  end
end
