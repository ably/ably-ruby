# encoding: utf-8
require 'spec_helper'
require 'ostruct'

describe 'Ably::Realtime::Connection through a Proxy', :event_machine do
  let(:connection) { client.connection }
  let(:channel)    { client.channels.get(random_str) }
  let(:client)     { auto_close Ably::Realtime::Client.new(client_options) }
  let(:token)      { Ably::Rest::Client.new(key: api_key, environment: environment, protocol: protocol).auth.request_token }
  let(:default_options) do
    { token: token, environment: environment, protocol: protocol, disconnected_retry_timeout: 2 }
  end

  vary_by_protocol do
    context 'using TLS' do
      context 'without authentication' do
        let(:no_auth_proxy_options) do
          default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6128 })
        end

        let(:client_options) { no_auth_proxy_options }

        it 'connects and publishes a message' do
          connection.on(:connected) do
            channel.publish('event') do
              stop_reactor
            end
          end
        end
      end

      context 'without authentication against an invalid proxy host' do
        let(:no_auth_proxy_options) do
          default_options.merge(proxy: { host: 'www.google.com', port: 80 })
        end

        let(:client_options) { no_auth_proxy_options.merge(log_level: :fatal) }

        it 'fails to connect' do
          connection.on(:disconnected) do
            expect(connection.error_reason).to be_a(Ably::Exceptions::ConnectionError)
            stop_reactor
          end
        end
      end

      context 'with basic authentication' do
        let(:no_auth_proxy_options) do
          default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6129, username: 'ably', password: 'password' })
        end

        let(:client_options) { no_auth_proxy_options }

        it 'connects and publishes a message' do
          connection.on(:connected) do
            channel.publish('event') do
              stop_reactor
            end
          end
        end
      end

      context 'with invalid authentication details' do
        let(:no_auth_proxy_options) do
          default_options.merge(proxy: { host: 'sandbox-proxy.ably.io', port: 6129, username: 'invalid', password: 'invalid' })
        end

        let(:client_options) { no_auth_proxy_options.merge(log_level: :fatal) }

        it 'fails to connect' do
          connection.on(:disconnected) do
            expect(connection.error_reason).to be_a(Ably::Exceptions::ConnectionError)
            stop_reactor
          end
        end
      end
    end
  end
end
