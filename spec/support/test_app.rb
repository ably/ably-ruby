require "singleton"

class TestApp
  APP_SPEC = {
    "keys" => [
      {}
    ],
    "namespaces" => [
      { "id" => "persisted", "persisted" => true }
    ]
  }.to_json

  include Singleton

  def initialize
    url = "https://staging-rest.ably.io/apps"

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
    url = "https://staging-rest.ably.io/apps/#{app_id}"

    basic_auth = Base64.encode64(api_key).chomp
    headers    = { "Authorization" => "Basic #{basic_auth}" }

    Faraday.delete(url, nil, headers)
  end
end
