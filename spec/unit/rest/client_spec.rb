# encoding: utf-8
require 'spec_helper'
require 'shared/client_initializer_behaviour'

describe Ably::Rest::Client do
  subject do
    Ably::Rest::Client.new(client_options)
  end

  it_behaves_like 'a client initializer'

  context 'initializer options' do
    context 'TLS' do
      context 'disabled' do
        let(:client_options) { { key: 'appid.keyuid:keysecret', tls: false } }

        it 'fails for any operation with basic auth and attempting to send an API key over a non-secure connection (#RSA1)' do
          expect { subject.channel('a').publish('event', 'message') }.to raise_error(Ably::Exceptions::InsecureRequest)
        end
      end
    end

    context 'fallback_retry_timeout (#RSC15f)' do
      context 'default' do
        let(:client_options) { { key: 'appid.keyuid:keysecret' } }

        it 'is set to 10 minutes' do
          expect(subject.options.fetch(:fallback_retry_timeout)).to eql(10 * 60)
        end
      end

      context 'when provided' do
        let(:client_options) { { key: 'appid.keyuid:keysecret', fallback_retry_timeout: 30 } }

        it 'configures a new timeout' do
          expect(subject.options.fetch(:fallback_retry_timeout)).to eql(30)
        end
      end
    end

    context 'use agent' do
      context 'set agent to non-default value' do
        context 'default agent' do
          let(:client_options) { { key: 'appid.keyuid:keysecret' } }

          it 'should return default ably agent' do
            expect(subject.agent).to eq(Ably::AGENT)
          end
        end

        context 'custom agent' do
          let(:client_options) { { key: 'appid.keyuid:keysecret', agent: 'example-gem/1.1.4 ably-ruby/1.1.5 ruby/3.0.0' } }

          it 'should overwrite client.agent' do
            expect(subject.agent).to eq('example-gem/1.1.4 ably-ruby/1.1.5 ruby/3.0.0')
          end
        end
      end
    end

    context ':use_token_auth' do
      context 'set to false' do
        context 'with a key and :tls => false' do
          let(:client_options) { { use_token_auth: false, key: 'appid.keyuid:keysecret', tls: false } }

          it 'fails for any operation with basic auth and attempting to send an API key over a non-secure connection' do
            expect { subject.channel('a').publish('event', 'message') }.to raise_error(Ably::Exceptions::InsecureRequest)
          end
        end

        context 'without a key' do
          let(:client_options) { { use_token_auth: false } }

          it 'fails as a key is required if not using token auth' do
            expect { subject.channel('a').publish('event', 'message') }.to raise_error(ArgumentError)
          end
        end
      end

      context 'set to true' do
        context 'without a key or token' do
          let(:client_options) { { use_token_auth: true, key: true } }

          it 'fails as a key is required to issue tokens' do
            expect { subject.channel('a').publish('event', 'message') }.to raise_error(ArgumentError)
          end
        end
      end
    end

    context 'log_exception_reporting_url' do
      context 'default' do
        let(:client_options) { { key: 'appid.keyuid:keysecret' } }

        it 'includes default log exception reporting url' do
          expect(subject.log_exception_reporting_url).to eql(nil)
        end

        it 'should set default log_exception_reporting_service' do
          expect(subject.log_exception_reporting_service).to be_a(Ably::Reporting::Service)
        end

        it 'should enable log_exception_reporting' do
          expect(subject.log_exception_reporting).to eql(true)
        end
      end

      context 'nil' do
        let(:client_options) { { log_exception_reporting_url: nil, key: 'appid.keyuid:keysecret' } }

        it 'should set log_exception_reporting_url to nil' do
          expect(subject.log_exception_reporting_url).to eql(nil)
        end

        it 'should not set log_exception_reporting_service' do
          expect(subject.log_exception_reporting_service).to eql(nil)
        end

        it 'should disable log_exception_reporting' do
          expect(subject.log_exception_reporting).to eql(false)
        end
      end

      context 'false' do
        let(:client_options) { { log_exception_reporting_url: false, key: 'appid.keyuid:keysecret' } }

        it 'should disable log_exception_reporting_url' do
          expect(subject.log_exception_reporting_url).to eql(false)
        end

        it 'should not set log_exception_reporting_service' do
          expect(subject.log_exception_reporting_service).to eq(nil)
        end
      end

      context 'custom string' do
        let(:custom_log_exception_reporting_url) { 'https://notify.errors.com' }
        let(:client_options) { { log_exception_reporting_url: custom_log_exception_reporting_url, key: 'appid.keyuid:keysecret' } }

        it 'includes custom log exception reporting url' do
          expect(subject.log_exception_reporting_url).to eql(custom_log_exception_reporting_url)
        end
      end
    end

    context 'log_exception_reporting_service' do
      context 'default' do
        let(:client_options) { { key: 'appid.keyuid:keysecret' } }

        it 'should return log exception reporting service' do
          expect(subject.log_exception_reporting_service).to be_a(Ably::Reporting::Service)
        end
      end

      context 'custom' do
        class CustomLogExceptionReportingService < Ably::Reporting::Base
          def initialize(options)
            @dsn = options.delete(:dsn)
          end

          def capture_exception(exception)
            @dsn
          end
        end

        let(:client_options) { { log_exception_reporting_class: CustomLogExceptionReportingService, log_exception_reporting_url: 'http://test.com', key: 'appid.keyuid:keysecret' } }

        it 'should return log exception reporting service' do
          expect(subject.log_exception_reporting_service).to be_a(CustomLogExceptionReportingService)
          expect(subject.log_exception_reporting_service.capture_exception(nil)).to eq('http://test.com')
        end
      end
    end
  end

  context 'request_id generation' do
    let(:client_options) { { key: 'appid.keyuid:keysecret', add_request_ids: true } }
    it 'includes request_id in URL' do
      expect(subject.add_request_ids).to eql(true)
    end
  end

  context 'push' do
    let(:client_options) { { key: 'appid.keyuid:keysecret' } }

    specify '#device is not supported and raises an exception' do
      expect { subject.device }.to raise_error Ably::Exceptions::PushNotificationsNotSupported
    end

    specify '#push returns a Push object' do
      expect(subject.push).to be_a(Ably::Rest::Push)
    end
  end

  context 'log exception report' do
    let(:client_options) { { key: 'appid.keyuid:keysecret' } }

    before { allow(subject).to receive(:send_request).with(:get, '/insecure_request', {}, {}).and_raise(Ably::Exceptions::InsecureRequest.new('log report')) }
    before { expect(subject).to receive(:log_exception_report).with(Ably::Exceptions::InsecureRequest) }

    after { ENV['LOG_EXCEPTION_REPORT'] = 'false' }

    context 'when LOG_EXCEPTION_REPORT is enabled' do
      let(:request) { subject.get('/insecure_request', {}, { disable_automatic_reauthorize: true }) }

      before { ENV['LOG_EXCEPTION_REPORT'] = 'true' }

      it 'should call log_exception_report' do
        expect { request }.to raise_error(Ably::Exceptions::InsecureRequest)
      end
    end
  end
end
