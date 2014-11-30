require 'spec_helper'

describe Ably::Rest do
  let(:options) { { api_key: 'app.key:secret' } }

  specify 'constructor returns an Ably::Rest::Client' do
    expect(Ably::Rest.new(options)).to be_instance_of(Ably::Rest::Client)
  end

  describe Ably::Rest::Client do
    describe 'initializing the client' do
      it 'should disallow an invalid key' do
        expect { Ably::Rest::Client.new({}) }.to raise_error(ArgumentError, /api_key is missing/)
        expect { Ably::Rest::Client.new(api_key: 'invalid') }.to raise_error(ArgumentError, /api_key is invalid/)
        expect { Ably::Rest::Client.new(api_key: 'invalid:asdad') }.to raise_error(ArgumentError, /api_key is invalid/)
        expect { Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret') }.to_not raise_error
      end

      it 'should disallow api_key and key_id' do
        expect { Ably::Rest::Client.new(api_key: 'valid', key_id: 'invalid') }.to raise_error(ArgumentError, /api_key and key_id or key_secret are mutually exclusive/)
      end

      it 'should disallow api_key and key_secret' do
        expect { Ably::Rest::Client.new(api_key: 'valid', key_secret: 'invalid') }.to raise_error(ArgumentError, /api_key and key_id or key_secret are mutually exclusive/)
      end

      context 'using key_id and key_secret' do
        let(:client) { Ably::Rest::Client.new(key_id: 'id', key_secret: 'secret') }

        it 'should allow key_id and key_secret in place of api_key' do
          expect(client.auth.api_key).to eql('id:secret')
        end
      end

      context 'with a string key instead of options' do
        let(:options) { 'app.key:secret' }
        subject { Ably::Rest::Client.new(options) }

        it 'should set the api_key' do
          expect(subject.auth.api_key).to eql(options)
        end

        it 'should set the key_id' do
          expect(subject.auth.key_id).to eql('app.key')
        end

        it 'should set the key_secret' do
          expect(subject.auth.key_secret).to eql('secret')
        end
      end

      context 'with a client_id' do
        it "should require a valid key" do
          expect { Ably::Rest::Client.new(client_id: 'valid') }.to raise_error(ArgumentError, /client_id cannot be provided without a complete API key/)
        end
      end

      it 'should default to the production REST end point' do
        expect(Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret').endpoint.to_s).to eql('https://rest.ably.io')
      end

      it 'should allow an environment to be set' do
        expect(Ably::Rest::Client.new(api_key: 'appid.keyuid:keysecret', environment: 'sandbox').endpoint.to_s).to eql('https://sandbox-rest.ably.io')
      end

      context 'with TLS disabled' do
        let(:client) { Ably::Rest::Client.new(api_key: 'appid.keyid:secret', tls: false) }

        it 'uses plain text' do
          expect(client.use_tls?).to eql(false)
        end

        it 'uses HTTP' do
          expect(client.endpoint.to_s).to eql('http://rest.ably.io')
        end

        it 'fails when authenticating with basic auth' do
          expect { client.channel('a').publish('event', 'message') }.to raise_error(Ably::Exceptions::InsecureRequestError)
        end
      end

      context 'with no TLS option provided' do
        let(:client) { Ably::Rest::Client.new(api_key: 'appid.keyid:secret') }

        it 'defaults to TLS' do
          expect(client.use_tls?).to eql(true)
        end
      end

      context 'with alternative environment' do
        let(:client) { Ably::Rest::Client.new(api_key: 'appid.keyid:secret', environment: 'sandbox') }

        it 'should alter the endpoint' do
          expect(client.endpoint.to_s).to eql('https://sandbox-rest.ably.io')
        end
      end

      context 'delegators' do
        subject { Ably::Rest::Client.new(options) }

        it 'should delegate :client_id to .auth' do
          expect(subject.auth).to receive(:client_id).and_return('john')
          expect(subject.client_id).to eql('john')
        end

        it 'should delegate :auth_options to .auth' do
          expect(subject.auth).to receive(:auth_options).and_return({ option: 1 })
          expect(subject.auth_options).to eql({ option: 1 })
        end
      end

      context 'logger' do
        context 'defaults' do
          subject { Ably::Rest::Client.new(options) }

          it 'uses default Ruby Logger by default' do
            expect(subject.logger.logger).to be_a(::Logger)
          end

          it 'defaults to Logger::ERROR log level' do
            expect(subject.logger.log_level).to eql(::Logger::ERROR)
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
          subject { Ably::Rest::Client.new(options.merge(logger: custom_logger.new, log_level: :debug)) }

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
end
