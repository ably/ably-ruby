require "singleton"

class TestApp
  APP_SPEC = {
    'keys' => [
      {}
    ],
    'namespaces' => [
      { 'id' => 'persisted', 'persisted' => true }
    ]
    # ],
    # 'channels' => [
    #   {
    #     'name' => 'persisted:presence_fixtures',
    #     'presence' => [
    #       { 'clientId' => 'client_bool',    'clientData' => true },
    #       { 'clientId' => 'client_int',     'clientData' => 24 },
    #       { 'clientId' => 'client_string',  'clientData' => 'This is a string clientData payload' },
    #       { 'clientId' => 'client_json',    'clientData' => { "test" => 'This is a JSONObject clientData payload'} }
    #     ]
    #   }
    # ]
  }.to_json

  include Singleton

  def initialize
    url = "#{sandbox_client.endpoint}/apps"

    headers = {
      "Accept"       => "application/json",
      "Content-Type" => "application/json"
    }

    response = Faraday.post(url, APP_SPEC, headers)

    @attributes = JSON.parse(response.body)
  end

  def app_id
    @attributes["id"]
  end

  def key
    @attributes["keys"].first
  end

  def key_id
    key["id"]
  end

  def key_value
    key["value"]
  end

  def api_key
    "#{app_id}.#{key_id}:#{key_value}"
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

  private
  def sandbox_client
    @sandbox_client ||= Ably::Rest::Client.new(api_key: 'app.key:secret', ssl: true, environment: environment)
  end
end
