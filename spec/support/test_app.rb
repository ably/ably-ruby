require "singleton"

class TestApp
  APP_SPEC = {
    'keys' => [
      {},
      {
        'capability' => '{ "*":["subscribe"], "canpublish:*":["publish"], "canpublish:andpresence":["presence","publish"] }'
      }
    ],
    'namespaces' => [
      { 'id' => 'persisted', 'persisted' => true }
    ],
    'channels' => [
      {
        'name' => 'persisted:presence_fixtures',
        'presence' => [
          { 'clientId' => 'client_bool',    'clientData' => true },
          { 'clientId' => 'client_int',     'clientData' => 24 },
          { 'clientId' => 'client_string',  'clientData' => 'This is a string clientData payload' },
          { 'clientId' => 'client_json',    'clientData' => { "test" => 'This is a JSONObject clientData payload'} }
        ]
      }
    ]
  }

  # If an app has already been created and we need a new app, create a new test app
  # This is sometimes needed when a test needs to be isolated from any other tests
  def self.reload
    instance.create_test_app if instance_variable_get('@singleton__instance__')
  end

  include Singleton

  def initialize
    create_test_app
  end

  def app_id
    @attributes["id"]
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
    url = "#{sandbox_client.endpoint}/apps/#{app_id}"

    basic_auth = Base64.encode64(api_key).chomp
    headers    = { "Authorization" => "Basic #{basic_auth}" }

    Faraday.delete(url, nil, headers)
  end

  def environment
    'sandbox'
  end

  def create_test_app
    url = "#{sandbox_client.endpoint}/apps"

    headers = {
      "Accept"       => "application/json",
      "Content-Type" => "application/json"
    }

    response = Faraday.post(url, APP_SPEC.to_json, headers)

    @attributes = JSON.parse(response.body)
  end

  private
  def sandbox_client
    @sandbox_client ||= Ably::Rest::Client.new(api_key: 'app.key:secret', tls: true, environment: environment)
  end
end
