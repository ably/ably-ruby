require 'spec_helper'

describe Ably::Realtime::Client do
  let(:client_options) { 'appid.keyuid:keysecret' }
  subject do
    Ably::Realtime::Client.new(client_options)
  end

  context 'delegation to the Rest Client' do
    let(:options) { { arbitrary: 'value' } }

    it 'passes on the options to the initializer' do
      rest_client = instance_double('Ably::Rest::Client', auth: instance_double('Ably::Auth'), options: {})
      expect(Ably::Rest::Client).to receive(:new).with(client_options).and_return(rest_client)
      subject
    end

    context 'for attribute' do
      [:environment, :use_tls?, :log_level].each do |attribute|
        specify "##{attribute}" do
          expect(subject.rest_client).to receive(attribute)
          subject.public_send attribute
        end
      end
    end

    context 'logger' do
      context 'defaults' do
        let(:logger) { subject.logger }

        subject { Ably::Realtime::Client.new(client_options) }

        it 'uses default Ruby Logger by default' do
          expect(subject.logger.logger).to be_a(::Logger)
        end

        it 'defaults to Logger::ERROR log level' do
          expect(subject.logger.log_level).to eql(::Logger::ERROR)
        end

        it 'returns the connection ID' do
          allow(subject).to receive_message_chain(:connection, :id).and_return('AAA')
          expect(logger.logger.formatter.call(0, Time.now, '', 'unique_message')).to match(/AAA/)
        end
      end

      context 'with custom logger and log_level' do
        let(:custom_logger) do
          Class.new do
            extend Forwardable
            def initialize
              @logger = Logger.new(STDOUT)
            end
            def_delegators :@logger, :fatal, :error, :warn, :info, :debug, :level, :level=
          end
        end
        subject { Ably::Realtime::Client.new(api_key: 'appid.keyuid:keysecret', logger: custom_logger.new, log_level: Logger::DEBUG) }

        it 'uses the custom logger' do
          expect(subject.logger.logger.class).to eql(custom_logger)
        end

        it 'sets the custom log level' do
          expect(subject.logger.log_level).to eql(Logger::DEBUG)
        end
      end
    end
  end
end
