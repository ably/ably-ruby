# encoding: utf-8

shared_examples 'a client initializer' do
  def subdomain
    if rest?
      'rest'
    else
      'realtime'
    end
  end

  def protocol
    if rest?
      'http'
    else
      'ws'
    end
  end

  def rest?
    subject.kind_of?(Ably::Rest::Client)
  end

  context 'with invalid arguments' do
    context 'empty hash' do
      let(:client_options) { Hash.new }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is missing/)
      end
    end

    context 'nil' do
      let(:client_options) { nil }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /Options Hash is expected/)
      end
    end

    context 'key: "invalid"' do
      let(:client_options) { { key: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is invalid/)
      end
    end

    context 'key: "invalid:asdad"' do
      let(:client_options) { { key: 'invalid:asdad' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key is invalid/)
      end
    end

    context 'key and key_name' do
      let(:client_options) { { key: 'appid.keyuid:keysecret', key_name: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key and key_name or key_secret are mutually exclusive/)
      end
    end

    context 'key and key_secret' do
      let(:client_options) { { key: 'appid.keyuid:keysecret', key_secret: 'invalid' } }

      it 'raises an exception' do
        expect { subject }.to raise_error(ArgumentError, /key and key_name or key_secret are mutually exclusive/)
      end
    end
  end

  context 'with valid arguments' do
    let(:default_options) { { key: 'appid.keyuid:keysecret', auto_connect: false } }
    let(:client_options)  { default_options }

    context 'key only' do
      it 'connects to the Ably service' do
        expect { subject }.to_not raise_error
      end

      it 'uses basic auth' do
        expect(subject.auth).to be_using_basic_auth
      end
    end

    context 'key_name and key_secret', api_private: true do
      let(:client_options) { { key_name: 'id', key_secret: 'secret', auto_connect: false } }

      it 'constructs a key' do
        expect(subject.auth.key).to eql('id:secret')
      end
    end

    context 'with a string key instead of options hash' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      let(:client_options) { 'App.k3y:sec-r3t' }

      it 'sets the key' do
        expect(subject.auth.key).to eql(client_options)
      end

      it 'sets the key_name' do
        expect(subject.auth.key_name).to eql('App.k3y')
      end

      it 'sets the key_secret' do
        expect(subject.auth.key_secret).to eql('sec-r3t')
      end

      it 'uses basic auth' do
        expect(subject.auth).to be_using_basic_auth
      end
    end

    context 'with a string token key instead of options hash' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      let(:client_options) { 'app.kjhkasjhdsakdh127g7g1271' }

      it 'sets the token' do
        expect(subject.auth.current_token_details.token).to eql(client_options)
      end
    end

    context 'with token' do
      let(:client_options) { { token: 'token', auth_connect: false } }

      it 'sets the token' do
        expect(subject.auth.current_token_details.token).to eql('token')
      end
    end

    context 'with token_details' do
      let(:client_options) { { token_details: Ably::Models::TokenDetails.new(token: 'token'), auto_connect: false } }

      it 'sets the token' do
        expect(subject.auth.current_token_details.token).to eql('token')
      end
    end

    context 'with token_params' do
      let(:client_options) { { default_token_params: { ttl: 777, client_id: 'john' }, token: 'token', auto_connect: false } }

      it 'configures default_token_params' do
        expect(subject.auth.token_params.fetch(:ttl)).to eql(777)
        expect(subject.auth.token_params.fetch(:client_id)).to eql('john')
      end
    end

    context 'endpoint' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      it 'defaults to production' do
        expect(subject.endpoint.to_s).to eql("#{protocol}s://#{subdomain}.ably.io")
      end

      context 'with environment option' do
        let(:client_options) { default_options.merge(environment: 'sandbox', auto_connect: false) }

        it 'uses an alternate endpoint' do
          expect(subject.endpoint.to_s).to eql("#{protocol}s://sandbox-#{subdomain}.ably.io")
        end
      end

      context 'with rest_host option' do
        let(:client_options) { default_options.merge(rest_host: 'custom-rest.host.com', auto_connect: false) }

        it 'uses an alternate endpoint for REST clients' do
          skip 'does not apply as testing a Realtime client' unless rest?
          expect(subject.endpoint.to_s).to eql("#{protocol}s://custom-rest.host.com")
        end
      end

      context 'with realtime_host option' do
        let(:client_options) { default_options.merge(realtime_host: 'custom-realtime.host.com', auto_connect: false) }

        it 'uses an alternate endpoint for Realtime clients' do
          skip 'does not apply as testing a REST client' if rest?
          expect(subject.endpoint.to_s).to eql("#{protocol}s://custom-realtime.host.com")
        end
      end

      context 'with port option and non-TLS connections' do
        let(:client_options) { default_options.merge(port: 999, tls: false, auto_connect: false) }

        it 'uses the custom port for non-TLS requests' do
          expect(subject.endpoint.to_s).to include(":999")
        end
      end

      context 'with tls_port option and a TLS connection' do
        let(:client_options) { default_options.merge(tls_port: 666, tls: true, auto_connect: false) }

        it 'uses the custom port for TLS requests' do
          expect(subject.endpoint.to_s).to include(":666")
        end
      end
    end

    context 'tls' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      context 'set to false' do
        let(:client_options) { default_options.merge(tls: false, auto_connect: false) }

        it 'uses plain text' do
          expect(subject.use_tls?).to eql(false)
        end

        it 'uses HTTP' do
          expect(subject.endpoint.to_s).to eql("#{protocol}://#{subdomain}.ably.io")
        end
      end

      it 'defaults to TLS' do
        expect(subject.use_tls?).to eql(true)
      end
    end

    context 'logger' do
      before do
        allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
      end

      context 'default' do
        it 'uses Ruby Logger' do
          expect(subject.logger.logger).to be_a(::Logger)
        end

        it 'specifies Logger::WARN log level' do
          expect(subject.logger.log_level).to eql(::Logger::WARN)
        end
      end

      context 'with log_level :none' do
        let(:client_options) { default_options.merge(log_level: :none, auto_connect: false) }

        it 'silences all logging with a NilLogger' do
          expect(subject.logger.logger.class).to eql(Ably::Models::NilLogger)
          expect(subject.logger.log_level).to eql(:none)
        end
      end

      context 'with custom logger and log_level' do
        let(:custom_logger) { TestLogger }
        let(:client_options) { default_options.merge(logger: custom_logger.new, log_level: Logger::DEBUG, auto_connect: false) }

        it 'uses the custom logger' do
          expect(subject.logger.logger.class).to eql(custom_logger)
        end

        it 'sets the custom log level' do
          expect(subject.logger.log_level).to eql(Logger::DEBUG)
        end
      end
    end

    context 'environment' do
      context 'when set without custom fallback hosts configured' do
        let(:environment) { 'foo' }
        let(:client_options) { default_options.merge(environment: environment) }
        let(:default_fallbacks) { %w(a b c d e).map { |id| "#{environment}-#{id}-fallback.ably-realtime.com" } }

        it 'sets the environment attribute' do
          expect(subject.environment).to eql(environment)
        end

        it 'uses the default fallback hosts (#TBC, see https://github.com/ably/wiki/issues/361)' do
          expect(subject.fallback_hosts.sort).to eql(default_fallbacks)
        end
      end

      context 'when set with custom fallback hosts configured' do
        let(:environment) { 'foo' }
        let(:custom_fallbacks) { %w(a b c).map { |id| "#{environment}-#{id}.foo.com" } }
        let(:client_options) { default_options.merge(environment: environment, fallback_hosts: custom_fallbacks) }

        it 'sets the environment attribute' do
          expect(subject.environment).to eql(environment)
        end

        it 'uses the custom provided fallback hosts (#RSC15a)' do
          expect(subject.fallback_hosts.sort).to eql(custom_fallbacks)
        end
      end

      context 'when set with fallback_hosts_use_default' do
        let(:environment) { 'foo' }
        let(:custom_fallbacks) { %w(a b c).map { |id| "#{environment}-#{id}.foo.com" } }
        let(:default_production_fallbacks) { %w(a b c d e).map { |id| "#{id}.ably-realtime.com" } }
        let(:client_options) { default_options.merge(environment: environment, fallback_hosts_use_default: true) }

        it 'sets the environment attribute' do
          expect(subject.environment).to eql(environment)
        end

        it 'uses the production default fallback hosts (#RTN17b)' do
          expect(subject.fallback_hosts.sort).to eql(default_production_fallbacks)
        end
      end
    end

    context 'rest_host' do
      context 'when set without custom fallback hosts configured' do
        let(:custom_rest_host) { 'foo.com' }
        let(:client_options) { default_options.merge(rest_host: custom_rest_host) }

        it 'sets the custom_host attribute' do
          expect(subject.custom_host).to eql(custom_rest_host)
        end

        it 'has no default fallback hosts' do
          expect(subject.fallback_hosts).to be_empty
        end
      end

      context 'when set with environment and without custom fallback hosts configured' do
        let(:environment) { 'foobar' }
        let(:custom_rest_host) { 'foo.com' }
        let(:client_options) { default_options.merge(environment: environment, rest_host: custom_rest_host) }

        it 'sets the environment attribute' do
          expect(subject.environment).to eql(environment)
        end

        it 'sets the custom_host attribute' do
          expect(subject.custom_host).to eql(custom_rest_host)
        end

        it 'has no default fallback hosts' do
          expect(subject.fallback_hosts).to be_empty
        end
      end

      context 'when set with custom fallback hosts configured' do
        let(:custom_rest_host) { 'foo.com' }
        let(:custom_fallbacks) { %w(a b c).map { |id| "#{environment}-#{id}.foo.com" } }
        let(:client_options) { default_options.merge(rest_host: custom_rest_host, fallback_hosts: custom_fallbacks) }

        it 'sets the custom_host attribute' do
          expect(subject.custom_host).to eql(custom_rest_host)
        end

        it 'has no default fallback hosts' do
          expect(subject.fallback_hosts.sort).to eql(custom_fallbacks)
        end
      end
    end

    context 'realtime_host' do
      context 'when set without custom fallback hosts configured' do
        let(:custom_realtime_host) { 'realtime.foo.com' }
        let(:client_options) { default_options.merge(realtime_host: custom_realtime_host) }

        # These tests are shared between realtime & rest clients
        # So don't test for the attribute, instead test the options
        it 'sets the realtime_host option' do
          expect(subject.options[:realtime_host]).to eql(custom_realtime_host)
        end

        it 'has no default fallback hosts' do
          expect(subject.fallback_hosts).to be_empty
        end
      end
    end

    context 'custom port' do
      context 'when set without custom fallback hosts configured' do
        let(:custom_port) { 555 }
        let(:client_options) { default_options.merge(port: custom_port) }

        it 'has no default fallback hosts' do
          expect(subject.fallback_hosts).to be_empty
        end
      end
    end

    context 'custom TLS port' do
      context 'when set without custom fallback hosts configured' do
        let(:custom_port) { 555 }
        let(:client_options) { default_options.merge(tls_port: custom_port) }

        it 'has no default fallback hosts' do
          expect(subject.fallback_hosts).to be_empty
        end
      end
    end
  end

  context 'delegators' do
    before do
      allow_any_instance_of(subject.class).to receive(:auto_connect).and_return(false)
    end

    let(:client_options) { 'app.key:secret' }

    it 'delegates :client_id to .auth' do
      expect(subject.auth).to receive(:client_id).and_return('john')
      expect(subject.client_id).to eql('john')
    end

    it 'delegates :auth_options to .auth' do
      expect(subject.auth).to receive(:auth_options).and_return({ option: 1 })
      expect(subject.auth_options).to eql({ option: 1 })
    end
  end
end
