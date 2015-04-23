require 'singleton'

class TestApp
  TEST_RESOURCES_PATH = File.expand_path('../../../lib/submodules/ably-common/test-resources', __FILE__)

  # App configuration for test app
  # See https://github.com/ably/ably-common/blob/master/test-resources/test-app-setup.json
  APP_SPEC = JSON.parse(File.read(File.join(TEST_RESOURCES_PATH, 'test-app-setup.json')))['post_apps']

  # Cipher details used for client_encoded presence data in test app
  # See https://github.com/ably/ably-common/blob/master/test-resources/test-app-setup.json
  APP_SPEC_CIPHER = JSON.parse(File.read(File.join(TEST_RESOURCES_PATH, 'test-app-setup.json')))['cipher']

  # If an app has already been created and we need a new app, create a new test app
  # This is sometimes needed when a test needs to be isolated from any other tests
  def self.reload
    if instance_variable_get('@singleton__instance__')
      instance.delete
      instance.create_test_app
    end
  end

  include Singleton

  def initialize
    create_test_app
  end

  def app_id
    @attributes.fetch('appId')
  end

  def key
    @attributes.fetch('keys').first
  end

  def restricted_key
    @attributes.fetch('keys')[1]
  end

  def key_name
    key.fetch('keyName')
  end

  def key_secret
    key.fetch('keySecret')
  end

  def api_key
    key.fetch('keyStr')
  end

  def restricted_api_key
    restricted_key.fetch('keyStr')
  end

  def delete
    return unless TestApp.instance_variable_get('@singleton__instance__')

    url = "#{sandbox_client.endpoint}/apps/#{app_id}"

    basic_auth = Base64.encode64(api_key).chomp
    headers    = { "Authorization" => "Basic #{basic_auth}" }

    Faraday.delete(url, nil, headers)
  end

  def environment
    ENV['ABLY_ENV'] || 'sandbox'
  end

  def create_test_app
    url = "#{sandbox_client.endpoint}/apps"

    headers = {
      'Accept'       => 'application/json',
      'Content-Type' => 'application/json'
    }

    response = Faraday.post(url, APP_SPEC.to_json, headers)
    raise "Could not create test app.  Ably responded with status #{response.status}\n#{response.body}" unless (200..299).include?(response.status)

    @attributes = JSON.parse(response.body)

    puts "Test app '#{app_id}' created in #{environment} environment"
  end

  def host
    sandbox_client.endpoint.host
  end

  def realtime_host
    host.gsub(/rest/, 'realtime')
  end

  def create_test_stats(stats)
    client = Ably::Rest::Client.new(key: api_key, environment: environment)
    response = client.post('/stats', stats)
    raise "Could not create stats fixtures.  Ably responded with status #{response.status}\n#{response.body}" unless (200..299).include?(response.status)
  end

  private
  def sandbox_client
    @sandbox_client ||= Ably::Rest::Client.new(key: 'app.key:secret', tls: true, environment: environment)
  end
end
