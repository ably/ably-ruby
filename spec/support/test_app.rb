require 'singleton'

class TestApp
  APP_SPEC = {
    'keys' => [
      {},
      {
        'capability' => '{ "cansubscribe:*":["subscribe"], "canpublish:*":["publish"], "canpublish:andpresence":["presence","publish"] }'
      }
    ],
    'namespaces' => [
      { 'id' => 'persisted', 'persisted' => true }
    ],
    'channels' => [
      {
        'name' => 'persisted:presence_fixtures',
        'presence' => [
          { 'clientId' => 'client_bool',    'data' => 'true' },
          { 'clientId' => 'client_int',     'data' => '24' },
          { 'clientId' => 'client_string',  'data' => 'This is a string clientData payload' },
          { 'clientId' => 'client_json',    'data' => '{ "test" => \'This is a JSONObject clientData payload\'}' }
        ]
      }
    ]
  }

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
    @attributes["appId"]
  end

  def key
    @attributes["keys"].first
  end

  def restricted_key
    @attributes["keys"][1]
  end

  def key_id
    "#{app_id}.#{key['id']}"
  end

  def key_value
    key['value']
  end

  def api_key
    "#{key_id}:#{key_value}"
  end

  def restricted_api_key
    "#{app_id}.#{restricted_key['id']}:#{restricted_key['value']}"
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
