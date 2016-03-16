require 'spec_helper'

describe 'Ably::Rest through a Proxy' do
  vary_by_protocol do
    let(:token) { Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol).auth.request_token }
    let(:client) { Ably::Rest::Client.new(client_options) }

    [true, false].each do |tls_enabled|
      let(:default_options) do
        { token: token, environment: environment, protocol: protocol, tls: tls_enabled }
      end

      context "with TLS #{tls_enabled ? 'enabled' : 'disabled'}" do
        context 'without authentication' do
          let(:client_options) do
            default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6128 })
          end

          it 'should return the service time as a Time object' do
            expect(client.time).to be_within(2).of(Time.now)
          end
        end

        context 'with authentication' do
          let(:client_options) do
            default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6129, username: 'ably', password: 'password' })
          end

          it 'should return the service time as a Time object' do
            expect(client.time).to be_within(2).of(Time.now)
          end

          context 'and invalid credentials' do
            let(:client_options) do
              default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6129, username: 'wrong', password: 'wrong' })
            end

            it 'should raise an exception' do
              expect { client.time }.to raise_error(Ably::Exceptions::InvalidResponseBody)
            end
          end
        end

        context 'with invalid proxy details' do
          let(:client_options) do
            default_options.merge(proxy: { host: 'www.google.com', port: 80 })
          end

          it 'should raise an exception' do
            expect { client.time }.to raise_error(Ably::Exceptions::InvalidResponseBody)
          end
        end
      end
    end

    context 'with basic auth' do
      let(:default_options) do
        { key: api_key, environment: environment, protocol: protocol, tls: tls_enabled }
      end
      let(:client_options) do
        default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6128 })
      end

      context 'with TLS disabled' do
        let(:tls_enabled) { false }

        before do
          allow(client.auth).to receive(:ensure_api_key_sent_over_secure_connection)
        end

        it 'should reject a basic auth request' do
          expect { client.stats }.to raise_error(Ably::Exceptions::UnauthorizedRequest)
        end
      end

      context 'with TLS enabled' do
        let(:tls_enabled) { true }

        it 'should accept a basic auth request' do
          client.stats
        end
      end
    end
  end
end
